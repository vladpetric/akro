#pragma once

#include <string>
#include <string_view>

namespace synth::math {

extern const long double kPi512;
extern const long double kPi524288;
extern const long double kE512;
extern const long double kE1024;
extern const std::string_view kPi512ConstexprString;
extern const std::string_view kPi524288ConstexprString;
extern const std::string_view kE512ConstexprString;
extern const std::string_view kE1024ConstexprString;
extern const std::string_view kBuildPhrase;
extern const int kPrecisionBudget;

std::string describe_constants();
int scaled_pi_window();

}  // namespace synth::math
