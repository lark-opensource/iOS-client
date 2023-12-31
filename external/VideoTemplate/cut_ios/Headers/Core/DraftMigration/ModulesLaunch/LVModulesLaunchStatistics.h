//
//  LVModulesLaunchStatistics.h
//  Pods
//
//  Created by kevin gao on 11/3/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class LVModulesLaunchDraft;

@protocol LVModulesLaunchStatisticsDeleagte <NSObject>

- (void)launchDraft:(NSString*)draftId;

- (void)startLaunch:(NSString*)draftId withKey:(NSString*)key;

- (void)endLaunch:(NSString*)draftId withKey:(NSString*)key;

//导出草稿启动数据
- (LVModulesLaunchDraft* _Nullable)exportDraftData:(NSString*)draftId;

- (void)clear:(NSString*)draftId;;

- (void)clear;

@end

/*
 统计草稿启动时长
 */
@interface LVModulesLaunchStatistics : NSObject <LVModulesLaunchStatisticsDeleagte>

@end

NS_ASSUME_NONNULL_END
