// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_BASE_PERFORMANCE_RECORD_H_
#define ANIMAX_BASE_PERFORMANCE_RECORD_H_

#include <memory>
#include <mutex>
#include <string>
#include <unordered_map>

namespace lynx {
namespace animax {

class AnimaXElement;

using TimeStamp = int64_t;
using TimeCost = uint32_t;

static constexpr double kFrameInterval = 1000.f / 60.f;

class ParseRecord {
 public:
  enum class Stage : uint8_t {
    kRequestStart = 0,       // Request src start
    kRequestEnd,             // Request src success
    kParseCompositionStart,  // Parse composition start
    kParseCompositionEnd,    // Parse composition end
    kLoadAssetStart,         // Load image/font start
    kLoadAssetEnd,           // Load image/font end
    kBuildLayerStart,        // Build composition layer start
    kBuildLayerEnd,          // Build composition layer end
    kAnimationStart,         // Ready to start animation
  };

  void Record(ParseRecord::Stage stage);

  void Reset();

  std::unordered_map<std::string, double> GetPerfMetrics();

 private:
  TimeCost StageInterval(Stage start, Stage end);

  std::unordered_map<Stage, TimeStamp> timestamps_;
};

class DrawRecord {
 public:
  enum class Stage : uint8_t {
    kDrawStart = 0,  // Start to draw, at the beginning of progress update
    kDrawEnd,        // End of flush
  };

  DrawRecord() = default;

  void Init(AnimaXElement* element);
  void Record(DrawRecord::Stage stage);

  void Reset();

  std::unordered_map<std::string, double> GetPerfMetrics();

  uint32_t session_interval_ = 0;

 private:
  void ProcessFpsEvent(const uint32_t drop_value);

  AnimaXElement* element_ = nullptr;

  // The total count of composition layer have been draw
  uint32_t total_draw_count_ = 0;

  // Timestamp of the first canvas draw call
  TimeStamp first_draw_start_ts_ = 0;
  TimeStamp last_draw_start_ts_ = 0;
  // Timestamp of the last canvas draw end call
  TimeStamp last_draw_end_ts_ = 0;
  uint32_t max_drop_value_ = 0;

  uint32_t session_draw_count_ = 0;
  TimeStamp session_draw_start_ts_ = 0;
  uint32_t session_max_drop_value_ = 0;
};

class PerformanceRecord {
 public:
  static TimeStamp Current();

  PerformanceRecord() = default;

  void Init(AnimaXElement* element);
  void SetFpsEventInterval(const long interval);
  void Record(ParseRecord::Stage stage);
  void Record(DrawRecord::Stage stage);

  void Reset();

  std::unordered_map<std::string, double> GetPerfMetrics();

 private:
  std::mutex m_;

  ParseRecord parse_record_;
  DrawRecord draw_record_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_BASE_PERFORMANCE_RECORD_H_
