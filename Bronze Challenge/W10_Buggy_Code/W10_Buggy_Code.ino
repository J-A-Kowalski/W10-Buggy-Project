#include "WiFiS3.h"

char ssid[] = "BuggyNetworkW10";
char pass[] = "MyS3cretToKn0w";

WiFiServer server(5200);
int status = WL_IDLE_STATUS;

// Pins
const int LED = 13;

const int leftIR = 10;
const int rightIR = 11;

const int enA = 9;
const int in1 = 8;
const int in2 = 7;

const int enB = 3;
const int in3 = 5;
const int in4 = 4;

const int trigPin = 2;
const int echoPin = 6;

// Variables
long duration;
float distance;
bool stopped = true;

// ---- Tuning ----
int baseSpeed = 140;      // overall speed
int k = 60;               // correction strength
float leftScale = 1.12;   //
float rightScale = 1.00;   
const int rampStep = 8;   // smoothing
const int stopDist = 20;  // cm


const int LINE = HIGH;    

int currA = 0;
int currB = 0;

int rampTo(int current, int target) {
  if (current < target) return min(current + rampStep, target);
  if (current > target) return max(current - rampStep, target);
  return current;
}

void stopMotors() {
  analogWrite(enA, 0);
  analogWrite(enB, 0);

  digitalWrite(in1, LOW); digitalWrite(in2, LOW);
  digitalWrite(in3, LOW); digitalWrite(in4, LOW);
}

void setMotorAForward(int pwm) {
  pwm = constrain(pwm, 0, 255);
  digitalWrite(in1, HIGH);
  digitalWrite(in2, LOW);
  analogWrite(enA, pwm);
}

void setMotorBForward(int pwm) {
  pwm = constrain(pwm, 0, 255);
  digitalWrite(in3, HIGH);
  digitalWrite(in4, LOW);
  analogWrite(enB, pwm);
}

void drivePWM(int leftPWM, int rightPWM) {
  leftPWM  = (int)(leftPWM  * leftScale);
  rightPWM = (int)(rightPWM * rightScale);
  leftPWM  = constrain(leftPWM, 0, 255);
  rightPWM = constrain(rightPWM, 0, 255);

  currA = rampTo(currA, leftPWM);
  currB = rampTo(currB, rightPWM);

  setMotorAForward(currA);
  setMotorBForward(currB);
}

float getDistanceCM() {
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  duration = pulseIn(echoPin, HIGH, 30000); // 30ms timeout
  if (duration == 0) return 999;
  return (duration * 0.0343) / 2.0;
}

void setup() {
  pinMode(LED, OUTPUT);
  Serial.begin(9600);

  Serial.print("Network named: ");
  Serial.println(ssid);
  status = WiFi.beginAP(ssid, pass);
  Serial.println("Network started");

  IPAddress ip = WiFi.localIP();
  Serial.print("IP Address: ");
  Serial.println(ip);

  server.begin();

  pinMode(leftIR, INPUT);
  pinMode(rightIR, INPUT);

  pinMode(enA, OUTPUT);
  pinMode(in1, OUTPUT);
  pinMode(in2, OUTPUT);

  pinMode(enB, OUTPUT);
  pinMode(in3, OUTPUT);
  pinMode(in4, OUTPUT);

  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
}

void loop() {
  
  // ---- Communicating with processing ----
  WiFiClient client = server.available();
  if (client) {
    client.setTimeout(5);          
    String msg = client.readStringUntil('\n');
    msg.trim();

    if (msg.length() > 0) {
      Serial.println(msg);
      if (msg == "CMD_STOP") stopped = true;
      if (msg == "CMD_GO")   stopped = false;
    }
  }

  // ---- Sensors ----
  int leftVal = digitalRead(leftIR);
  int rightVal = digitalRead(rightIR);

  bool leftOnLine  = (leftVal == LINE);
  bool rightOnLine = (rightVal == LINE);

  // ---- Stop info sent to processing ----
  distance = getDistanceCM();
  if (distance < stopDist) {
    client.write(5);
  }

  if (stopped) {
    if (distance < stopDist){
    client.write(5);}
    else { client.write(6); }
}

  // ---- Stop logic ----
  if (distance < stopDist || stopped) {
    stopMotors();
    currA = 0; currB = 0;
    return;
  }

  // --- Driving logic ---
  if (leftOnLine && rightOnLine) {
    drivePWM(baseSpeed, baseSpeed);
    client.write(1);
  } else if (leftOnLine && !rightOnLine) {
    drivePWM(baseSpeed + k, baseSpeed - k); // steer right
    client.write(2); 
  } else if (!leftOnLine && rightOnLine) {
    drivePWM(baseSpeed - k, baseSpeed + k); // steer left
    client.write(3); 
  } else {
    drivePWM(baseSpeed - 15, baseSpeed - 15); // junction / wide line
    client.write(4);
  }
}