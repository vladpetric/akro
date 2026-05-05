#include "telemetry.h"

#include "bias.h"

const int kSynthTelemetryScale = 5;

int synth_telemetry_value(void) {
  return kSynthTelemetryScale * 3 + synth_bias_window();
}

const char* synth_telemetry_label(void) {
  return synth_telemetry_value() % 2 == 0 ? "even-telemetry" : "odd-telemetry";
}
