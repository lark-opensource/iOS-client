//
// Created by LIJING on 2021/1/22.
//

#ifndef SAMI_AUDIO_BACKEND_AUDIO_BACKEND_DEFS_H
#define SAMI_AUDIO_BACKEND_AUDIO_BACKEND_DEFS_H

#ifndef MAMMON_EXPORT
#if defined(__clang__) || defined(__GNUC__)
#define MAMMON_EXPORT __attribute__ ((visibility("default")))
#elif defined(_MSC_VER)
#define MAMMON_EXPORT __declspec(dllexport)
#else
#define MAMMON_EXPORT
#endif
#endif

#endif //SAMI_AUDIO_BACKEND_AUDIO_BACKEND_DEFS_H
