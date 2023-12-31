// Copyright 2019 The Lynx Authors. All rights reserved.
#include "tasm/react/ios/prop_bundle_darwin.h"
#include "lepus/array.h"
#include "lepus/table.h"
#include "tasm/value_utils.h"

#import "LynxLog.h"

namespace lynx {
namespace tasm {

PropBundleDarwin::PropBundleDarwin() { propMap = [[NSMutableDictionary alloc] init]; }

void PropBundleDarwin::SetNullProps(const char* key) {
  [propMap setObject:[NSNull alloc] forKey:[[NSString alloc] initWithUTF8String:key]];
}

void PropBundleDarwin::SetProps(const char* key, uint value) {
  [propMap setObject:[NSNumber numberWithUnsignedInt:value]
              forKey:[[NSString alloc] initWithUTF8String:key]];
}

void PropBundleDarwin::SetProps(const char* key, int value) {
  [propMap setObject:[NSNumber numberWithInt:value]
              forKey:[[NSString alloc] initWithUTF8String:key]];
}

void PropBundleDarwin::SetProps(const char* key, const char* value) {
  [propMap setObject:[[NSString alloc] initWithUTF8String:value]
              forKey:[[NSString alloc] initWithUTF8String:key]];
}

void PropBundleDarwin::SetProps(const char* key, bool value) {
  [propMap setObject:[NSNumber numberWithBool:value]
              forKey:[[NSString alloc] initWithUTF8String:key]];
}

void PropBundleDarwin::SetProps(const char* key, double value) {
  [propMap setObject:[NSNumber numberWithDouble:value]
              forKey:[[NSString alloc] initWithUTF8String:key]];
}

void PropBundleDarwin::SetProps(const char* key, const lepus::Value& value) {
  AssembleMap(propMap, key, value);
}

void PropBundleDarwin::SetEventHandler(const EventHandler& handler) {
  if (!handler.name().empty()) {
    NSString* event;
    if (!handler.type().empty()) {
      event = [NSString stringWithFormat:@"%s(%s)", handler.name().c_str(), handler.type().c_str()];
    } else {
      event = [NSString stringWithUTF8String:handler.name().c_str()];
    }
    if (handler.is_js_event()) {
      if (!eventSet) {
        eventSet = [[NSMutableSet alloc] init];
      }
      [eventSet addObject:event];
    } else {
      if (!lepusEventSet) {
        lepusEventSet = [[NSMutableSet alloc] init];
      }
      [lepusEventSet addObject:event];
    }
  }
}

void PropBundleDarwin::ResetEventHandler() {
  [eventSet removeAllObjects];
  [lepusEventSet removeAllObjects];
}

void PropBundleDarwin::AssembleMap(NSMutableDictionary* map, const char* key,
                                   const lepus::Value& value) {
  NSString* oc_key = [[NSString alloc] initWithUTF8String:key];
  if (value.IsNil()) {
    [map setObject:[NSNull alloc] forKey:oc_key];
  } else if (value.IsString()) {
    NSString* oc_str = [[NSString alloc] initWithUTF8String:value.String()->c_str()];
    if (oc_str) {
      [map setObject:oc_str forKey:oc_key];
    } else {
      LLogError(@"Value is not an utf8 string when set props with key %@.", oc_key);
      [map setObject:[NSNull alloc] forKey:oc_key];
    }
  } else if (value.IsNumber()) {
    [map setObject:[NSNumber numberWithDouble:value.Number()] forKey:oc_key];
  } else if (value.IsArrayOrJSArray()) {
    NSMutableArray* oc_array = [[NSMutableArray alloc] init];
    for (int i = 0; i < value.GetLength(); ++i) {
      AssembleArray(oc_array, value.GetProperty(i));
    }
    [map setObject:oc_array forKey:oc_key];
  } else if (value.IsObject()) {
    NSMutableDictionary* oc_map = [[NSMutableDictionary alloc] init];
    ForEachLepusValue(value, [this, &oc_map](const lepus::Value& key, const lepus::Value& value) {
      AssembleMap(oc_map, key.String()->c_str(), value);
    });
    [map setObject:oc_map forKey:oc_key];
  } else if (value.IsBool()) {
    [map setObject:[NSNumber numberWithBool:value.Bool()] forKey:oc_key];
  } else {
    assert(false);
  }
}

void PropBundleDarwin::AssembleArray(NSMutableArray* array, const lepus::Value& value) {
  if (value.IsNil()) {
    [array addObject:[NSNull alloc]];
  } else if (value.IsString()) {
    NSString* oc_str = [[NSString alloc] initWithUTF8String:value.String()->c_str()];
    if (oc_str) {
      [array addObject:oc_str];
    } else {
      LLogError(@"Value is not an utf8 string when set props with array");
      [array addObject:[NSNull alloc]];
    }
  } else if (value.IsNumber()) {
    [array addObject:[NSNumber numberWithDouble:value.Number()]];
  } else if (value.IsArrayOrJSArray()) {
    NSMutableArray* oc_array = [[NSMutableArray alloc] init];
    for (int i = 0; i < value.GetLength(); ++i) {
      AssembleArray(oc_array, value.GetProperty(i));
    }
    [array addObject:oc_array];
  } else if (value.IsObject()) {
    NSMutableDictionary* oc_map = [[NSMutableDictionary alloc] init];
    ForEachLepusValue(value, [this, &oc_map](const lepus::Value& key, const lepus::Value& value) {
      AssembleMap(oc_map, key.String()->c_str(), value);
    });
    [array addObject:oc_map];
  } else if (value.IsBool()) {
    [array addObject:[NSNumber numberWithBool:value.Bool()]];
  } else {
    assert(false);
  }
}

std::unique_ptr<PropBundle> PropBundle::Create() {
  auto pda = std::make_unique<PropBundleDarwin>();
  return std::move(pda);
}

}  // namespace tasm
}  // namespace lynx
