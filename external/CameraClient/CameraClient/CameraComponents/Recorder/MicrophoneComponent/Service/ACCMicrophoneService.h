//
//  ACCMicrophoneService.h
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/6/6.
//

#import <Foundation/Foundation.h>

#import "AWERepoVideoInfoModel.h"

NS_ASSUME_NONNULL_BEGIN

@class RACSignal;

@protocol ACCMicrophoneService <NSObject>

@property (nonatomic, strong, readonly) RACSignal *micStateSignal;

@property (nonatomic, assign, readonly) ACCMicrophoneBarState currentMicBarState;

@end

NS_ASSUME_NONNULL_END
