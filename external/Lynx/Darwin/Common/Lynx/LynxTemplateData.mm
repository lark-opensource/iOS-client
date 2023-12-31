// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxTemplateData.h"
#import <sys/utsname.h>
#import "LynxDefines.h"
#import "LynxTemplateData+Converter.h"

#include "LynxLog.h"
#include "lepus/array.h"
#include "lepus/json_parser.h"
#include "tasm/lynx_view_data_manager.h"
#include "tasm/react/ios/lepus_value_converter.h"

using namespace lynx::tasm;
using namespace lynx::lepus;

@implementation LynxTemplateData {
  std::shared_ptr<lynx::lepus::Value> value_;
  NSString* _processerName;
  BOOL _readOnly;
}

- (instancetype)init {
  if (self = [super init]) {
    _processerName = nil;
    _readOnly = false;
  }
  return self;
}

lepus_value LynxConvertToLepusValue(id data) {
  return RecursiveLynxConvertToLepusValue(data, [[NSMutableSet alloc] init]);
}

lepus_value RecursiveLynxConvertToLepusValue(id data, NSMutableSet* allObjects) {
  // Will convert @YES and @NO to lepus number 1 and 0.
  // It's hard to correct this behavior due to some production code rely on it.
  if ([data isKindOfClass:[NSNumber class]]) {
    if (strcmp([data objCType], @encode(BOOL)) == 0) {
      return lepus_value([data boolValue]);
    } else if (strcmp([data objCType], @encode(char)) == 0 ||
               strcmp([data objCType], @encode(unsigned char)) == 0) {
      return lepus_value([data charValue]);
    } else if (strcmp([data objCType], @encode(int)) == 0 ||
               strcmp([data objCType], @encode(short)) == 0 ||
               strcmp([data objCType], @encode(unsigned int)) == 0 ||
               strcmp([data objCType], @encode(unsigned short)) == 0) {
      return lepus_value([data intValue]);
    } else if (strcmp([data objCType], @encode(long)) == 0 ||
               strcmp([data objCType], @encode(long long)) == 0 ||
               strcmp([data objCType], @encode(unsigned long)) == 0 ||
               strcmp([data objCType], @encode(unsigned long long)) == 0) {
      return lepus_value([data longLongValue]);
    } else if (strcmp([data objCType], @encode(float)) == 0 ||
               strcmp([data objCType], @encode(double)) == 0) {
      return lepus_value([data doubleValue]);
    } else {
      return lepus_value([data doubleValue]);
    }
  } else if ([data isKindOfClass:[NSString class]]) {
    lynx::base::scoped_refptr<StringImpl> pstr = lynx::lepus::StringImpl::Create([data UTF8String]);
    return lepus_value(pstr);
  } else if ([data isKindOfClass:[NSArray class]]) {
    if ([allObjects containsObject:data]) {
      LLogError(@"LynxConvertToLepusValue has cycle array!");
      return lepus_value();
    }
    [allObjects addObject:data];
    lynx::base::scoped_refptr<CArray> ary = CArray::Create();
    [data enumerateObjectsUsingBlock:^(id _Nonnull value, NSUInteger idx, BOOL* _Nonnull stop) {
      ary->push_back(RecursiveLynxConvertToLepusValue(value, allObjects));
    }];
    [allObjects removeObject:data];
    return lepus_value(ary);

  } else if ([data isKindOfClass:[NSDictionary class]]) {
    if ([allObjects containsObject:data]) {
      LLogError(@"LynxConvertToLepusValue has cycle dict!");
      return lepus_value();
    }
    [allObjects addObject:data];
    lynx::base::scoped_refptr<Dictionary> dict = Dictionary::Create();
    [data enumerateKeysAndObjectsUsingBlock:^(NSString* _Nonnull key, id _Nonnull value,
                                              BOOL* _Nonnull stop) {
      dict->SetValue([key UTF8String], RecursiveLynxConvertToLepusValue(value, allObjects));
    }];
    [allObjects removeObject:data];
    return lepus_value(dict);
  } else if ([data isKindOfClass:[NSData class]]) {
    size_t length = [data length];
    std::unique_ptr<uint8_t[]> buffer;
    if (length > 0) {
      buffer = std::make_unique<uint8_t[]>(length);
    }
    if (buffer && length > 0) {
      [data getBytes:buffer.get() length:length];
    }
    return lepus_value(ByteArray::Create(std::move(buffer), length));
  } else if ([data isKindOfClass:[LynxTemplateData class]]) {
    return *LynxGetLepusValueFromTemplateData(data);
  }
  return lepus_value();
}

lynx::lepus::Value* LynxGetLepusValueFromTemplateData(LynxTemplateData* data) {
  if (data == nil) return nullptr;
  return data->value_.get();
}

- (instancetype)initWithDictionary:(NSDictionary*)dictionary {
  self = [self init];
  if (self) {
    value_ = std::make_shared<lynx::lepus::Value>(lynx::lepus::Dictionary::Create());
    if (dictionary) {
      [self updateWithDictionary:dictionary];
    }
  }
  return self;
}

- (void)updateWithTemplateData:(LynxTemplateData*)value {
  [self updateWithLepusValue:LynxGetLepusValueFromTemplateData(value)];
}

