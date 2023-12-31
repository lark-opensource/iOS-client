// Copyright 2022 The Lynx Authors. All rights reserved.

#import "LepusApiActorManager.h"
#import "LynxEvent.h"
#import "LynxTemplateData+Converter.h"
#import "LynxTouchEvent.h"

@interface LepusApiActorManager () {
  std::shared_ptr<lynx::tasm::LepusApiActorDarwin> lepus_api_actor_;
}

@end

@implementation LepusApiActorManager

- (instancetype)init {
  if (self = [super init]) {
    lepus_api_actor_ = std::make_shared<lynx::tasm::LepusApiActorDarwin>();
  }
  return self;
}

- (std::shared_ptr<lynx::tasm::LepusApiActorDarwin>)lepusApiActor {
  return lepus_api_actor_;
}

- (void)invokeLepusFunc:(NSDictionary *)data callbackID:(int32_t)callbackID {
  lynx::lepus::Value value = LynxConvertToLepusValue(data);
  lepus_api_actor_->InvokeLepusApiCallback(callbackID,
                                           std::string([data[@"entry_name"] UTF8String]), value);
}

- (bool)sendSyncTouchEvent:(LynxTouchEvent *)event {
  if (lepus_api_actor_ != nullptr) {
    lepus_api_actor_->SendTouchEvent([event.eventName UTF8String], (int)event.targetSign,
                                     event.viewPoint.x, event.viewPoint.y, event.point.x,
                                     event.point.y, event.pagePoint.x, event.pagePoint.y);
  }
  return NO;
}

- (void)sendCustomEvent:(LynxCustomEvent *)event {
  if (lepus_api_actor_ != nullptr) {
    lepus_api_actor_->SendCustomEvent([event.eventName UTF8String], (int)event.targetSign,
                                      LynxConvertToLepusValue(event.params),
                                      [[event paramsName] UTF8String]);
  }
}

- (void)onPseudoStatusChanged:(int32_t)tag
                fromPreStatus:(int32_t)preStatus
              toCurrentStatus:(int32_t)currentStatus {
  if (lepus_api_actor_ != nullptr) {
    lepus_api_actor_->OnPseudoStatusChanged(tag, preStatus, currentStatus);
  }
}

@end
