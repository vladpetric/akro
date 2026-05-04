#pragma once

#include <array>
#include <string>

namespace synth::detail {

extern const int kSeedBias;

int cache_seed();
std::array<int, 4> cache_window();
std::string cache_marker();

}  // namespace synth::detail
