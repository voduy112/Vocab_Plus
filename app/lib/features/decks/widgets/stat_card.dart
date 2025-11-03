// import 'package:flutter/material.dart';

// class StatCard extends StatelessWidget {
//   final String title;
//   final String value;
//   final Color color;

//   const StatCard({
//     super.key,
//     required this.title,
//     required this.value,
//     required this.color,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Column(
//         children: [
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: color,
//             ),
//           ),
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 12,
//               color: color,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
