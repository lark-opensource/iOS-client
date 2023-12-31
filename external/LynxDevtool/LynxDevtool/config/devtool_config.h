// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNXDEVTOOL_CONFIG_DEVTOOL_CONFIG_H_
#define LYNXDEVTOOL_CONFIG_DEVTOOL_CONFIG_H_

#include <atomic>

namespace lynxdev {
namespace devtool {

class DevToolConfig {
 public:
  static void SetStopAtEntry(bool stop_at_entry);
  static bool ShouldStopAtEntry();

 private:
  static std::atomic<bool> should_stop_at_entry_;
  static std::atomic<bool> should_stop_lepus_at_entry_;
};

}  // namespace devtool
}  // namespace lynxdev

#endif  // LYNXDEVTOOL_CONFIG_DEVTOOL_CONFIG_H_
