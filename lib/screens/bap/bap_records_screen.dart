import 'package:flutter/material.dart';
import 'bap_list_screen.dart';

class BAPRecordsScreen extends StatelessWidget {
  final String? studentId;

  const BAPRecordsScreen({super.key, this.studentId});

  @override
  Widget build(BuildContext context) {
    return BAPListScreen(studentId: studentId);
  }
}
