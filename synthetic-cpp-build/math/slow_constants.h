#pragma once

#include <array>
#include <cstddef>
#include <string_view>

namespace synth::slowmeta {

template <int Begin, int End>
struct FactorialRange {
  static constexpr int kMid = Begin + (End - Begin) / 2;
  static constexpr long double value =
      FactorialRange<Begin, kMid>::value * FactorialRange<kMid, End>::value;
};

template <int N>
struct FactorialRange<N, N> {
  static constexpr long double value = 1.0L;
};

template <int N>
struct FactorialRange<N, N + 1> {
  static constexpr long double value = static_cast<long double>(N);
};

template <int N>
struct ReciprocalFactorial {
  static constexpr long double value = 1.0L / FactorialRange<1, N + 1>::value;
};

template <>
struct ReciprocalFactorial<0> {
  static constexpr long double value = 1.0L;
};

template <int Begin, int End>
struct ESumRange {
  static constexpr int kMid = Begin + (End - Begin) / 2;
  static constexpr long double value =
      ESumRange<Begin, kMid>::value + ESumRange<kMid, End>::value;
};

template <int N>
struct ESumRange<N, N + 1> {
  static constexpr long double value = ReciprocalFactorial<N>::value;
};

template <int Terms>
struct EApprox {
  static constexpr long double value = ESumRange<0, Terms + 1>::value;
};

template <int Index>
struct PiLeibnizTerm {
  static constexpr long double value =
      (Index % 2 == 0 ? 1.0L : -1.0L) / static_cast<long double>(2 * Index + 1);
};

template <int Begin, int End>
struct PiSumRange {
  static constexpr int kMid = Begin + (End - Begin) / 2;
  static constexpr long double value =
      PiSumRange<Begin, kMid>::value + PiSumRange<kMid, End>::value;
};

template <int Index>
struct PiSumRange<Index, Index + 1> {
  static constexpr long double value = PiLeibnizTerm<Index>::value;
};

template <int Terms>
struct PiApprox {
  static constexpr long double value = 4.0L * PiSumRange<0, Terms>::value;
};

constexpr unsigned long long pow10(std::size_t exponent) {
  unsigned long long value = 1;
  for (std::size_t i = 0; i < exponent; ++i) {
    value *= 10ULL;
  }
  return value;
}

constexpr std::size_t decimal_digits(unsigned long long value) {
  std::size_t digits = 1;
  while (value >= 10ULL) {
    value /= 10ULL;
    ++digits;
  }
  return digits;
}

template <typename Approximation, std::size_t FractionalDigits>
struct DecimalString {
  static constexpr bool kNegative = Approximation::value < 0.0L;
  static constexpr long double kAbsoluteValue =
      kNegative ? -Approximation::value : Approximation::value;
  static constexpr unsigned long long kScale = pow10(FractionalDigits);
  static constexpr unsigned long long kScaledValue =
      static_cast<unsigned long long>(
          kAbsoluteValue * static_cast<long double>(kScale) + 0.5L);
  static constexpr unsigned long long kIntegerPart = kScaledValue / kScale;
  static constexpr unsigned long long kFractionalPart = kScaledValue % kScale;
  static constexpr std::size_t kIntegerDigits = decimal_digits(kIntegerPart);
  static constexpr std::size_t kLength =
      (kNegative ? 1U : 0U) + kIntegerDigits +
      (FractionalDigits == 0 ? 0U : 1U + FractionalDigits);

  static constexpr std::array<char, kLength + 1> make() {
    std::array<char, kLength + 1> out{};
    std::size_t pos = 0;
    if (kNegative) {
      out[pos++] = '-';
    }

    unsigned long long integer = kIntegerPart;
    std::array<char, kIntegerDigits> reversed{};
    for (std::size_t i = 0; i < kIntegerDigits; ++i) {
      reversed[i] = static_cast<char>('0' + (integer % 10ULL));
      integer /= 10ULL;
    }
    for (std::size_t i = 0; i < kIntegerDigits; ++i) {
      out[pos++] = reversed[kIntegerDigits - 1 - i];
    }

    if constexpr (FractionalDigits > 0) {
      out[pos++] = '.';
      unsigned long long divisor = kScale / 10ULL;
      for (std::size_t i = 0; i < FractionalDigits; ++i) {
        out[pos++] =
            static_cast<char>('0' + ((kFractionalPart / divisor) % 10ULL));
        if (divisor > 1ULL) {
          divisor /= 10ULL;
        }
      }
    }

    out[kLength] = '\0';
    return out;
  }
};

template <typename Approximation, std::size_t FractionalDigits>
inline constexpr auto decimal_string =
    DecimalString<Approximation, FractionalDigits>::make();

template <typename Approximation, std::size_t FractionalDigits>
constexpr std::string_view decimal_string_view() {
  return std::string_view(decimal_string<Approximation, FractionalDigits>.data(),
                          DecimalString<Approximation, FractionalDigits>::kLength);
}

template <std::size_t Index>
struct PhraseChar {
  static constexpr char kPattern[] = "AKRO_SYNTHETIC_META_BUILD_";
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

}  // namespace synth::slowmeta
