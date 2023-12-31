// Copyright 2023 The Lynx Authors. All rights reserved.

#include "tasm/fluency/fluency_tracer.h"

#include <stdlib.h>

#include <utility>

#include "tasm/event_report_tracker.h"
#include "tasm/fluency/fluency_tracer.h"
namespace lynx {
namespace tasm {

std::atomic<bool> FluencyTracer::enable_{false};

void FluencyTracer::SetEnable(bool b) { enable_ = b; }

bool FluencyTracer::IsEnable() { return enable_; }

void FluencyTracer::Trigger(int64_t time_stamp) {
  if (!enable_) {
    return;
  }
  double total_dur = 0;
  if (start_timestamp_ == 0) {
    start_timestamp_ = time_stamp;
  } else if ((total_dur = (time_stamp - start_timestamp_) / 1.0e+9) > 30) {
    // compute every 30 seconds
    frames_dur_.push_back((time_stamp - last_timestamp_) / 1.0e+6);
    ReportFluency(total_dur);
    frames_dur_.clear();
    start_timestamp_ = time_stamp;
  } else {
    frames_dur_.push_back((time_stamp - last_timestamp_) / 1.0e+6);
  }
  last_timestamp_ = time_stamp;
}

void FluencyTracer::ReportFluency(double total_dur) {
  double rate = 16.667;
  // If a single drawing exceeds 16.667ms, it is considered a frame drop.
  // drop1: The number of times a single drawing exceeds 16.667ms
  // drop3: The number of times a single drawing exceeds (16.667 * 3)ms
  // drop7: The number of times a single drawing exceeds (16.667 * 7)ms
  int drop1 = 0;
  int drop3 = 0;
  int drop7 = 0;
  int frame_count = total_dur * 1000 / rate;
  double fps = frames_dur_.size() / total_dur;
  for (double dur : frames_dur_) {
    double drop = dur / rate;
    if (drop <= 0) {
      continue;
    }
    if (drop >= 1) {
      drop1++;
    }
    if (drop >= 3) {
      drop3++;
    }
    if (drop >= 7) {
      drop7++;
    }
  }

  auto event = tasm::PropBundle::Create();
  event->set_tag("lynxsdk_fluency_event");
  event->SetProps("lynxsdk_fluency_scene", "canvas");
  event->SetProps("lynxsdk_fluency_fps", fps);
  event->SetProps("lynxsdk_fluency_dur", total_dur * 1000);
  event->SetProps("lynxsdk_fluency_frames_number", frame_count);
  event->SetProps("lynxsdk_fluency_drop1_count", drop1);
  event->SetProps("lynxsdk_fluency_drop1_count_per_second", drop1 / total_dur);
  event->SetProps("lynxsdk_fluency_drop3_count", drop3);
  event->SetProps("lynxsdk_fluency_drop3_count_per_second", drop3 / total_dur);
  event->SetProps("lynxsdk_fluency_drop7_count", drop7);
  event->SetProps("lynxsdk_fluency_drop7_count_per_second", drop7 / total_dur);

  tasm::EventReportTracker::Report(std::move(event));
}
}  // namespace tasm
}  // namespace lynx
