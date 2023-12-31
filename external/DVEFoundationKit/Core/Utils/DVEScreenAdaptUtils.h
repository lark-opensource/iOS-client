//
//  DVEScreenAdaptUtils.h
//  DVEFoundationKit
//
//  Created by bytedance on 2022/1/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVEScreenAdaptUtils : NSObject

//轻剪辑全屏Preview的标准尺寸，非刘海屏Preview会铺满整个屏幕
+ (CGRect)standFullPlayerFrame;

+ (BOOL)aspectFillForRatio:(CGSize)ratio;

@end

NS_ASSUME_NONNULL_END
