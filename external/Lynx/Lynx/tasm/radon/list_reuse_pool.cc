// Copyright 2021 The Lynx Authors. All rights reserved.

#include "tasm/radon/list_reuse_pool.h"

#include "tasm/radon/radon_component.h"

namespace lynx {
namespace tasm {

void ListReusePool::Enqueue(const lepus::String& item_key,
                            const lepus::String& reuse_identifier) {
  pool_[reuse_identifier][item_key] = lepus::String();
}

ListReusePool::Action ListReusePool::Dequeue(
    const lepus::String& item_key, const lepus::String& reuse_identifier,
    RadonComponent* component) {
  auto has_element = component->element() != nullptr;
  if (has_element) {
    Invalidate(reuse_identifier, item_key);
    return Action{Action::Type::UPDATE, ""};
  }
  // `set_` does not contains the specified `item_key`.
  // We try to find another key: `key_to_resue` to reuse.
  if (pool_.count(reuse_identifier) && pool_[reuse_identifier].size() > 0) {
    lepus::String key_to_reuse = pool_[reuse_identifier].front().first;
    Invalidate(reuse_identifier, key_to_reuse);
    return Action{Action::Type::REUSE, key_to_reuse};
  }

  // pool_ is empty, nothing to reuse, return CREATE
  return Action{Action::Type::CREATE, ""};
}

RadonComponent* ListReusePool::GetComponentFromListKeyComponentMap(
    const lepus::String& item_key) {
  auto it = key_component_map_.find(item_key);
  if (it != key_component_map_.end()) {
    return it->second;
  }
  return nullptr;
}

void ListReusePool::InsertIntoListKeyComponentMap(const lepus::String& item_key,
                                                  RadonComponent* val) {
  key_component_map_[item_key] = val;
}

void ListReusePool::Invalidate(const lepus::String& reuse_identifier,
                               const lepus::String& item_key) {
  if (pool_.count(reuse_identifier)) {
    pool_[reuse_identifier].erase(item_key);
  }
}

void ListReusePool::Remove(const lepus::String& item_key,
                           const lepus::String& reuse_identifier) {
  RadonComponent* component = GetComponentFromListKeyComponentMap(item_key);
  if (component != nullptr) {
    auto has_element = component->element();
    if (has_element) {
      // the element could be reused, so, just mark need_remove_after_reused_ =
      // true
      component->list_need_remove_after_reused_ = true;
    } else {
      // remove component immediately
      if (pool_.count(reuse_identifier)) {
        pool_[reuse_identifier].erase(item_key);
      }
      key_component_map_.erase(item_key);
      // mark component to be removed, so that it will not be added to this new
      // list_node
      component->list_need_remove_ = true;
    }
  }
}

}  // namespace tasm
}  // namespace lynx
