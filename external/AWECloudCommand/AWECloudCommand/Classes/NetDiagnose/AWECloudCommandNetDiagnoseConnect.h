//
//  AWECloudCommandNetDiagnoseConnect.h
//  AWELive
//
//  Created by songxiangwu on 2018/4/16.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AWECloudCommandNetDiagnoseConnectDelegate <NSObject>

- (void)didAppendPingLog:(NSString *)log;
- (void)didFinishPing;

@end

@interface AWECloudCommandNetDiagnoseConnect : NSObject

@property (nonatomic, weak) id<AWECloudCommandNetDiagnoseConnectDelegate> delegate;

- (void)startPingWithHost:(NSString *)host maxLoop:(NSInteger)maxLoop;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
