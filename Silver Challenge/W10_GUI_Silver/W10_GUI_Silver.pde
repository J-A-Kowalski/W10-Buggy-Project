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

// Variable to store saved text when return is hit
int saved = 0;
String inputList[] = new String[100];
boolean misinput = false;
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
  int indent = 25;
  
  rectMode(CENTER);
  
  // Set the font and fill for text
  textFont(font);
  fill(255);
  background(40);
  strokeWeight(2);

  //power button
  if(overBtn_start == true){stroke(255);}
  else{stroke(0);}
  fill(50, 205, 50, 55 + (200 * powerButton));
  rect(280, 500, 200, 130);
  
  //power button text
  textFont(font);
  textSize(40);
  if(powerButton == 1){fill(255);}
  else{fill(0);}
  text("START", 830, 280);

  //Central buggy
  shape(buggy, 300, 280, 160, 160);
  
  int btnSize = 120;
  textAlign(CENTER);
  
  //left turning indicator
  int leftx = 190;
  int lefty = 350;
  fill(50, 205, 50);
  if(overBtn_left == true){stroke(255);}
  else{stroke(0);}
  rect(leftx, lefty, btnSize, btnSize);
  fill(255);
  text("<", leftx, lefty);
  
  //right turning indicator
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
  if (misinput == true){
    text("Input Invalid", indent, 400);
  }
  if (arPos != 0){
  for (int i = 0; i != arPos; i = i+1 ){
  text("Step " + (i + 1) + " : " + inputList[i], 950, 100 + (20 * i));
  }
  }
  text (distTravelled, 400, 600);
  distTravelled = distTravelled + 0.001;
  
}

//void keyPressed() {
  // If the return key is pressed, save the String and clear it
  //if (key == '\n' ) {
    //misinput = false;
    //saved = distInput;
    //if (saved == 789) {
    //inputList = new String[100];
    //arPos = 0;
  //}
    //else{
      // misinput = true;  
    //}
    // resetting string
    //distInput = 0; 
  //} else if (key == 48 ) {
  
    //distInput = distInput + key;
  //}
//}

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

if (overBtn_right == true)
{
  inputList[arPos] = "Turn right";
  arPos = arPos + 1;
  //myClient.write("C");
}

if (overBtn_left == true)
{
  inputList[arPos] = "Turn left";
  arPos = arPos + 1;
  //myClient.write("A100");
}

if (overBtn_fwd == true)
{
  distPrompt = true;
  inputList[arPos] = "Go forward";
  arPos = arPos + 1;
  //myClient.write("G");
}

}

void keyPressed(){
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
}
