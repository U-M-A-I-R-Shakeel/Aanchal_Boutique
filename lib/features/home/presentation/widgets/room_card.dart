import 'package:flutter/material.dart';

import '../../domain/models/room.dart';
import 'status_badge.dart';

class RoomCard extends StatelessWidget {
  const RoomCard({super.key, required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            StatusBadge(status: room.status),
          ],
        ),
      ),
    );
  }
}
