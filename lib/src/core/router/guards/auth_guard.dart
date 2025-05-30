import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:octopus/octopus.dart';
import 'package:poem/src/features/auth/model/user.dart';

/// {@template auth_guard}
/// A guard that checks if the user is authenticated.
/// If the user is authenticated, it allows the navigation to continue.
/// If the user is not authenticated, it redirects to the sign-in page.
/// {@endtemplate}
class AuthGuard extends OctopusGuard {
  /// {@macro auth_guard}
  AuthGuard({
    required User? Function() getUser,
    required Set<String> routes,
    required OctopusState signInNavigation,
    required OctopusState homeNavigation,
    OctopusState? lastNavigation,
    super.refresh,
  })  : _getUser = getUser,
        _routes = routes,
        _lastNavigation = lastNavigation ?? homeNavigation,
        _signinNavigation = signInNavigation {
    // Get the last navigation from the platform default route.
    if (lastNavigation == null) {
      try {
        final platformDefault =
            WidgetsBinding.instance.platformDispatcher.defaultRouteName;
        final state = OctopusState.fromLocation(platformDefault);
        if (state.isNotEmpty) {
          _lastNavigation = state;
        }
      } on Object {/* ignore */}
    }
  }

  /// Get the current user.
  final User? Function() _getUser;

  /// Routes names that stand for the authentication routes.
  final Set<String> _routes;

  /// The navigation to use when the user is not authenticated.
  final OctopusState _signinNavigation;

  /// The navigation to use when the user is authenticated.
  OctopusState _lastNavigation;

  @override
  FutureOr<OctopusState> call(
    List<OctopusHistoryEntry> history,
    OctopusState$Mutable state,
    Map<String, Object?> context,
  ) async {
    final user = await _getUser(); // Get the current user.
    context['user'] = user; // Save the user in the context.

    final isAuthNav = state.children.any(
      (child) => _routes.contains(
        child.name,
      ),
    );

    final isEmailVerified = user?.isEmailVerified == true;

    if (isAuthNav) {
      // New state is an authentication navigation.
      if (isEmailVerified) {
        // User authenticated.
        // Remove any navigation that is an authentication navigation.
        state.removeWhere((child) => _routes.contains(child.name));
        // Restore the last navigation when the user is authenticated
        // if the state contains only the authentication routes.
        return state.isEmpty ? _lastNavigation : state;
      } else {
        // User not authenticated.
        // Remove any navigation that is not an authentication navigation.
        state.removeWhere((child) => !_routes.contains(child.name));
        // Add the signin navigation if the state is empty.
        // Or return the state if it contains the signin navigation.
        return state.isEmpty ? _signinNavigation : state;
      }
    } else {
      // New state is not an authentication navigation.
      if (isEmailVerified) {
        // User authenticated.
        // Save the current navigation as the last navigation.
        return super.call(history, state, context);
      } else {
        // User not authenticated.
        // Replace the current navigation with the signin navigation.
        return _signinNavigation;
      }
    }
  }
}
