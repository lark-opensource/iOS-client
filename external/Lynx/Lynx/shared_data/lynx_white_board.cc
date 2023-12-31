//  Copyright 2022 The Lynx Authors. All rights reserved.

#include "lynx_white_board.h"

#include <algorithm>

namespace lynx {
namespace tasm {

void WhiteBoard::SetSharedData(const lepus::String &key,
                               const lepus::Value &value) {
  auto iter = data_center_.find(key);
  auto old_val = lepus::Value();
  if (iter != data_center_.end()) {
    old_val = iter->second;
  }
  data_center_[key] = value;
  TriggerLepusDataListener(key, old_val);
  TriggerClientDataListener(key, old_val);
  TriggerJSDataListener(key, old_val);
}

lepus::Value WhiteBoard::GetSharedData(const lepus::String &key) {
  auto iter = data_center_.find(key);
  if (iter != data_center_.end()) {
    return iter->second;
  }
  return lepus::Value();
}

void WhiteBoard::TriggerJSDataListener(const lepus::String &key,
                                       const lepus::Value &old_value) {
  // TODO(nihao.royal). implement this later.
}

void WhiteBoard::TriggerLepusDataListener(const lepus::String &key,
                                          const lepus::Value &old_value) {
  // TODO(nihao.royal). implement this later
}

void WhiteBoard::TriggerClientDataListener(const lepus::String &key,
                                           const lepus::Value &old_value) {
  // TODO(nihao.royal). implement this later
}

WhiteBoard::~WhiteBoard() { LOGE("whiteboard destructed~ "); }

}  // namespace tasm
}  // namespace lynx
