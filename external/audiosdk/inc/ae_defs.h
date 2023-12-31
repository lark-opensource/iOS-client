#pragma once

#if defined(__clang__) || defined(__GNUC__)
#define MAMMON_DEPRECATED __attribute__((deprecated))
#elif defined(_MSC_VER)
#define MAMMON_DEPRECATED __declspec(deprecated)
#else
#define MAMMON_DEPRECATED
#endif

#ifndef MAMMON_EXPORT
#if defined(__clang__) || defined(__GNUC__)
#define MAMMON_EXPORT __attribute__((visibility("default")))
#elif defined(_MSC_VER)
#ifdef BUILDING_MAMMON_NULL
#define MAMMON_EXPORT
#else
#ifdef BUILDING_MAMMON
#define MAMMON_EXPORT __declspec(dllexport)
#else
#define MAMMON_EXPORT __declspec(dllimport)
#endif
#endif
#else
#define MAMMON_EXPORT
#endif
#endif

#ifndef MAMMON_DEPRECATED_EXPORT
#define MAMMON_DEPRECATED_EXPORT MAMMON_EXPORT MAMMON_DEPRECATED
#endif

#if __cplusplus

#include <cstdint>
namespace mammon {
    namespace acore {

        using byte = std::uint8_t;

    }
}  // namespace mammon

#endif
