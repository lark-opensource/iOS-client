// Copyright 2017 The Lynx Authors. All rights reserved.
//
// Created by 李岩波 on 2019-12-26.
//

#include "base/perf_collector.h"

#include <mutex>
#include <utility>

#include "base/float_comparison.h"
#include "base/no_destructor.h"
#include "base/threading/task_runner_manufactor.h"
#include "base/trace_event/trace_event.h"
#include "tasm/lynx_trace_event.h"

namespace lynx {
namespace base {

namespace {
template <typename T>
static constexpr int PerfToInt(T perf) noexcept {
  return static_cast<int>(perf);
}

// 计算first的打点个数。
static constexpr int BOTH_THRESHOLD =
    PerfToInt(PerfCollector::Perf::BOTH_SEP) -
    PerfToInt(PerfCollector::Perf::FIRST_SEP) - 1;

#if ENABLE_RENDERKIT
static constexpr int RK_FIRST_THRESHOLD =
    PerfToInt(PerfCollector::Perf::RK_FIRST_SEP) -
    PerfToInt(PerfCollector::Perf::RK_SEP) - 1;

static constexpr int RK_UPDATE_THRESHOLD =
    PerfToInt(PerfCollector::Perf::RK_UPDATE_SEP) -
    PerfToInt(PerfCollector::Perf::RK_FIRST_SEP) - 1;

static constexpr int FIRST_THRESHOLD =
    PerfToInt(PerfCollector::Perf::FIRST_SEP) + BOTH_THRESHOLD +
    RK_FIRST_THRESHOLD;
#else
static constexpr int FIRST_THRESHOLD =
    PerfToInt(PerfCollector::Perf::FIRST_SEP) + BOTH_THRESHOLD;
#endif

static constexpr int SSR_FIRST_THRESHOLD =
    PerfToInt(PerfCollector::Perf::SSR_END_SEP) -
    PerfToInt(PerfCollector::Perf::SSR_START_SEP) - 1;

// 计算 update 的打点个数。
static constexpr int UPDATE_THRESHOLD =
    PerfToInt(PerfCollector::Perf::UPDATE_SEP) -
    PerfToInt(PerfCollector::Perf::BOTH_SEP) - 1 + BOTH_THRESHOLD;

constexpr const static int DYNAMIC_THRESHOLD =
    PerfToInt(PerfCollector::DynamicComponentPerfStampTag::THRESHOLD);

}  // namespace

// The flag to mark it's ssr hydrate perf records.
static constexpr int kIsSsrHydrateIndex = 20220425;

PerfCollector& PerfCollector::GetInstance() {
  static base::NoDestructor<PerfCollector> instance;
  return *instance.get();
}

// public
PerfCollector::PerfCollector() noexcept {
  k_mapping_ = {
    {Perf::TASM_BINARY_DECODE, "tasm_binary_decode"},
    {Perf::TASM_END_DECODE_FINISH_LOAD_TEMPLATE,
     "tasm_end_decode_finish_load_template"},
    {Perf::TASM_FINISH_LOAD_TEMPLATE, "tasm_finish_load_template"},
    {Perf::DIFF_ROOT_CREATE, "diff_root_create"},
    {Perf::JS_FINISH_LOAD_CORE, "js_finish_load_core"},
    {Perf::JS_FINISH_LOAD_APP, "js_finish_load_app"},
    {Perf::JS_AND_TASM_ALL_READY, "js_and_tasm_all_ready"},
    {Perf::TTI, "tti"},
    {Perf::JS_RUNTIME_TYPE, "js_runtime_type"},
    {Perf::JS_RUNTIME_TYPE, "js_runtime_type"},
    {Perf::CORE_JS, "corejs_size"},
    {Perf::SOURCE_JS, "source_js_size"},
    {Perf::LAYOUT, "layout"},
    {Perf::FIRST_PAGE_LAYOUT, "first_page_layout"},
    {Perf::RENDER_PAGE, "render_page"},
    {Perf::DIFF_SAME_ROOT, "diff_same_root"},
    {Perf::SSR_FMP, "ssr_fmp"},
    {Perf::SSR_DISPATCH, "ssr_dispatch"},
    {Perf::SSR_GENERATE_DOM, "ssr_generate_dom"},
    {Perf::SSR_SOURCE_SIZE, "ssr_source_size"},

#if ENABLE_RENDERKIT
    // renderkit performance
    {Perf::RK_LAYOUT, "rk_layout"},
    {Perf::RK_PAINT, "rk_paint"},
    {Perf::RK_BUILD_FRAME, "rk_build_frame"},
    {Perf::RK_RASTER, "rk_raster"},
    {Perf::RK_MAX_TIME_PER_FRAME, "rk_max_time_per_frame"},
    {Perf::RK_AVERAGE_TIME_PER_FRAME, "rk_average_time_per_frame"},
#endif
  };
}

void PerfCollector::UnRegisterReadyDelegate(int trace_id) {
  base::UIThread::GetRunner()->PostTask([self = this, trace_id]() {
    self->on_ready_delegates_.erase(trace_id);
    self->first_perf_container_.erase(trace_id);
    self->ssr_first_perf_container_.erase(trace_id);
    self->update_perf_container_.erase(trace_id);
    self->is_first_.erase(trace_id);
    self->is_send_first_perf_.erase(trace_id);
    self->perf_record_.erase(trace_id);
    self->perf_record_timestamp_.erase(trace_id);
    self->dynamic_component_perf_record_.erase(trace_id);
    self->is_ssr_hydrate_.erase(trace_id);

#if ENABLE_RENDERKIT
    self->rk_update_perf_container_.erase(trace_id);
#endif
  });
}

void PerfCollector::RegisterReadyDelegate(int trace_id,
                                          std::weak_ptr<PerfReadyDelegate> cb) {
  base::UIThread::GetRunner()->PostTask([self = this, trace_id, cb]() {
    self->on_ready_delegates_[trace_id] = std::move(cb);
    self->first_perf_container_.insert(
        {trace_id, std::unordered_map<int, double>()});
    self->update_perf_container_.insert(
        {trace_id, std::unordered_map<int, double>()});
    self->ssr_first_perf_container_.insert(
        {trace_id, std::unordered_map<int, double>()});
    self->is_first_[trace_id] = true;
    self->is_send_first_perf_[trace_id] = true;
    self->perf_record_.insert({trace_id, std::unordered_map<int, PerfTime>()});
    self->perf_record_timestamp_.insert(
        {trace_id, std::unordered_map<int, std::string>()});
    self->is_ssr_hydrate_[trace_id] = false;

#if ENABLE_RENDERKIT
    self->rk_update_perf_container_.insert(
        {trace_id, std::unordered_map<int, double>()});
#endif
  });
}

bool PerfCollector::DynamicComponentPerfInfo::PerfReady() const {
  return perf_time_stamps_.size() == DYNAMIC_THRESHOLD;
}

const std::string& PerfCollector::DynamicComponentPerfInfo::GetName(
    const DynamicComponentPerfTag& tag) {
  const static base::NoDestructor<
      std::unordered_map<DynamicComponentPerfTag, std::string>>
      kTagNameMap{{{DynamicComponentPerfTag::DYNAMIC_COMPONENT_REQUIRE_TIME,
                    "require_time"},
                   {DynamicComponentPerfTag::DYNAMIC_COMPONENT_DECODE_TIME,
                    "decode_time"}}};
  return kTagNameMap.get()->at(tag);
}

const std::string& PerfCollector::DynamicComponentPerfInfo::GetName(
    const DynamicComponentPerfStampTag& tag) {
  const static base::NoDestructor<
      std::unordered_map<DynamicComponentPerfStampTag, std::string>>
      kTagNameMap{{
          {DynamicComponentPerfStampTag::DYNAMIC_COMPONENT_REQUIRE_TIME_START,
           "require_start_time"},
          {DynamicComponentPerfStampTag::DYNAMIC_COMPONENT_REQUIRE_TIME_END,
           "require_end_time"},
          {DynamicComponentPerfStampTag::DYNAMIC_COMPONENT_DECODE_TIME_START,
           "decode_start_time"},
          {DynamicComponentPerfStampTag::DYNAMIC_COMPONENT_DECODE_TIME_END,
           "decode_end_time"},
      }};
  return kTagNameMap.get()->at(tag);
}

const PerfCollector::DynamicComponentPerfStampTag&
PerfCollector::DynamicComponentPerfInfo::GetStartStampTag(
    const DynamicComponentPerfTag& tag) {
  const static base::NoDestructor<
      std::unordered_map<DynamicComponentPerfTag, DynamicComponentPerfStampTag>>
      kStartTagMapping{
          {{DynamicComponentPerfTag::DYNAMIC_COMPONENT_REQUIRE_TIME,
            DynamicComponentPerfStampTag::DYNAMIC_COMPONENT_REQUIRE_TIME_START},
           {DynamicComponentPerfTag::DYNAMIC_COMPONENT_DECODE_TIME,
            DynamicComponentPerfStampTag::
                DYNAMIC_COMPONENT_DECODE_TIME_START}}};
  return kStartTagMapping.get()->at(tag);
}

const PerfCollector::DynamicComponentPerfStampTag&
PerfCollector::DynamicComponentPerfInfo::GetEndStampTag(
    const DynamicComponentPerfTag& tag) {
  const static base::NoDestructor<
      std::unordered_map<DynamicComponentPerfTag, DynamicComponentPerfStampTag>>
      kEndTagMapping{
          {{DynamicComponentPerfTag::DYNAMIC_COMPONENT_REQUIRE_TIME,
            DynamicComponentPerfStampTag::DYNAMIC_COMPONENT_REQUIRE_TIME_END},
           {DynamicComponentPerfTag::DYNAMIC_COMPONENT_DECODE_TIME,
            DynamicComponentPerfStampTag::DYNAMIC_COMPONENT_DECODE_TIME_END}}};
  return kEndTagMapping.get()->at(tag);
}

void PerfCollector::StartRecord(int trace_id,
                                lynx::base::PerfCollector::Perf perf) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "PerfCollector::");
  long long start = std::chrono::duration_cast<std::chrono::milliseconds>(
                        std::chrono::system_clock::now().time_since_epoch())
                        .count();

