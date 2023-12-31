// Copyright 2019 The Lynx Authors. All rights reserved.

#include "script_manager.h"

#include "base/json/json_util.h"

namespace lynx {
namespace devtool {
static int javascript_id_ = 0;

void ScriptManager::SetBreakpointDetail(const rapidjson::Value& content) {
  std::lock_guard<std::mutex> lock(mutex_);
  int message_id = content["id"].GetInt();
  Breakpoint bp;
  bp.line_number_ = content["params"]["lineNumber"].GetInt();
  bp.column_number_ = content["params"]["columnNumber"].GetInt();
  if (content["params"].HasMember("url")) {
    bp.url_ = content["params"]["url"].GetString();
  } else if (content["params"].HasMember("urlRegex")) {
    bp.url_ = content["params"]["urlRegex"].GetString();
  }
  if (content["params"].HasMember("condition")) {
    bp.condition_ = content["params"]["condition"].GetString();
  }
  set_breakpoint_map_[message_id] = bp;
}

void ScriptManager::SetBreakpointId(const rapidjson::Value& content) {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = set_breakpoint_map_.find(content["id"].GetInt());
  if (it != set_breakpoint_map_.end()) {
    if (!content.HasMember("error")) {
      Breakpoint bp = it->second;
      bp.breakpoint_id_ = content["result"]["breakpointId"].GetString();
      AddBreakpoint(bp);
    }
    set_breakpoint_map_.erase(it);
  }
}

void ScriptManager::AddBreakpoint(Breakpoint breakpoint) {
  if (breakpoint_.find(breakpoint.breakpoint_id_) != breakpoint_.end()) {
    return;
  }
  breakpoint_.insert(std::make_pair(breakpoint.breakpoint_id_, breakpoint));
}

void ScriptManager::RemoveBreakpoint(std::string breakpoint_id) {
  breakpoint_.erase(breakpoint_id);
}

void ScriptManager::RemoveAllBreakpoints() { breakpoint_.clear(); }

void ScriptManager::SetBreakpointsActive(bool active) {
  breakpoints_active_ = active;
}

bool ScriptManager::GetBreakpointsActive() { return breakpoints_active_; }

std::map<std::string, Breakpoint> ScriptManager::GetBreakpoint() {
  return breakpoint_;
}

void ScriptManager::AddScriptId(std::string real_script_id) {
  script_id_map_[real_script_id] = ++javascript_id_;
}

void ScriptManager::ClearScriptId() { script_id_map_.clear(); }

rapidjson::Document ScriptManager::MapScriptId(const rapidjson::Value& message,
                                               bool true_id, bool fake_id) {
  rapidjson::Document content;
  std::string str = base::ToJson(message);
  std::string result = "";
  size_t pos = str.find("\"scriptId\"");
  while (pos != std::string::npos) {
    std::string substr1 = str.substr(0, pos);
    size_t sub_pos = str.find(':', pos);
    sub_pos = str.find('\"', sub_pos);
    sub_pos = str.find('\"', sub_pos + 1) + 1;
    std::string substr2 = str.substr(sub_pos);

    std::string tmp_str = str.substr(pos, sub_pos - pos);
    tmp_str = "{" + tmp_str + "}";

    rapidjson::Document tmp_json = base::strToJson(tmp_str.c_str());
    std::string before_id = tmp_json["scriptId"].GetString();
    std::string after_id = before_id;
    if (true_id) {
      after_id = MapTrueToFakeScriptId(before_id);
    } else if (fake_id) {
      after_id = MapFakeToTrueScriptId(before_id);
    }
    result += substr1 + "\"scriptId\":\"" + after_id + "\"";
    pos = substr2.find("\"scriptId\"");
    str = substr2;
  }
  result += str;
  content = base::strToJson(result.c_str());
  return content;
}

std::string ScriptManager::MapFakeToTrueScriptId(std::string fake_id) {
  std::string true_id = fake_id;
  for (auto id : script_id_map_) {
    if (id.second == std::atoi(fake_id.c_str())) true_id = id.first;
  }
  return true_id;
}
std::string ScriptManager::MapTrueToFakeScriptId(std::string true_id) {
  std::string fake_id = true_id;
  auto fake = script_id_map_.find(true_id);
  if (fake != script_id_map_.end()) fake_id = std::to_string(fake->second);
  return fake_id;
}

}  // namespace devtool
}  // namespace lynx
