import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:poem/src/core/extension/build_context.dart';
import 'package:poem/src/core/widget/ui_text.dart';
import 'package:poem/src/features/poems/constant/constant.dart';

/// {@template select_font_bottom_modal_sheet}
/// SelectFontBottomModalSheet widget.
/// {@endtemplate}
class SelectFontBottomModalSheet extends StatelessWidget {
  /// {@macro select_font_bottom_modal_sheet}
  const SelectFontBottomModalSheet({
    this.selectedFontFamily,
    super.key, // ignore: unused_element
  });

  /// The font family selected.
  final String? selectedFontFamily;

  /// Show the modal bottom sheet to select a font.
  /// Returns the selected font family.
  static Future<String?> show(
    BuildContext context, {
    String? selectedFontFamily,
  }) =>
      showModalBottomSheet<String?>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) => SelectFontBottomModalSheet(
          selectedFontFamily: selectedFontFamily,
        ),
      );

  /* #endregion */
  @override
  Widget build(BuildContext context) => Ink(
        padding: const EdgeInsets.symmetric(
          vertical: 16.0,
        ),
        decoration: BoxDecoration(
          color: context.colors.background,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(
              12.0,
            ),
          ),
        ),
        child: Column(
          spacing: 16.0,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            UiText.bodyLarge(
              'Select Font',
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: fontFamilies.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(height: 8.0),
              itemBuilder: (BuildContext context, int index) {
                final fontFamily = fontFamilies[index];
                final isSelected = selectedFontFamily == fontFamily;

                final googleFont = GoogleFonts.getFont(
                  fontFamily,
                  textStyle: TextStyle(
                    color: selectedFontFamily == fontFamily
                        ? context.colors.primary
                        : null,
                  ),
                );

                return ListTile(
                  title: Text(
                    fontFamily,
                    style: googleFont,
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check,
                          color: context.colors.primary,
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(context, fontFamily);
                  },
                );
              },
            ),
          ],
        ),
      );
}
