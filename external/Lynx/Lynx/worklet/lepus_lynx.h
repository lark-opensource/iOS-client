// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_WORKLET_LEPUS_LYNX_H_
#define LYNX_WORKLET_LEPUS_LYNX_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#include "base/thread/timed_task.h"
#include "jsbridge/napi/base.h"
#include "worklet/lepus_element.h"
#include "worklet/lepus_raf_handler.h"

namespace lynx {

namespace tasm {
class TemplateAssembler;
}  // namespace tasm

namespace worklet {

using piper::BridgeBase;
using piper::ImplBase;

class NapiFrameCallback;
class NapiFuncCallback;

class LepusLynx : public ImplBase {
 public:
  static LepusLynx* Create(Napi::Env env, const std::string& entry_name,
                           tasm::TemplateAssembler* assembler) {
    return new LepusLynx(env, entry_name, assembler);
  }
  LepusLynx(const LepusLynx&) = delete;
  virtual ~LepusLynx() = default;

  uint32_t SetTimeout(std::unique_ptr<NapiFuncCallback> callback,
                      int64_t delay);
  uint32_t SetInterval(std::unique_ptr<NapiFuncCallback> callback,
                       int64_t delay);
  void ClearTimeout(uint32_t task_id);
  void ClearInterval(uint32_t task_id);

  void TriggerLepusBridge(const std::string& method_name,
                          Napi::Object method_detail,
                          std::unique_ptr<NapiFuncCallback> callback);
  Napi::Value TriggerLepusBridgeSync(const std::string& method_name,
                                     Napi::Object method_detail);
  void InvokeLepusBridge(const int32_t callback_id, const lepus::Value& data);

 private:
  LepusLynx(Napi::Env env, const std::string& entry_name,
            tasm::TemplateAssembler* assembler);
  void EnsureTimeTaskInvoker();
  void RemoveTimedTask(uint32_t task_id);

  Napi::Env env_;
  std::string entry_name_;
  tasm::TemplateAssembler* tasm_;
  std::unique_ptr<LepusApiHandler> task_handler_;
  std::unique_ptr<base::TimedTaskManager> timer_;

  std::unordered_map<uint32_t, int64_t> task_to_callback_map_{};
};
}  // namespace worklet
}  // namespace lynx

#endif  // LYNX_WORKLET_LEPUS_LYNX_H_
