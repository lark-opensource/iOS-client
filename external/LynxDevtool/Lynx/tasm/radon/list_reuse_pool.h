// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_RADON_LIST_REUSE_POOL_H_
#define LYNX_TASM_RADON_LIST_REUSE_POOL_H_

#include <unordered_map>

#include "base/lynx_ordered_map.h"
#include "lepus/lepus_string.h"

namespace lynx {
namespace tasm {

class RadonComponent;

using ListKeyComponentMap = std::unordered_map<lepus::String, RadonComponent*>;

class ListReusePool {
 public:
  struct Action {
    enum class Type : int32_t {
      CREATE,
      REUSE,
      UPDATE,
    };
    Type type_;
    lepus::String key_to_reuse_;
  };
  void Enqueue(const lepus::String& item_key,
               const lepus::String& reuse_identifier);

  Action Dequeue(const lepus::String& item_key,
                 const lepus::String& reuse_identifier,
                 RadonComponent* component);

  void InsertIntoListKeyComponentMap(const lepus::String& item_key,
                                     RadonComponent* val);
  RadonComponent* GetComponentFromListKeyComponentMap(
      const lepus::String& item_key);

  void Remove(const lepus::String& item_key,
              const lepus::String& reuse_identifier);

 private:
  using Pool =
      std::unordered_map<lepus::String,
                         lynx::lynx_ordered_map<lepus::String, lepus::String>>;
  // This pool is a map from ReuseIdentifier to ItemKey LinkedHashMap.
  // The LinkedHashMap (actually it's a set) includes all of the item_key_
  // whose component can be reused.
  Pool pool_{};

  // this map includes all of the component which has been created before.
  ListKeyComponentMap key_component_map_;

  void Invalidate(const lepus::String& reuse_identifier,
                  const lepus::String& item_key);
};
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_RADON_LIST_REUSE_POOL_H_
