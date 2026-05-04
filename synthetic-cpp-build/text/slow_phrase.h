#pragma once

#include <array>
#include <cstddef>
#include <string_view>

namespace synth::text::slowmeta {

template <std::size_t Index>
struct PhraseChar {
  static constexpr char kPattern[] = "AKRO_SYNTHETIC_TEXT_PAYLOAD_";
  static constexpr std::size_t kPeriod = sizeof(kPattern) - 1;
  static constexpr char value = kPattern[Index % kPeriod];
};

template <std::size_t Length, std::size_t Index = 0>
struct PhraseBuilder {
  static constexpr std::array<char, Length + 1> make() {
    auto out = PhraseBuilder<Length, Index + 1>::make();
    out[Index] = PhraseChar<Index>::value;
    return out;
  }
};

template <std::size_t Length>
struct PhraseBuilder<Length, Length> {
  static constexpr std::array<char, Length + 1> make() {
    std::array<char, Length + 1> out{};
    out[Length] = '\0';
    return out;
  }
};

template <std::size_t Length>
inline constexpr auto generated_phrase = PhraseBuilder<Length>::make();

template <std::size_t Length>
constexpr std::string_view generated_phrase_view() {
  return std::string_view(generated_phrase<Length>.data(), Length);
}

}  // namespace synth::text::slowmeta
