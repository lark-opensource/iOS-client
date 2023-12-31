//
//  ACCCameraServiceNewImpls.h
//  Pods
//
//  Created by liyingpeng on 2020/5/28.
//

#import <Foundation/Foundation.h>
#import <CreationKitRTProtocol/ACCCameraService.h>

@protocol IESServiceProvider;

NS_ASSUME_NONNULL_BEGIN

@interface ACCCameraServiceNewImpls : NSObject <ACCCameraService>

- (void)configResolver:(id<IESServiceProvider>)resolver;

@end

NS_ASSUME_NONNULL_END
