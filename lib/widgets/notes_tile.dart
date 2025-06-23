import 'dart:async';

import 'package:flutter/cupertino.dart';

class NoteTile extends StatelessWidget {
  final String title;
  final String time;
  final String snippet;
  final String folder;

  final FutureOr<void> Function()? onTap;

  const NoteTile({
    super.key,
    required this.title,
    required this.snippet,
    required this.folder,
    this.onTap,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoListTile.notched(
      title: Text(title),
      subtitle: Column(
        children: [
          Text(
            '$time $snippet',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              color: CupertinoDynamicColor.resolve(
                CupertinoColors.secondaryLabel,
                context,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.folder,
                color: CupertinoDynamicColor.resolve(
                  CupertinoColors.secondaryLabel,
                  context,
                ),
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                folder,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  color: CupertinoDynamicColor.resolve(
                    CupertinoColors.secondaryLabel,
                    context,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),

      onTap: onTap,
    );
  }
}
