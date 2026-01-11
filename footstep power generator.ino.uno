
#include <Wire.h>
#include <LiquidCrystal_I2C.h>

// ---------------------- CONFIGURATION ----------------------

// LCD settings
const int lcd_i2c_addr = 0x27;  // I2C address of the LCD

// Pin assignments
const int pin_a0  = 36;  // Analog input for piezo sensor
const int pin_led = 2;   // LED output for step indication

// Resistor divider values (scales piezo voltage for ADC input)
const float r_top      = 100000.0f; // 100kΩ (upper resistor)
const float r_bot      = 10000.0f;  // 10kΩ (lower resistor)
const float div_factor = (r_top + r_bot) / r_bot; // Voltage scaling factor

// ADC reference settings
const long adc_ref_mv = 1100L; // Internal 1.1V reference (millivolts)
const int adc_max     = 1023;  // 10-bit ADC maximum value

// Sampling and smoothing
const int samples_per_read         = 32;   // Number of samples per reading
const unsigned int sample_delay_us = 400;  // Delay between samples (µs)

// Display / bar graph configuration
const bool  enable_visual_stretch   = true;   // Enable stretched visual display
const float visual_gain             = 4.0f;   // Gain applied to bar graph
const float default_max_display_mv  = 200.0f; // Default bar graph upper limit

// Step detection parameters
float step_delta_threshold_mv          = 8.0f;   // Minimum voltage delta for step
const unsigned long step_debounce_ms   = 400UL;  // Step debounce time (ms)
const bool use_dynamic_threshold       = true;   // Enable adaptive threshold
const float threshold_peak_fraction    = 0.12f;  // Dynamic threshold (% of peak)

// User-adjustable sensitivity (0.0–1.0)
// Example: 0.5 = half threshold, 1.0 = default
float STEP_SENSITIVITY = 1.0f;

// LED feedback timing
const unsigned long led_on_ms = 180UL; // LED ON duration after step (ms)

// Baseline voltage tracking (Exponential Moving Average)
const float baseline_alpha = 0.08f;

// Peak value decay rate
const unsigned long peak_decay_ms = 3000UL;

// Debugging (set to false for production)
bool serial_debug = true;

// ---------------------- GLOBAL VARIABLES ----------------------
LiquidCrystal_I2C lcd(lcd_i2c_addr, 16, 2);

unsigned long last_step_time = 0UL;
unsigned long last_led_time  = 0UL;
bool led_state = false;
unsigned long step_count = 0UL;

float baseline_mv = 0.0f;
float running_peak_mv = 20.0f;
unsigned long last_peak_decay = 0UL;

// Custom bar graph characters (6 levels)
byte bar_chars[6][8] = {
  {B00000,B00000,B00000,B00000,B00000,B00000,B00000,B00000},
  {B10000,B10000,B10000,B10000,B10000,B10000,B10000,B10000},
  {B11000,B11000,B11000,B11000,B11000,B11000,B11000,B11000},
  {B11100,B11100,B11100,B11100,B11100,B11100,B11100,B11100},
  {B11110,B11110,B11110,B11110,B11110,B11110,B11110,B11110},
  {B11111,B11111,B11111,B11111,B11111,B11111,B11111,B11111}
};

// ---------------------- SETUP ----------------------
void setup() {
  if (serial_debug) Serial.begin(115200);

  analogReference(INTERNAL); // Use 1.1V reference for high accuracy

  lcd.init();
  lcd.backlight();
  for (int i = 0; i < 6; ++i) lcd.createChar(i, bar_chars[i]);

  pinMode(pin_led, OUTPUT);
  digitalWrite(pin_led, LOW);

  show_splash(); // Display splash screen at startup

  // Establish baseline by averaging initial readings
  float sum = 0.0f;
  for (int i = 0; i < 12; ++i) {
    sum += read_rectified_mv();
    delay(20);
  }
  baseline_mv = sum / 12.0f;
  running_peak_mv = max(baseline_mv, 20.0f);
  last_peak_decay = millis();

  if (serial_debug) {
    Serial.print(F("Initial baseline (mV): "));
    Serial.println(baseline_mv, 3);
  }
}

