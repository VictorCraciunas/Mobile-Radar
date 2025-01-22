import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:radar/services/networking.dart';
import 'package:radar/classes/radar_circle.dart';

class RadarPage extends StatefulWidget {
  const RadarPage({super.key});

  @override
  State<RadarPage> createState() => _RadarPageState();
}

class _RadarPageState extends State<RadarPage>
    with TickerProviderStateMixin {

  late AnimationController _controller;  // Animation Controller

  List<double> radarStops = [0.20, 0.25, 0.20];  // Radar line design (how the color is dissipated)
  NetworkHelper networkHelper = NetworkHelper("http://192.168.4.1");
  Timer? _httpRequestTimer;
  double radarAngle = 0.0;


  final List<RadarCircle> radarCircles = []; // List to store found objects

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 5));
    _controller.forward();


    _startHttpRequestTimer(); // Start the periodic HTTP request
  }

  void _startHttpRequestTimer() {
    _httpRequestTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) async {  // Repeats the http request
      try {
        var radarData = await networkHelper.getData();
        int angle = radarData['angle'];
        double distance = radarData['distance'];

        setState(() {
          radarAngle = 360 - angle.toDouble(); // Adjust the angle for rotation
          if (distance <= 50) {    // if the object is further that 50 (the value received from ultrasonic) we ignore
            _addRadarCircle(radarAngle, distance);
          }
          if (angle == 180){
            radarStops=[0.20, 0.25, 0.20];
          }
          else if(angle == 0){
            radarStops=[0.25, 0.25, 0.30];
          }
        });
        print("distance " + distance.toString());
        print ("angle " + angle.toString());
      } catch (e) {
        print("Error fetching radar data: $e");
      }
    });
  }

  void _addRadarCircle(double angle, double distance) {
    const double scalingFactor = 10.0;
    final double scaledDistance = distance * scalingFactor;

    final double screenHeight = MediaQuery.of(context).size.height;

    // Starting point of the radar line (middle of the left edge)
    const double startX = 0;
    final double startY = screenHeight / 2;

    final double x = startX + scaledDistance * cos((angle - 270) * pi / 180);
    final double y = startY + scaledDistance * sin((angle - 270) * pi / 180);

    AnimationController fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..forward();

    Animation<Color?> fadeAnimation = ColorTween(
      begin: Colors.red,
      end: Colors.transparent,
    ).animate(fadeController);


    // create Circle
    radarCircles.add(RadarCircle(
      x: x,
      y: y,
      controller: fadeController,
      animation: fadeAnimation,
    ));

    // Remove the circle when the animation completes
    fadeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          radarCircles.removeWhere((circle) => circle.animation == fadeAnimation);
        });
        fadeController.dispose();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _httpRequestTimer?.cancel();
    for (var circle in radarCircles) {
      circle.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        // Radar background
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('images/rdar_imagine.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              // Radar Line
              Positioned(
                left: -screenWidth / 2,
                top: -screenHeight / 2,
                child: Transform.rotate(
                  angle: radarAngle * pi / 180,
                  child: Container(
                    width: screenWidth,
                    height: screenHeight * 2,
                    decoration: BoxDecoration(
                      gradient: SweepGradient(
                        center: const FractionalOffset(0.5, 0.5), // Starting at the middle of the left edge
                        colors: const <Color>[
                          Colors.transparent,
                          Color(0xFF3A87DC),
                          Colors.transparent,
                        ],
                        stops: radarStops,
                      ),
                    ),
                  ),
                ),
              ),
              ...radarCircles.map((circle) {
                return Positioned(
                  left: circle.x - 10,
                  top: circle.y - 10,
                  child: AnimatedBuilder(
                    animation: circle.animation,
                    builder: (context, child) {
                      return Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: circle.animation.value,
                          shape: BoxShape.circle,
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}


