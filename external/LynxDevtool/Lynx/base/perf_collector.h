// Copyright 2017 The Lynx Authors. All rights reserved.
//
// Created by 李岩波 on 2019-12-26.
//

#ifndef LYNX_BASE_PERF_COLLECTOR_H_
#define LYNX_BASE_PERF_COLLECTOR_H_

#include <chrono>
#include <memory>
#include <string>
#include <unordered_map>

#include "base/debug/lynx_assert.h"
#include "base/log/logging.h"
#include "config/config.h"
namespace lynx {
namespace base {
class PerfCollector {
 public:
  using PerfMap = std::unordered_map<int, std::unordered_map<int, double>>;

  enum class Perf {
    // 必发数据
    TASM_BINARY_DECODE,                         // 0  加载tasm和解码的时间
    TASM_END_DECODE_FINISH_LOAD_TEMPLATE,       // 1  加载tasm + 解码 + loadTemplate的总耗时
    TASM_FINISH_LOAD_TEMPLATE,                  // 2  loadTemplate的耗时
    DIFF_ROOT_CREATE,                           // 3  首次diff的耗时（包括创建dom和native view）
    JS_FINISH_LOAD_CORE,                        // 4  js线程加载core.js
    JS_FINISH_LOAD_APP,                         // 5  js线程加载app.js
    JS_AND_TASM_ALL_READY,                      // 6  LOAD_CORE + LOAD_APP的总和
    TTI,                                        // 7
    JS_RUNTIME_TYPE,                            // 8  js_runtime_type类型
    CORE_JS,                                    // 9  core.js的大小
    SOURCE_JS,                                  // 10 template.js的大小
    FIRST_PAGE_LAYOUT,                          // 11 Layout时间
    // 计算必发数据的数量
    FIRST_SEP, /* DON'T USE THIS! THIS SHOULD ONLY BE USED BY PERF COLLECTOR
                  SELF.*/                       // 12

    LAYOUT,                                     // 13

    BOTH_SEP, /* DON'T USE THIS! THIS SHOULD ONLY BE USED BY PERF COLLECTOR
                  SELF.*/                       // 14

    // update perf perf.
    RENDER_PAGE,                                // 15
    DIFF_SAME_ROOT,                             // 16

    UPDATE_SEP, /* DON'T USE THIS! THIS SHOULD ONLY BE USED BY PERF COLLECTOR
                   SELF.*/                      // 17
    
    // for ssr
    SSR_START_SEP, /* DON'T USE THIS! THIS SHOULD ONLY BE USED BY PERF COLLECTOR SELF.*/  // 18
    SSR_FMP,                                                  // SSR fmp                 // 19
    SSR_DISPATCH,                                             // SSR dispatch            // 20
    SSR_GENERATE_DOM,                                         // SSR generate dom        // 21
    SSR_SOURCE_SIZE,                                          // SSR source size         // 22
    SSR_END_SEP, /* DON'T USE THIS! THIS SHOULD ONLY BE USED BY PERF COLLECTOR SELF.*/    // 23
  // for ssr end

#if ENABLE_RENDERKIT
    RK_SEP, /* DON'T USE THIS! THIS SHOULD ONLY BE USED BY PERF COLLECTOR
               SELF.*/                          // 24

    // renderkit performance
    RK_LAYOUT,                                  // 25
    RK_PAINT,                                   // 26
    RK_BUILD_FRAME,                             // 27
    RK_RASTER,                                  // 28

    RK_FIRST_SEP, /* DON'T USE THIS! THIS SHOULD ONLY BE USED BY PERF COLLECTOR
                     SELF.*/                    // 29

    RK_MAX_TIME_PER_FRAME,                      // 30
    RK_AVERAGE_TIME_PER_FRAME,                  // 31

    RK_UPDATE_SEP, /* DON'T USE THIS! THIS SHOULD ONLY BE USED BY PERF COLLECTOR
                      SELF.*/                   // 32
#endif
  };

  enum class PerfStamp {
    INIT_START,
    INIT_END,
    LOAD_TEMPLATE_START,
    LOAD_TEMPLATE_END,
    DECODE_BINARY_START,
    DECODE_BINARY_END,
    RENDER_TEMPLATE_START,
    RENDER_TEMPLATE_END,
    DIFF_ROOT_START,
    DIFF_ROOT_END,
    LAYOUT_START,
    LAYOUT_END,
    LOAD_COREJS_START,
    LOAD_COREJS_END,
    LOAD_APPJS_START,
    LOAD_APPJS_END,

    START_DIFF,
    END_DIFF,
    UPDATE_PAGE_START,
    UPDATE_PAGE_END,

#if ENABLE_RENDERKIT
    RK_LAYOUT_START,
    RK_LAYOUT_END,
    RK_PAINT_START,
    RK_PAINT_END,
    RK_BUILD_FRAME_START,
    RK_BUILD_FRAME_END,
    RK_RASTER_START,
    RK_RASTER_END,
#endif
  };

