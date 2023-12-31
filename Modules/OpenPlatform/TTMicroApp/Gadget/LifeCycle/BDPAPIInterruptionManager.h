//
//  BDPAPIInterruptionManager.h
//  Timor
//
//  Created by liuxiangxin on 2019/5/23.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/BDPJSBridgeProtocol.h>



NS_ASSUME_NONNULL_BEGIN

@interface BDPAPIInterruptionManager : NSObject

+ (instancetype)sharedManager;

//是否正在中断
- (BOOL)shouldInterruptionForAppUniqueID:(BDPUniqueID *)uniqueID;
- (BOOL)shouldInterruptionForEngine:(id<BDPEngineProtocol>)engine;
- (BOOL)shouldInterruptionV2ForAppUniqueID:(BDPUniqueID *)uniqueID;
- (BOOL)shouldInterruptionV2ForEngine:(id<BDPEngineProtocol>)engine;
- (void)clearInterruptionStatusForApp:(BDPUniqueID *)uniqueID;
- (void)beginInvokeEvent:(NSString *)event uniqueID:(BDPUniqueID *)uniqueID;
- (void)completeInvokeEvent:(NSString *)event uniqueID:(BDPUniqueID *)uniqueID;
- (void)pauseInterruptionForUniqueID:(BDPUniqueID *)uniqueID;
- (void)resumeInterruptionForUniqueID:(BDPUniqueID *)uniqueID;

@end

NS_ASSUME_NONNULL_END
