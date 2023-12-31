//
//  ACCMomentReframe.h
//  Pods
//
//  Created by Pinka on 2020/6/2.
//

#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCMomentReframe : MTLModel <MTLJSONSerializing>

///< Center X of bounding box
@property (assign, nonatomic) CGFloat centerX;
///< Center Y of bounding box
@property (assign, nonatomic) CGFloat centerY;
///< Width of bounding box
@property (assign, nonatomic) CGFloat width;
///< Height of bounding box
@property (assign, nonatomic) CGFloat height;
///< Clockwise rotate angle, in range [0, 360)
@property (assign, nonatomic) CGFloat rotateAngle;

- (NSArray<NSValue *> *)cropPoints;

@end

NS_ASSUME_NONNULL_END
