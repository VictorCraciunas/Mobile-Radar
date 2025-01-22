#define DEBUG true
#include <Servo.h>

Servo myservo;
int angle = 0;
bool goingUp = true;      // global direction control
unsigned long lastMove;   // tracks the last time we moved the servo
const unsigned long stepDelay = 15;  // how often we move one degree
const int trigPin = 9;  
const int echoPin = 10; 
double duration, distance;


void setup() {
  Serial.begin(115200);
  Serial1.begin(115200);
  	pinMode(trigPin, OUTPUT);  
	pinMode(echoPin, INPUT); 

  myservo.attach(8); // Attach servo to pin 8
  myservo.write(angle); // Initialize the servo to the starting angle
  sendData("AT+RST\r\n", 2000, false); // reset module
  sendData("AT+CWMODE=2\r\n", 1000, false); // configure as access point
  sendData("AT+CIFSR\r\n", 1000, DEBUG); // read IP address
  sendData("AT+CWSAP?\r\n", 2000, DEBUG); // read SSID (network name) info
  sendData("AT+CIPMUX=1\r\n", 1000, false); // configure multiple connections
  sendData("AT+CIPSERVER=1,80\r\n", 1000, false); // start server on port 80
}

void loop() {
  // 1. Non-blocking servo update:
  unsigned long now = millis();


  // 2. Continuously check for incoming data:
  if (Serial1.available()) {
    if (Serial1.find("+IPD,")) {
      delay(100);
      int connectionId = Serial1.read() - 48;
        if (now - lastMove >= stepDelay) {
    lastMove = now;
    if (goingUp) {
      angle = angle + 10;
      if (angle >= 180) {
        angle = 180;
        goingUp = false;
      }
    } else {
      angle= angle - 10;
      if (angle <= 0) {
        angle = 0;
        goingUp = true;
      }
    }
    myservo.write(angle);
  }

    digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);
    duration = pulseIn(echoPin, HIGH);
  distance = (duration*.0343)/2;
  
      // Build the JSON with *current* angle
      String webpage = "HTTP/1.1 200 OK\r\n";
      webpage += "Content-Type: application/json\r\n";
      webpage += "Connection: close\r\n\r\n";
      webpage += "{";
      webpage += "\"angle\": " + String(angle) + ",";
      webpage += "\"distance\": " + String(distance);
      webpage += "}";

      String cipSend = "AT+CIPSEND=" + String(connectionId) + "," + webpage.length() + "\r\n";
      sendData(cipSend, 100, DEBUG);
      sendData(webpage, 150, DEBUG);

      // Close the connection
      String closeCommand = "AT+CIPCLOSE=" + String(connectionId) + "\r\n";
      sendData(closeCommand, 300, DEBUG);
    }
  }
  Serial.print(distance);
}

String sendData(String command, const int timeout, boolean debug) {
  String response = "";
  Serial1.print(command); // send command to ESP8266
  long int time = millis();
  while ((time + timeout) > millis()) {
    while (Serial1.available()) {
      char c = Serial1.read(); // read next character
      response += c;
    }
  }

  if (debug) {
    Serial.print(response);
  }
  return response;
}


