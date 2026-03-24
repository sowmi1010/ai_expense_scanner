import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/controllers/voice_assistant_controller.dart';

class VoiceQueryScreen extends ConsumerStatefulWidget {
  const VoiceQueryScreen({super.key});

  @override
  ConsumerState<VoiceQueryScreen> createState() => _VoiceQueryScreenState();
}

class _VoiceQueryScreenState extends ConsumerState<VoiceQueryScreen> {
  String _heard = 'Tap mic and speak';
  String _status = 'Try: "I paid 250 in gpay for recharge"';
  bool _listening = false;
  bool _processing = false;

  Future<void> _openManualCommandDialog() async {
    if (_processing) return;

    final controller = TextEditingController();
    final typed = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Type command'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'Example: paid 300 in cash for food',
            ),
            onSubmitted: (value) {
              Navigator.of(context).pop(value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Run'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (!mounted) return;
    if (typed == null || typed.trim().isEmpty) return;

    await _handleVoiceText(typed.trim().toLowerCase());
  }

  Future<void> _startListening() async {
    if (_listening || _processing) return;

    try {
      final startResult = await ref
          .read(voiceAssistantControllerProvider)
          .startListening(
            onListeningStart: () {
              setState(() {
                _listening = true;
                _status = 'Listening...';
              });
            },
            onListeningStop: () {
              if (mounted) {
                setState(() {
                  _listening = false;
                  if (!_processing) {
                    _status =
                        'Did not catch that. Try again or type your command manually.';
                  }
                });
              }
            },
            onResult: _handleVoiceText,
          );

      if (!startResult.started && mounted) {
        final message =
            startResult.message ??
            'Voice recognition unavailable. Please type your command manually.';
        setState(() {
          _listening = false;
          _status = message;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _listening = false;
        _status = 'Could not start voice assistant. Try again.';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Voice start failed: $e')));
    }
  }

  Future<void> _handleVoiceText(String text) async {
    setState(() {
      _heard = text;
      _processing = true;
      _status = 'Processing command...';
    });

    try {
      final result = await ref
          .read(voiceAssistantControllerProvider)
          .handleVoiceText(text);

      if (mounted) {
        if (result.showSnackBar) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(result.message)));
        }
        setState(() => _status = result.message);
      }
      final speakResult = await ref
          .read(voiceAssistantControllerProvider)
          .speak(result.message);
      if (mounted && !speakResult.success && speakResult.message != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(speakResult.message!)));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Something went wrong while handling your command.';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Voice processing failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Voice Assistant')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _heard,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_processing) ...[
                const SizedBox(height: 10),
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
              const SizedBox(height: 30),
              GestureDetector(
                onTap: (_listening || _processing) ? null : _startListening,
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: _processing
                      ? cs.secondary
                      : (_listening ? cs.error : cs.primary),
                  child: Icon(
                    _processing
                        ? Icons.hourglass_top_rounded
                        : (_listening ? Icons.mic : Icons.mic_none),
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _processing ? null : _openManualCommandDialog,
                icon: const Icon(Icons.keyboard_rounded),
                label: const Text('Type command instead'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
