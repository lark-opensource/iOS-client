//
//  DVEUIHelper.h
//  DVEFoundationKit
//
//  Created by bytedance on 2020/12/20
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DVEMacros.h"

NS_ASSUME_NONNULL_BEGIN

#define DVEBottomMargn (isIphoneX ? (34) : (0))
#define DVETopMargnValue 28.0
#define DVEBottomMargnValue 34.0

@interface DVEUIHelper : NSObject

+ (CGFloat)topBarMargn;

+ (CGFloat)topBarMargn:(UINavigationController *)nav;

+ (UIEdgeInsets)dve_safeAreaInsets;

+ (CAShapeLayer *)topRoundCornerShapeLayerWithFrame:(CGRect)frame
                                             radius:(CGFloat)radius;

@end

#define DVE_SafeAreaInsets     [DVEUIHelper dve_safeAreaInsets]

NS_ASSUME_NONNULL_END
