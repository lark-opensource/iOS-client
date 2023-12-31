//
//  BDAutoTrackSessionHandler.h
//  Applog
//
//  Created by bob on 2019/1/18.
//

#import <Foundation/Foundation.h>
#import "BDCommonDefine.h"

NS_ASSUME_NONNULL_BEGIN

/// 管理Session
@interface BDAutoTrackSessionHandler : NSObject

@property (atomic, copy, readonly) NSString *sessionID;
@property (nonatomic, assign) BDAutoTrackLaunchFrom launchFrom;
@property (nonatomic, copy, readonly) NSArray *previousLaunchs;
@property (nonatomic, copy, readonly) NSArray *previousTerminates;

/// 标记是否要把启动事件标记为被动启动。初始值同launchedPassively，应用进入前台时无条件置为NO。
@property (nonatomic) BOOL shouldMarkLaunchedPassively;

+ (instancetype)sharedHandler;

/// 返回调用之前是否 sessionStart
- (BOOL)checkAndStartSession;

/// for unit test
- (void)startSessionWithIDChange:(BOOL)change;


- (void)onUUIDChanged;
- (void)createUUIDChangeSession;

- (NSInteger)computeTotalDuration;

@end

NS_ASSUME_NONNULL_END
