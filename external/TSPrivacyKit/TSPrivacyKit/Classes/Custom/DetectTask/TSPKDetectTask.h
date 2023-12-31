//
//  TSPKDetectTask.h
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/27.
//

#import <Foundation/Foundation.h>

#import "TSPKDetectEvent.h"
#import "TSPKDetectPlanModel.h"
#import "TSPKContext.h"


@class TSPKDetectTask;

@protocol TSPKDetectTaskProtocol <NSObject>

- (void)detectTaskDidFinsh:(TSPKDetectTask * _Nonnull)detectTask;

@end

@interface TSPKDetectTask : NSObject

@property (nonatomic) BOOL onCurrentThread;
@property (nonatomic, strong, readonly, nonnull) TSPKDetectEvent *detectEvent;
@property (nonatomic, strong, nonnull) TSPKContext *context;
@property (nonatomic, weak, nullable) id<TSPKDetectTaskProtocol> delegate;

- (instancetype _Nullable)initWithDetectEvent:(TSPKDetectEvent * _Nonnull)event;

- (void)executeWithScheduleTime:(NSTimeInterval)scheduleTime;

- (void)markTaskFinish;

- (void)decodeParams:(NSDictionary * _Nonnull)params;

@end

