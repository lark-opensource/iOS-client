// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_FLUENCY_FLUENCY_TRACER_H_
#define LYNX_TASM_FLUENCY_FLUENCY_TRACER_H_
#include <stdlib.h>

#include <atomic>
#include <vector>

namespace lynx {
namespace tasm {
class FluencyTracer {
 public:
  static void SetEnable(bool b);
  static bool IsEnable();
  void Trigger(int64_t time_stamp);

 private:
  void ReportFluency(double total_dur);
  static std::atomic<bool> enable_;
  std::vector<double> frames_dur_;
  int64_t last_timestamp_ = 0;
  int64_t start_timestamp_ = 0;
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_FLUENCY_FLUENCY_TRACER_H_
