// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_LYNX_CARD_CACHE_DATA_MANAGER_H_
#define LYNX_SHELL_LYNX_CARD_CACHE_DATA_MANAGER_H_

#include <atomic>
#include <mutex>
#include <vector>

#include "lepus/value.h"
#include "shell/lynx_card_cache_data_op.h"

namespace lynx {

namespace shell {
/*
 * use for UpdateData, logic is same with 1.4, tricky
 * shared by all threads, ensure thread safe
 */
using CacheDataOpVector = std::vector<CacheDataOp>;

class LynxCardCacheDataManager {
 public:
  LynxCardCacheDataManager() = default;
  ~LynxCardCacheDataManager() = default;

  LynxCardCacheDataManager(const LynxCardCacheDataManager&) = delete;
  LynxCardCacheDataManager& operator=(const LynxCardCacheDataManager&) = delete;
  LynxCardCacheDataManager(LynxCardCacheDataManager&&) = delete;
  LynxCardCacheDataManager& operator=(LynxCardCacheDataManager&&) = delete;

  void AddCardCacheData(const lepus::Value& data, const CacheDataType type);

  CacheDataOpVector GetCardCacheData();
  CacheDataOpVector ObtainCardCacheData();

  void IncrementTaskCount() { ++update_data_tasks_count_; }

  void DecrementTaskCount() { --update_data_tasks_count_; }

  int32_t GetTaskCount() { return update_data_tasks_count_; }

 private:
  /*
   * use for update data, protect by cached_page_data_mutex_.
   * lepus value not thread safe, use const lepus value.
   */
  CacheDataOpVector card_cache_data_;

  // count of update data task
  std::atomic<int32_t> update_data_tasks_count_{0};

  std::mutex card_cache_data_mutex_;
};

}  // namespace shell
}  // namespace lynx

#endif  // LYNX_SHELL_LYNX_CARD_CACHE_DATA_MANAGER_H_
