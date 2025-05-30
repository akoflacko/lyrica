import 'dart:async';
import 'dart:io';

import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path_provider;

/// {@template text_to_speech_dialog}
/// TextToSpeechDialog widget.
/// {@endtemplate}
class TextToSpeechDialog extends StatefulWidget {
  /// {@macro text_to_speech_dialog}
  const TextToSpeechDialog({
    required this.id,
    required this.content,
    super.key, // ignore: unused_element
  });

  /// Poem identifier.
  final int id;

  /// Shows the text-to-speech dialog and returns the audio file path.
  final String content;

  /// Shows the text-to-speech dialog and returns the audio file path.
  static Future<void> show(
    BuildContext context, {
    required int id,
    required String content,
  }) =>
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => TextToSpeechDialog(
          id: id,
          content: content,
        ),
      );

  @override
  State<TextToSpeechDialog> createState() => _TextToSpeechDialogState();
}

/// State for widget TextToSpeechDialog.
class _TextToSpeechDialogState extends State<TextToSpeechDialog> {
  bool _isProcessing = false;
  bool _isPlaying = false;
  bool _isCompleted = false;

  String? _errorMessage;

  // Create the audio file using OpenAI API
  Future<void> _createAudioFile() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final directory = await path_provider.getTemporaryDirectory();

      final audioName = 'audio_${widget.id}';
      final audioFile = File(path.join(directory.path, '$audioName.aac'));

      if (audioFile.existsSync()) {
        await _player.setFilePath(audioFile.path);
        _player.play();
        return;
      }

      final result = await OpenAI.instance.audio.createSpeech(
        input: widget.content,
        model: 'gpt-4o-mini-tts',
        responseFormat: OpenAIAudioSpeechResponseFormat.aac,
        voice: 'nova',
        outputDirectory: directory,
        outputFileName: audioName,
      );

      await _player.setFilePath(result.path);
      _player.play();
    } catch (e) {
      _errorMessage = 'Error creating audio file: $e';
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  late final AudioPlayer _player;

  StreamSubscription<PlayerEvent>? _isPlayingSubscription;

  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  /* #region Lifecycle */
  @override
  void initState() {
    super.initState();

    _player = AudioPlayer();
    _player.setLoopMode(LoopMode.off);

    _isPlayingSubscription = _player.playerEventStream.listen(
      (event) {
        final isPlaying = event.playing;
        if (isPlaying == _isPlaying) return;

        setState(() => _isPlaying = event.playing);
      },
      onDone: () {
        _isPlayingSubscription?.cancel();
        _isPlayingSubscription = null;
      },
    );

    // listen when the audio is finished playing
    _player.playerStateStream.listen(
      (state) {
        if (state.processingState == ProcessingState.completed) {
          setState(
            () {
              _isPlaying = false;
              _isCompleted = true;
            },
          );
        }
      },
    );

    _createAudioFile();
  }

  @override
  void dispose() {
    _isPlayingSubscription?.cancel();
    _isPlayingSubscription = null;

    _player.dispose();

    super.dispose();
  }
  /* #endregion */

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Text to Speech'),
        alignment: Alignment.center,
        content: SizedBox(
          height: 240,
          child: Center(
            child: _isProcessing
                ? CircularProgressIndicator.adaptive()
                : _errorMessage != null
                    ? Text(_errorMessage!)
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: _isPlaying
                                ? _player.pause
                                : () {
                                    if (_isCompleted) {
                                      _player.seek(Duration.zero);
                                      _isCompleted = false;
                                    }
                                    _player.play();
                                  },
                            child: Text(_isPlaying ? 'Pause' : 'Play'),
                          ),
                        ],
                      ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      );
}
