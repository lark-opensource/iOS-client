
//
// Created by William.Hua on 2020/10/14.
//

#ifndef MAMMON_AUDIO_IO_INCLUDE_MAMMON_AUDIO_IO_DEFS_H
#define MAMMON_AUDIO_IO_INCLUDE_MAMMON_AUDIO_IO_DEFS_H

#ifndef MAMMON_EXPORT
#if defined(__clang__) || defined(__GNUC__)
#define MAMMON_EXPORT __attribute__ ((visibility("default")))
#elif defined(_MSC_VER)
#define MAMMON_EXPORT __declspec(dllexport)
#else
#define MAMMON_EXPORT
#endif
#endif

#endif //MAMMON_AUDIO_IO_INCLUDE_MAMMON_AUDIO_IO_DEFS_H
