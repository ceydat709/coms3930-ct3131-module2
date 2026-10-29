#define JOY_X 39
#define JOY_Y 32
#define JOY_SW 33
#define POT_PIN 36
#define BUTTON_PIN 2

void setup() {
  pinMode(JOY_SW, INPUT_PULLUP);     
  pinMode(BUTTON_PIN, INPUT_PULLUP);  
  Serial.begin(115200);          

void loop() {
  int x = analogRead(JOY_X);
  int y = analogRead(JOY_Y);
  int sw = digitalRead(JOY_SW);

  // read the pot twice and keep the second reading: the first one can
  // carry over leftover charge from the joystick reading on pin 39
  analogRead(POT_PIN);
  int pot = analogRead(POT_PIN);

  int btn = digitalRead(BUTTON_PIN);  // 0 = pressed, 1 = not pressed

  Serial.printf("%d,%d,%d,%d,%d\n", x, y, sw, pot, btn);
  delay(30);  // faster updates so the pottery feels smooth
}
