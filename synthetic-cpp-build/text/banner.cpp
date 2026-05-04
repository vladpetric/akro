#include "banner.h"

#include <string>

#include "../math/compiled_constants.h"
#include "hidden_phrase.h"

namespace synth::text {

const int kBannerWidth = 48 + (math::kPrecisionBudget % 11);

std::string banner_line() {
  const std::string core = hidden_phrase() + ":" + hidden_suffix();
  std::string line = "[" + core + "]";
  if (static_cast<int>(line.size()) < kBannerWidth) {
    line.append(static_cast<std::size_t>(kBannerWidth) - line.size(),
                static_cast<char>('=' + (math::scaled_pi_window() % 3)));
  }
  return line;
}

}  // namespace synth::text
