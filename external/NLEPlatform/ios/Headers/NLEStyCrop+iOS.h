//
//  NLEStyCrop+iOS.h
//  Pods
//
//  Created by bytedance on 2020/12/8.
//

#ifndef NLEStyCrop_iOS_h
#define NLEStyCrop_iOS_h

#import <Foundation/Foundation.h>
#import "NLENode+iOS.h"
#import "NLENativeDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLEStyCrop_OC : NLENode_OC

/// 裁剪四个点的坐标，左上角为原点，归一化坐标
@property (nonatomic, assign) CGFloat lowerLeftX;
@property (nonatomic, assign) CGFloat lowerLeftY;
@property (nonatomic, assign) CGFloat lowerRightX;
@property (nonatomic, assign) CGFloat lowerRightY;
@property (nonatomic, assign) CGFloat upperLeftX;
@property (nonatomic, assign) CGFloat upperLeftY;
@property (nonatomic, assign) CGFloat upperRightX;
@property (nonatomic, assign) CGFloat upperRightY;

@end

NS_ASSUME_NONNULL_END


#endif /* NLEStyCrop_iOS_h */
