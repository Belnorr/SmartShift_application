import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateShiftPage extends StatefulWidget {
  const CreateShiftPage({super.key});

  @override
  State<CreateShiftPage> createState() => _CreateShiftPageState();
}

class _CreateShiftPageState extends State<CreateShiftPage> {
  final _titleCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _payCtrl = TextEditingController();
  final _pointsCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();

  DateTime? _start;
  DateTime? _end;

  bool _loading = false;
  String _error = '';

  Future<void> _pickDateTime(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      if (isStart) {
        _start = dt;
      } else {
        _end = dt;
      }
    });
  }

  Future<void> _createShift() async {
    if (_start == null || _end == null) {
      setState(() => _error = 'Please select start and end time');
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection('shifts').add({
        'employerId': uid,
        'title': _titleCtrl.text.trim(),
        'company': _companyCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'startAt': Timestamp.fromDate(_start!),
        'endAt': Timestamp.fromDate(_end!),
        'payPerHour': int.parse(_payCtrl.text),
        'rewardPoints': int.parse(_pointsCtrl.text),
        'urgency': 3,
        'requiredSkills': ['Barista'],
        'capacity': int.parse(_capacityCtrl.text),
        'bookedCount': 0,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shift created')),
        );
        _titleCtrl.clear();
        _companyCtrl.clear();
        _locationCtrl.clear();
        _payCtrl.clear();
        _pointsCtrl.clear();
        _capacityCtrl.clear();
        setState(() {
          _start = null;
          _end = null;
        });
      }
    } catch (e) {
      setState(() => _error = 'Failed to create shift');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Shift'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _field(_titleCtrl, 'Job Title'),
            _field(_companyCtrl, 'Company'),
            _field(_locationCtrl, 'Location'),
            _field(_payCtrl, 'Pay per hour'),
            _field(_pointsCtrl, 'Reward points'),
            _field(_capacityCtrl, 'Capacity'),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDateTime(true),
                    child: Text(
                      _start == null
                          ? 'Select Start'
                          : _start.toString(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDateTime(false),
                    child: Text(
                      _end == null
                          ? 'Select End'
                          : _end.toString(),
                    ),
                  ),
                ),
              ],
            ),

            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _createShift,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Create Shift'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType:
            label.contains('Pay') || label.contains('Capacity')
                ? TextInputType.number
                : TextInputType.text,
      ),
    );
  }
}
