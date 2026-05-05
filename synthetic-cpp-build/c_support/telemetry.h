#pragma once

#ifdef __cplusplus
extern "C" {
#endif

extern const int kSynthTelemetryScale;

int synth_bias_window(void);
int synth_telemetry_value(void);
const char* synth_telemetry_label(void);

#ifdef __cplusplus
}
#endif
