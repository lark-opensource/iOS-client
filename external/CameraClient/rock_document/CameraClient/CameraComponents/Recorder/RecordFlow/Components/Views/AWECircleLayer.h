//
//  AWECircleLayer.h
//  Aweme
//
//  Created by 郝一鹏 on 2017/8/23.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface AWECircleLayer : CALayer

@property (nonatomic,assign) CGFloat  innerFragment; //内环占比，[0,1]

+ (instancetype)circleLayerWithUsePinkColor:(BOOL)usePinkColor;

@end
