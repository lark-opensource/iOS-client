// Copyright 2019 The Lynx Authors. All rights reserved

#ifndef VMSDK_DEVTOOL_PROFILER_SAMPLING_H
#define VMSDK_DEVTOOL_PROFILER_SAMPLING_H

#include <queue>
#include <thread>

struct LEPUSContext;

namespace VMSDK {
namespace CpuProfiler {

class ProfileGenerator;
class TickSampleEventRecord;
class CpuSampler;
class PlatformData;

class Semaphore {
 public:
  Semaphore(int32_t count = 0) : count_(count) {}

  inline void Notify() {
    std::unique_lock<std::mutex> lock(mtx_);
    count_++;
    cv_.notify_one();
  }

  inline void Wait() {
    std::unique_lock<std::mutex> lock(mtx_);

    while (count_ == 0) {
      cv_.wait(lock);
    }
    count_--;
  }

 private:
  std::mutex mtx_;
  std::condition_variable cv_;
  int32_t count_;
};

class ProfilerSampling : public std::thread {
 public:
  ProfilerSampling(LEPUSContext*, LEPUSContext*, ProfileGenerator*, uint32_t);
  ~ProfilerSampling();

  void Run();

  void RunThread();

  void StopSynchronously();

  void AddCurrentStack(LEPUSContext*, LEPUSContext*);

  void PushTicksBuffer(std::shared_ptr<TickSampleEventRecord>&);

  void ProcessOneSample();

  void ProcessAllSamples();

  Semaphore ticks_buffer_semaphore_;

 private:
  std::queue<std::shared_ptr<TickSampleEventRecord>> ticks_buffer_;
  std::unique_ptr<CpuSampler> sampler_;
  bool running_;
  const uint32_t period_;
  std::thread cpu_profiler_processor_thread_;
  std::mutex mutex_;
  ProfileGenerator* generator_;
};

typedef enum {
  UNINITIALIZE,
  SIGNAL_HANDLER_NOT_INSTALL,
  CONTEXT_DESTRUCTED,
  SUCCESS,
} SampleProcessState;

class CpuSampler {
 public:
  CpuSampler(LEPUSContext*, LEPUSContext*, ProfilerSampling*);
  ~CpuSampler() = default;

  LEPUSContext* context() const { return ctx_; }

  void Install();
  void Restore();
  bool registered() const { return registered_ != 0; }
  std::shared_ptr<PlatformData> platform_data() const { return data_; }
  void SampleStack();
  SampleProcessState DoSample();

 private:
  void set_registered(bool value) { registered_ = value; }
  LEPUSContext* ctx_;
  LEPUSContext* profiler_ctx_;
  ProfilerSampling* processor_;
  bool registered_;
  std::shared_ptr<PlatformData> data_;
};

class SamplerManager {
 public:
  SamplerManager() = default;
  ~SamplerManager() = default;
  void set_sampler(CpuSampler*);
  void DoSample();
  static SamplerManager*& GetInstance() {
    static SamplerManager instance;
    static SamplerManager* instance_pointer = &instance;
    return instance_pointer;
  }

  static std::shared_ptr<TickSampleEventRecord>& GetRecord();
  void ClearRecord();
  Semaphore samplingDoneSem_;

 private:
  CpuSampler* sampler_;
};
}  // namespace CpuProfiler
}  // namespace VMSDK
#endif