// Copyright 2019 The Lynx Authors. All rights reserved.

#include "tasm/lynx_view_data_manager.h"

#include <base/debug/lynx_assert.h>
#include <base/log/logging.h>

#include "lepus/json_parser.h"
#include "lepus/lepus_global.h"

namespace lynx {
namespace tasm {

lepus::Value* LynxViewDataManager::ParseData(const char* data) {
  lepus_value* value = new lepus_value;
  *value = lepus::jsonValueTolepusValue(data);
  if (!value->IsNil() && !value->IsTable()) {
    if (data != nullptr || strlen(data) != 0) {
      LynxInfo(LYNX_ERROR_CODE_PARSE_DATA, "ParseData error, data is:%s", data);
    }
    return nullptr;
  }
  return value;
}

// TODO
lepus::Value* LynxViewDataManager::ParseData(rapid_value&& data) {
  lepus_value* value = new lepus_value;
  *value = lepus::jsonValueTolepusValue(data);
  if (!value->IsNil() && !value->IsTable()) {
    LynxInfo(LYNX_ERROR_CODE_PARSE_DATA, "ParseData error, data is not table");
    return nullptr;
  }
  return value;
}

bool LynxViewDataManager::UpdateData(lepus::Value* target,
                                     lepus::Value* value) {
  if (!target->IsTable()) {
    target->SetTable(lepus::Dictionary::Create());
  }
  auto data_dict = target->Table();

  if (!value->IsTable()) {
    return false;
  }
  auto dict = value->Table();
  for (auto iter = dict->begin(); iter != dict->end(); ++iter) {
    const lepus::String key = iter->first;
    data_dict->SetValue(key, dict->GetValue(key));
  }
  return true;
}

void LynxViewDataManager::ReleaseData(lepus::Value* obj) {
  if (obj != nullptr) {
    delete obj;
  }
}

}  // namespace tasm
}  // namespace lynx
