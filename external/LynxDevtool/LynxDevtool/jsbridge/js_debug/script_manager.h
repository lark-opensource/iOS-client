// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_INSPECTOR_SCRIPT_MANAGER_H
#define LYNX_INSPECTOR_SCRIPT_MANAGER_H

#include <map>
#include <mutex>
#include <string>

#include "third_party/rapidjson/document.h"

namespace lynx {
namespace devtool {

struct Breakpoint {
  std::string breakpoint_id_;
  int line_number_;
  int column_number_;
  std::string url_;
  std::string condition_;

  bool operator<(Breakpoint const& other) const {
    return breakpoint_id_ < other.breakpoint_id_;
  }
};

class ScriptManager {
 public:
  ScriptManager() = default;
  ~ScriptManager() {
    breakpoint_.clear();
    set_breakpoint_map_.clear();
  }

  void SetBreakpointDetail(const rapidjson::Value& content);
  void SetBreakpointId(const rapidjson::Value& content);

  void AddBreakpoint(Breakpoint breakpoint);
  void RemoveBreakpoint(std::string breakpoint_id);
  void RemoveAllBreakpoints();
  void SetBreakpointsActive(bool active);
  bool GetBreakpointsActive();
  std::map<std::string, Breakpoint> GetBreakpoint();

  void AddScriptId(std::string real_script_id);
  void ClearScriptId();
  rapidjson::Document MapScriptId(const rapidjson::Value& message, bool true_id,
                                  bool fake_id);

 private:
  std::string MapFakeToTrueScriptId(std::string fake_id);
  std::string MapTrueToFakeScriptId(std::string true_id);

  std::mutex mutex_;
  bool breakpoints_active_ = true;

  std::map<int, Breakpoint> set_breakpoint_map_;
  std::map<std::string, Breakpoint> breakpoint_;
  std::map<std::string, int> script_id_map_;
};
}  // namespace devtool
}  // namespace lynx

#endif  // LYNX_INSPECTOR_SCRIPT_MANAGER_H
