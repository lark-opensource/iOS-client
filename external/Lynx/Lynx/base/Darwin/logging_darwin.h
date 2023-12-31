// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_BASE_DARWIN_LOGGING_DARWIN_H_
#define LYNX_BASE_DARWIN_LOGGING_DARWIN_H_

#include "base/log/logging.h"

namespace lynx {
namespace base {
namespace logging {

constexpr const char* kLynxLogLevels[] = {"V", "D", "I", "W", "E", "F"};

void SetLynxLogMinLevel(int min_level);

void InternalLogNative(int level, const char* message);

void PrintLogMessageByLogDelegate(LogMessage* msg);

}  // namespace logging
}  // namespace base
}  // namespace lynx

#endif  // LYNX_BASE_DARWIN_LOGGING_DARWIN_H_
