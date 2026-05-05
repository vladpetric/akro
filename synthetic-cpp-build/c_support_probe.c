#include <stdio.h>

#include "c_support/telemetry.h"

int main(void) {
  printf("%s:%d\n", synth_telemetry_label(), synth_telemetry_value());
  return 0;
}
