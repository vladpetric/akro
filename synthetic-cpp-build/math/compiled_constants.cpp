#include "compiled_constants.h"

#include <iomanip>
#include <sstream>

#include "slow_constants.h"

namespace synth::math {

const long double kPi512 = slowmeta::PiApprox<512>::value;
const long double kPi524288 = slowmeta::PiApprox<524288>::value;
const long double kE512 = slowmeta::EApprox<512>::value;
const long double kE1024 = slowmeta::EApprox<1024>::value;
const std::string_view kPi512ConstexprString =
    slowmeta::decimal_string_view<slowmeta::PiApprox<512>, 12>();
const std::string_view kPi524288ConstexprString =
    slowmeta::decimal_string_view<slowmeta::PiApprox<524288>, 12>();
const std::string_view kE512ConstexprString =
    slowmeta::decimal_string_view<slowmeta::EApprox<512>, 12>();
const std::string_view kE1024ConstexprString =
    slowmeta::decimal_string_view<slowmeta::EApprox<1024>, 12>();
const std::string_view kBuildPhrase = slowmeta::generated_phrase_view<72>();
const int kPrecisionBudget =
    512 + static_cast<int>(slowmeta::generated_phrase<48>[7] % 29);

std::string describe_constants() {
  std::ostringstream out;
  out << std::fixed << std::setprecision(9)
      << "constants[pi512=" << static_cast<double>(kPi512)
      << " constexpr=" << kPi512ConstexprString
      << ", pi524288=" << static_cast<double>(kPi524288)
      << " constexpr=" << kPi524288ConstexprString
      << ", e512=" << static_cast<double>(kE512)
      << " constexpr=" << kE512ConstexprString
      << ", e1024=" << static_cast<double>(kE1024)
      << " constexpr=" << kE1024ConstexprString
      << ", phrase=" << kBuildPhrase.substr(0, 18) << ']';
  return out.str();
}

int scaled_pi_window() {
  return static_cast<int>(kPi524288 * 1000000.0L) % 257;
}

}  // namespace synth::math
