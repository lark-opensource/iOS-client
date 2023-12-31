//
//  UIDevice+BDCTAdditions.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/3/31.
//

#import <UIKit/UIKit.h>
#import <smash/tt_common.h>

NS_ASSUME_NONNULL_BEGIN


@interface UIDevice (BDCTAdditions)

+ (ScreenOrient)bdct_deviceOrientation;

@end

NS_ASSUME_NONNULL_END