  base::UIThread::GetRunner()->PostTask([self = this, trace_id, perf, start]() {
    if (self->perf_record_.find(trace_id) == self->perf_record_.end()) {
      return;
    }
    self->perf_record_[trace_id][PerfToInt(perf)] = start;
  });
}

void PerfCollector::EndRecord(int trace_id,
                              lynx::base::PerfCollector::Perf perf) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "PerfCollector::");
  long long end = std::chrono::duration_cast<std::chrono::milliseconds>(
                      std::chrono::system_clock::now().time_since_epoch())
                      .count();
  base::UIThread::GetRunner()->PostTask([self = this, trace_id, perf, end]() {
    if (self->perf_record_.find(trace_id) == self->perf_record_.end()) {
      return;
    }
    auto start = self->perf_record_[trace_id][PerfToInt(perf)];

    // for ssr
    if (self->isSSRPerf(perf)) {
      if (base::FloatsLarger(start, 0.f)) {
        self->DoInsertForSSR(trace_id, perf, end - start);
      }
      return;
    }
    // for ssr end

    double cost = end - start;
    self->DoInsert(trace_id, perf, cost);
  });
}

void PerfCollector::InsertDouble(int trace_id, Perf perf, double value) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "PerfCollector::");
  base::UIThread::GetRunner()->PostTask([self = this, trace_id, perf, value]() {
    // for ssr
    if (self->isSSRPerf(perf)) {
      self->DoInsertForSSR(trace_id, perf, value);
      return;
    }
    // for ssr end
    self->DoInsert(trace_id, perf, value);
  });
}

