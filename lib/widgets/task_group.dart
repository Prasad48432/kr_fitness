import 'package:flutter/material.dart';

class TaskGroupContainer extends StatelessWidget {
  final Color color;
  final bool? isSmall;
  final IconData icon;
  final String taskGroup;
  final String taskCount;
  final Function()? onTap;
  final Color IconColor;
  final Color TitleColor; // Added onTap parameter
  final double subtitleFontSize;

  const TaskGroupContainer({
    Key? key,
    required this.color,
    this.isSmall = false,
    required this.icon,
    required this.taskGroup,
    required this.taskCount,
    required this.IconColor,
    required this.TitleColor,
    required this.subtitleFontSize,
    this.onTap, // Added onTap parameter
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Use onTap parameter here
      child: Container(
        height: 300,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              height: 5,
            ),
            Align(
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 50,
                color: IconColor,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              taskGroup,
              maxLines: 2,
              overflow: TextOverflow.fade,
              style: TextStyle(
                color: TitleColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 0),
            Text(
              "$taskCount",
              style: TextStyle(
                color: Colors.white,
                fontSize: subtitleFontSize,
              ),
            ),
            const SizedBox(
              height: 5,
            ),
          ],
        ),
      ),
    );
  }
}
