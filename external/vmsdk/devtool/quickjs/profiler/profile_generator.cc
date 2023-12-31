// Copyright 2019 The Lynx Authors. All rights reserved

#include "devtool/quickjs/profiler/profile_generator.h"

#include <assert.h>

#include "devtool/quickjs/debugger/debugger.h"
#include "devtool/quickjs/interface.h"
#include "devtool/quickjs/profiler/cpu_profiler.h"
#include "devtool/quickjs/profiler/profile_result.h"
#include "devtool/quickjs/profiler/profile_tree.h"
#include "devtool/quickjs/profiler/tracing_cpu_profiler.h"

namespace VMSDK {
namespace CpuProfiler {

// Thomas Wang, Integer Hash Functions.
// http://www.concentric.net/~Ttwang/tech/inthash.htm`
uint64_t ComputedHashUint64(uint64_t u) {
  uint64_t v = u * 3935559000370003845 + 2691343689449507681;
  v ^= v >> 21;
  v ^= v << 37;
  v ^= v >> 4;
  v *= 4768777513237032717;
  v ^= v << 20;
  v ^= v >> 41;
  v ^= v << 5;
  return v;
}

uint64_t HashString(const char* s) {
  uint64_t h = 37;
  while (*s) {
    h = (h * 54059) ^ (s[0] * 76963);
    s++;
  }
  return h;
}

static void GetSrcLine(LEPUSContext* ctx, struct LEPUSFunctionBytecode* b,
                       const uint8_t* pc, int32_t& src_line_num) {
  int64_t line_col_num =
      find_line_num(ctx, b, (uint32_t)(pc - GetFunctionBytecodeBuf(b) - 1));
  int64_t column_num = 0;
  ComputeLineCol(line_col_num, &src_line_num, &column_num);
}

CpuProfile::CpuProfile(CpuProfiler* profiler, std::string title)
    : title_(std::move(title)),
      start_time_(std::chrono::time_point_cast<std::chrono::microseconds>(
                      std::chrono::system_clock::now())
                      .time_since_epoch()
                      .count()),
      end_time_(0),
      profiler_(profiler),
      streaming_next_sample_(0),
      last_timestamp_(0) {
  // use new context for profiler thread
  ctx_ = profiler_->context();
  profile_result_ = std::make_shared<ProfileResult>();
  top_down_ = std::make_shared<ProfileTree>(profiler->context());
}

CpuProfile::~CpuProfile() = default;

std::shared_ptr<CodeEntry> GetCodeEntry(
    const std::shared_ptr<TickSampleEventRecord>& sample, int32_t index,
    int32_t& src_line_num) {
  LEPUSContext* profiler_ctx = sample->profiler_ctx_;
  auto& each_sample = sample->stack_meta_info_[index];
  LEPUSValue frame_func = each_sample.frame_func_;
  if (LEPUS_IsUndefined(frame_func)) {
    return nullptr;
  }
  LEPUSFunctionBytecode* b = LEPUS_GetFunctionBytecode(frame_func);
  if (b) {
    const char* func_name_str = get_func_name(profiler_ctx, frame_func);
    std::string func_name(func_name_str);
    LEPUS_FreeCString(profiler_ctx, func_name_str);

    const uint8_t* pc = each_sample.pc_;
    int32_t script_id = -1;
    std::string url = "lepus.js";
    int32_t line_number = GetFunctionDebugLineNum(profiler_ctx, b);
    int64_t column_number = GetFunctionDebugColumnNum(profiler_ctx, b);

    if (FunctionBytecodeHasDebug(b)) {
      if (index == 0) {
        GetSrcLine(profiler_ctx, b, pc, src_line_num);
      }
      LEPUSScriptSource* script = each_sample.script_;
      script_id = script ? script->id : -1;
      if (GetBytecodeScript(b)) {
        const char* script_url = script ? script->url : nullptr;
        if (script_url) {
          url = std::string(script_url);
        }
      }
    }
    std::shared_ptr<CodeEntry> code_entry = std::make_shared<CodeEntry>(
        func_name, url, line_number, column_number, script_id);
    return code_entry;
  } else {
    return nullptr;
  }
}

void CpuProfile::AddPath(const std::shared_ptr<TickSampleEventRecord>& sample) {
  ProfileNode* node = top_down_->root();
  int32_t parent_line_number = 0;
  // tranverse the stack, start from the top frame
  int32_t frame_count = sample->frames_count_;
  int32_t src_line_num = 0;
  for (int32_t i = frame_count - 1; i >= 0; i--) {
    auto code_entry = GetCodeEntry(sample, i, src_line_num);
    if (!code_entry) continue;
    node = node->FindOrAddChild(code_entry, parent_line_number);
  }

  node->IncrementSelfTicks();
  if (src_line_num > 0) {
    node->IncrementLineTicks(src_line_num);
  }

  assert(sample->timestamp_ >= 0);
  timestamps_.emplace_back(sample->timestamp_);
  samples_.emplace_back(node->node_id());

  // add datachunk
  const int kSamplesFlushCount = 100;
  if (samples_.size() - streaming_next_sample_ >= kSamplesFlushCount) {
    StreamPendingTraceEvents();
  }
}

void CpuProfile::GenerateNodeValue(const ProfileNode* node) {
  auto entry = node->entry();
  auto call_frame = std::make_shared<CallFrame>(
      entry->name(), entry->script_id(), entry->resource_name(),
      entry->line_number(), entry->column_number());

  // positionTicks
  std::vector<std::shared_ptr<PositionTickInfo>> position_tick_infos{};
  auto line_ticks_map = node->line_ticks();
  if (!line_ticks_map.empty()) {
    for (const auto& element : line_ticks_map) {
      auto info =
          std::make_shared<PositionTickInfo>(element.first + 1, element.second);
      position_tick_infos.emplace_back(std::move(info));
    }
  }

  int32_t parent_id = -1;
  if (node->parent()) {
    parent_id = node->parent()->node_id();
  }
  std::vector<int32_t> children_ids_{};
  for (const auto& children : *node->children_list()) {
    children_ids_.emplace_back(children->node_id());
  }

  auto profile_node = std::make_shared<Node>(
      node->node_id(), call_frame, node->self_ticks(), parent_id,
      std::move(children_ids_), "", position_tick_infos);
  profile_result_->PushNodes(profile_node);
}

std::string CpuProfile::GetCpuProfileContent() {
  return profile_result_->Serialize();
}

void CpuProfile::FinishStreamPendingTraceEvents() {
  StreamPendingTraceEvents();
  auto pending_nodes = top_down_->TakePendingNodes();
  if (!pending_nodes.empty()) {
    for (const auto& node : pending_nodes) {
      GenerateNodeValue(node);
    }
  }
  std::vector<const ProfileNode*> node_swap{};
  pending_nodes.swap(node_swap);
}

void CpuProfile::StreamPendingTraceEvents() {
  if (start_time_ != 0) {
    profile_result_->set_start_time(start_time_);
  }

  assert(samples_.size() == timestamps_.size());
  assert(streaming_next_sample_ == 0);
  profile_result_->PushSamples(samples_);
  last_timestamp_ = !last_timestamp_ ? start_time() : last_timestamp_;
  for (const auto& timestamp : timestamps_) {
    profile_result_->PushTimeDeltas(
        static_cast<uint64_t>((timestamp - last_timestamp_)));
    last_timestamp_ = timestamp;
  }
  std::vector<uint64_t> timestamp_swap{};
  timestamps_.swap(timestamp_swap);
  std::vector<int32_t> sample_swap{};
  samples_.swap(sample_swap);
  streaming_next_sample_ = 0;
};

void CpuProfile::FinishProfile() {
  // microseconds
  end_time_ = std::chrono::time_point_cast<std::chrono::microseconds>(
                  std::chrono::system_clock::now())
                  .time_since_epoch()
                  .count();
  FinishStreamPendingTraceEvents();
  profile_result_->set_end_time(end_time_);
}

std::string CpuProfile::title() const { return title_; }
uint64_t CpuProfile::start_time() const { return start_time_; }

// ProfileGenerator
ProfileGenerator::ProfileGenerator(std::shared_ptr<CpuProfile>& profile)
    : profile_(profile) {}

void ProfileGenerator::RecordTickSample(
    const std::shared_ptr<TickSampleEventRecord>& sample) {
  if (sample->profiler_ctx_) {
    // traverse the frame, start from the top frame
    profile_->AddPath(sample);
  } else {
    printf("QJS CPU PROFILER: PROFILER CTX IS NULL, PLEASE CHECK\n");
  }
}

// CodeEntry
CodeEntry::CodeEntry(const std::string& name, std::string resource_name,
                     int32_t line_number, int64_t column_number,
                     int32_t script_id)
    : name_(std::move(name)),
      resource_name_(std::move(resource_name)),
      line_number_(line_number),
      column_number_(column_number),
      script_id_(std::to_string(script_id)){};

bool CodeEntry::IsSameFunctionAs(
    const std::shared_ptr<CodeEntry>& other) const {
  // no need to compare column number
  return script_id_ == other->script_id_ && name_ == other->name_ &&
         resource_name_ == other->resource_name_ &&
         line_number_ == other->line_number_ &&
         column_number_ == other->column_number_;
}

uint32_t CodeEntry::GetHash() const {
  uint32_t hash = 0;
  hash ^= ComputedHashUint64(HashString(name_.c_str()));
  hash ^= ComputedHashUint64(HashString(resource_name_.c_str()));
  hash ^= ComputedHashUint64(static_cast<uint64_t>(line_number_));
  hash ^= ComputedHashUint64(static_cast<uint64_t>(column_number_));
  if (script_id_ != "-1") {
    hash ^= ComputedHashUint64(HashString(script_id_.c_str()));
  }
  return hash;
}

std::string CodeEntry::name() const { return name_; }
std::string CodeEntry::resource_name() const { return resource_name_; }
int32_t CodeEntry::line_number() const { return line_number_; }
int64_t CodeEntry::column_number() const { return column_number_; }
std::string CodeEntry::script_id() const { return script_id_; }
}  // namespace CpuProfiler
}  // namespace VMSDK
