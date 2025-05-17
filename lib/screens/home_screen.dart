import 'dart:async';
import 'package:flutter/material.dart';
import '../services/motion_service.dart';
import '../services/alarm_service.dart';
import '../models/detection_mode.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DetectionMode _mode = DetectionMode.rest;
  bool _isArmed = false;
  bool _isCountingDown = false;
  bool _isMotionDetected = false;
  int _countdown = 10;
  Timer? _countdownTimer;

  void _startActivationSequence() {
    setState(() {
      _isCountingDown = true;
      _countdown = 10;
    });

    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _countdown--;
      });

      if (_countdown <= 0) {
        timer.cancel();
        setState(() {
          _isCountingDown = false;
          _isArmed = true;
          _isMotionDetected = true;
        });

        MotionService.startDetection(
          _mode,
          onMotionDetected: _onMotionDetected,
          onMotionStopped: _onMotionStopped,
        );
      }
    });
  }

  void _onMotionDetected() {
    if (_isArmed) {
      AlarmService.triggerAlarm();
      setState(() {
        _isMotionDetected = true;
      });
    }
  }

  void _onMotionStopped() {
    if (_isArmed) {
      setState(() {
        _isMotionDetected = false;
      });
      print("⚠️ Motion Stopped — Camera Capture Paused.");
    }
  }

  void _deactivateSystem() {
    AlarmService.stopAlarm();
    MotionService.stopDetection();

    _countdownTimer?.cancel();
    setState(() {
      _isArmed = false;
      _isCountingDown = false;
      _isMotionDetected = false;
      _countdown = 10;
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    MotionService.stopDetection();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActivationDisabled = _isCountingDown || _isArmed;

    return Scaffold(
      appBar: AppBar(
        title: Text('Phone Security System'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Mode:', style: TextStyle(fontSize: 20)),
            ListTile(
              title: Text('Rest Mode'),
              leading: Radio(
                value: DetectionMode.rest,
                groupValue: _mode,
                onChanged: isActivationDisabled ? null : (DetectionMode? value) {
                  if (value != null) {
                    setState(() => _mode = value);
                  }
                },
              ),
            ),
            ListTile(
              title: Text('Pocket Mode'),
              leading: Radio(
                value: DetectionMode.pocket,
                groupValue: _mode,
                onChanged: isActivationDisabled ? null : (DetectionMode? value) {
                  if (value != null) {
                    setState(() => _mode = value);
                  }
                },
              ),
            ),
            SizedBox(height: 30),
            Center(
              child: _isCountingDown
                  ? Text(
                'Activating in $_countdown...',
                style: TextStyle(fontSize: 26, color: Colors.orange),
              )
                  : _isArmed
                  ? Text(
                _isMotionDetected
                    ? 'System Armed — Motion Detected'
                    : 'System Armed — No Motion Detected',
                style: TextStyle(
                  fontSize: 24,
                  color: _isMotionDetected ? Colors.red : Colors.blue,
                ),
              )
                  : Text(
                'System Disarmed',
                style: TextStyle(fontSize: 26, color: Colors.green),
              ),
            ),
            Spacer(),
            Center(
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed:
                    isActivationDisabled ? null : _startActivationSequence,
                    child: Text('Activate'),
                    style: ElevatedButton.styleFrom(
                      padding:
                      EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      backgroundColor: Colors.green,
                      textStyle: TextStyle(fontSize: 18),
                    ),
                  ),
                  SizedBox(height: 16),
                  if (_isArmed)
                    ElevatedButton(
                      onPressed: _deactivateSystem,
                      child: Text('Deactivate'),
                      style: ElevatedButton.styleFrom(
                        padding:
                        EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        backgroundColor: Colors.red,
                        textStyle: TextStyle(fontSize: 18),
                      ),
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
