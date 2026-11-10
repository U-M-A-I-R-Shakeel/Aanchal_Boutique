import 'package:flutter/material.dart';

import '../../domain/models/room.dart';
import 'status_badge.dart';

class RoomCard extends StatelessWidget {
  const RoomCard({super.key, required this.room, this.onTap});

  final Room room;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.checkroom,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  room.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              StatusBadge(status: room.status),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: room.canBook
                    ? theme.colorScheme.onSurfaceVariant
                    : Colors.transparent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
