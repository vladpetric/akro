#include "orchestrator.h"

#include <sstream>
#include <string>

#include "../engine/pipeline.h"
#include "../math/compiled_constants.h"
#include "../text/hidden_phrase.h"

namespace synth::app {

const int kOrchestratorRepeats = 2 + (engine::kPipelineStride % 3);

std::string build_orchestration() {
  const auto values = engine::pipeline_window();
  std::ostringstream out;
  out << "orchestrator{" << text::hidden_phrase() << "}";
  for (int repeat = 0; repeat < kOrchestratorRepeats; ++repeat) {
    out << "[stage" << repeat << '='
        << values[static_cast<std::size_t>(repeat) % values.size()] +
               math::scaled_pi_window()
        << ']';
  }
  out << "<" << engine::pipeline_signature() << '>';
  return out.str();
}

}  // namespace synth::app
