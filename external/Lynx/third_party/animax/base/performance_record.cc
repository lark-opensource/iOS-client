// Copyright 2023 The Lynx Authors. All rights reserved.

#include "animax/base/performance_record.h"

#include <chrono>

#include "animax/base/log.h"
#include "animax/bridge/animax_element.h"
#include "animax/bridge/animax_event.h"

namespace lynx {
namespace animax {

TimeCost ParseRecord::StageInterval(Stage start, Stage end) {
  if (timestamps_.find(start) != timestamps_.end() &&
      timestamps_.find(end) != timestamps_.end()) {
    TimeCost cost = timestamps_.at(end) - timestamps_.at(start);
    if (cost > 0) {
      return cost;
    }
  }
  return 0;
}

void ParseRecord::Reset() { timestamps_.clear(); }

std::unordered_map<std::string, double> ParseRecord::GetPerfMetrics() {
  std::unordered_map<std::string, double> metrics;
  TimeCost request_cost =
      StageInterval(Stage::kRequestStart, Stage::kRequestEnd);
  if (request_cost > 0) {
    metrics["cost_src_net_load"] = request_cost;
  }
  TimeCost parse_cost =
      StageInterval(Stage::kParseCompositionStart, Stage::kParseCompositionEnd);
  if (parse_cost > 0) {
    metrics["cost_src_parse"] = parse_cost;
  }
  TimeCost asset_load =
      StageInterval(Stage::kLoadAssetStart, Stage::kLoadAssetEnd);
  if (asset_load > 0) {
    metrics["cost_asset_load"] = asset_load;
  }
  TimeCost build_cost =
      StageInterval(Stage::kBuildLayerStart, Stage::kBuildLayerEnd);
  if (build_cost > 0) {
    metrics["cost_layer_build"] = build_cost;
  }
  TimeCost total_cost =
      StageInterval(Stage::kRequestStart, Stage::kAnimationStart);
  if (total_cost > 0) {
    metrics["cost_set_src_total"] = total_cost;
  }
  return metrics;
}

void ParseRecord::Record(ParseRecord::Stage stage) {
  timestamps_.insert({stage, PerformanceRecord::Current()});
}

void DrawRecord::Init(AnimaXElement* element) { element_ = element; }

void DrawRecord::Record(DrawRecord::Stage stage) {
  auto current_ts = PerformanceRecord::Current();
  switch (stage) {
    case DrawRecord::Stage::kDrawStart:
      if (first_draw_start_ts_ == 0) {
        first_draw_start_ts_ = current_ts;
      }
      last_draw_start_ts_ = current_ts;
      break;
    case DrawRecord::Stage::kDrawEnd:
      last_draw_end_ts_ = current_ts;
      total_draw_count_ += 1;

      if (last_draw_start_ts_ > 0) {
        auto last_draw_interval = last_draw_end_ts_ - last_draw_start_ts_;
        auto drop_value =
            static_cast<uint32_t>(last_draw_interval / kFrameInterval);
        if (drop_value > max_drop_value_) {
          max_drop_value_ = drop_value;
        }

        ProcessFpsEvent(drop_value);
      }
      break;
  }
}

void DrawRecord::ProcessFpsEvent(const uint32_t drop_value) {
  if (session_interval_ <= 0 || !element_) {
    return;
  }

  session_draw_count_ += 1;

  // update session fps
  auto draw_start_ts = session_draw_start_ts_ == 0 ? first_draw_start_ts_
                                                   : session_draw_start_ts_;
  auto draw_interval = last_draw_end_ts_ - draw_start_ts;
  if (draw_interval > session_interval_) {
    auto fps =
        round((session_draw_count_ * 1000.0 / draw_interval) * 100) / 100.f;
    auto fps_param = std::make_unique<FpsParams>(session_max_drop_value_, fps);
    element_->NotifyEvent(Event::kFps, fps_param.get());

    ANIMAX_LOGE("Session fps: ")
        << std::to_string(fps)
        << ", max_drop_value: " << std::to_string(session_max_drop_value_);

    session_draw_start_ts_ = last_draw_start_ts_;
    session_draw_count_ = 0;
    session_max_drop_value_ = 0;
  }

  // update session max drop value
  if (drop_value > session_max_drop_value_) {
    session_max_drop_value_ = drop_value;
  }
}

void DrawRecord::Reset() {
  total_draw_count_ = 0;

  first_draw_start_ts_ = 0;
  last_draw_start_ts_ = 0;
  last_draw_end_ts_ = 0;
  max_drop_value_ = 0;

  session_draw_count_ = 0;
  session_draw_start_ts_ = 0;
  session_max_drop_value_ = 0;
}

std::unordered_map<std::string, double> DrawRecord::GetPerfMetrics() {
  std::unordered_map<std::string, double> metrics;
  auto draw_interval = last_draw_end_ts_ - first_draw_start_ts_;
  if (draw_interval > 0) {
    metrics["play_duration"] = draw_interval;
    metrics["fps"] =
        round((total_draw_count_ * 1000.0 / draw_interval) * 100) / 100.f;
    metrics["max_drop_value"] = max_drop_value_;
  }

  if (element_) {
    metrics["animation_duration"] = element_->GetDurationMs();
  }

  return metrics;
}

void PerformanceRecord::Init(AnimaXElement* element) {
  std::lock_guard<std::mutex> lock(m_);
  draw_record_.Init(element);
};

void PerformanceRecord::Record(ParseRecord::Stage stage) {
  std::lock_guard<std::mutex> lock(m_);
  parse_record_.Record(stage);
}

void PerformanceRecord::SetFpsEventInterval(const long interval) {
  std::lock_guard<std::mutex> lock(m_);
  draw_record_.session_interval_ = interval;
}

void PerformanceRecord::Record(DrawRecord::Stage stage) {
  std::lock_guard<std::mutex> lock(m_);
  draw_record_.Record(stage);
}

void PerformanceRecord::Reset() {
  std::lock_guard<std::mutex> lock(m_);
  parse_record_.Reset();
  draw_record_.Reset();
}

std::unordered_map<std::string, double> PerformanceRecord::GetPerfMetrics() {
  std::lock_guard<std::mutex> lock(m_);
  std::unordered_map<std::string, double> metrics;
  for (auto& item : parse_record_.GetPerfMetrics()) {
    metrics[item.first] = item.second;
  }
  for (auto& item : draw_record_.GetPerfMetrics()) {
    metrics[item.first] = item.second;
  }
  return metrics;
}

TimeStamp PerformanceRecord::Current() {
  return std::chrono::duration_cast<std::chrono::milliseconds>(
             std::chrono::system_clock::now().time_since_epoch())
      .count();
}

}  // namespace animax
}  // namespace lynx
