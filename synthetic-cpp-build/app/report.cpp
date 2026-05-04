#include "report.h"

#include <sstream>
#include <string>

#include "orchestrator.h"
#include "../math/compiled_constants.h"
#include "../text/banner.h"

namespace synth::app {

const int kReportColumns = 3;

std::string build_report() {
  std::ostringstream out;
  out << "report{" << kReportColumns << " cols} " << text::banner_line() << '\n'
      << build_orchestration() << '\n'
      << math::describe_constants();
  return out.str();
}

}  // namespace synth::app
