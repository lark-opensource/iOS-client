// Copyright 2019 The Lynx Authors. All rights reserved.

#include "devtool/quickjs/profiler/cpu_profiler.h"

#include <assert.h>

#include "devtool/quickjs/debugger/debugger.h"
#include "devtool/quickjs/interface.h"
#include "devtool/quickjs/profiler/profile_generator.h"
#include "devtool/quickjs/profiler/profiler_sampling.h"

namespace VMSDK {
namespace CpuProfiler {

void SignalHandler::Install() {
  struct sigaction sa {};
  // register profiler singal function
  sa.sa_sigaction = &HandleCpuProfilerSignal;
  sigemptyset(&sa.sa_mask);
  sa.sa_flags = SA_RESTART | SA_SIGINFO;
  set_signal_handler_install(sigaction(SIGPROF, &sa, &old_signal_handler()) ==
                             0);
}

void SignalHandler::Restore() {
  if (signal_handler_installed()) {
    sigaction(SIGPROF, &old_signal_handler(), nullptr);
    set_signal_handler_install(false);
  }
}

int32_t& SignalHandler::client_count() {
  static int32_t client_count = 0;
  return client_count;
}

struct sigaction& SignalHandler::old_signal_handler() {
  static struct sigaction old_signal_handler;
  return old_signal_handler;
}

bool& SignalHandler::signal_handler_installed() {
  static bool signal_handler_installed = false;
  return signal_handler_installed;
}

void SignalHandler::set_signal_handler_install(bool is_installed) {
  signal_handler_installed() = is_installed;
}

std::mutex& SignalHandler::mutex() {
  static std::mutex mutex;
  return mutex;
}

void SignalHandler::IncreaseClientCount() { client_count()++; }
void SignalHandler::DecreaseClientCount() { client_count()--; }

CpuProfileMetaInfo::CpuProfileMetaInfo()
    : pc_(nullptr), frame_func_(LEPUS_UNDEFINED), script_(nullptr) {}

void SignalHandler::HandleCpuProfilerSignal(int signal, siginfo_t* info,
                                            void* context) {
  if (signal != SIGPROF) return;
  SamplerManager::GetInstance()->DoSample();
  SamplerManager::GetInstance()->samplingDoneSem_.Notify();
}

// CpuProfiler
CpuProfiler::CpuProfiler(LEPUSContext* ctx)
    : ctx_(ctx),
      sampling_interval_(0),
      generator_(nullptr),
      processor_(nullptr),
      is_profiling_(false) {
  InitProfilerVM();
}

CpuProfiler::~CpuProfiler() {
  assert(!is_profiling_);
  if (profiler_ctx_ && profiler_rt_) {
    LEPUS_FreeContext(profiler_ctx_);
    LEPUS_FreeRuntime(profiler_rt_);
  }
  profiler_rt_ = nullptr;
  profiler_ctx_ = nullptr;
}

void CpuProfiler::InitProfilerVM() {
  if (profiler_rt_ && profiler_ctx_) {
    LEPUS_FreeContext(profiler_ctx_);
    LEPUS_FreeRuntime(profiler_rt_);
    profiler_ctx_ = nullptr;
    profiler_rt_ = nullptr;
  }
  profiler_rt_ = LEPUS_NewRuntime();
  profiler_ctx_ = LEPUS_NewContext(profiler_rt_);
  SetIsProfilerCtx(profiler_ctx_, 1);
  InitQJSDebugger(profiler_ctx_);
}
// set sampling interval
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Profiler/#method-setSamplingInterval
void CpuProfiler::set_sampling_interval(uint32_t value) {
  assert(!is_profiling_);
  sampling_interval_ = value;
}

bool CpuProfiler::ProfilingEnabled() const {
  if (ctx_) {
    LEPUSDebuggerInfo* info = GetDebuggerInfo(ctx_);
    if (info) {
      return (info->is_profiling_enabled > 0);
    }
  }
  return false;
}

void CpuProfiler::StartProfiling(const char* title) {
  if (!ProfilingEnabled()) {
    return;
  }

  auto* info = GetDebuggerInfo(ctx_);
  info->cpu_profiling_started = true;
  profile_ = std::make_shared<CpuProfile>(this, title);
  StartProcessorIfNotStarted();
}

LEPUSContext* CpuProfiler::context() const { return ctx_; }
void CpuProfiler::StartProcessorIfNotStarted() {
  if (processor_) {
    processor_->AddCurrentStack(ctx_, profiler_ctx_);
    return;
  }

  if (!generator_) {
    generator_ = std::make_unique<ProfileGenerator>(profile_);
  }

  processor_ = std::make_unique<ProfilerSampling>(
      ctx_, profiler_ctx_, generator_.get(), sampling_interval_);
  is_profiling_ = true;

  // profiler thread begin to run
  processor_->Run();
}

std::shared_ptr<CpuProfile> CpuProfiler::StopProfiling(
    const std::string& title) {
  auto* info = GetDebuggerInfo(ctx_);
  info->cpu_profiling_started = false;
  if (!is_profiling_) return nullptr;
  StopProcessorIfLastProfile(title);
  profile_->FinishProfile();
  return profile_;
}

void CpuProfiler::StopProcessorIfLastProfile(const std::string& title) {
  StopProcessor();
}

void CpuProfiler::StopProcessor() {
  is_profiling_ = false;
  processor_->StopSynchronously();
  processor_.reset();
}

ProfileGenerator* CpuProfiler::Generator() const { return generator_.get(); }
ProfilerSampling* CpuProfiler::Processor() const { return processor_.get(); }

TickSampleEventRecord::TickSampleEventRecord()
    : frames_count_(0),
      profiler_ctx_(nullptr),
      is_new_(false),
      profiler_finish_(false) {}

TickSampleEventRecord::TickSampleEventRecord(
    const TickSampleEventRecord* record) {
  timestamp_ = record->timestamp_;
  profiler_ctx_ = record->profiler_ctx_;
  is_new_ = record->is_new_;
  profiler_finish_ = record->profiler_finish_;
  frames_count_ = record->frames_count_;
  for (int i = 0; i < record->frames_count_; i++) {
    stack_meta_info_[i] = record->stack_meta_info_[i];
    stack_meta_info_[i].frame_func_ =
        LEPUS_DupValue(profiler_ctx_, record->stack_meta_info_[i].frame_func_);
  }
}

TickSampleEventRecord::~TickSampleEventRecord() {
  for (int i = 0; i < frames_count_; i++) {
    auto& info = stack_meta_info_[i];
    info.pc_ = nullptr;
    info.script_ = nullptr;
    LEPUS_FreeValue(profiler_ctx_, info.frame_func_);
    info.frame_func_ = LEPUS_UNDEFINED;
  }
}
}  // namespace CpuProfiler
}  // namespace VMSDK
