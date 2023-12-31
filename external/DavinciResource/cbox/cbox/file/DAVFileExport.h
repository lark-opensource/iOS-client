//
// Created by bytedance on 2021/6/28.
//
#ifndef DAV_FILE_DEFINE_H
#define DAV_FILE_DEFINE_H

#ifdef _MSC_VER
#define DAV_FILE_EXPORT __declspec(dllexport)
#else
#define DAV_FILE_EXPORT __attribute__((visibility("default")))
#endif

#endif //DAV_FILE_DEFINE_H
