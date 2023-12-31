//
//  ACCEditBarItemLottieExtraData.h
//  CameraClient-Pods-Aweme
//
//  Created by admin on 2021/7/29.
//

#import "ACCEditBarItemExtraData.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCEditBarItemLottieExtraData : ACCEditBarItemExtraData

@property (nonatomic, assign) BOOL isLottie;
@property (nonatomic, copy) NSString *lottieResourceName;

- (instancetype)initWithButtonClass:(nullable Class)buttonClass
                               type:(AWEEditAndPublishViewDataType)type
                           isLottie:(BOOL)isLottie
                 lottieResourceName:(NSString *)lottieResourceName;

@end

NS_ASSUME_NONNULL_END
