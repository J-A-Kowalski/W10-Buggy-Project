#include "WiFiS3.h"

// ================= WIFI =================
char ssid[] = "BuggyNetworkW10";
char pass[] = "123456789";

WiFiServer server(5200);
WiFiClient client;
int status = WL_IDLE_STATUS;

bool isConect = false;

// ================= PINS =================
const int LED = 13;

// Motor pins
const int enA = 9;
const int in1 = 8;
const int in2 = 7;

const int enB = 3;
const int in3 = 5;
const int in4 = 4;

// Ultrasonic
const int trigPin = 1;
const int echoPin = 6;

// CD4021 / CD4040
const int clockPin = 11;
const int latchPin = 12;
const int dataPin  = 10;
const int resetPin = 0;

// Direct encoder
const int encoderBPin = 2;

// ================= BUGGY CONSTANTS =================
const float wheelCircumference = 20.4;
const float ticksPerRev = 8.0;
const float cmPerTick = wheelCircumference / ticksPerRev;

const float trackWidth = 14.0;
const float perimeter = PI * trackWidth;
const float turnpath90 = perimeter / 4.0;

// ================= MOTOR SETTINGS =================
const float baseSpeed = 100;
const float turnSpeed = 100;

const float d = 1.095;
const float rightScalar = 1.00;
const float kP = 0.0;

float SpeedL = baseSpeed * d;
float SpeedR = baseSpeed;

// ================= COMMAND VARIABLES =================
bool stopped = false;

char msg = 'B';
float targetValue = 0.0;
float startDistance = 0.0;

// ================= ENCODER VARIABLES =================
volatile unsigned long directTicks = 0;
byte switchVar1 = 0;
byte prev4021 = 0;
unsigned long chipTicks = 0;

// ================= TELEMETRY =================
float totalDistanceCm = 0.0;
float currentSpeedCmS = 0.0;
unsigned long lastSpeedTime = 0;
unsigned long lastSpeedTicks = 0;
unsigned long lastTelemetryTime = 0;

// ================= ULTRASONIC =================
long duration;
float obstacleDistance = -1.0;

// ================= FUNCTION HEADERS =================
void stopBuggy();
void driveStraight();
void turnR();
void turnL();

void countEncoderB();

byte shiftIn(int myDataPin, int myClockPin);
byte read4021(int latchPin, int dataPin, int clockPin);
void updateChipTicks();
void reset4040();
void resetEncoders();

float getSegmentDistance();
float getAverageTicks();
float readUltrasonic();
void updateSpeed();
void sendTelemetry();

void debugEncoderState(const char* label);

void setup() {
  pinMode(LED, OUTPUT);
  Serial.begin(9600);
  while (!Serial) { }

  Serial.print("Network named: ");
  Serial.println(ssid);
  status = WiFi.beginAP(ssid, pass);
  Serial.println("Network started");

  IPAddress ip = WiFi.localIP();
  Serial.print("IP Address: ");
  Serial.println(ip);

  server.begin();

  pinMode(enA, OUTPUT);
  pinMode(in1, OUTPUT);
  pinMode(in2, OUTPUT);
  pinMode(enB, OUTPUT);
  pinMode(in3, OUTPUT);
  pinMode(in4, OUTPUT);

  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);

  pinMode(encoderBPin, INPUT_PULLUP);

  pinMode(clockPin, OUTPUT);
  pinMode(dataPin, INPUT);
  pinMode(latchPin, OUTPUT);
  pinMode(resetPin, OUTPUT);

  digitalWrite(clockPin, HIGH);
  digitalWrite(latchPin, LOW);
  digitalWrite(resetPin, LOW);

  attachInterrupt(digitalPinToInterrupt(encoderBPin), countEncoderB, CHANGE);

  reset4040();
  switchVar1 = read4021(latchPin, dataPin, clockPin);
  prev4021 = switchVar1;

  stopBuggy();
  lastSpeedTime = millis();

  debugEncoderState("Setup");
}

void loop() {
  updateChipTicks();
  updateSpeed();

  static unsigned long lastDebug = 0;
  if (millis() - lastDebug > 1000) {
    lastDebug = millis();
    debugEncoderState("Loop");
  }

  WiFiClient newClient = server.available();
  if (newClient) {
    client = newClient;
  }

  if (client.connected()) {
    if (!isConect) {
      client.write("Hello Client\n");
      isConect = true;
    }

    if (client.available()) {
      String cmd = client.readStringUntil('\n');
      cmd.trim();

      if (cmd.length() > 0) {
        msg = cmd.charAt(0);

        if (cmd.length() > 1) {
          targetValue = cmd.substring(1).toFloat();
        } else {
          targetValue = 0.0;
        }

        if (msg == 'A' || msg == 'C' || msg == 'D') {
          resetEncoders();
          startDistance = totalDistanceCm;

          if (msg == 'C' || msg == 'D') {
            targetValue = turnpath90;
          }
        }
      }
    }

    obstacleDistance = readUltrasonic();

    if (msg == 'S') {
      stopped = true;
      stopBuggy();
    }
    else if (msg == 'G') {
      stopped = false;
      msg = 'B';
    }

    if (!stopped) {
      float segmentDistance = getSegmentDistance();

      if ((msg == 'A' || msg == 'C' || msg == 'D') && targetValue > 0) {
        if (segmentDistance >= targetValue) {
          totalDistanceCm += segmentDistance;
          msg = 'B';
          targetValue = 0.0;
        }
      }

      if (msg == 'A' && obstacleDistance > 0 && obstacleDistance < 20.0) {
        msg = 'B';
      }

      if (msg == 'A') {
        driveStraight();
      }
      else if (msg == 'B') {
        stopBuggy();
      }
      else if (msg == 'C') {
        turnR();
      }
      else if (msg == 'D') {
        turnL();
      }
    }

    sendTelemetry();
  }

  if (!client.connected()) {
    isConect = false;
    stopped = true;
    stopBuggy();
  }
}

