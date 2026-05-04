#pragma once

#include <string>
#include <string_view>

namespace synth::math {

extern const long double kPi512;
extern const long double kPi1024;
extern const long double kE512;
extern const long double kE1024;
extern const std::string_view kBuildPhrase;
extern const int kPrecisionBudget;

std::string describe_constants();
int scaled_pi_window();

}  // namespace synth::math
