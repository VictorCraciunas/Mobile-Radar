import 'package:flutter/material.dart';

class RadarCircle {
  final double x;
  final double y;
  final AnimationController controller; // Fading animation controller
  final Animation<Color?> animation; // Fading animation

  RadarCircle({
    required this.x,
    required this.y,
    required this.controller,
    required this.animation,
  });
}