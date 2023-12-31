//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_PERFORMANCE_LYNXTIMINGHANDLER_H_
#define DARWIN_COMMON_LYNX_PERFORMANCE_LYNXTIMINGHANDLER_H_

#import <Foundation/Foundation.h>

#define OC_SETUP_CREATE_LYNX_START @"setup_create_lynx_start"
#define OC_SETUP_CREATE_LYNX_END @"setup_create_lynx_end"
#define OC_SETUP_UI_OPERATION_FLUSH_END @"setup_ui_operation_flush_end"
#define OC_UPDATE_UI_OPERATION_FLUSH_END @"update_ui_operation_flush_end"
#define OC_SETUP_DRAW_END @"setup_draw_end"
#define OC_UPDATE_DRAW_END @"update_draw_end"
#define OC_PREPARE_TEMPLATE_START @"prepare_template_start"
#define OC_PREPARE_TEMPLATE_END @"prepare_template_end"

NS_ASSUME_NONNULL_BEGIN

@class LynxContext;
@class LynxExtraTiming;

/*
 Here will give an example of the lifecycle of LynxTimingHandler.
 1. LynxView init -> LynxTimingHandler init
 2. Mark Timing/Set Timing
    During the process of setup or update, the timing info will be stored in setupTiming
    or updateTimings Dictionary.
               /--> isSetupTiming  -> processSetupTiming   -\
    setTiming ----> isUpdateTiming -> processUpdateTiming  ----> dispatchAttributeTimingIfNeeded
               \--> setExtraTimingIfNeeded                 -/
 3. Dispatch Timing
    Every time after timing is set, we need to check whether the timing info should be dispatched.
    a. setup:
       processSetupTiming   ->  dispatchSetupTimingIfNeeded: isSetupReady  ?-> dispatchSetupTiming
       -> calculateBySetup  ->  dispatch
    b. update:
       processUpdateTiming  ->  dispatchUpdateTimingIfNeeded isUpdateReady ?-> dispatchUpdateTiming
       -> calculateByUpdate ->  dispatch -> clearUpdateTimingAfterDispatch
 4. Cleaning
    After clearAllTimingInfo, the setupTiming, updateTimings and metrics would be empty.
 */

@interface LynxTimingHandler : NSObject

@property(nonatomic, weak) LynxContext *lynxContext;
@property(nonatomic, strong, readonly) LynxExtraTiming *extraTiming;
@property(nonatomic, copy) NSString *url;
@property(nonatomic, assign) BOOL enableJSRuntime;

- (NSDictionary *)timingInfo;

- (instancetype)initWithThreadStrategy:(NSInteger)threadStrategy;

- (void)markTiming:(NSString *)key updateFlag:(NSString *_Nullable)flag;

- (void)setTiming:(uint64_t)timestamp key:(NSString *)key updateFlag:(NSString *_Nullable)flag;

- (void)addAttributeTimingFlag:(NSString *)flag;

- (void)clearAllTimingInfo;

- (void)setExtraTiming:(LynxExtraTiming *)extraTiming;

- (void)setSsrTimingInfo:(NSDictionary *)info;

@end

NS_ASSUME_NONNULL_END

#endif  // DARWIN_COMMON_LYNX_PERFORMANCE_LYNXTIMINGHANDLER_H_
