import 'dart:async';
import 'package:flutter/material.dart';
import '../services/motion_service.dart';
import '../services/alarm_service.dart';
import '../services/flashlight_service.dart';
import '../models/detection_mode.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
          _isMotionDetected = false;
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
      FlashlightService.toggleFlashlight(true);
      setState(() {
        _isMotionDetected = true;
      });
      print("⚠️ Motion Detected — Alarm and Flashlight Activated.");
    }
  }

  void _onMotionStopped() {
    if (_isArmed) {
      AlarmService.stopAlarm();
      FlashlightService.toggleFlashlight(false);
      setState(() {
        _isMotionDetected = false;
      });
      print("⚠️ Motion Stopped — Alarm and Flashlight Deactivated.");
    }
  }

  void _deactivateSystem() {
    AlarmService.stopAlarm();
    FlashlightService.toggleFlashlight(false);
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
    FlashlightService.toggleFlashlight(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActivationDisabled = _isCountingDown || _isArmed;

    return Scaffold(
      appBar: AppBar(
        title: Text('Phone Security System',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22)),
        centerTitle: true,
        backgroundColor: Colors.blue[700],
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[50]!,
              Colors.blue[100]!,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Select Detection Mode:',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800])),
                      SizedBox(height: 10),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _mode == DetectionMode.rest
                                ? Colors.green[100]
                                : Colors.blue[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Radio<DetectionMode>(
                            value: DetectionMode.rest,
                            groupValue: _mode,
                            onChanged: isActivationDisabled ? null : (value) {
                              if (value != null) setState(() => _mode = value);
                            },
                            activeColor: Colors.green[800],
                          ),
                        ),
                        title: Text('Rest Mode',
                            style: TextStyle(
                                color: Colors.blue[800],
                                fontWeight: FontWeight.w500)),
                        tileColor: Colors.transparent,
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _mode == DetectionMode.pocket
                                ? Colors.green[100]
                                : Colors.blue[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Radio<DetectionMode>(
                            value: DetectionMode.pocket,
                            groupValue: _mode,
                            onChanged: isActivationDisabled ? null : (value) {
                              if (value != null) setState(() => _mode = value);
                            },
                            activeColor: Colors.green[800],
                          ),
                        ),
                        title: Text('Pocket Mode',
                            style: TextStyle(
                                color: Colors.blue[800],
                                fontWeight: FontWeight.w500)),
                        tileColor: Colors.transparent,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),
              Center(
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  color: _isCountingDown
                      ? Colors.orange[50]
                      : _isArmed
                      ? _isMotionDetected
                      ? Colors.red[50]
                      : Colors.blue[50]
                      : Colors.green[50],
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: _isCountingDown
                        ? Text(
                      'Activating in $_countdown...',
                      style: TextStyle(
                          fontSize: 26,
                          color: Colors.orange[800],
                          fontWeight: FontWeight.bold),
                    )
                        : _isArmed
                        ? Column(
                      children: [
                        Text(
                          'SYSTEM ARMED',
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.blue[800],
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _isMotionDetected
                              ? '🚨 MOTION DETECTED!'
                              : '✅ No Motion',
                          style: TextStyle(
                              fontSize: 24,
                              color: _isMotionDetected
                                  ? Colors.red[800]
                                  : Colors.green[800],
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                        : Text(
                      'SYSTEM DISARMED',
                      style: TextStyle(
                          fontSize: 26,
                          color: Colors.green[800],
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              Spacer(),
              Center(
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: isActivationDisabled
                          ? null
                          : _startActivationSequence,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            horizontal: 40, vertical: 18),
                        backgroundColor: Colors.green[600],
                        disabledBackgroundColor: Colors.grey[400],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                        shadowColor: Colors.green[800],
                      ),
                      child: Text('ACTIVATE SYSTEM',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(height: 20),
                    if (_isArmed)
                      ElevatedButton(
                        onPressed: _deactivateSystem,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 40, vertical: 18),
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                          shadowColor: Colors.red[800],
                        ),
                        child: Text('DEACTIVATE SYSTEM',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}