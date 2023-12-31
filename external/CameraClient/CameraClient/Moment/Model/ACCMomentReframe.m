//
//  ACCMomentReframe.m
//  Pods
//
//  Created by Pinka on 2020/6/2.
//

#import "ACCMomentReframe.h"

@implementation ACCMomentReframe

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"centerX": @"center_x",
        @"centerY": @"center_y",
        @"width": @"width",
        @"height": @"height",
        @"rotateAngle": @"rotate_angle"
    };
}

- (NSArray<NSValue *> *)cropPoints {
    /// Normalized coordinates [upper left, upper right, lower left, lower right]
    NSValue *leftTop = [NSValue valueWithCGPoint:CGPointMake(self.centerX - self.width / 2, self.centerY - self.height / 2)];
    NSValue *rightTop = [NSValue valueWithCGPoint:CGPointMake(self.centerX + self.width / 2, self.centerY - self.height / 2)];
    NSValue *leftBottom = [NSValue valueWithCGPoint:CGPointMake(self.centerX - self.width / 2, self.centerY + self.height / 2)];
    NSValue *rightBottom = [NSValue valueWithCGPoint:CGPointMake(self.centerX + self.width / 2, self.centerY + self.height / 2)];
    NSArray<NSValue *> * points = @[leftTop, rightTop, leftBottom, rightBottom];
    return points;
}
@end
