// Copyright 2019 The Lynx Authors. All rights reserved

#ifndef VMSDK_DEVTOOL_PROFILER_GENERATOR_H
#define VMSDK_DEVTOOL_PROFILER_GENERATOR_H

#include <condition_variable>
#include <vector>

#ifdef __cplusplus
extern "C" {
#endif
#include "quickjs/include/quickjs.h"
#ifdef __cplusplus
}
#endif

namespace VMSDK {
namespace CpuProfiler {

class TickSampleEventRecord;
class CpuProfiler;
class ProfileNode;
class ProfileTree;
class ProfileResult;
class ProfilerSampling;

uint64_t HashString(const char*);
uint64_t ComputedHashUint64(uint64_t);

class CodeEntry {
 public:
  CodeEntry(const std::string&, std::string resource_name = "",
            int32_t line_number = -1, int64_t column_number = -1,
            int32_t script_id = 0);
  std::string name() const;
  std::string resource_name() const;
  int32_t line_number() const;
  int64_t column_number() const;
  std::string script_id() const;
  uint32_t GetHash() const;
  bool IsSameFunctionAs(const std::shared_ptr<CodeEntry>&) const;

 private:
  std::string name_;
  std::string resource_name_;
  int32_t line_number_;    // function line number
  int64_t column_number_;  // function column number
  std::string script_id_;
};

struct CodeEntryAndLineNumber {
  std::shared_ptr<CodeEntry> code_entry;
  int32_t line_number;
};

class CpuProfile {
 public:
  CpuProfile(CpuProfiler*, std::string);
  ~CpuProfile();
  void AddPath(const std::shared_ptr<TickSampleEventRecord>&);
  void FinishProfile();
  std::string title() const;
  uint64_t start_time() const;
  std::string GetCpuProfileContent();

 private:
  void StreamPendingTraceEvents();
  void FinishStreamPendingTraceEvents();
  void GenerateNodeValue(const ProfileNode*);
  std::string title_;
  uint64_t start_time_;
  uint64_t end_time_;
  std::vector<int32_t> samples_;
  std::vector<uint64_t> timestamps_;
  CpuProfiler* profiler_;
  size_t streaming_next_sample_;
  std::shared_ptr<ProfileResult> profile_result_;
  std::shared_ptr<ProfileTree> top_down_;
  LEPUSContext* ctx_;
  uint64_t last_timestamp_;
};

class ProfileGenerator {
 public:
  explicit ProfileGenerator(std::shared_ptr<CpuProfile>&);
  void RecordTickSample(const std::shared_ptr<TickSampleEventRecord>&);

 private:
  std::shared_ptr<CpuProfile> profile_;
};
}  // namespace CpuProfiler
}  // namespace VMSDK
#endif
