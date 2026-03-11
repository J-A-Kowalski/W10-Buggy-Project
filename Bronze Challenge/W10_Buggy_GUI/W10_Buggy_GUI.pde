import processing.serial.*;
import processing.net.*;

//custom buggy vector image
PShape buggy;

//communicating with buggy
Client myClient; 
int data = 0;
int input = 0;

//GUI element variables
int turnRight = 0; //0 and 1 used instead of true and false to enable multiplying by them
int turnLeft = 0;
int obstacle = 0;
int going = 0;
String status = "Check connection to buggy network";

//custom start button
boolean overButton = false;
int powerButton = 0;

//custom font
PFont font;

void setup() { 
  size (1280, 720);
  myClient = new Client(this,"192.168.4.1",5200); 
  
//loading custom sprite and font   
 buggy = loadShape("fella.svg");
 font = createFont("unispace.bold.otf", 128);
} 


void draw() { 
  data = myClient.read();
  if (data != -1){
    input = data;
  }
 
  if(input == 1){
    going = 1;
    status = "Buggy: Driving along track";}
  else if (input != 4)
    {going = 0;}
 
  if(input == 2){
    turnRight = 1;
    status = "Buggy: Turning right";}
  else{turnRight = 0;}
 
  if(input == 3){
    turnLeft = 1;
    status = "Buggy: Turning left";}
  else{turnLeft = 0;}
  
  if(input == 4){
    going = 1;
    status = "Buggy: Driving along track, cautiously";}
  else if (input != 1)
    {going = 0;}
 
  if(input == 5){
    obstacle = 1;
    if(powerButton == 1){status = "Buggy: Stuck behind obstacle";}
    else{status = "Buggy: Stopped by user, obstacle ahead";}}
  else{obstacle = 0;}
  
  if(input == 6){
   status = "Buggy: Stopped by user"; 
  }
 
  background(40);
  strokeWeight(2);
  
  //power button
  if(overButton == true){stroke(255);}
  else{stroke(0);}
  fill(50, 205, 50, 55 + (200 * powerButton));
  rect(800, 200, 200, 130);
  
  //hovering over power button
  if((mouseX > 800 && mouseX < 1000 && mouseY > 200 && mouseY < 330))
  {overButton = true;}
  else
  {overButton = false;}
  
  //power button text
  textFont(font);
  textSize(40);
  if(powerButton == 1){fill(255);}
  else{fill(0);}
  text("START", 830, 280);
  
  //Central buggy
  shape(buggy, 300, 280, 160, 160);
  
  //left turning indicator
  fill(50, 205, 50, 55 + (200 * turnLeft));
  stroke(255 * turnLeft);
  triangle(120, 350, 225, 290, 225, 410);
  
  //right turning indicator
  fill(50, 205, 50, 55 + (200 * turnRight));
  stroke(255 * turnRight);
  triangle(650, 350, 545, 290, 545, 410);
  
  //forward indicator
  fill(50, 205, 50, 55 + (200 * going));
  stroke(255 * going);
  triangle(315, 200, 375, 100, 435, 200);
  
  //obstacle indicator
  stroke(255 * obstacle);
  fill(255, 140, 0, 55 + (200 * obstacle));
  rect(270, 210, 200, 50);
  fill(255 * obstacle);
  textFont(font);
  textSize(18);
  text("OBSTACLE DETECTED",275, 235);
  
  //console
  stroke(255);
  fill(0);
  rect(0, 500, 1280, 220);
  
  fill(255);
  textSize(20);
  text(status, 40, 560);
} 

//Interfacing with start button
void mousePressed(){
if (overButton == true)
{
  if (powerButton == 0){
    powerButton = 1;
    myClient.write("CMD_GO");
  }
  else
  {
    powerButton = 0;
    myClient.write("CMD_STOP");
    status = "Buggy: Stopped by user";
  }
}
}
