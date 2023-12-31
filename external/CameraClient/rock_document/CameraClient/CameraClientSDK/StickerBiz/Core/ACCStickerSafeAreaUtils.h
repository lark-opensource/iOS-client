//
//  ACCStickerSafeAreaUtils.h
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/8/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCStickerSafeAreaUtils : NSObject

+ (UIEdgeInsets)safeAreaInsetsWithPlayerFrame:(CGRect)playerFrame containerFrame:(CGRect)containerFrame;

@end

NS_ASSUME_NONNULL_END
