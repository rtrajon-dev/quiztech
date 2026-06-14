import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks whether quiz sound effects are enabled. Toggled from the drawer.
class SoundViewModel extends Notifier<bool> {
  @override
  bool build() => true;

  bool get soundOn => state;

  void toggleSound(bool value) => state = value;
}

final soundViewModelProvider =
    NotifierProvider<SoundViewModel, bool>(SoundViewModel.new);
