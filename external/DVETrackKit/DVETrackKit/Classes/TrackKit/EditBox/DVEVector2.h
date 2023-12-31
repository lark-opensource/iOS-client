//
//  DVEVector2.h
//  TTVideoEditorDemo
//
//  created by bytedance on 2020/12/8.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVEVector2 : NSObject

@property (nonatomic) CGFloat x;
@property (nonatomic) CGFloat y;

- (instancetype)initWithX:(CGFloat)x andY:(CGFloat)y;

- (CGFloat)length;

- (void)normalize;

- (DVEVector2 *)normalized;

- (CGFloat)dot:(DVEVector2 *)another;

- (CGFloat)cross:(DVEVector2 *)another;

- (double)angle:(DVEVector2 *)another;

- (DVEVector2 *)add:(DVEVector2 *)another;

- (DVEVector2 *)sub:(DVEVector2 *)another;

- (DVEVector2 *)multi:(CGFloat)scale;

@end

static inline DVEVector2 *VEGenVec2Between(CGPoint a, CGPoint b) {
    DVEVector2 *vec2 = [[DVEVector2 alloc] init];
    vec2.x = a.x - b.x;
    vec2.y = a.y - b.y;
    return vec2;
}

static inline DVEVector2 *VEConvertPoint(CGPoint a) {
    return [[DVEVector2 alloc] initWithX:a.x andY:a.y];
}

NS_ASSUME_NONNULL_END
