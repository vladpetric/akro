#include "hidden_phrase.h"

#include <string>

#include "../math/compiled_constants.h"
#include "slow_phrase.h"

namespace synth::text {

const int kHiddenMultiplier = 2 + (math::kPrecisionBudget % 5);

std::string hidden_phrase() {
  return std::string(slowmeta::generated_phrase_view<48>().substr(0, 24)) + "-" +
         std::to_string(kHiddenMultiplier * 7);
}

std::string hidden_suffix() {
  return std::string(slowmeta::generated_phrase_view<18>().substr(0, 6)) + "-" +
         std::to_string(static_cast<int>(math::kPi1048576 * 1000.0L) % 1000);
}

}  // namespace synth::text
