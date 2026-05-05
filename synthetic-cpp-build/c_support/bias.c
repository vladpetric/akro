#include "bias.h"

#include "telemetry.h"

const int kSynthBiasBase = 11;

int synth_bias_window(void) {
  return kSynthBiasBase + (kSynthTelemetryScale % 7);
}
