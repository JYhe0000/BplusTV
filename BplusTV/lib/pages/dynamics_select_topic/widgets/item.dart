import 'package:bplus_tv/common/widgets/custom_icon.dart';
import 'package:bplus_tv/models_new/dynamic/dyn_topic_top/topic_item.dart';
import 'package:bplus_tv/utils/num_utils.dart';
import 'package:material_ui/material_ui.dart';

class DynTopicItem extends StatelessWidget {
  const DynTopicItem({
    super.key,
    required this.item,
    required this.onTap,
  });

  final TopicItem item;
  final ValueChanged<TopicItem> onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        minVerticalPadding: 12,
        onTap: () => onTap(item),
        leading: const Icon(CustomIcons.topic_tag, size: 24),
        title: Text(
          item.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 18,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${NumUtils.numFormat(item.view)}浏览 · ${NumUtils.numFormat(item.discuss)}讨论',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
    );
  }
}
