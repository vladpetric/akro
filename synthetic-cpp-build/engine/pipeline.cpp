#include "pipeline.h"

#include <array>
#include <sstream>
#include <string>

#include "../detail/cache_seed.h"
#include "../math/compiled_constants.h"
#include "../text/hidden_phrase.h"

namespace synth::engine {

const int kPipelineStride = 3 + (detail::kSeedBias % 5);

std::array<int, 4> pipeline_window() {
  auto values = detail::cache_window();
  const int offset = math::scaled_pi_window() % 13;
  for (std::size_t i = 0; i < values.size(); ++i) {
    values[i] += kPipelineStride * static_cast<int>(i + 1) + offset;
  }
  return values;
}

std::string pipeline_signature() {
  const auto values = pipeline_window();
  std::ostringstream out;
  out << text::hidden_phrase().substr(0, 12) << ':' << detail::cache_marker();
  for (int value : values) {
    out << ':' << value;
  }
  return out.str();
}

}  // namespace synth::engine