void PerfCollector::InsertDouble(int trace_id, PerfStamp perf, double value) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "PerfCollector::");
  base::UIThread::GetRunner()->PostTask([self = this, trace_id, perf, value]() {
    self->DoInsert(trace_id, perf, value);
  });
}

void PerfCollector::RecordPerfTime(int trace_id, PerfStamp perf) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "PerfCollector::");
  long long time = std::chrono::duration_cast<std::chrono::milliseconds>(
                       std::chrono::system_clock::now().time_since_epoch())
                       .count();
  std::string time_str_ = std::to_string(time);

  base::UIThread::GetRunner()->PostTask(
      [self = this, trace_id, perf, time_str_]() {
        if (self->perf_record_timestamp_.find(trace_id) ==
            self->perf_record_timestamp_.end()) {
          return;
        }
        self->perf_record_timestamp_[trace_id][PerfToInt(perf)] = time_str_;
      });
}

void PerfCollector::RecordPerfTime(int trace_id, PerfStamp perf1,
                                   PerfStamp perf2) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "PerfCollector::");
  long long time = std::chrono::duration_cast<std::chrono::milliseconds>(
                       std::chrono::system_clock::now().time_since_epoch())
                       .count();
  std::string time_str_ = std::to_string(time);

  base::UIThread::GetRunner()->PostTask(
      [self = this, trace_id, perf1, perf2, time_str_]() {
        if (self->perf_record_timestamp_.find(trace_id) ==
            self->perf_record_timestamp_.end()) {
          return;
        }
        self->perf_record_timestamp_[trace_id][PerfToInt(perf1)] = time_str_;
        self->perf_record_timestamp_[trace_id][PerfToInt(perf2)] = time_str_;
      });
}