// ---------------------- MAIN LOOP ----------------------
void loop() {
  float vrect_mv = read_rectified_mv();

  // Update running peak for dynamic thresholding
  if (vrect_mv > running_peak_mv) {
    running_peak_mv = vrect_mv;
    last_peak_decay = millis();
  } else if (millis() - last_peak_decay > peak_decay_ms) {
    running_peak_mv *= 0.995f; // Gradual decay
    if (running_peak_mv < 5.0f) running_peak_mv = 5.0f;
    last_peak_decay = millis();
  }

  // Scale display values for bar graph
  float bar_value_mv = vrect_mv;
  float bar_display_max_mv = max(default_max_display_mv, running_peak_mv);
  if (enable_visual_stretch) {
    bar_value_mv *= visual_gain;
    bar_display_max_mv *= visual_gain;
  }

  // Step detection with dynamic threshold
  float delta_mv = vrect_mv - baseline_mv;
  float effective_threshold = step_delta_threshold_mv * STEP_SENSITIVITY;
  if (use_dynamic_threshold) {
    float dyn = running_peak_mv * threshold_peak_fraction * STEP_SENSITIVITY;
    if (dyn > effective_threshold) effective_threshold = dyn;
  }

  // Register step if conditions are met
  if ((delta_mv >= effective_threshold) && (millis() - last_step_time > step_debounce_ms)) {
    step_count++;
    last_step_time = millis();

    digitalWrite(pin_led, HIGH);
    led_state = true;
    last_led_time = millis();

    if (serial_debug) {
      Serial.print(F("STEP #"));
      Serial.print(step_count);
      Serial.print(F("  vrect_mv="));
      Serial.print(vrect_mv, 3);
      Serial.print(F("  delta="));
      Serial.println(delta_mv, 3);
    }
  }

  // Turn off LED after set duration
  if (led_state && (millis() - last_led_time >= led_on_ms)) {
    digitalWrite(pin_led, LOW);
    led_state = false;
  }

  // Update baseline using slow averaging
  baseline_mv += (vrect_mv - baseline_mv) * baseline_alpha;

  // Render LCD output
  render_main_screen(vrect_mv, step_count, bar_value_mv, bar_display_max_mv);

  delay(30); // Small delay for stable refresh
}

// ---------------------- FUNCTIONS ----------------------

/**
 * Displays splash screen and initialization progress
 */
void show_splash() {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print(F("Footsteps Energy"));
  lcd.setCursor(0, 1);
  lcd.print(F("    Generator    "));
  delay(2000);

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print(F(" Initializing..."));
  lcd.setCursor(0, 1);
  for (int i = 0; i < 16; ++i) {
    lcd.write(byte(5));
    delay(30);
  }
  delay(800);
  lcd.clear();
}

/**
 * Reads rectified piezo voltage in millivolts (averaged samples)
 */
float read_rectified_mv() {
  unsigned long raw_sum = 0UL;
  for (int i = 0; i < samples_per_read; ++i) {
    raw_sum += analogRead(pin_a0);
    delayMicroseconds(sample_delay_us);
  }
  float raw_avg = (float)raw_sum / samples_per_read;
  float vnode_mv = (raw_avg * (float)adc_ref_mv) / adc_max;
  float vrect_mv = vnode_mv * div_factor;

  if (serial_debug) {
    Serial.print(F("rawAvg:")); Serial.print(raw_avg, 2);
    Serial.print(F("  vnode(mV):")); Serial.print(vnode_mv, 4);
    Serial.print(F("  vrect(mV):")); Serial.println(vrect_mv, 4);
  }
  return vrect_mv;
}

/**
 * Renders main LCD display (Voltage, Step Count, and Bar Graph)
 */
void render_main_screen(float true_mv, unsigned long steps, float bar_value_mv, float bar_display_max_mv) {
  lcd.setCursor(0, 0);
  lcd.print(F("V:"));
  print_mv_field(true_mv);
  lcd.print(F(" S:"));
  lcd.print(steps);

  int used = 2 + 7 + 3 + digits_count(steps);
  if (used < 16) for (int i = used; i < 16; ++i) lcd.print(' ');

  draw_bar(bar_value_mv, bar_display_max_mv);
}

/**
 * Draws a bar graph representation of voltage on LCD second row
 */
void draw_bar(float voltage_mv, float max_mv) {
  if (max_mv <= 1.0f) max_mv = 1.0f;
  const int cols = 16;
  const int sub  = 5;
  const int total_units = cols * sub;

  int filled = (int)((voltage_mv / max_mv) * total_units + 0.5f);
  if (filled < 0) filled = 0;
  if (filled > total_units) filled = total_units;

  lcd.setCursor(0, 1);
  for (int col = 0; col < cols; ++col) {
    int units = filled - (col * sub);
    int level;
    if (units >= 5) level = 5;
    else if (units <= 0) level = 0;
    else level = units;
    lcd.write((byte)level);
  }
}

/**
 * Prints voltage field (formatted with mV suffix)
 */
void print_mv_field(float mv) {
  long imv = (long)(mv + 0.5f);
  char buf[8];
  sprintf(buf, "%4ld", imv);
  lcd.print(buf);
  lcd.print(F("mV"));
}

/**
 * Utility: Returns number of digits in an unsigned long
 */
int digits_count(unsigned long v) {
  if (v == 0) return 1;
  int c = 0;
  while (v) { v /= 10; ++c; }
  return c;
}