// ================= MOTOR FUNCTIONS =================
void driveStraight() {
  unsigned long leftCount = directTicks;
  unsigned long rightCount = chipTicks;

  long error = (long)leftCount - (long)rightCount;
  int correction = (int)(kP * error);

  int leftPWM = constrain((int)(baseSpeed * d) + correction, 90, 255);
  int rightPWM = constrain((int)(baseSpeed * rightScalar) - correction, 90, 255);

  analogWrite(enA, leftPWM);
  digitalWrite(in1, HIGH);
  digitalWrite(in2, LOW);

  analogWrite(enB, rightPWM);
  digitalWrite(in3, HIGH);
  digitalWrite(in4, LOW);
}

void stopBuggy() {
  analogWrite(enA, 0);
  analogWrite(enB, 0);

  digitalWrite(in1, LOW);
  digitalWrite(in2, LOW);
  digitalWrite(in3, LOW);
  digitalWrite(in4, LOW);
}

void turnR() {
  int leftPWM = constrain(turnSpeed, 90, 255);
  int rightPWM = constrain(turnSpeed, 90, 255);

  analogWrite(enA, leftPWM);
  digitalWrite(in1, HIGH);
  digitalWrite(in2, LOW);

  analogWrite(enB, rightPWM);
  digitalWrite(in3, LOW);
  digitalWrite(in4, HIGH);
}

void turnL() {
  int leftPWM = constrain(turnSpeed, 90, 255);
  int rightPWM = constrain(turnSpeed, 90, 255);

  analogWrite(enA, leftPWM);
  digitalWrite(in1, LOW);
  digitalWrite(in2, HIGH);

  analogWrite(enB, rightPWM);
  digitalWrite(in3, HIGH);
  digitalWrite(in4, LOW);
}

// ================= DIRECT ENCODER =================
void countEncoderB() {
  directTicks++;
}

// ================= CD4021 / CD4040 =================
void reset4040() {
  digitalWrite(resetPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(resetPin, LOW);
  delayMicroseconds(10);
}

byte shiftIn(int myDataPin, int myClockPin) {
  int i;
  int temp = 0;
  int pinState;
  byte myDataIn = 0;

  pinMode(myClockPin, OUTPUT);
  pinMode(myDataPin, INPUT);

  for (i = 7; i >= 0; i--) {
    digitalWrite(myClockPin, LOW);
    delayMicroseconds(1);

    temp = digitalRead(myDataPin);

    if (temp) {
      pinState = 1;
      myDataIn = myDataIn | (1 << i);
    } else {
      pinState = 0;
    }

    digitalWrite(myClockPin, HIGH);
  }

  return myDataIn;
}

byte read4021(int latchPin, int dataPin, int clockPin) {
  digitalWrite(latchPin, HIGH);
  delayMicroseconds(20);
  digitalWrite(latchPin, LOW);

  return shiftIn(dataPin, clockPin);
}

void updateChipTicks() {
  switchVar1 = read4021(latchPin, dataPin, clockPin);
  int diff = switchVar1 - prev4021;

  if (diff < 0) {
    diff += 256;
  }

  chipTicks += diff;
  prev4021 = switchVar1;
}

void resetEncoders() {
  noInterrupts();
  directTicks = 0;
  interrupts();

  chipTicks = 0;
  reset4040();
  delay(5);
  switchVar1 = read4021(latchPin, dataPin, clockPin);
  prev4021 = switchVar1;

  lastSpeedTicks = 0;
  lastSpeedTime = millis();

  debugEncoderState("After reset");
}

// ================= DISTANCE / SPEED =================
float getAverageTicks() {
  return (directTicks + chipTicks) / 2.0;
}

float getSegmentDistance() {
  return getAverageTicks() * cmPerTick;
}

void updateSpeed() {
  unsigned long now = millis();

  if (now - lastSpeedTime >= 100) {
    unsigned long avgTicks = (directTicks + chipTicks) / 2;
    unsigned long deltaTicks = avgTicks - lastSpeedTicks;
    float dt = (now - lastSpeedTime) / 1000.0;

    currentSpeedCmS = (deltaTicks * cmPerTick) / dt;

    lastSpeedTicks = avgTicks;
    lastSpeedTime = now;
  }
}

// ================= ULTRASONIC =================
float readUltrasonic() {
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  duration = pulseIn(echoPin, HIGH, 25000);

  if (duration == 0) {
    return -1.0;
  }

  return (duration * 0.0343) / 2.0;
}

// ================= TELEMETRY =================
void sendTelemetry() {
  unsigned long now = millis();

  if (client.connected() && now - lastTelemetryTime >= 200) {
    lastTelemetryTime = now;

    float segmentDistance = getSegmentDistance();
    float reportedTotal = startDistance + segmentDistance;

    client.print("DIST=");
    client.print(reportedTotal, 1);
    client.print(",SPEED=");
    client.println(currentSpeedCmS, 1);
  }
}

// ================= DEBUG =================
void debugEncoderState(const char* label) {
  byte raw4021 = read4021(latchPin, dataPin, clockPin);

  noInterrupts();
  unsigned long dt = directTicks;
  interrupts();

  Serial.print(label);
  Serial.print(" directTicks=");
  Serial.print(dt);
  Serial.print(" chipTicks=");
  Serial.print(chipTicks);
  Serial.print(" raw4021=");
  Serial.println(raw4021);
}