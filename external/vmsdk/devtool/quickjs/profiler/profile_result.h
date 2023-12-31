// Copyright 2019 The Lynx Authors. All rights reserved

#ifndef VMSDK_DEVTOOL_PROFILE_RESULT_H
#define VMSDK_DEVTOOL_PROFILE_RESULT_H

#include <string>
#include <vector>

namespace VMSDK {
namespace CpuProfiler {

class CallFrame {
 public:
  CallFrame(const std::string&, const std::string&, const std::string&, int32_t,
            int64_t);
  std::string Serialize() const;

 private:
  std::string function_name_;
  std::string script_id_;
  std::string url_;
  int32_t line_number_;
  int64_t column_number_;
};

class PositionTickInfo {
 public:
  PositionTickInfo(int32_t line, int32_t tick) : line_(line), ticks_(tick) {}
  std::string Serialize() const;

 private:
  int32_t line_;
  int32_t ticks_;
};

class Node {
 public:
  Node();
  Node(int32_t, std::shared_ptr<CallFrame>&, int64_t, int32_t,
       std::vector<int32_t>, const std::string&,
       std::vector<std::shared_ptr<PositionTickInfo>>&);
  std::string Serialize() const;

 private:
  int32_t id_;
  std::shared_ptr<CallFrame> call_frame_;
  int32_t hit_count_;
  int32_t parent_id_;
  std::vector<int32_t> children_ids_;
  std::string deopt_reason_;
  std::vector<std::shared_ptr<PositionTickInfo>> position_ticks_;
};

class ProfileResult {
 public:
  ProfileResult();
  std::string Serialize();
  void PushNodes(std::shared_ptr<Node>&);
  void set_start_time(uint64_t);
  void set_end_time(uint64_t);
  void PushSamples(const std::vector<int32_t>&);
  void PushTimeDeltas(uint32_t);

 private:
  std::vector<std::shared_ptr<Node>> nodes_;
  uint64_t start_time_;
  uint64_t end_time_;
  std::string samples_string_;
  std::string time_deltas_string_;
  std::string nodes_string_;
};

}  // namespace CpuProfiler
}  // namespace VMSDK
#endif