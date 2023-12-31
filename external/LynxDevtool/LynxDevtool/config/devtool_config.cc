// Copyright 2020 The Lynx Authors. All rights reserved.

#include "config/devtool_config.h"

namespace lynxdev {
namespace devtool {

std::atomic<bool> DevToolConfig::should_stop_at_entry_ = {false};
std::atomic<bool> DevToolConfig::should_stop_lepus_at_entry_ = {false};

void DevToolConfig::SetStopAtEntry(bool stop_at_entry) {
  should_stop_at_entry_ = stop_at_entry;
}

bool DevToolConfig::ShouldStopAtEntry() { return should_stop_at_entry_; }

}  // namespace devtool
}  // namespace lynxdev
