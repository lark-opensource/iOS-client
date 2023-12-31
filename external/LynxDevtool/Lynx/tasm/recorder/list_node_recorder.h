// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_RECORDER_LIST_NODE_RECORDER_H_
#define LYNX_TASM_RECORDER_LIST_NODE_RECORDER_H_

#include "tasm/recorder/ark_base_recorder.h"

namespace lynx {
namespace tasm {
namespace recorder {

class ListNodeRecorder {
 public:
  static constexpr const char* kParamBaseId = "base_id";
  static constexpr const char* kParamImplId = "impl_id";
  static constexpr const char* kParamIndex = "index";
  static constexpr const char* kParamOperationId = "operation_id";
  static constexpr const char* kParamRow = "row";
  static constexpr const char* kParamSign = "sign";

  static constexpr const char* kFuncRemoveComponent = "removeComponent";
  static constexpr const char* kFuncRenderComponentAtIndex =
      "renderComponentAtIndex";
  static constexpr const char* kFuncUpdateComponent = "updateComponent";

  // List Node Func
  static void RecordRemoveComponent(const uint32_t sign, const int32_t impl_id,
                                    const int32_t base_impl_id,
                                    int64_t record_id = 0);
  static void RecordRenderComponentAtIndex(const uint32_t index,
                                           const int64_t operation_id,
                                           const int32_t impl_id,
                                           const int32_t base_impl_id,
                                           int64_t record_id = 0);
  static void RecordUpdateComponent(const uint32_t sign, const uint32_t row,
                                    const int64_t operation_id,
                                    const int32_t impl_id,
                                    const int32_t base_impl_id,
                                    int64_t record_id = 0);
};

}  // namespace recorder
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_RECORDER_LIST_NODE_RECORDER_H_
