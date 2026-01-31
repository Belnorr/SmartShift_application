import 'package:flutter/material.dart';

import 'urgency_chip.dart';
import 'points_chip.dart';
import 'tag_chip.dart';

class ShiftCard extends StatelessWidget {
  final String title;
  final String company;
  final String location;
  final String dateLabel;
  final int payPerHour;
  final int urgency;
  final int rewardPoints;
  final List<String> tags;
  final String imageUrl;

  const ShiftCard({
    super.key,
    required this.title,
    required this.company,
    required this.location,
    required this.dateLabel,
    required this.payPerHour,
    required this.urgency,
    required this.rewardPoints,
    required this.tags,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGE
          SizedBox(
            height: 160,
            width: double.infinity,
            child: Image.asset(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade300,
                child: const Center(
                  child: Icon(Icons.image_not_supported),
                ),
              ),
            ),
          ),

          // CONTENT
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TITLE + PAY
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '\$$payPerHour/h',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  company,
                  style: const TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 8),

                // LOCATION + DATE
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.calendar_today, size: 14),
                    const SizedBox(width: 4),
                    Text(dateLabel),
                  ],
                ),

                const SizedBox(height: 10),

                // TAGS + CHIPS
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    UrgencyChip(urgency),
                    PointsChip(rewardPoints),
                    ...tags.map((tag) => TagChip(tag)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
