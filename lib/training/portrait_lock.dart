import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Keeps the app in portrait while any [PortraitLock] is in the tree (P07 to P09, SCRUM-45).
///
/// The screens stack on top of each other, so the lock is released only when the last one
/// leaves; otherwise closing P08 would unlock P07 underneath it.
class PortraitLock extends StatefulWidget {
  const PortraitLock({super.key, required this.child});

  final Widget child;

  @override
  State<PortraitLock> createState() => _PortraitLockState();
}

class _PortraitLockState extends State<PortraitLock> {
  static var _holders = 0;

  @override
  void initState() {
    super.initState();
    if (_holders++ == 0) SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    if (--_holders == 0) SystemChrome.setPreferredOrientations([]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
