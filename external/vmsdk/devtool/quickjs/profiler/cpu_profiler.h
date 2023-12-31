// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef VMSDK_DEVTOOL_CPU_PROFILER_H
#define VMSDK_DEVTOOL_CPU_PROFILER_H

#include <signal.h>

#include <thread>

#ifdef __cplusplus
extern "C" {
#endif
#include "quickjs/include/quickjs.h"
#ifdef __cplusplus
}
#endif

namespace VMSDK {
namespace CpuProfiler {

class ProfilerSampling;
class CpuSampler;
class SamplerManager;
class CpuProfile;
class ProfileGenerator;

// when the cpuprofiler thread take a sample, the thread send a signal to main
// thread, the main thread get meta info the cpuprofiler needed, and add to
// the samples
class SignalHandler {
 public:
  static void Install();
  static void Restore();

 private:
  // signal processing function
  static void HandleCpuProfilerSignal(int, siginfo_t*, void*);
  static int32_t& client_count();
  static void IncreaseClientCount();
  static void DecreaseClientCount();
  static struct sigaction& old_signal_handler();
  static bool& signal_handler_installed();
  static void set_signal_handler_install(bool);
  static std::mutex& mutex();
};

class PlatformData {
 public:
  PlatformData() : thread_id_(pthread_self()) {}
  pthread_t thread_id() const { return thread_id_; }

 private:
  pthread_t thread_id_;
};

typedef struct CpuProfileMetaInfo {
  const uint8_t* pc_;
  LEPUSValue frame_func_;
  LEPUSScriptSource* script_;
  CpuProfileMetaInfo();
} CpuProfileMetaInfo;

class TickSampleEventRecord {
 public:
  TickSampleEventRecord();

  ~TickSampleEventRecord();

  TickSampleEventRecord(const TickSampleEventRecord*);

  uint64_t timestamp_;
  static const unsigned kMaxFramesCountLog2 = 8;
  static const unsigned kMaxFramesCount = (1 << kMaxFramesCountLog2) - 1;
  CpuProfileMetaInfo stack_meta_info_[kMaxFramesCount];
  int32_t frames_count_;
  LEPUSContext* profiler_ctx_;
  bool is_new_;
  bool profiler_finish_;
};

class CpuProfiler {
 public:
  CpuProfiler(LEPUSContext*);

  ~CpuProfiler();

  void InitProfilerVM();
  void set_sampling_interval(uint32_t);
  void StartProfiling(const char*);
  std::shared_ptr<CpuProfile> StopProfiling(const std::string&);

  ProfileGenerator* Generator() const;
  ProfilerSampling* Processor() const;
  LEPUSContext* context() const;
  bool ProfilingEnabled() const;

 private:
  void StartProcessorIfNotStarted();
  void StopProcessorIfLastProfile(const std::string&);
  void StopProcessor();

  LEPUSContext* ctx_;
  LEPUSContext* profiler_ctx_ = nullptr;
  LEPUSRuntime* profiler_rt_ = nullptr;
  uint32_t sampling_interval_;
  std::unique_ptr<ProfileGenerator> generator_;
  std::unique_ptr<ProfilerSampling> processor_;
  bool is_profiling_;
  std::shared_ptr<CpuProfile> profile_;
};
}  // namespace CpuProfiler
}  // namespace VMSDK
#endif