- (void)updateWithLepusValue:(lynx::lepus::Value*)value {
  if (_readOnly) {
    NSLog(@"can not update readOnly TemplateData");
    return;
  }
  auto baseValue = value_.get();
  if (baseValue->IsTable() && baseValue->Table()->IsConst()) {
    value_ = std::make_shared<lynx::lepus::Value>(lynx::lepus::Value::Clone(*baseValue));
    baseValue = value_.get();
  }
  if (value->IsTable()) {
    lynx::lepus::Dictionary* dict = value->Table().Get();
    for (auto iter = dict->begin(); iter != dict->end(); iter++) {
      if (iter->second.IsTable()) {
        lynx::lepus::Value oldValue = baseValue->GetProperty(iter->first);
        if (oldValue.IsTable()) {
          if (oldValue.Table()->IsConst()) {
            oldValue = lynx::lepus::Value::Clone(oldValue);
            baseValue->SetProperty(iter->first, oldValue);
          }
          lynx::lepus::Dictionary* table = iter->second.Table().Get();
          for (auto it = table->begin(); it != table->end(); it++) {
            oldValue.SetProperty(it->first, it->second);
          }
          continue;
        }
      }
      baseValue->SetProperty(iter->first, iter->second);
    }
  }
}

- (instancetype)initWithJson:(NSString*)json {
  NSData* data = [json dataUsingEncoding:NSUTF8StringEncoding];
  NSError* error;
  NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:data
                                                       options:NSJSONReadingMutableContainers
                                                         error:&error];
  return [self initWithDictionary:dict];
}

- (BOOL)checkIsLegalData {
  lynx::lepus::Value* value = value_.get();
  if (value == nullptr || value->IsNil() ||
      (value->IsTable() && value->Table().Get()->size() == 0) ||
      (value->IsArray() && value->Array().Get()->size() == 0)) {
    return false;
  }
  return true;
}

- (void)updateWithJson:(NSString*)json {
  NSData* data = [json dataUsingEncoding:NSUTF8StringEncoding];
  NSError* error;
  NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:data
                                                       options:NSJSONReadingMutableContainers
                                                         error:&error];
  [self updateWithDictionary:dict];
}

- (void)updateWithDictionary:(NSDictionary*)dict {
  lepus_value value = LynxConvertToLepusValue(dict);
  [self updateWithLepusValue:&value];
}

- (void)setObject:(id)object withKey:(NSString*)key {
  [self updateObject:object forKey:key];
}

- (void)updateObject:(id)object forKey:(NSString*)key {
  if (_readOnly) {
    NSLog(@"can not update readOnly TemplateData");
    return;
  }
  lynx::base::scoped_refptr<StringImpl> pstr = lynx::lepus::StringImpl::Create([key UTF8String]);
  lepus_value value = LynxConvertToLepusValue(object);
  value_->Table()->SetValue(lynx::lepus::String(pstr), value);
}

- (void)updateBool:(BOOL)value forKey:(NSString*)key {
  if (_readOnly) {
    NSLog(@"can not update readOnly TemplateData");
    return;
  }
  lynx::base::scoped_refptr<StringImpl> pstr = lynx::lepus::StringImpl::Create([key UTF8String]);
  value_->Table()->SetValue(lynx::lepus::String(pstr), lynx::lepus::Value((bool)value));
}

- (void)updateInteger:(NSInteger)value forKey:(NSString*)key {
  if (_readOnly) {
    NSLog(@"can not update readOnly TemplateData");
    return;
  }
  value_->Table()->SetValue(lynx::lepus::String([key UTF8String]), lepus_value((int64_t)value));
}

- (void)updateDouble:(CGFloat)value forKey:(NSString*)key {
  if (_readOnly) {
    NSLog(@"can not update readOnly TemplateData");
    return;
  }
  value_->Table()->SetValue(lynx::lepus::String([key UTF8String]), lepus_value((double)value));
}

- (LynxTemplateData*)deepClone {
  auto base_value = *LynxGetLepusValueFromTemplateData(self);
  LynxTemplateData* data = [[LynxTemplateData alloc] init];
  data->value_ = std::make_shared<lynx::lepus::Value>(lynx::lepus::Value::Clone(base_value));
  data->_processerName = self.processorName;
  data->_readOnly = self.isReadOnly;
  return data;
}

- (void)markState:(NSString*)name {
  _processerName = name;
}

- (NSString*)processorName {
  return _processerName;
}

- (void)markReadOnly {
  _readOnly = true;
}

- (BOOL)isReadOnly {
  return _readOnly;
}

- (NSDictionary*)dictionary {
  id dict = convertLepusValueToNSObject(*value_);

  if ([dict isKindOfClass:[NSDictionary class]]) {
    return dict;
  } else {
    return nil;
  }
}

std::shared_ptr<lynx::tasm::TemplateData> ConvertLynxTemplateDataToTemplateData(
    LynxTemplateData* data) {
  return std::make_shared<lynx::tasm::TemplateData>(
      *LynxGetLepusValueFromTemplateData(data), data.isReadOnly,
      data.processorName ? data.processorName.UTF8String : "");
}

@end
