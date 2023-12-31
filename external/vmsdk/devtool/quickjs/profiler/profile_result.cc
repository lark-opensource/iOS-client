// Copyright 2019 The Lynx Authors. All rights reserved

#include "devtool/quickjs/profiler/profile_result.h"

namespace VMSDK {
namespace CpuProfiler {

std::string CallFrame::Serialize() const {
  std::string res = "{";
  res += R"("functionName":")" + function_name_ + R"(",)";
  res += R"("scriptId":")" + script_id_ + R"(",)";
  res += R"("url":")" + url_ + R"(",)";
  res += R"("lineNumber":)" + std::to_string(line_number_) + ",";
  res += R"("columnNumber":)" + std::to_string(column_number_) + "}";
  return res;
}

CallFrame::CallFrame(const std::string& function_name,
                     const std::string& script_id, const std::string& url,
                     int32_t line_num, int64_t column_num)
    : function_name_(std::move(function_name)),
      script_id_(std::move(script_id)),
      url_(std::move(url)),
      line_number_(line_num),
      column_number_(column_num) {}

std::string PositionTickInfo::Serialize() const {
  std::string result = "{";
  result += "\"line\":" + std::to_string(line_) + "," +
            "\"ticks\":" + std::to_string(ticks_) + "}";
  return result;
}

Node::Node()
    : id_(0),
      call_frame_(nullptr),
      hit_count_(0),
      parent_id_(0),
      children_ids_({}),
      deopt_reason_(""),
      position_ticks_({}) {}
Node::Node(int32_t id, std::shared_ptr<CallFrame>& callframe, int64_t hit_count,
           int32_t parent_id, std::vector<int32_t> children_ids,
           const std::string& deopt_reason,
           std::vector<std::shared_ptr<PositionTickInfo>>& position_ticks)
    : id_(id),
      call_frame_(callframe),
      hit_count_(hit_count),
      parent_id_(parent_id),
      children_ids_(std::move(children_ids)),
      deopt_reason_(std::move(deopt_reason)),
      position_ticks_(position_ticks) {}
std::string Node::Serialize() const {
  std::string res = "{";
  res += R"("id":)" + std::to_string(id_) + ",";
  res += R"("callFrame":)" + call_frame_->Serialize() + ",";
  res += R"("hitCount":)" + std::to_string(hit_count_) + ",";
  res += R"("parent":)" + std::to_string(parent_id_) + ",";
  if (!deopt_reason_.empty()) {
    res += R"("deoptReason":")" + deopt_reason_ + R"(",)";
  }
  //  res += "\"children\": [";
  //  size_t children_size = children_ids_.size();
  //  for (auto i = 0; i < children_size; i++) {
  //    res += std::to_string(children_ids_[i]);
  //    if (i != children_size - 1) {
  //      res += ",";
  //    }
  //  }
  //  res += "],";
  res += R"("positionTicks":[)";
  size_t position_tick_size = position_ticks_.size();
  for (auto i = 0; i < position_tick_size; ++i) {
    res += position_ticks_[i]->Serialize();
    if (i != position_tick_size - 1) {
      res += ",";
    }
  }
  res += "]}";
  return res;
}

ProfileResult::ProfileResult()
    : start_time_(0),
      end_time_(0),
      samples_string_(""),
      time_deltas_string_(""),
      nodes_string_("") {
  nodes_ = std::vector<std::shared_ptr<Node>>();
}

std::string ProfileResult::Serialize() {
  std::string res = "{\"profile\":{";
  res += R"("nodes": [)";
  size_t node_size = nodes_.size();
  for (size_t i = 0; i < node_size; i++) {
    res += nodes_[i]->Serialize();
    if (i != node_size - 1) {
      res += ",";
    }
  }
  res += "],";
  res += R"("startTime":)" + std::to_string(start_time_) + ",";
  res += R"("endTime":)" + std::to_string(end_time_) + ",";
  res += R"("samples":[)";
  res += samples_string_.substr(
      0, samples_string_.length() - 1);  // remove the last ,
  res += "],";
  res += R"("timeDeltas":[)";
  res += time_deltas_string_.substr(
      0, time_deltas_string_.length() - 1);  // remove the last ,
  res += "]";
  res += "}}";
  return res;
}

void ProfileResult::PushNodes(std::shared_ptr<Node>& node) {
  nodes_.emplace_back(std::move(node));
}

void ProfileResult::set_start_time(uint64_t time) { start_time_ = time; }

void ProfileResult::set_end_time(uint64_t time) { end_time_ = time; }

void ProfileResult::PushSamples(const std::vector<int32_t>& samples) {
  for (const auto& sample : samples) {
    samples_string_ += (std::to_string(sample) + ",");
  }
}

void ProfileResult::PushTimeDeltas(uint32_t time_delta) {
  time_deltas_string_ += (std::to_string(time_delta) + ",");
}

}  // namespace CpuProfiler
}  // namespace VMSDK