import processing.serial.*;
import processing.net.*;

//communicating with buggy
//Client myClient; 
int data = 0;

PFont f;

// Variable to store text currently being typed
String typing = "";
int arPos = 0; 

// Variable to store saved text when return is hit
String saved = "";
String inputList[] = new String[100];

void setup() {
  size (1280, 720);
  //myClient = new Client(this,"192.168.4.1",5200);
  f = createFont("Arial",16);
}

void draw() {
  //data = myClient.read();
  background(255);
  int indent = 25;
  
  // Set the font and fill for text
  textFont(f);
  fill(0);
  
  // Display everything
  text("Click in this window and type. \nHit enter to save. ", indent, 40);
  text("Input: " + typing,indent,190);
  text("Saved text: " + saved,indent,230);
  text("Input list: " + inputList[4], indent, 400);
  if (arPos != 0){
  for (int i = 0; i != arPos; i = i+1 ){
  text("Step " + i + " : " + inputList[i], indent, 500 + (20 * i));
  }
  }
}

void keyPressed() {
  // If the return key is pressed, save the String and clear it
  if (key == '\n' ) {
    saved = typing;
    inputList[arPos] = typing;
    arPos = arPos + 1;
    // A String can be cleared by setting it equal to ""
    typing = ""; 
  } else {
    // Otherwise, concatenate the String
    // Each character typed by the user is added to the end of the String variable.
    typing = typing + key; 
  }
}
