//
//  ACCEditBarItemLottieExtraData.m
//  CameraClient-Pods-Aweme
//
//  Created by admin on 2021/7/29.
//

#import "ACCEditBarItemLottieExtraData.h"

@implementation ACCEditBarItemLottieExtraData

- (instancetype)initWithButtonClass:(nullable Class)buttonClass
                               type:(AWEEditAndPublishViewDataType)type
                           isLottie:(BOOL)isLottie
                 lottieResourceName:(NSString *)lottieResourceName {
    if (self = [super initWithButtonClass:buttonClass type:type]) {
        _isLottie = isLottie;
        _lottieResourceName = lottieResourceName;
    }
    return self;
}

@end
