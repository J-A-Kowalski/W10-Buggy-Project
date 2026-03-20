import processing.serial.*;
import processing.net.*;

//communicating with buggy
//Client myClient; 
int data = 0;

//custom buggy vector image
PShape buggy;
PFont font;

//custom buttons
boolean overBtn_start = false;
boolean overBtn_right = false;
boolean overBtn_left = false;
boolean overBtn_fwd = false;
boolean distPrompt = false;
int powerButton = 0;

// Variable to store text currently being typed
int numInput = 0;
int distInput = 0;

int arPos = 0; //position in the list of inputs

//Lists the steps the buggy needs to take
String inputList[] = new String[20];

//Distance travelled by buggy
float distTravelled = 0;

void setup() {
  size (1280, 720);
  //myClient = new Client(this,"192.168.4.1",5200);
  buggy = loadShape("fella.svg");
  font = createFont("unispace.bold.otf", 128);
  
}

void draw() {
  //data = myClient.read();
  background(255);
  
  rectMode(CENTER);
  
  // Set the font and fill for text
  textFont(font);
  fill(255);
  background(40);
  strokeWeight(2);

  int btnSize = 120;
  textAlign(CENTER);

  //power button
  int gox = 380;
  int goy = 540;
  if(overBtn_start == true){stroke(255);}
  else{stroke(0);}
  fill(50, 205, 50);
  rect(gox, goy, btnSize * 2, btnSize * 0.75);
  
  //power button text
  textFont(font);
  textSize(40);
  if(powerButton == 1){
  fill(255); text("STOP", gox, goy);}
  else{fill(0); text("START", gox, goy);}

  //Central buggy
  shape(buggy, 300, 280, 160, 160);
  
  //left turning button
  int leftx = 190;
  int lefty = 350;
  fill(50, 205, 50);
  if(overBtn_left == true){stroke(255);}
  else{stroke(0);}
  rect(leftx, lefty, btnSize, btnSize);
  fill(255);
  text("<", leftx, lefty);
  
  //right turning button
  int rightx = 570;
  int righty = 350;
  fill(50, 205, 50);
  if(overBtn_right == true){stroke(255);}
  else{stroke(0);}
  rect(rightx, righty, btnSize, btnSize);
  fill(255);
  text(">", rightx, righty);
  
  //forward indicator
  int fwdx = 380;
  int fwdy = 180;
  fill(50, 205, 50);
  if(overBtn_fwd == true){stroke(255);}
  else{stroke(0);}
  rect(fwdx, fwdy, btnSize, btnSize);
  fill(255);
  text("^", fwdx, fwdy);
  
  //hovering over buttons
  if((mouseX > 280 && mouseX < 480 && mouseY > 500 && mouseY < 630))
  {overBtn_start = true;}
  else
  {overBtn_start = false;}
  
  if((mouseX > (leftx - (btnSize / 2))) && (mouseX < (leftx + (btnSize / 2))) && (mouseY > (lefty - (btnSize / 2))) && (mouseY < (lefty + (btnSize / 2))) && distPrompt == false)
  {overBtn_left = true;}
  else
  {overBtn_left = false;}
  
  if((mouseX > (rightx - (btnSize / 2))) && (mouseX < (rightx + (btnSize / 2))) && (mouseY > (righty - (btnSize / 2))) && (mouseY < (righty + (btnSize / 2))) && distPrompt == false)
  {overBtn_right = true;}
  else
  {overBtn_right = false;}
  
  if((mouseX > (fwdx - (btnSize / 2))) && (mouseX < (fwdx + (btnSize / 2))) && (mouseY > (fwdy - (btnSize / 2))) && (mouseY < (fwdy + (btnSize / 2))) && distPrompt == false)
  {overBtn_fwd = true;}
  else
  {overBtn_fwd = false;}
  
  textAlign(LEFT);
  
  //distance prompt
  if (distPrompt == true){
  stroke(255);
  fill(0);
  rect(640, 360, 300, 100);
  fill(255);
  textSize(20);
  text("Enter distance: " + distInput, 540, 360);
  }
  
  //console
  rectMode(CORNER);
  stroke(255);
  fill(0);
  rect(900, 0, 400, 718);
  
  fill(255);
  textSize(20);
  text("List of Buggy Directions", 940, 40);
    
  // text inputs
  if (arPos != 0){
  for (int i = 0; i != arPos; i = i+1 ){
  text("Step " + (i + 1) + " : " + inputList[i], 950, 100 + (30 * i));
  }
  }
  
}

//Interfacing with start button
void mousePressed(){
if (overBtn_start == true)
{
  if (powerButton == 0){
    powerButton = 1;
    //myClient.write("G");
  }
  else
  {
    powerButton = 0;
    //myClient.write("B");
  }
}

if (overBtn_right == true && arPos != 20)
{
  inputList[arPos] = "Turn right";
  arPos = arPos + 1;
  //myClient.write("C");
}

if (overBtn_left == true && arPos != 20)
{
  inputList[arPos] = "Turn left";
  arPos = arPos + 1;
  //myClient.write("A100");
}

if (overBtn_fwd == true && arPos != 20)
{
  distPrompt = true;
  //inputList[arPos] = "Go forward";
  //arPos = arPos + 1;
  //myClient.write("G");
}

}

void keyPressed(){
  if(distPrompt == true){
switch(key) {
  case 48: numInput = 0; break;
  case 49: numInput = 1; break;
  case 50: numInput = 2; break;
  case 51: numInput = 3; break;
  case 52: numInput = 4; break;
  case 53: numInput = 5; break;
  case 54: numInput = 6; break;
  case 55: numInput = 7; break;
  case 56: numInput = 8; break;
  case 57: numInput = 9; break;
  case 8: numInput = 0; distInput = 0; distPrompt = false; break;
  default: numInput = -1; break;
}
if (numInput == -1){
  numInput = 0;
}
else if(distInput < 999){
distInput = (distInput * 10) + numInput;
}
if(distInput > 999){
distInput = (distInput - numInput) / 10;
}
if(key == '\n'){
  inputList[arPos] = "Go forward " + distInput + "cm";
  arPos = arPos + 1;
  numInput = 0; 
  distInput = 0; 
  distPrompt = false;
}
}
}
