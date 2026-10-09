import 'package:flutter/material.dart';

/// Anchor popovers to a non-zero screen rect on iPad (share_plus).
/// This is also safe to supply on Android and iPhone.
Rect shareSheetOrigin(BuildContext context) {
  final render = context.findRenderObject();
  if (render is RenderBox && render.hasSize) {
    final center = render.localToGlobal(render.size.center(Offset.zero));
    return Rect.fromCenter(center: center, width: 2, height: 2);
  }
  return const Rect.fromLTWH(1, 1, 2, 2);
}
