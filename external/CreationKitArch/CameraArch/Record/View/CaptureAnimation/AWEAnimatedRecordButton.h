//
//  AWEAnimatedRecordButton.h
//  AWEStudio
//
// Created by Hao Yipeng on December 10, 2018
//  Copyright © 2018 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AWEAnimatedRecordLayerProtocol.h"

typedef NS_ENUM(NSUInteger, AWEAnimatedRecordButtonType) {
    AWEAnimatedRecordButtonTypeUnknown,
    AWEAnimatedRecordButtonTypeHoldVideo,
    AWEAnimatedRecordButtonTypeTapVideo,
    AWEAnimatedRecordButtonTypeTapPicture,
    AWEAnimatedRecordButtonTypeCountDown,
    AWEAnimatedRecordButtonTypeMixTapHoldVideo,
};

NS_ASSUME_NONNULL_BEGIN

@interface AWEAnimatedRecordButton : UIButton

@property (nonatomic, strong) CALayer<AWEAnimatedRecordLayerProtocol> *innerLayer;
@property (nonatomic, strong) CALayer<AWEAnimatedRecordLayerProtocol> *outterLayer;

@property (nonatomic, assign) AWEAnimatedRecordButtonType type;

- (void)beginAnimation;
- (void)endAnimation;

@end

NS_ASSUME_NONNULL_END
