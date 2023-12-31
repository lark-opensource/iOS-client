//
// Created by bytedance on 2020/5/15.
//

#ifndef NLE_EXPORT_H
#define NLE_EXPORT_H

#ifdef NLE_STATIC_LIBRARY
#define NLE_EXPORT_CLASS
#define NLE_EXPORT_METHOD

#elif defined(_WINDOWS)
#ifdef NLE_BUILD_SHARED
#ifdef NLE_LIBRARY
#define NLE_EXPORT_CLASS __declspec(dllexport)
#define NLE_EXPORT_METHOD __declspec(dllexport)
#else
#define NLE_EXPORT_CLASS __declspec(dllimport)
#define NLE_EXPORT_METHOD __declspec(dllimport)
#endif
#else
#define NLE_EXPORT_CLASS
#define NLE_EXPORT_METHOD
#endif

#else

#ifdef NLE_LIBRARY
#define NLE_EXPORT_CLASS __attribute__((visibility("default")))
#define NLE_EXPORT_METHOD __attribute__((visibility("default")))
#else
#define NLE_EXPORT_CLASS
#define NLE_EXPORT_METHOD
#endif

#endif

#endif // NLE_EXPORT_H
