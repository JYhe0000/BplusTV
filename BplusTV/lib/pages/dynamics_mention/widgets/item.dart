import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/models/common/image_type.dart';
import 'package:bplus_tv/models_new/dynamic/dyn_mention/item.dart';
import 'package:bplus_tv/utils/num_utils.dart';
import 'package:material_ui/material_ui.dart';

class DynMentionItem extends StatelessWidget {
  const DynMentionItem({
    super.key,
    required this.item,
    required this.onTap,
    required this.onCheck,
  });

  final MentionItem item;
  final VoidCallback onTap;
  final ValueChanged<bool?> onCheck;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        minVerticalPadding: 10,
        visualDensity: .standard,
        leading: NetworkImgLayer(
          src: item.face,
          width: 48,
          height: 48,
          type: ImageType.avatar,
        ),
        title: Text(
          item.name!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: MediaQuery.sizeOf(context).width >= 1280 ? 18 : 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${NumUtils.numFormat(item.fans)}粉丝',
          style: TextStyle(
            color: Theme.of(context).colorScheme.outline,
            fontSize: 14,
          ),
        ),
        trailing: Checkbox(
          materialTapTargetSize: MaterialTapTargetSize.padded,
          tristate: false,
          value: item.checked,
          onChanged: (value) {
            item.checked = value!;
            (context as Element).markNeedsBuild();
            onCheck(value);
          },
        ),
      ),
    );
  }
}
