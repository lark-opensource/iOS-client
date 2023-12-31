// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_TASM_REACT_IOS_PROP_BUNDLE_DARWIN_H_
#define LYNX_TASM_REACT_IOS_PROP_BUNDLE_DARWIN_H_

#import <Foundation/Foundation.h>

#include "tasm/react/prop_bundle.h"

namespace lynx {
namespace tasm {
class PropBundleDarwin : public PropBundle {
 public:
  PropBundleDarwin();
  void SetNullProps(const char* key) override;
  void SetProps(const char* key, uint value) override;
  void SetProps(const char* key, int value) override;
  void SetProps(const char* key, const char* value) override;
  void SetProps(const char* key, bool value) override;
  void SetProps(const char* key, double value) override;
  void SetProps(const char* key, const lepus::Value& value) override;
  void SetEventHandler(const EventHandler& handler) override;
  void ResetEventHandler() override;

  inline NSDictionary* dictionary() { return [propMap copy]; }
  inline NSSet* event_set() { return eventSet; }
  inline NSSet* lepus_event_set() { return lepusEventSet; }

 private:
  void AssembleArray(NSMutableArray* array, const lepus::Value& value);
  void AssembleMap(NSMutableDictionary* map, const char* key, const lepus::Value& value);
  NSMutableDictionary* propMap;
  NSMutableSet* eventSet;
  NSMutableSet* lepusEventSet;
};
}  // namespace tasm
}  // namespace lynx
#endif  // LYNX_TASM_REACT_IOS_PROP_BUNDLE_DARWIN_H_
