#pragma once

#include <array>
#include <cstddef>

namespace synth::detail::slowmeta {

template <int Index>
struct WindowTerm {
  static constexpr int value = (Index * Index + 13 * Index + 17) % 211;
};

template <int Begin, int End>
struct WindowSum {
  static constexpr int kMid = Begin + (End - Begin) / 2;
  static constexpr int value =
      WindowSum<Begin, kMid>::value + WindowSum<kMid, End>::value;
};

template <int Index>
struct WindowSum<Index, Index + 1> {
  static constexpr int value = WindowTerm<Index>::value;
};

template <std::size_t Length, std::size_t Index = 0>
struct WindowBuilder {
  static constexpr std::array<int, Length> make() {
    auto out = WindowBuilder<Length, Index + 1>::make();
    out[Index] = WindowSum<static_cast<int>(Index) * 32,
                           static_cast<int>(Index) * 32 + 64>::value %
                 257;
    return out;
  }
};

template <std::size_t Length>
struct WindowBuilder<Length, Length> {
  static constexpr std::array<int, Length> make() {
    return {};
  }
};

template <std::size_t Length>
inline constexpr auto generated_window = WindowBuilder<Length>::make();

}  // namespace synth::detail::slowmeta
