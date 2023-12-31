// Copyright 2019 The Lynx Authors. All rights reserved

#include "devtool/quickjs/profiler/profiler_sampling.h"

#include "devtool/quickjs/debugger/debugger.h"
#include "devtool/quickjs/interface.h"
#include "devtool/quickjs/profiler/cpu_profiler.h"
#include "devtool/quickjs/profiler/profile_generator.h"
#include "devtool/quickjs/profiler/tracing_cpu_profiler.h"

#ifdef __cplusplus
extern "C" {
#endif
#include "quickjs/include/quickjs.h"
#ifdef __cplusplus
}
#endif

#if defined(ANDROID) || defined(__ANDROID__)
#include <android/log.h>
#endif

namespace VMSDK {
namespace CpuProfiler {

// ProfilerSampling
ProfilerSampling::ProfilerSampling(LEPUSContext* ctx,
                                   LEPUSContext* profiler_ctx,
                                   ProfileGenerator* generator, uint32_t period)
    : ticks_buffer_semaphore_(1),
      sampler_(new CpuSampler(ctx, profiler_ctx, this)),
      running_(true),
      period_(period),
      generator_(generator) {
  // install sampler signal handler
  sampler_->Install();
}

ProfilerSampling::~ProfilerSampling() { sampler_->Restore(); }

static void GetRecordInfo(LEPUSContext* ctx, LEPUSContext* profiler_ctx,
                          std::shared_ptr<TickSampleEventRecord>& record) {
  // function name, url, script id, line_num, col_num
  // tranverse from the top frame
  int32_t level = 0;
  for (auto* sf = GetStackFrame(ctx); sf; sf = GetPreFrame(sf)) {
    LEPUSValue frame_func = GetFrameFunction(sf);
    auto* b = LEPUS_GetFunctionBytecode(frame_func);
    LEPUSScriptSource* script = nullptr;
    if (b) {
      auto* bytecode_script = GetBytecodeScript(b);
      script = (bytecode_script && bytecode_script->id)
                   ? bytecode_script
                   : GetScriptByScriptURL(ctx, "lepus.js");
    }
    auto& current_level_data = record->stack_meta_info_[level++];
    current_level_data.pc_ = GetFrameCurPC(sf);
    // deep clone part of frame_func we needed
    LEPUS_FreeValue(profiler_ctx, current_level_data.frame_func_);
    current_level_data.frame_func_ =
        DeepCloneFuncFrameForProfiler(ctx, profiler_ctx, frame_func);
    current_level_data.script_ = script;
    if (level >= TickSampleEventRecord::kMaxFramesCount) {
      printf("QJS CPU PROFILER: FUNCTINON FRAME SIZE IS OVER 255\n");
      break;
    }
  }

  record->profiler_ctx_ = profiler_ctx;
  record->frames_count_ = level;
  record->is_new_ = true;
  record->timestamp_ = std::chrono::time_point_cast<std::chrono::microseconds>(
                           std::chrono::system_clock::now())
                           .time_since_epoch()
                           .count();
}

// get info needed by cpuprofiler thread
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Runtime/#type-CallFrame
void ProfilerSampling::AddCurrentStack(LEPUSContext* ctx,
                                       LEPUSContext* profile_ctx) {
  auto record = std::make_shared<TickSampleEventRecord>();
  if (ctx && profile_ctx) {
    GetRecordInfo(ctx, profile_ctx, record);
    ticks_buffer_semaphore_.Wait();
    ticks_buffer_.push(record);
    ticks_buffer_semaphore_.Notify();
  }
}

void ProfilerSampling::PushTicksBuffer(
    std::shared_ptr<TickSampleEventRecord>& record) {
  ticks_buffer_.push(record);
}

// cpuprofiler thread begin to run
void ProfilerSampling::RunThread() {
  const uint64_t time_interval = std::chrono::microseconds(period_).count();
  bool is_running;
  SampleProcessState res = UNINITIALIZE;
  while (true) {
    {
      std::lock_guard<std::mutex> lck(mutex_);
      is_running = running_;
    }

    if (is_running) {
      // use time interval to compute the next sample time in microseconds
      uint64_t nextSampleTime =
          std::chrono::time_point_cast<std::chrono::microseconds>(
              std::chrono::system_clock::now())
              .time_since_epoch()
              .count() +
          time_interval;

      // do sampling
      if (sampler_) {
        res = sampler_->DoSample();
        if (res == SIGNAL_HANDLER_NOT_INSTALL || res == CONTEXT_DESTRUCTED)
          break;
      }

      while (true) {
        uint64_t now = std::chrono::time_point_cast<std::chrono::microseconds>(
                           std::chrono::system_clock::now())
                           .time_since_epoch()
                           .count();
        if (nextSampleTime > now) {
          ProcessOneSample();
        } else {
          break;
        }
      }
    } else {
      break;
    }
  }
  if (res != CONTEXT_DESTRUCTED) {
    // process the rest of samples
    ProcessAllSamples();
  } else {
#if defined(ANDROID) || defined(__ANDROID__)
    __android_log_print(ANDROID_LOG_ERROR, "VMSDK_CPU_PROFILER",
                        "Context destructed! Do not process samples");
#endif
  }
  // clear record
  SamplerManager::GetInstance()->ClearRecord();
}

void ProfilerSampling::Run() {
  cpu_profiler_processor_thread_ =
      std::thread(&ProfilerSampling::RunThread, this);
#if defined(ANDROID) || defined(__ANDROID__)
  pthread_setname_np(cpu_profiler_processor_thread_.native_handle(),
                     "QJS_Profile_Sampling");
#endif
}

void ProfilerSampling::StopSynchronously() {
  bool is_running = running_;
  if (!is_running) return;

  {
    std::lock_guard<std::mutex> lck(mutex_);
    running_ = false;
  }
  // wait for cpu profiler processor thread to end
  cpu_profiler_processor_thread_.join();
}

// CpuSampler
CpuSampler::CpuSampler(LEPUSContext* ctx, LEPUSContext* profiler_ctx,
                       ProfilerSampling* processor)
    : ctx_(ctx),
      profiler_ctx_(profiler_ctx),
      processor_(processor),
      registered_(false) {
  data_ = std::make_shared<PlatformData>();
}

void CpuSampler::Install() { SignalHandler::Install(); }

void CpuSampler::Restore() { SignalHandler::Restore(); }

void CpuSampler::SampleStack() {
  auto& new_record = SamplerManager::GetInstance()->GetRecord();
  if (new_record && profiler_ctx_ && ctx_) {
    if (!GetDebuggerInfo(ctx_)->cpu_profiling_started) {
      new_record->profiler_finish_ = true;
      return;
    }
    GetRecordInfo(ctx_, profiler_ctx_, new_record);
  }
}

void ProfilerSampling::ProcessOneSample() {
  ticks_buffer_semaphore_.Wait();
  std::shared_ptr<TickSampleEventRecord> record = nullptr;
  if (!ticks_buffer_.empty()) {
    record = ticks_buffer_.front();
    ticks_buffer_.pop();
  }
  ticks_buffer_semaphore_.Notify();
  if (record && generator_) {
    generator_->RecordTickSample(record);
  }
}

void ProfilerSampling::ProcessAllSamples() {
  ticks_buffer_semaphore_.Wait();
  while (!ticks_buffer_.empty()) {
    auto record = ticks_buffer_.front();
    ticks_buffer_.pop();
    if (record && generator_) {
      generator_->RecordTickSample(record);
    }
  }
  ticks_buffer_semaphore_.Notify();
}

SampleProcessState CpuSampler::DoSample() {
  // send signal for sampling
  if (!registered()) {
    SamplerManager::GetInstance()->set_sampler(this);
    set_registered(true);
  }

  // send signal to target thread
  pthread_kill(platform_data()->thread_id(), SIGPROF);
  SamplerManager::GetInstance()->samplingDoneSem_.Wait();

  // this record will be deleted when ticks_buffer done consuming it
  auto& record = SamplerManager::GetInstance()->GetRecord();
  if (record->profiler_finish_) {
    return CONTEXT_DESTRUCTED;
  }
  if (record->is_new_) {
    auto sample_record = std::make_shared<TickSampleEventRecord>(record.get());
    processor_->ticks_buffer_semaphore_.Wait();
    processor_->PushTicksBuffer(sample_record);
    processor_->ticks_buffer_semaphore_.Notify();
    record->is_new_ = false;
  }
  return SUCCESS;
}

// SamplerManager
void SamplerManager::set_sampler(CpuSampler* sampler) { sampler_ = sampler; }

void SamplerManager::DoSample() {
  if (sampler_) {
    sampler_->SampleStack();
  }
}

void SamplerManager::ClearRecord() {
  auto& record = GetRecord();
  record->is_new_ = false;
  record->timestamp_ = 0;
  record->profiler_finish_ = false;
  for (auto& item : record->stack_meta_info_) {
    item.script_ = nullptr;
    item.pc_ = nullptr;
    if (!LEPUS_IsUndefined(item.frame_func_)) {
      LEPUS_FreeValue(record->profiler_ctx_, item.frame_func_);
      item.frame_func_ = LEPUS_UNDEFINED;
    }
  }
  record->frames_count_ = 0;
  record->profiler_ctx_ = nullptr;
}

std::shared_ptr<TickSampleEventRecord>& SamplerManager::GetRecord() {
  // initialize a sample record because there are no allocations in the signal
  // handler
  static auto record = std::make_shared<TickSampleEventRecord>();
  return record;
}
}  // namespace CpuProfiler
}  // namespace VMSDK