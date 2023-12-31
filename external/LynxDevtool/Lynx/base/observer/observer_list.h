// Copyright 2017 The Lynx Authors. All rights reserved.

#ifndef LYNX_BASE_OBSERVER_OBSERVER_LIST_H_
#define LYNX_BASE_OBSERVER_OBSERVER_LIST_H_

#include <list>

#include "base/base_export.h"

namespace lynx {
namespace base {
class Observer;
class ObserverList {
 public:
  ObserverList() {}

  BASE_EXPORT_FOR_DEVTOOL void AddObserver(Observer* obs);
  BASE_EXPORT_FOR_DEVTOOL void RemoveObserver(Observer* obs);
  void Clear();
  BASE_EXPORT_FOR_DEVTOOL void ForEachObserver();

 private:
  std::list<Observer*> list_;
};
}  // namespace base
}  // namespace lynx

#endif  // LYNX_BASE_OBSERVER_OBSERVER_LIST_H_
