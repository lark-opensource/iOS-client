//
//  HMDSessionTracker.h
//  Heimdallr
//
//  Created by fengyadong on 2018/2/8.
//

#import <Foundation/Foundation.h>
#import "HMDApplicationSession.h"
#import "HMDStoreCondition.h"

extern NSString * _Nullable const kHMDApplicationSessionIDDidChange;

@class HMDCleanupConfig;

@interface HMDSessionTracker : NSObject

+ (instancetype _Nonnull)sharedInstance;
+ (HMDApplicationSession * _Nullable)currentSession;
+ (NSDictionary * _Nullable)latestSessionDicAtLastLaunch;
- (NSString * _Nullable)eternalSessionID;
- (NSString * _Nullable)lastTimeEternalSessionID;

+ (HMDApplicationSession * _Nullable)latestSessionAtLastLaunch DEPRECATED_MSG_ATTRIBUTE("use latestSessionDicAtLastLaunch instead");
- (NSArray <HMDApplicationSession*>* _Nullable)getSessionsInAscendingOrder DEPRECATED_MSG_ATTRIBUTE("deprecated. The new version does not need to invoke it");
- (void)cleanupWithAndConditons:(NSArray<HMDStoreCondition *> * _Nullable)andCondtions DEPRECATED_MSG_ATTRIBUTE("deprecated. The new version does not need to invoke it");
- (void)cleanupWithAndConditions:(NSArray<HMDStoreCondition *> * _Nullable)andCondtions DEPRECATED_MSG_ATTRIBUTE("deprecated. The new version does not need to invoke it.");


/// 计算过期的session的时间
/// @param maxCount session的最大数量
/// @param interval 更新过期时间的间隔
/// @param complete 计算出来的过期时间
- (void)outdateSessionTimestampWithMaxCount:(NSInteger)maxCount interval:(NSTimeInterval)interval complete:(void(^ _Nullable)(NSTimeInterval))complete DEPRECATED_MSG_ATTRIBUTE("deprecated. The new version does not need to invoke it.");

@end