void PerfCollector::StartRecordDynamicComponentPerf(
    int trace_id, const std::string& url, DynamicComponentPerfTag perf) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "PerfCollector::");
  int64_t time = std::chrono::duration_cast<std::chrono::milliseconds>(
                     std::chrono::system_clock::now().time_since_epoch())
                     .count();
  base::UIThread::GetRunner()->PostTask(
      [self = this, trace_id, url, perf, time]() {
        auto ptr = self->EnsureDynamicComponentPerfInfo(trace_id, url);
        if (!ptr) {
          return;
        }
        // Insert Only time_stamp. perf_time will be calculated when endRecord.
        ptr->perf_time_stamps().insert({ptr->GetStartStampTag(perf), time});
      });
}

void PerfCollector::EndRecordDynamicComponentPerf(
    int trace_id, const std::string& url, DynamicComponentPerfTag perf) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "PerfCollector::");
  int64_t time = std::chrono::duration_cast<std::chrono::milliseconds>(
                     std::chrono::system_clock::now().time_since_epoch())
                     .count();
  base::UIThread::GetRunner()->PostTask(
      [self = this, trace_id, url, perf, time]() {
        auto ptr = self->EnsureDynamicComponentPerfInfo(trace_id, url);
        if (!ptr) {
          return;
        }

        // Get perf start time, calculate perf_time.
        auto iter = ptr->perf_time_stamps().find(ptr->GetStartStampTag(perf));
        if (iter == ptr->perf_time_stamps().end()) {
          return;
        }
        ptr->perf_time_stamps().insert({ptr->GetEndStampTag(perf), time});
        ptr->perf_time().insert({perf, time - iter->second});
        // Since `OnDynamicComponentPerfReady` is called ON Tasm Thread, and
        // Then posted to JSThread. It's safe that the js constructor is already
        // executed to listener to this event.
        if (perf == DynamicComponentPerfTag::DYNAMIC_COMPONENT_DECODE_TIME) {
          self->MayBeSendDynamicCompPerf(trace_id);
        }
      });
}

void PerfCollector::RecordDynamicComponentRequireMode(int trace_id,
                                                      const std::string& url,
                                                      bool sync) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "PerfCollector::");
  base::UIThread::GetRunner()->PostTask([self = this, trace_id, url, sync]() {
    auto ptr = self->EnsureDynamicComponentPerfInfo(trace_id, url);
    if (!ptr) {
      return;
    }
    ptr->set_sync_require(sync);
  });
}

