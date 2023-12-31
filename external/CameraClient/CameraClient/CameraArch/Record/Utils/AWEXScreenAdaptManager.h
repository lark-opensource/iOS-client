//
//  AWEXScreenAdaptManager.h
//  Pods
//
//  Created by li xingdong on 2019/3/15.
//

#import <Foundation/Foundation.h>

@interface AWEXScreenAdaptManager : NSObject

+ (BOOL)needAdaptScreen;

+ (CGRect)standPlayerFrame;

+ (CGRect)customFullFrame;

+ (CAShapeLayer *)maskLayerWithPlayerFrame:(CGRect)playerFrame;

+ (BOOL)aspectFillForRatio:(CGSize)ratio isVR:(BOOL)isVR;

@end
