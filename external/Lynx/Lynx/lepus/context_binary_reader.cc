// Copyright 2019 The Lynx Authors. All rights reserved.

#include "lepus/context_binary_reader.h"

#include <tasm/config.h>

#include "config/config.h"
#include "lepus/array.h"
#include "lepus/function.h"
#include "lepus/lepus_date.h"
#include "lepus/quick_context.h"
#include "lepus/table.h"
#include "lepus/value-inl.h"
#include "lepus/vm_context.h"

namespace lynx {
namespace lepus {

bool ContextBinaryReader::Decode() {
  if (context_->IsLepusNGContext()) {
    // read quickjs bytecode
    DECODE_U64LEB(data_len);
    std::vector<uint8_t> data;
    data.resize(static_cast<std::size_t>(data_len + 1));
    ERROR_UNLESS(ReadData(data.data(), static_cast<int>(data_len)));
    return QuickContext::Cast(context_)->DeSerialize(data.data(), data_len);
  }

#if !ENABLE_JUST_LEPUSNG
  VMContext::Cast(context_)->SetSdkVersion(version_);
  std::unordered_map<lepus::String, lepus::Value> lepus_root_global_{};
  ERROR_UNLESS(DeserializeGlobal(lepus_root_global_));
  for (auto& pair : lepus_root_global_) {
    VMContext::Cast(context_)->global_.Add(pair.first, pair.second);
  }

  base::scoped_refptr<Function> parent =
      base::make_scoped_refptr<Function>(nullptr);
  DECODE_FUNCTION(parent, root_function);
  VMContext::Cast(context_)->root_function_ = root_function;
  std::unordered_map<lepus::String, long> lepus_top_variables_{};
  ERROR_UNLESS(DeserializeTopVariables(lepus_top_variables_));
  VMContext::Cast(context_)->top_level_variables_.insert(
      std::make_move_iterator(lepus_top_variables_.begin()),
      std::make_move_iterator(lepus_top_variables_.end()));
  return true;
#else
  error_message_ = "lepusng just can decode lepusng template.lepus";
  LOGE("lepusng just can decode lepusng template.lepus");
  return false;
#endif
}

}  // namespace lepus
}  // namespace lynx