void PerfCollector::RecordDynamicComponentBinarySize(int trace_id,
                                                     const std::string& url,
                                                     int64_t size) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "PerfCollector::");
  base::UIThread::GetRunner()->PostTask([self = this, trace_id, url, size]() {
    auto ptr = self->EnsureDynamicComponentPerfInfo(trace_id, url);
    if (!ptr) {
      return;
    }
    ptr->set_size(size);
  });
}

// private
void PerfCollector::DoInsert(int trace_id, Perf perf, double value) {
  if (!Ensure(trace_id)) {
    return;
  }
  if (perf < Perf::FIRST_SEP) {
    first_perf_container_[trace_id][PerfToInt(perf)] = value;
  } else if (perf > Perf::BOTH_SEP) {
#if ENABLE_RENDERKIT
    if (perf > Perf::RK_SEP) {
      if (is_send_first_perf_[trace_id] && perf < Perf::RK_FIRST_SEP) {
        first_perf_container_[trace_id][PerfToInt(perf)] = value;
      }
      if (perf > Perf::RK_FIRST_SEP && perf < Perf::RK_UPDATE_SEP) {
        rk_update_perf_container_[trace_id][PerfToInt(perf)] = value;
      }
    }
#else
    update_perf_container_[trace_id][PerfToInt(perf)] = value;
#endif
  } else {
    if (is_first_[trace_id]) {
      first_perf_container_[trace_id][PerfToInt(perf)] = value;
      is_first_[trace_id] = false;
    } else {
      update_perf_container_[trace_id][PerfToInt(perf)] = value;
    }
  }

  if (perf == Perf::FIRST_PAGE_LAYOUT || perf == Perf::JS_AND_TASM_ALL_READY ||
      perf == Perf::RENDER_PAGE || perf == Perf::LAYOUT) {
    MayBeSendPerf(trace_id, perf);
  }
}

void PerfCollector::DoInsertForSSR(int trace_id, Perf perf, double value) {
  if (!Ensure(trace_id)) {
    return;
  }
  ssr_first_perf_container_[trace_id][PerfToInt(perf)] = value;
  if (perf == Perf::SSR_FMP) {
    MayBeSendPerfForSSR(trace_id, perf);
  }
}

// private
void PerfCollector::DoInsert(int trace_id, PerfStamp perf, double value) {
  if (perf_record_timestamp_.find(trace_id) == perf_record_timestamp_.end()) {
    return;
  }
  perf_record_timestamp_[trace_id][PerfToInt(perf)] = std::to_string(value);
}

#if ENABLE_RENDERKIT
void PerfCollector::OnRKPerfInsertFinished(int trace_id) {
  if (!Ensure(trace_id)) {
    return;
  }
  base::UIThread::GetRunner()->PostTask([self = this, trace_id]() {
    self->MayBeSendPerf(trace_id, Perf::RK_RASTER);
  });
}
#endif

void PerfCollector::MayBeSendPerf(int trace_id, Perf perf) {
  auto maybe_first = first_perf_container_[trace_id];
  auto maybe_update = update_perf_container_[trace_id];
  if (maybe_first.size() == FIRST_THRESHOLD && is_send_first_perf_[trace_id]) {
    auto delegate = on_ready_delegates_[trace_id].lock();
    if (delegate) {
      auto first_stamp_ = perf_record_timestamp_[trace_id];
      MayBeSendDynamicCompPerf(trace_id);

      if (is_ssr_hydrate_[trace_id]) {
        maybe_first[kIsSsrHydrateIndex] = static_cast<double>(1);
        // Remove meaningless values for hydrating.
        maybe_first.erase(PerfToInt(Perf::FIRST_PAGE_LAYOUT));
        maybe_first.erase(PerfToInt(Perf::LAYOUT));
        maybe_first.erase(PerfToInt(Perf::JS_AND_TASM_ALL_READY));
      }

      delegate->OnFirstLoadPerfReady(maybe_first, first_stamp_);
      perf_record_timestamp_[trace_id].clear();
    }
    is_send_first_perf_[trace_id] = false;
    is_ssr_hydrate_[trace_id] = false;
  }
  if (maybe_update.size() == UPDATE_THRESHOLD) {
    auto delegate = on_ready_delegates_[trace_id].lock();
    if (delegate) {
      auto update_stamp = perf_record_timestamp_[trace_id];
      MayBeSendDynamicCompPerf(trace_id);
      delegate->OnUpdatePerfReady(maybe_update, update_stamp);
      // FIXME(yxping):主要问题发生在 iOS ，会存在更新回调的 timestamp 后
      // 清空首屏回调的 timestamp
      // 的问题，为了规避这个情况，暂时先通过判断发生了首屏回调之后才进行清空的动作。这里会存在一个
      // bad case 是 layout 的时间戳并不准确，另外 update
      // 的时间戳并不准确。需要后续修复。
      if (!is_send_first_perf_[trace_id]) {
        perf_record_timestamp_[trace_id].clear();
      }
    }
    update_perf_container_[trace_id].clear();
  }

#if ENABLE_RENDERKIT
  auto rk_maybe_update = rk_update_perf_container_[trace_id];
  if (rk_maybe_update.size() == RK_UPDATE_THRESHOLD) {
    auto delegate = on_ready_delegates_[trace_id].lock();
    if (delegate) {
      delegate->OnDynamicComponentPerfReady(GetDynamicComponentPerf(trace_id));
      delegate->OnUpdatePerfReady(rk_maybe_update, {});
    }
    rk_update_perf_container_[trace_id].clear();
  }
#endif
}

