//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHARED_DATA_LYNX_WHITE_BOARD_H_
#define LYNX_SHARED_DATA_LYNX_WHITE_BOARD_H_

#include <memory>
#include <unordered_map>
#include <vector>

#include "lepus/value-inl.h"
#include "lepus/value.h"

namespace lynx {
namespace tasm {

/**
 WhiteBoard is a DataCenter that can be shared and operated by multi LynxViews,
 it is not thread-safe, should be operated only on TASM thread Now. users can
 `set` `get` `registerListener` to whiteboard for sharing data between multiple
 lynxViews.
 */
class WhiteBoard final {
 public:
  WhiteBoard(const WhiteBoard&) = delete;
  WhiteBoard& operator=(const WhiteBoard&) = delete;

  WhiteBoard(WhiteBoard&&) = default;
  WhiteBoard& operator=(WhiteBoard&&) = default;

  void SetSharedData(const lepus::String& key, const lepus::Value& value);
  lepus::Value GetSharedData(const lepus::String& key);

  ~WhiteBoard();

 private:
  using LynxWhiteBoardMap = std::unordered_map<lepus::String, lepus::Value>;

  void TriggerJSDataListener(const lepus::String& key,
                             const lepus::Value& old_value);
  void TriggerLepusDataListener(const lepus::String& key,
                                const lepus::Value& old_value);
  void TriggerClientDataListener(const lepus::String& key,
                                 const lepus::Value& old_value);

  LynxWhiteBoardMap data_center_;
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_SHARED_DATA_LYNX_WHITE_BOARD_H_
