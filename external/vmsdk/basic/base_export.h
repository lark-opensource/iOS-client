#ifndef VMSDK_EXPORT_HEADER
#define VMSDK_EXPORT_HEADER
#if defined(WIN32)

#define VMSDK_EXPORT __declspec(dllimport)
#define VMSDK_HIDE

#else  // defined(WIN32)

#define VMSDK_EXPORT __attribute__((visibility("default")))
#define VMSDK_HIDE __attribute__((visibility("hidden")))

#endif

#endif  // VMSDK_EXPORT_HEADER