  enum class DynamicComponentPerfTag {
    DYNAMIC_COMPONENT_REQUIRE_TIME,
    DYNAMIC_COMPONENT_DECODE_TIME
  };

  enum class DynamicComponentPerfStampTag {
    DYNAMIC_COMPONENT_REQUIRE_TIME_START,
    DYNAMIC_COMPONENT_REQUIRE_TIME_END,
    DYNAMIC_COMPONENT_DECODE_TIME_START,
    DYNAMIC_COMPONENT_DECODE_TIME_END,
    THRESHOLD
  };

  class DynamicComponentPerfInfo {
   public:
    DynamicComponentPerfInfo() = default;
    DynamicComponentPerfInfo(const DynamicComponentPerfInfo& info) = default;
    DynamicComponentPerfInfo(DynamicComponentPerfInfo&& info) = default;
    DynamicComponentPerfInfo& operator=(const DynamicComponentPerfInfo& info) =
        default;
    DynamicComponentPerfInfo& operator=(DynamicComponentPerfInfo&& info) =
        default;

    bool PerfReady() const;
    static const std::string& GetName(const DynamicComponentPerfTag& tag);
    static const std::string& GetName(const DynamicComponentPerfStampTag& tag);
    static const DynamicComponentPerfStampTag& GetStartStampTag(
        const DynamicComponentPerfTag& tag);
    static const DynamicComponentPerfStampTag& GetEndStampTag(
        const DynamicComponentPerfTag& tag);

    inline std::string size_key() const { return "size"; }
    inline int64_t size() const { return size_; }
    inline void set_size(int64_t size) { size_ = size; }

    inline std::string sync_require_key() const { return "sync_require"; }
    inline bool sync_require() const { return sync_require_; }
    inline void set_sync_require(bool sync) { sync_require_ = sync; }

    inline std::unordered_map<DynamicComponentPerfTag, int64_t>& perf_time() {
      return perf_time_;
    }
    inline const std::unordered_map<DynamicComponentPerfTag, int64_t>&
    perf_time() const {
      return perf_time_;
    }

    inline std::string perf_time_stamps_key() const { return "timing"; }
    inline std::unordered_map<DynamicComponentPerfStampTag, int64_t>&
    perf_time_stamps() {
      return perf_time_stamps_;
    }
    inline const std::unordered_map<DynamicComponentPerfStampTag, int64_t>&
    perf_time_stamps() const {
      return perf_time_stamps_;
    }

   private:
    int64_t size_{0};
    bool sync_require_{true};
    std::unordered_map<DynamicComponentPerfTag, int64_t> perf_time_{};
    std::unordered_map<DynamicComponentPerfStampTag, int64_t>
        perf_time_stamps_{};
  };

  class PerfReadyDelegate {
   public:
    virtual void OnFirstLoadPerfReady(
        const std::unordered_map<int32_t, double>& perf,
        const std::unordered_map<int32_t, std::string>& perf_timing) = 0;
    virtual void OnUpdatePerfReady(
        const std::unordered_map<int32_t, double>& perf,
        const std::unordered_map<int32_t, std::string>& perf_timing) = 0;
    virtual void OnDynamicComponentPerfReady(
        const std::unordered_map<std::string,
                                 base::PerfCollector::DynamicComponentPerfInfo>&
            dynamic_component_perf) = 0;
  };

  struct PerfHasher {
    template <typename T>
    std::size_t operator()(const T& t) const {
      return static_cast<std::size_t>(t);
    }
  };

  static std::string ToString(Perf perf) {
    auto it = GetInstance().k_mapping_.find(perf);
    LynxFatal(it != GetInstance().k_mapping_.end(), LYNX_ERROR_CODE_BASE_LIB,
              "can't not find match name for performance!");
    return it->second;
  }

