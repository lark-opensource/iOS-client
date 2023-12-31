#pragma once

#ifndef MAMMON_ENGINE_NAMESPACE
#define MAMMON_ENGINE_NAMESPACE
#define MAMMON_ENGINE_NAMESPACE_BEGIN namespace mammonengine {
#define MAMMON_ENGINE_NAMESPACE_END }
#endif

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
#define MAMMON_EXPORT __declspec(dllexport)
#else
#define MAMMON_EXPORT
#endif
#endif

// Error code

#define MAMMON_RESULT_SUCCESS 0
#define MAMMON_RESULT_FAIL -1

#define MAMMON_RESULT_BAD_CHANNEL_NUM 101
#define MAMMON_RESULT_BAD_SAMPLE_RATE 102
#define MAMMON_RESULT_BAD_MODEL 201
