#include "cache_seed.h"

#include <array>
#include <string>

#include "slow_window.h"
#include "../math/compiled_constants.h"
#include "../text/banner.h"

namespace synth::detail {

const int kSeedBias = static_cast<int>(synth::math::kPi512 * 100000.0L) % 97;

int cache_seed() {
  return kSeedBias + synth::math::kPrecisionBudget +
         static_cast<int>(synth::math::kE512 * 1000.0L) % 31;
}

std::array<int, 4> cache_window() {
  const int seed = cache_seed();
  return {(seed + slowmeta::generated_window<4>[0]) % 17,
          (seed / 3 + slowmeta::generated_window<4>[1]) % 19,
          (seed / 5 + slowmeta::generated_window<4>[2]) % 23,
          (seed / 7 + slowmeta::generated_window<4>[3]) % 29};
}

std::string cache_marker() {
  return text::banner_line().substr(0, 18);
}

}  // namespace synth::detail
