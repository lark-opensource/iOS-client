/**
 * @file AMGExport.h
 * @author fanjiaqi (fanjiaqi.837@bytedance.com)
 * @brief Define export and import macros
 * @version 0.1
 * @date 2019-11-25
 *
 * @copyright Copyright (c) 2019
 *
 */

#ifndef _GAIA_LIB_EXPORT_
#define _GAIA_LIB_EXPORT_
// define USE_DEPRECATED_API is used to include in API which is being fazed out
// if you can compile your apps with this turned off you are
// well placed for compatibility with future versions.
#define USE_DEPRECATED_API

// disable VisualStudio warnings
#if defined(_MSC_VER) && defined(AE_DISABLE_MSVC_WARNINGS)
#pragma warning(disable : 4244)
#pragma warning(disable : 4251)
#pragma warning(disable : 4275)
#pragma warning(disable : 4512)
#pragma warning(disable : 4267)
#pragma warning(disable : 4702)
#pragma warning(disable : 4511)
#pragma warning(disable : 4005)
#endif

#if defined(_MSC_VER) || defined(__CYGWIN__) || defined(__MINGW32__) || defined(__BCPLUSPLUS__) || defined(__MWERKS__)
#if defined(AMG_LIBRARY_STATIC) && !defined(AMG_LIBRARY_SHARED)
#define AMAZING_EXPORT
#elif defined(AMG_LIBRARY_SHARED)
#define AMAZING_EXPORT __declspec(dllexport)
#else
#define AMAZING_EXPORT __declspec(dllimport)
#endif
#else
#if defined(AMG_LIBRARY_STATIC)
#define AMAZING_EXPORT
#elif defined(AMG_LIBRARY_SHARED)
#define AMAZING_EXPORT __attribute__((visibility("default")))
#else
#define AMAZING_EXPORT
#endif
#endif

// only export in editor
#ifdef AMAZING_EDITOR_SDK
#define AMAZING_EDITOR_SDK_EXPORT AMAZING_EXPORT
#else
#define AMAZING_EDITOR_SDK_EXPORT
#endif

#if defined(_MSC_VER) || defined(__CYGWIN__) || defined(__MINGW32__) || defined(__BCPLUSPLUS__) || defined(__MWERKS__)
#if defined(GAIA_LIBRARY_STATIC) && !defined(GAIA_LIBRARY_SHARED)
#define GAIA_LIB_EXPORT
#elif defined(GAIA_LIBRARY_SHARED)
#define GAIA_LIB_EXPORT __declspec(dllexport)
#else
#define GAIA_LIB_EXPORT __declspec(dllimport)
#endif
#else
#if defined(GAIA_LIBRARY_STATIC)
#define GAIA_LIB_EXPORT
#elif defined(GAIA_LIBRARY_SHARED)
#define GAIA_LIB_EXPORT __attribute__((visibility("default")))
#else
#define GAIA_LIB_EXPORT
#endif
#endif

#ifdef _EFFECT_SDK_EXPORTS_
#if defined(_MSC_VER) || defined(__CYGWIN__) || defined(__MINGW32__) || defined(__BCPLUSPLUS__) || defined(__MWERKS__)
#define AMAZING_SDK_EXPORT __declspec(dllexport)
#else
#define AMAZING_SDK_EXPORT __attribute__((visibility("default")))
#endif
#else
#define AMAZING_SDK_EXPORT
#endif

// set up define for whether member templates are supported by VisualStudio compilers.
#ifdef _MSC_VER
#if (_MSC_VER >= 1300)
#define __STL_MEMBER_TEMPLATES
#endif
#endif

#endif
