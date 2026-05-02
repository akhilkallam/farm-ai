import 'package:flutter/material.dart';

class VoiceRecorder extends StatelessWidget {
  final bool isRecording;
  final bool isSupported;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const VoiceRecorder({
    super.key,
    required this.isRecording,
    required this.isSupported,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: isSupported ? (_) => onStart() : null,
      onLongPressEnd: isSupported ? (_) => onStop() : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isRecording
              ? Colors.red
              : (isSupported ? const Color(0xFFDCFCE7) : Colors.grey.shade200),
          boxShadow: isRecording
              ? [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: Icon(
          isRecording ? Icons.stop_circle : Icons.mic,
          color: isRecording
              ? Colors.white
              : (isSupported ? const Color(0xFF166534) : Colors.grey),
          size: 28,
        ),
      ),
    );
  }
}
