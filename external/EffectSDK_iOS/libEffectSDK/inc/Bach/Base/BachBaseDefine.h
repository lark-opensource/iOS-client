#ifdef __cplusplus
#ifndef _BACH_BASE_DEFINE_H_
#define _BACH_BASE_DEFINE_H_

#if defined(_MSC_VER) || defined(__CYGWIN__) || defined(__MINGW32__) || defined(__BCPLUSPLUS__) || defined(__MWERKS__)
#if defined(BACH_EXPORT_SYMBOL)
#define BACH_EXPORT __declspec(dllexport)
#define BACH_VAR_EXPORT __declspec(dllexport)
#else
#define BACH_EXPORT
#define BACH_VAR_EXPORT __declspec(dllimport)
#endif
#else
#if defined(BACH_EXPORT_SYMBOL)
#define BACH_EXPORT __attribute__((visibility("default")))
#else
#define BACH_EXPORT
#endif
#define BACH_VAR_EXPORT BACH_EXPORT
#endif

#ifdef AMAZING_EDITOR_SDK
#define BACH_EXPORT_TOOL BACH_EXPORT
#else
#define BACH_EXPORT_TOOL
#endif

#define NAMESPACE_BACH_BEGIN \
    namespace Bach           \
    {
#define NAMESPACE_BACH_END \
    }
#define NAMESPACE_BACH_USING using namespace Bach;

#endif //_BACH_BASE_DEFINE_H_

#endif