#pragma once

#include <array>
#include <string>

namespace synth::engine {

extern const int kPipelineStride;

std::array<int, 4> pipeline_window();
std::string pipeline_signature();

}  // namespace synth::engine
