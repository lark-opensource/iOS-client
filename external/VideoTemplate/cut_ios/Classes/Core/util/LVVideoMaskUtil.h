//
//  LVVideoMaskUtil.h
//  VideoTemplate
//
//  Created by zenglifeng on 2020/7/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LVVideoMaskUtil : NSObject

+ (CGSize)maskAspectSizeWith:(CGSize)videoSize maskSize:(CGSize)maskSize aspectRatio:(CGFloat)aspectRatio;

@end

NS_ASSUME_NONNULL_END
