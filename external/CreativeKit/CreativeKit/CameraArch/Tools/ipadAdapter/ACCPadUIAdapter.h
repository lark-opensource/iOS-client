//
//  ACCPadUIAdapter.h
//  AWEAuth
//
//  Created by Shuang on 2022/3/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCPadUIAdapter : NSObject

+ (CGFloat)iPadScreenWidth;

+ (void)setIPadScreenWidth:(CGFloat)width;

+ (CGFloat)iPadScreenHeight;

+ (void)setIPadScreenHeight:(CGFloat)height;

@end

NS_ASSUME_NONNULL_END
