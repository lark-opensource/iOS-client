// Copyright 2021 The Lynx Authors. All rights reserved.

#include "shell/lynx_card_cache_data_manager.h"

#include <utility>

#include "lepus/table.h"

namespace lynx {
namespace shell {

void LynxCardCacheDataManager::AddCardCacheData(const lepus::Value& data,
                                                const CacheDataType type) {
  std::lock_guard<std::mutex> lock(card_cache_data_mutex_);
  if (type == CacheDataType::RESET) {
    // when reset, cached data before is unneeded, can be cleared.
    card_cache_data_.clear();
  }
  card_cache_data_.emplace_back(CacheDataOp(data, type));
}

CacheDataOpVector LynxCardCacheDataManager::GetCardCacheData() {
  std::lock_guard<std::mutex> lock(card_cache_data_mutex_);
  return card_cache_data_;
}

CacheDataOpVector LynxCardCacheDataManager::ObtainCardCacheData() {
  std::lock_guard<std::mutex> lock(card_cache_data_mutex_);
  return std::move(card_cache_data_);
}

}  // namespace shell
}  // namespace lynx
