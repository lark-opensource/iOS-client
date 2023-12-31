//
//  ACCStickerScreenAdaptInjectionProtocol.h
//  ACCStickerSDK-Pods-Aweme
//
//  Created by Pinka on 2020/11/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCStickerScreenAdaptInjectionProtocol <NSObject>

@optional
+ (BOOL)needAdaptScreen;
+ (CGRect)standPlayerFrame;

@end

NS_ASSUME_NONNULL_END
