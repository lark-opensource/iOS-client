//
//   DVEUILayoutConfig.h
//   DVEFoundationKit
//
//   Created  by ByteDance on 2021/7/1.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, DVEUILayoutAlignment) {
    DVEUILayoutAlignmentLeft,
    DVEUILayoutAlignmentCenter,
    DVEUILayoutAlignmentRight,
    DVEUILayoutAlignmentTop,
    DVEUILayoutAlignmentBottom,
};

// 用于提取 layout.json 中注入的信息
@interface DVEUILayoutConfig : NSObject

@property (nonatomic, assign) CGPoint position;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) DVEUILayoutAlignment alignment;
@property (nonatomic, assign) NSInteger sizeNumber;
@property (nonatomic, assign) UIEdgeInsets edgeInsets;
@property (nonatomic, assign) BOOL enable;

+ (BOOL)dve_boolValueWithKey:(NSString *)key;

+ (NSInteger)dve_intValueWithKey:(NSString *)key;

+ (CGFloat)dve_floatValueWithKey:(NSString *)key;

+ (CGSize)dve_sizeValueWithKey:(NSString *)key;

+ (CGPoint)dve_pointValueWithKey:(NSString *)key;

+ (DVEUILayoutAlignment)dve_alignmentValueWithKey:(NSString *)key;

+ (UIEdgeInsets)dve_edgeInsetsValueWithKey:(NSString *)key;

+ (DVEUILayoutConfig *)dve_layoutValueWithSize:(NSString *)size
                                      position:(NSString *)position
                                     alignment:(NSString *)alignment
                                    edgeInsets:(NSString *)edgeInsets;

@end

NS_ASSUME_NONNULL_END
