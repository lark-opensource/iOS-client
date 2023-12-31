// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_LEPUSAPIACTORMANAGER_H_
#define DARWIN_COMMON_LYNX_LEPUSAPIACTORMANAGER_H_

#import <Foundation/Foundation.h>
#include "tasm/lepus_api_actor/ios/lepus_api_actor_darwin.h"

NS_ASSUME_NONNULL_BEGIN

@class LynxTouchEvent;
@class LynxCustomEvent;

@interface LepusApiActorManager : NSObject

/**
 * Get the shared pointer of LepusApiActorDarwin
 */
- (std::shared_ptr<lynx::tasm::LepusApiActorDarwin>)lepusApiActor;
/**
 * Invoke lepus function
 *  @param data function params
 *  @param callbackID the key of invoke task
 */
- (void)invokeLepusFunc:(NSDictionary*)data callbackID:(int32_t)callbackID;
/**
 * Synchronously send touch event to runtime
 *  @param event touch param
 */
- (bool)sendSyncTouchEvent:(LynxTouchEvent*)event;
/**
 * Synchronously send custom event to runtime
 *  @param event custom event param
 */
- (void)sendCustomEvent:(LynxCustomEvent*)event;
/**
 * Notify css pseudo status change
 *  @param tag pseudo tag
 *  @param preStatus previous pseudo status
 *  @param currentStatus current pseudo status
 */
- (void)onPseudoStatusChanged:(int32_t)tag
                fromPreStatus:(int32_t)preStatus
              toCurrentStatus:(int32_t)currentStatus;

@end

NS_ASSUME_NONNULL_END

#endif  // DARWIN_COMMON_LYNX_LEPUSAPIACTORMANAGER_H_
