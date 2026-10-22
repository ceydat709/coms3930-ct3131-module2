import processing.serial.*;

Serial myPort;
String val;
int analogMax = 4095;

int W = 240;
int H = 180;
int SCALE = 4;

// the clay is a stack of rings
int rings = 34;
float[] clay = new float[rings];

int wheelX = 85; // center of wheel
int wheelY = 104; // top
float angle = 0;
float speed = 0;
float handHeight = 0.5;
float push = 0;

int step = 0;
int lastButton = 1;
color glaze;
String[] stepNames = { "Place clay", "Shape it", "Open the top", "Fired!" };

color outline = color(74, 52, 46);
color cream = color(252, 245, 228);
color border = color(196, 158, 146);
color sky = color(140, 205, 232);
color accent = color(222, 98, 92);

// pixel frog
String[] frog = {
  ".XXX..XXX.",
  "XWKWXXWKWX",
  "XGGGGGGGGX",
  "XGGGGGGGGX",
  "XGXGGGGXGX",
  "XGGXXXXGGX",
  ".XGGGGGGX.",
  "..XXXXXX..",
};

void setup()
{
  size(960, 720);
  pixelDensity(1);
  noSmooth();
  textFont(createFont("Silom", 22));
  printArray(Serial.list());
  String portName = Serial.list()[5];
  println(portName);
  myPort = new Serial(this, portName, 115200);
}

void draw()
{
  // read every line from ESP32
  while (myPort.available() > 0) {
    val = myPort.readStringUntil('\n');
    if (val != null) {
      val = val.trim();
      int[] data = int(split(val, ','));
      if (data.length == 5) readSensors(data[0], data[1], data[3], data[4]);
    }
  }

  updateClay();

  drawWindow();
  drawWheel();
  if (step > 0) drawClay();

  PImage small = get(0, 0, W, H);
  image(small, 0, 0, W * SCALE, H * SCALE);
  drawText();
}

void readSensors(int x, int y, int pot, int button) {
  push = map(x, 0, analogMax, -1, 1);
  float upDown = map(y, 0, analogMax, -1, 1);
  if (abs(push) < 0.15) push = 0;
  if (abs(upDown) < 0.15) upDown = 0;
  handHeight = constrain(handHeight - upDown * 0.01, 0, 1);
  if (pot < 250) {
    speed = 0;
  } else {
    speed = map(pot, 250, analogMax, 0, 1);
  }

  if (button == 0 && lastButton == 1) nextStep();
  lastButton = button;
}

void nextStep() {
  step = step + 1;
  if (step == 4) step = 0;

  if (step == 1) {
    // new clay
    for (int i = 0; i < rings; i++) {
      clay[i] = 22 - i * 0.3;
    }
  }

  if (step == 3) {
    // pick a random  color
    color[] glazes = { color(120, 175, 160), color(90, 130, 190), color(240, 232, 215), color(150, 110, 170) };
    glaze = glazes[int(random(glazes.length))];
  }
}

void updateClay() {
  angle = angle + speed * 0.25;

  // clay only changes while shaping and wheel spinning
  if ((step == 1 || step == 2) && speed > 0) {
    int handRing = round(handHeight * (rings - 1));

    for (int i = 0; i < rings; i++) {
      // rings close to your hands change the most
      float closeness = max(0, 1 - abs(i - handRing) / 4.0);
      clay[i] = clay[i] + push * 0.35 * speed * closeness;
      clay[i] = constrain(clay[i], 5, 60);
    }

    // blend each ring a bit
    for (int i = 1; i < rings - 1; i++) {
      float average = (clay[i - 1] + clay[i + 1]) / 2;
      clay[i] = lerp(clay[i], average, 0.02);
    }
  }
}

void block(int x, int y, int w, int h, color c) {
  fill(c);
  rect(x, y, w, h);
}

void box(int x, int y, int w, int h, color inside) {
  color light = lerpColor(inside, color(255), 0.6);
  color dark = lerpColor(inside, color(0), 0.25);

  if (h > 10) {
    block(x + 3, y + 3, w, h, color(205, 184, 156));  // drop shadow
  }
  block(x, y, w, h, outline);
  block(x + 1, y + 1, w - 2, h - 2, inside);
  block(x + 1, y + 1, w - 2, 2, light);      // top edge
  block(x + 1, y + 1, 2, h - 2, light);      // left edge
  block(x + 1, y + h - 3, w - 2, 2, dark);   // bottom edge
  block(x + w - 3, y + 3, 2, h - 4, dark);   // right edge
}