bool PerfCollector::isSSRPerf(PerfCollector::Perf perf) {
  return perf > Perf::SSR_START_SEP && perf < Perf::SSR_END_SEP;
}

void PerfCollector::MayBeSendPerfForSSR(int trace_id, Perf perf) {
  auto maybe_first = ssr_first_perf_container_[trace_id];
  if (maybe_first.size() == SSR_FIRST_THRESHOLD) {
    auto delegate = on_ready_delegates_[trace_id].lock();
    if (delegate) {
      std::unordered_map<int32_t, std::string> first_stamp_(0);
      delegate->OnFirstLoadPerfReady(maybe_first, first_stamp_);
    }
  }
}

void PerfCollector::MayBeSendDynamicCompPerf(int trace_id) {
  auto delegate = on_ready_delegates_[trace_id].lock();
  if (delegate) {
    delegate->OnDynamicComponentPerfReady(GetDynamicComponentPerf(trace_id));
  }
}

bool PerfCollector::Ensure(int trace_id) {
  return first_perf_container_.find(trace_id) != first_perf_container_.end() &&
         on_ready_delegates_.find(trace_id) != on_ready_delegates_.end() &&
         update_perf_container_.find(trace_id) !=
             update_perf_container_.end() &&
         is_send_first_perf_.find(trace_id) != is_send_first_perf_.end();
}

void PerfCollector::setHydrating(int trace_id) {
  base::UIThread::GetRunner()->PostTask(
      [self = this, trace_id]() { self->is_ssr_hydrate_[trace_id] = true; });
}

PerfCollector::DynamicComponentPerfInfo*
PerfCollector::EnsureDynamicComponentPerfInfo(int trace_id,
                                              const std::string& url) {
  auto iter_pair = dynamic_component_perf_record_.insert(
      {trace_id, std::unordered_map<std::string, DynamicComponentPerfInfo>()});
  auto info_iter_pair =
      iter_pair.first->second.insert({url, DynamicComponentPerfInfo()});
  return &(info_iter_pair.first->second);
}

std::unordered_map<std::string, PerfCollector::DynamicComponentPerfInfo>
PerfCollector::GetDynamicComponentPerf(int trace_id) {
  std::unordered_map<std::string, DynamicComponentPerfInfo> res{};
  auto iter = dynamic_component_perf_record_.find(trace_id);
  if (iter == dynamic_component_perf_record_.end()) {
    return res;
  }
  auto iter_info = iter->second.begin();
  while (iter_info != iter->second.end()) {
    if (iter_info->second.PerfReady()) {
      res[iter_info->first] = std::move(iter_info->second);
      iter_info = iter->second.erase(iter_info);
    } else {
      iter_info++;
    }
  }
  return res;
}

}  // namespace base
}  // namespace lynx
