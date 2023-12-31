// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_HEADLESS_HEADLESS_EVENT_EMITTER_H_
#define LYNX_HEADLESS_HEADLESS_EVENT_EMITTER_H_

#include <set>
#include <tuple>
#include <unordered_map>
#include <utility>

#include "base/blocking_queue.h"
#include "base/log/logging.h"
#include "base/no_destructor.h"
#include "tasm/template_assembler.h"

namespace lynx {
namespace headless {

// a deadly simple implementation of EventEmitter
template <class T, class K>
class EventEmitter {
  using Callback = std::function<bool(T, K, void*)>;
  using QueueMessage = std::tuple<T, K, void*>;

 public:
  static EventEmitter* GetInstance();

  EventEmitter();

  ~EventEmitter() = delete;

  void EmitSync(T channel, K event, void* context = nullptr);

  int Subscribe(T channel, Callback callback, bool once = false);
  void Unsubscribe(int id);

 private:
  std::mutex callbacks_map_mutex_;
  int callback_id_ = 1;
  std::unordered_map<int, std::tuple<T, Callback, bool>> callback_map_;
  base::BlockingQueue<QueueMessage> queue_;
};

template <class T, class K>
EventEmitter<T, K>::EventEmitter() : queue_(1024) {}

template <class T, class K>
EventEmitter<T, K>* EventEmitter<T, K>::GetInstance() {
  static base::NoDestructor<EventEmitter<T, K>> queue;
  return queue.get();
}

template <class T, class K>
void EventEmitter<T, K>::EmitSync(T channel, K event, void* context) {
  std::unique_lock<std::mutex> lock(callbacks_map_mutex_);

  std::set<int> unsubscribed_ids;

  for (auto& [id, callback] : callback_map_) {
    auto [channel_, func_, once] = callback;
    if (channel_ == channel) {
      auto stop = func_(channel, event, context);

      if (once || stop) {
        unsubscribed_ids.insert(id);
      }
    }
  }

  // we dont want to erase inside the loop above
  for (auto id : unsubscribed_ids) {
    callback_map_.erase(id);
  }
}

template <class T, class K>
int EventEmitter<T, K>::Subscribe(T channel, Callback callback, bool once) {
  std::unique_lock<std::mutex> lock(callbacks_map_mutex_);

  auto id = callback_id_++;
  callback_map_[id] = std::make_tuple(channel, std::move(callback), once);
  return id;
}

template <class T, class K>
void EventEmitter<T, K>::Unsubscribe(int id) {
  std::unique_lock<std::mutex> lock(callbacks_map_mutex_);

  callback_map_.erase(id);
}

}  // namespace headless
}  // namespace lynx

#endif  // LYNX_HEADLESS_HEADLESS_EVENT_EMITTER_H_
