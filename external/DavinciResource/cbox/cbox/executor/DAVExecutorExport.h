//
// Created by bytedance on 2021/6/28.
//
#ifndef DAV_EXECUTOR_DEFINE_H
#define DAV_EXECUTOR_DEFINE_H

#ifdef _MSC_VER
#define DAV_EXECUTOR_EXPORT __declspec(dllexport)
#else
#define DAV_EXECUTOR_EXPORT __attribute__((visibility("default")))
#endif

#endif //DAV_EXECUTOR_DEFINE_H
