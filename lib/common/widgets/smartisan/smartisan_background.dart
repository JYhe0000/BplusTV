import 'package:bplus_tv/smartisan/smartisan_bars.dart';
import 'package:material_ui/material_ui.dart';

/// The Smartisan page bed: flat grey with the system's faint vertical
/// pinstripe. A single static paint — no animation, blur or capture.
class SmartisanBackground extends StatelessWidget {
  const SmartisanBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const SmartisanPinstripe(child: SizedBox.expand());
  }
}
