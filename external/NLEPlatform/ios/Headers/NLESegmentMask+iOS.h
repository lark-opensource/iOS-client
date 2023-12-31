//
//  NLESegmentMask+iOS.h
//  Pods
//
//  Created by bytedance on 2020/12/25.
//

#ifndef NLESegmentMask_iOS_h
#define NLESegmentMask_iOS_h

#import <Foundation/Foundation.h>
#import "NLESegment+iOS.h"
#import "NLEResourceNode+iOS.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLESegmentMask_OC : NLESegment_OC

/// 蒙版资源
@property (nonatomic, strong) NLEResourceNode_OC* effectSDKMask;
@property (nonatomic, copy) NSString *maskType;

/// 直接使用上面的属性即可
//- (NLEResourceNode_OC*)getEffectSDKMask;

- (void)setEffectSDKMask:(NLEResourceNode_OC*)effectSDKMask;

- (void)setAspectRatio:(float)aspectRatio;
- (float)aspectRatio;

- (void)setCenterX:(float)centerX;
- (float)centerX;

- (void)setCenterY:(float)centerY;
- (float)centerY;

- (void)setFeather:(float)feather;
- (float)feather;

- (void)setWidth:(float)width;
- (float)width;

- (void)setHeight:(float)height;
- (float)height;

- (void)setRotation:(float)rotation;
- (float)rotation;

- (void)setRoundCorner:(float)roundCorner;
- (float)roundCorner;

- (void)setInvert:(bool)invert;
- (bool)invert;

- (NLEResourceNode_OC*)getResource;
                                                         
@end

NS_ASSUME_NONNULL_END

#endif /* NLESegmentMask_iOS_h */
