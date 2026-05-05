#include <iomanip>
#include <iostream>

#include "app/report.h"
#include "math/compiled_constants.h"
#include "text/banner.h"

int main() {
  std::cout << synth::text::banner_line() << '\n';
  std::cout << std::fixed << std::setprecision(12);
  std::cout << "pi(512)=" << static_cast<double>(synth::math::kPi512)
            << " constexpr=" << synth::math::kPi512ConstexprString
            << " pi(524288)=" << static_cast<double>(synth::math::kPi524288)
            << " constexpr=" << synth::math::kPi524288ConstexprString
            << " e(1024)=" << static_cast<double>(synth::math::kE1024)
            << " constexpr=" << synth::math::kE1024ConstexprString << '\n';
  std::cout << synth::app::build_report() << '\n';
  return 0;
}
