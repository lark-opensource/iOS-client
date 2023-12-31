/**
 * @file AMGPlatform.h
 * @author benny.liu (benny.liu@bytedance.com)
 * @brief Platform macro definition for amazing engine.
 * @version 0.1
 * @date 2019-12-05
 * 
 * @copyright Copyright (c) 2019
 * 
 */

#ifndef AMGPlatformDef_h
#define AMGPlatformDef_h

#pragma once

#define AMAZING_WINDOWS (1 << 0)
#define AMAZING_ANDROID (1 << 1)
#define AMAZING_IOS (1 << 2)
#define AMAZING_MACOS (1 << 3)
#define AMAZING_LINUX (1 << 4)
#define AMAZING_WEB (1 << 5)
#define AMAZING_UNKOWN (1 << 31)

#define AMAZING_PLATFORM_32BIT (1 << 0)
#define AMAZING_PLATFORM_64BIT (1 << 1)

#define AMAZING_PLATFORM_DEBUG (1 << 0)
#define AMAZING_PLATFORM_RELEASE (1 << 1)

#ifdef WIN32
#ifdef _DEBUG
#define AMAZING_PLATFORM_CONFIG AMAZING_PLATFORM_DEBUG
#define AMAZING_DEBUG 1
#else
#define AMAZING_PLATFORM_CONFIG AMAZING_PLATFORM_RELEASE
#endif
#else
#if defined(DEBUG) && DEBUG
#define AMAZING_PLATFORM_CONFIG AMAZING_PLATFORM_DEBUG
#define AMAZING_DEBUG 1
#else
#define AMAZING_PLATFORM_CONFIG AMAZING_PLATFORM_RELEASE
#endif
#endif

#if defined(__ANDROID_API__) || defined(TARGET_OS_ANDROID)
#define AMAZING_PLATFORM AMAZING_ANDROID
#elif __APPLE__
#include "TargetConditionals.h"

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#define AMAZING_PLATFORM AMAZING_IOS

#elif TARGET_OS_OSX
#define AMAZING_PLATFORM AMAZING_MACOS
#endif

#elif defined(__linux__)
#define AMAZING_PLATFORM AMAZING_LINUX

#elif TARGET_OS_WASM
#define AMAZING_PLATFORM AMAZING_WEB

// Windows
#elif defined(_MSC_VER) || defined(_WIN32) || defined(__WIN64) || defined(_WINDOWS)
#define AMAZING_PLATFORM AMAZING_WINDOWS
#endif

#if AMAZING_PLATFORM == AMAZING_WINDOWS || AMAZING_PLATFORM == AMAZING_MACOS || AMAZING_PLATFORM == AMAZING_LINUX || AMAZING_PLATFORM == AMAZING_WEB
#define AMAZING_SUPPORTS_FPU 0
#define AMAZING_SUPPORTS_SSE 0
#define AMAZING_SUPPORTS_VFP 0
#define AMAZING_SUPPORTS_NEON 0
//#   include "Foundation/Math/Simd/sse.h"
#elif AMAZING_PLATFORM == AMAZING_ANDROID || AMAZING_PLATFORM == AMAZING_IOS
#define AMAZING_SUPPORTS_FPU 0
#define AMAZING_SUPPORTS_SSE 0
#define AMAZING_SUPPORTS_VFP 0
#define AMAZING_SUPPORTS_NEON 0
//#   include "Foundation/Math/Simd/neon.h"
#else
#define AMAZING_SUPPORTS_FPU 1
#define AMAZING_SUPPORTS_SSE 0
#define AMAZING_SUPPORTS_VFP 0
#define AMAZING_SUPPORTS_NEON 0
//#   include "Foundation/Math/Simd/fpu.h"
#endif

////#define DEBUG_SIMD_ASSERT_IF 1
//#if DEBUG_SIMD_ASSERT_IF
//#define SIMD_ASSERT_IF(x) AssertIf(x)
//#else
#define SIMD_ASSERT_IF(x)
//#endif

#endif /* AMGPlatformDef_h */
