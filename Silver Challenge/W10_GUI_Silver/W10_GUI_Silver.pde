import processing.serial.*;
import processing.net.*;

//communicating with buggy
Client myClient; 
String data = "";
float dataInt = 0.0;

//custom font & buggy vector image
PShape buggy;
PFont font;

//custom button variables
boolean overBtn_start = false;
boolean overBtn_right = false;
boolean overBtn_left = false;
boolean overBtn_fwd = false;
boolean distPrompt = false;
int powerButton = 0;
int btnSize = 120;

// Variable to store text currently being typed
String inputDisplay = "Ready for input";
int numInput = 0;
int distInput = 0;

//Indent for text in the GUI
int indent = 30;

//Distance travelled by buggy
float distTravelled = 0.0;

void setup() {
  size (1280, 720);
  myClient = new Client(this,"192.168.4.1",5200);
  buggy = loadShape("fella.svg");
  font = createFont("unispace.bold.otf", 128);
}

void draw() {
  data = myClient.readString();
  
  background(255);
  
  //updates the amount of distance covered recieved from the buggy
  if ((data != null)) {
    dataInt = float(data);
    if (distTravelled < dataInt) {
      distTravelled = dataInt;
    }
  }
  
  //Set the font and fill for text
  textFont(font);
  fill(255);
  background(40);
  strokeWeight(2);
  textAlign(CENTER);
  rectMode(CENTER);

  //power button
  int gox = 900; //x & y coordinates of the button
  int goy = 220;
  if(overBtn_start == true){stroke(255);} //outline turns white when you hover over
  else{stroke(0);}
  fill(50, 205, 50);
  rect(gox, goy, btnSize * 2, btnSize); //creates the button
  
  //power button text
  textFont(font);
  textSize(40);
  if(powerButton == 1) {
    fill(255); text("STOP", gox, goy);
  }
  else {
    fill(0); text("START", gox, goy);
  }

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
  
  //forward button
  int fwdx = 380;
  int fwdy = 180;
  fill(50, 205, 50);
  if(overBtn_fwd == true){stroke(255);}
  else{stroke(0);}
  rect(fwdx, fwdy, btnSize, btnSize);
  fill(255);
  text("^", fwdx, fwdy);
  
  //hardcoding hovering over buttons
  if((mouseX > (gox - (btnSize))) 
  && (mouseX < (gox + (btnSize))) 
  && (mouseY > (goy - (btnSize / 2))) 
  && (mouseY < (goy + (btnSize / 2))) 
  && distPrompt == false)
    {overBtn_start = true;}
  else
    {overBtn_start = false;}
  
  if((mouseX > (leftx - (btnSize / 2))) 
  && (mouseX < (leftx + (btnSize / 2))) 
  && (mouseY > (lefty - (btnSize / 2))) 
  && (mouseY < (lefty + (btnSize / 2))) 
  && distPrompt == false)
    {overBtn_left = true;}
  else
    {overBtn_left = false;}
  
  if((mouseX > (rightx - (btnSize / 2)))
  && (mouseX < (rightx + (btnSize / 2)))
  && (mouseY > (righty - (btnSize / 2)))
  && (mouseY < (righty + (btnSize / 2)))
  && distPrompt == false)
    {overBtn_right = true;}
  else
    {overBtn_right = false;}
  
  if((mouseX > (fwdx - (btnSize / 2)))
  && (mouseX < (fwdx + (btnSize / 2)))
  && (mouseY > (fwdy - (btnSize / 2)))
  && (mouseY < (fwdy + (btnSize / 2)))
  && distPrompt == false)
    {overBtn_fwd = true;}
  else
    {overBtn_fwd = false;}
  
  //Distance prompt
  textAlign(LEFT);
  if (distPrompt == true){
    stroke(255);
    fill(0);
    rect(640, 360, 300, 100);
    fill(255);
    textSize(20);
    text("Enter distance: " + distInput, 490 + indent, 360);
  }
  
  //bottom information panel
  rectMode(CORNER);
  stroke(255);
  fill(0);
  rect(0, 500, 1280, 220);
  fill(255);
  textSize(20);
  text("Last Buggy Command: " + inputDisplay, indent, 560);
  text("Distance Covered: " + distTravelled + "cm", indent, 600);

}

//CLicking on buttons
void mousePressed(){
  if (overBtn_start == true)
  {
    if (powerButton == 0)
    {
      powerButton = 1;
      myClient.write("G"); //sends command to buggy
      inputDisplay = "Turn on";
    }
    else
    {
      powerButton = 0;
      myClient.write("S");
      inputDisplay = "Turn off";
    }
  }
  
  if (overBtn_right == true)
  {
    inputDisplay = "Turn right";
    myClient.write("C");
  }
  if (overBtn_left == true)
  {
    inputDisplay = "Turn left";
    myClient.write("D");
  }
  if (overBtn_fwd == true)
  {
    distPrompt = true;
  }

}

//Typing in forward distance
void keyPressed(){
  if(distPrompt == true) {
    
    // Cancel with backspace
    if (key == BACKSPACE) {
        numInput = 0;
        distInput = 0;
        distPrompt = false;
    }

    // If it's a digit 0–9
    else if (key >= '0' && key <= '9') {
      numInput = key - '0';
    }
    else {
      numInput = -1;
    }

    //Cancels invalid in puts, doesn't allow distance greater than 999cm
    if (numInput == -1) {
      numInput = 0;
    }
    else if(distInput < 999) {
      distInput = (distInput * 10) + numInput;
    }
    
    if(distInput > 999) {
      distInput = (distInput - numInput) / 10;
    }
    
    //Sends command as a string containing the distance number to the buggy
    if(key == '\n') {
      inputDisplay = "Go forward " + distInput + "cm";
      myClient.write("A" + (distInput));
      numInput = 0; 
      distInput = 0; 
      distPrompt = false;
    }
  }
}