void drawWindow() {
  noStroke();
  box(0, 0, W, H, cream);

  // dot pattern on the background
  for (int y = 20; y < H - 4; y += 4) {
    for (int x = 4 + (y / 4 % 2) * 2; x < W - 4; x += 4) {
      block(x, y, 1, 1, color(232, 217, 192));
    }
  }

  box(4, 3, W - 9, 13, border);

  // studio wall
  if (step == 3) {
    box(10, 19, 151, 101, color(255, 228, 200));
  } else {
    box(10, 19, 151, 101, color(255, 250, 240));
  }
  block(12, 92, 147, 26, color(236, 222, 200));

  box(167, 19, 63, 101, sky); // stats box
  box(10, 127, 34, 44, sky);
  box(50, 127, 180, 44, cream);

  // speed bar
  box(172, 33, 53, 6, color(255));
  block(173, 34, round(51 * speed), 4, accent);

  for (int r = 0; r < frog.length; r++) {
    for (int c = 0; c < frog[r].length(); c++) {
      char letter = frog[r].charAt(c);
      if (letter == 'X') fill(outline);
      if (letter == 'W') fill(255);
      if (letter == 'G') fill(125, 190, 95);
      if (letter == 'K') fill(40, 30, 30);
      if (letter != '.') rect(17 + c * 2, 141 + r * 2, 2, 2);
    }
  }
}

void drawWheel() {
  fill(215, 198, 175);
  ellipse(wheelX + 3, wheelY + 7, 130, 16);
  fill(outline);
  ellipse(wheelX, wheelY + 4, 128, 22);
  fill(110, 106, 100);
  ellipse(wheelX, wheelY + 4, 126, 20);
  // wheel head
  fill(130, 128, 122);
  ellipse(wheelX, wheelY + 1, 100, 12);
  fill(178, 175, 168);
  ellipse(wheelX, wheelY, 100, 11);

  // tick marks
  for (int k = 0; k < 8; k++) {
    float a = angle + k * QUARTER_PI;
    if (sin(a) > 0.2) block(round(wheelX + cos(a) * 44), round(wheelY + sin(a) * 4), 1, 2, color(130, 128, 122));
  }
}

void drawClay() {
  // the clay is brown, and turns the glaze color once it is fired
  color main = color(200, 135, 95);
  if (step == 3) main = glaze;
  color light = lerpColor(main, color(255), 0.25);
  color shadow = lerpColor(main, color(0), 0.18);
  color dark = lerpColor(main, color(0), 0.5);

  for (int i = 0; i < rings; i++) {
    int w = round(clay[i]);
    int y = wheelY - 2 - i * 2;

    block(wheelX - w - 1, y, w * 2 + 2, 2, dark);
    block(wheelX - w, y, w * 2, 2, main);
    block(wheelX - round(w * 0.6), y, max(1, round(w * 0.25)), 2, light);
    block(wheelX + round(w * 0.45), y, round(w * 0.55), 2, shadow);
    if (cos(angle) > 0) block(wheelX + round(sin(angle) * w * 0.85), y, 1, 2, dark);
  }

  // top of the clay
  int topW = round(clay[rings - 1]);
  if (step >= 2) {
    fill(dark);
  } else {
    fill(light);
  }
  ellipse(wheelX, wheelY - 1 - rings * 2, topW * 2, max(3, topW * 0.35));

  // hands
  if (step == 1 || step == 2) {
    int handRing = round(handHeight * (rings - 1));
    int w = round(clay[handRing]);
    int y = wheelY - 3 - handRing * 2;
    box(wheelX - w - 7, y, 6, 4, color(242, 200, 170));
    box(wheelX + w + 2, y, 6, 4, color(242, 200, 170));
  }
}

void label(String s, int x, int y, color c) {
  fill(c);
  text(s, x * SCALE, y * SCALE);
}

void drawText() {
  textAlign(LEFT, CENTER);

  // title and stats
  label("Ribbit & Throw", 9, 9, cream);
  label("Speed", 172, 27, outline);
  label(round(speed * 240) + " RPM", 172, 47, outline);
  label("Hands " + round(handHeight * 100) + "%", 172, 59, outline);
  label("Step " + (step + 1) + " of 4", 172, 79, outline);
  label(stepNames[step], 172, 91, accent);

  // message box
  String line1 = "";
  String line2 = "";
  if (step == 0) {
    line1 = "Welcome to Ribbit & Throw!";
    line2 = "Press the button to drop clay on the wheel.";
  } else if (step == 3) {
    line1 = "Fresh out of the kiln!";
    line2 = "Press the button to make another.";
  } else if (speed == 0) {
    line1 = "The wheel is stopped.";
    line2 = "Turn the knob to spin it.";
  } else if (push < 0) {
    line1 = "You are pushing the clay in!";
    line2 = "It gets narrower where your hands are.";
  } else if (push > 0) {
    line1 = "You are pulling the clay out!";
    line2 = "It gets wider where your hands are.";
  } else {
    line1 = "Your hands are resting on the clay.";
    line2 = "Joystick left/right to push or pull.";
  }
  label(line1, 56, 137, outline);
  label(line2, 56, 149, color(120, 92, 80));

  if (step == 1) label("Press: open the top", 56, 161, accent);
  if (step == 2) label("Press: fire it in the kiln", 56, 161, accent);
}
