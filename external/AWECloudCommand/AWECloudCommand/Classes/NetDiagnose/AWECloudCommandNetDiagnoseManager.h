//
//  AWECloudCommandNetDiagnoseManager.h
//  AWELive
//
//  Created by songxiangwu on 2018/4/16.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AWECloudCommandNetDiagnoseManagerDelegate <NSObject>

- (void)netDiagnoseOutputInfo:(NSString *)info;
- (void)netDiagnoseDidFinish;

@end


@interface AWECloudCommandNetDiagnoseManager : NSObject

@property (nonatomic, copy) NSString *testHost;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *deviceId;
@property (nonatomic, weak) id<AWECloudCommandNetDiagnoseManagerDelegate> delegate;

- (void)startNetDiagnose;

- (void)startNetDiagnoseWithCompletionBlock:(void(^ _Nullable)(NSString *text))completion;

- (void)startNetDiagnoseWithProgressBlock:(void(^ _Nullable)(CGFloat percentage))progressBlock
                          completionBlock:(void(^ _Nullable)(NSString *text))completion;

- (void)stopNetDiagnose;

@end

NS_ASSUME_NONNULL_END
