import 'package:flutter/services.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static final AudioPlayer _beepPlayer = AudioPlayer();
  
  // Custom SOS beep sound file path
  static const String _sosBeepSound = 'sounds/beep.mp3'; // User's custom beep file
  
  // Initialize audio service
  static Future<void> initialize() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.stop);
    await _beepPlayer.setReleaseMode(ReleaseMode.stop);
  }
  
  // Play custom SOS beep sound
  static Future<void> playCustomSosBeep() async {
    try {
      await _beepPlayer.play(AssetSource(_sosBeepSound));
    } catch (e) {
      print('Error playing custom beep: $e');
      // No fallback - only use custom beep
    }
  }
  
  // Play multiple custom SOS beeps for emergency start
  static Future<void> playEmergencyStartSound() async {
    try {
      // Play urgent alert beeps for emergency start
      await playCustomSosBeep();
      await Future.delayed(Duration(milliseconds: 200));
      await playCustomSosBeep();
      await Future.delayed(Duration(milliseconds: 200));
      await playCustomSosBeep();
      
      // Add haptic feedback
      HapticFeedback.heavyImpact();
    } catch (e) {
      print('Error playing emergency start sound: $e');
      // No fallback - only use custom beep
    }
  }
  
  // Play countdown beep (regular intervals)
  static Future<void> playCountdownBeep() async {
    try {
      await playCustomSosBeep();
    } catch (e) {
      print('Error playing countdown beep: $e');
      // No fallback - only use custom beep
    }
  }
  
  // Play urgent beeping for last 3 seconds
  static Future<void> playUrgentBeep() async {
    try {
      // Rapid custom beeps for urgency
      await playCustomSosBeep();
      await Future.delayed(Duration(milliseconds: 100));
      await playCustomSosBeep();
    } catch (e) {
      print('Error playing urgent beep: $e');
      // No fallback - only use custom beep
    }
  }
  
  // Play continuous emergency alarm when activated
  static Future<void> playEmergencyActiveSound() async {
    try {
      // Play continuous alarm pattern for emergency activation
      for (int i = 0; i < 10; i++) {
        await playCustomSosBeep();
        await Future.delayed(Duration(milliseconds: 100));
      }
    } catch (e) {
      print('Error playing emergency active sound: $e');
      // No fallback - only use custom beep
    }
  }
  
  // Play cancellation sound
  static Future<void> playCancellationSound() async {
    try {
      // Play descending custom beeps for cancellation
      await playCustomSosBeep();
      await Future.delayed(Duration(milliseconds: 150));
      await playCustomSosBeep();
      await Future.delayed(Duration(milliseconds: 150));
      await playCustomSosBeep();
    } catch (e) {
      print('Error playing cancellation sound: $e');
      // No fallback - only use custom beep
    }
  }
  
  // Stop all audio playback
  static Future<void> stopAllAudio() async {
    try {
      await _audioPlayer.stop();
      await _beepPlayer.stop();
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }
  
  // Set volume for audio players
  static Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume);
      await _beepPlayer.setVolume(volume);
    } catch (e) {
      print('Error setting volume: $e');
    }
  }
  
  // Dispose audio resources
  static Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
      await _beepPlayer.dispose();
    } catch (e) {
      print('Error disposing audio players: $e');
    }
  }
  
  // Test if custom audio file exists and can be played
  static Future<bool> testCustomAudio() async {
    try {
      await _beepPlayer.play(AssetSource(_sosBeepSound));
      await Future.delayed(Duration(milliseconds: 100));
      await _beepPlayer.stop();
      print('Custom beep.mp3 audio test successful!');
      return true;
    } catch (e) {
      print('Custom beep.mp3 audio test failed: $e');
      return false;
    }
  }
} 