  static std::string ToString(PerfStamp perf) {
    switch (perf) {
      case PerfStamp::INIT_START:
        return "init_start";
      case PerfStamp::INIT_END:
        return "init_end";
      case PerfStamp::LOAD_TEMPLATE_START:
        return "load_template_start";
      case PerfStamp::LOAD_TEMPLATE_END:
        return "load_template_end";
      case PerfStamp::DECODE_BINARY_START:
        return "decode_binary_start";
      case PerfStamp::DECODE_BINARY_END:
        return "decode_binary_end";
      case PerfStamp::RENDER_TEMPLATE_START:
        return "render_template_start";
      case PerfStamp::RENDER_TEMPLATE_END:
        return "render_template_end";
      case PerfStamp::DIFF_ROOT_START:
        return "diff_root_start";
      case PerfStamp::DIFF_ROOT_END:
        return "diff_root_end";
      case PerfStamp::LAYOUT_START:
        return "layout_start";
      case PerfStamp::LAYOUT_END:
        return "layout_end";
      case PerfStamp::LOAD_COREJS_START:
        return "load_corejs_start";
      case PerfStamp::LOAD_COREJS_END:
        return "load_corejs_end";
      case PerfStamp::LOAD_APPJS_START:
        return "load_appjs_start";
      case PerfStamp::LOAD_APPJS_END:
        return "load_appjs_end";
      case PerfStamp::START_DIFF:
        return "start_diff";
      case PerfStamp::END_DIFF:
        return "end_diff";
      case PerfStamp::UPDATE_PAGE_START:
        return "update_page_start";
      case PerfStamp::UPDATE_PAGE_END:
        return "update_page_end";
#if ENABLE_RENDERKIT
      case PerfStamp::RK_LAYOUT_START:
        return "rk_layout_start";
      case PerfStamp::RK_LAYOUT_END:
        return "rk_layout_end";
      case PerfStamp::RK_PAINT_START:
        return "rk_paint_start";
      case PerfStamp::RK_PAINT_END:
        return "rk_paint_end";
      case PerfStamp::RK_BUILD_FRAME_START:
        return "rk_build_frame_start";
      case PerfStamp::RK_BUILD_FRAME_END:
        return "rk_build_frame_end";
      case PerfStamp::RK_RASTER_START:
        return "rk_raster_start";
      case PerfStamp::RK_RASTER_END:
        return "rk_raster_end";
#endif
    }
    return "unknown";
  }

  // only use for NoDestructor
  PerfCollector() noexcept;
  /**
   * 获取单例
   * @return Perf instance
   */
  BASE_EXPORT_FOR_DEVTOOL static PerfCollector& GetInstance();

  PerfCollector(const PerfCollector&) = delete;
  void operator=(const PerfCollector&) = delete;

  // 以下三个方法都含有锁，保证线程安全。
  void StartRecord(int trace_id, Perf perf);
  void EndRecord(int trace_id, Perf perf);
  void InsertDouble(int trace_id, Perf perf, double value);
  void InsertDouble(int trace_id, PerfStamp perf, double value);
  void RecordPerfTime(int trace_id, PerfStamp perf);
  void RecordPerfTime(int trace_id, PerfStamp perf1, PerfStamp perf2);
  void setHydrating(int trace_id);

  void StartRecordDynamicComponentPerf(int trace_id, const std::string& url,
                                       DynamicComponentPerfTag perf);
  void EndRecordDynamicComponentPerf(int trace_id, const std::string& url,
                                     DynamicComponentPerfTag perf);
  void RecordDynamicComponentRequireMode(int trace_id, const std::string& url,
                                         bool sync);
  void RecordDynamicComponentBinarySize(int trace_id, const std::string& url,
                                        int64_t size);

#if ENABLE_RENDERKIT
  void OnRKPerfInsertFinished(int trace_id);
#endif

  /**
   * 注册打点回调
   * @param trace_id 跟踪id
   * @param cb 回调
   */
  void RegisterReadyDelegate(int trace_id, std::weak_ptr<PerfReadyDelegate> cb);
  /**
   * 注销打点回调
   * @param trace_id 事件id
   */
  void UnRegisterReadyDelegate(int trace_id);

  inline PerfMap* getFirstPerfContainer() { return &first_perf_container_; }

 private:
  std::unordered_map<std::string, DynamicComponentPerfInfo>
  GetDynamicComponentPerf(int trace_id);

  using PerfTime = long long;
  ~PerfCollector() = default;
  void DoInsert(int trace_id, Perf perf, double value);
  void DoInsert(int trace_id, PerfStamp perf, double value);
  inline void MayBeSendPerf(int trace_id, Perf perf);
  void MayBeSendDynamicCompPerf(int trace_id);
  bool Ensure(int trace_id);
  DynamicComponentPerfInfo* EnsureDynamicComponentPerfInfo(
      int trace_id, const std::string& url);

  std::unordered_map<Perf, std::string, PerfHasher> k_mapping_;
  PerfMap first_perf_container_;
  PerfMap update_perf_container_;
#if ENABLE_RENDERKIT
  PerfMap rk_update_perf_container_;
#endif
  std::unordered_map<int, bool> is_first_;
  std::unordered_map<int, std::unordered_map<int, PerfTime>> perf_record_;
  std::unordered_map<int, std::unordered_map<int, std::string>>
      perf_record_timestamp_;
  std::unordered_map<int,
                     std::unordered_map<std::string, DynamicComponentPerfInfo>>
      dynamic_component_perf_record_;
  std::unordered_map<int, std::weak_ptr<PerfReadyDelegate>> on_ready_delegates_;
  std::unordered_map<int, bool> is_send_first_perf_;

  // for ssr
  void DoInsertForSSR(int trace_id, Perf perf, double value);
  inline void MayBeSendPerfForSSR(int trace_id, Perf perf);
  inline bool isSSRPerf(Perf perf);
  PerfMap ssr_first_perf_container_;
  std::unordered_map<int, bool> is_ssr_hydrate_;
};
}  // namespace base
}  // namespace lynx

#endif  // LYNX_BASE_PERF_COLLECTOR_H_
