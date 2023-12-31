//  Copyright 2020 The Vmsdk Authors. All rights reserved.
//
//  thread_impl_ios.h
//  Vmsdk
//
//  Created by wangheyang on 2020/6/13.

#ifndef VMSDK_BASE_THREADING_THREAD_IMPL_IOS_H
#define VMSDK_BASE_THREADING_THREAD_IMPL_IOS_H

#include "basic/threading/thread_impl.h"

namespace vmsdk {
namespace general {

class ThreadImplIOS : public ThreadImpl {
 public:
  explicit ThreadImplIOS(MessageLoop::MESSAGE_LOOP_TYPE type,
                         const ThreadInfo &name);

  virtual ~ThreadImplIOS();

  void Start() override;

  void Run() override;

  void Join() override;

 protected:
  bool is_ui_;
};

}  // namespace general
}  // namespace vmsdk

#endif /* VMSDK_BASE_THREADING_THREAD_IMPL_IOS_H */
