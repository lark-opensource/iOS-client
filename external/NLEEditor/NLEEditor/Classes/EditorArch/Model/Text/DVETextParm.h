//
//  DVETextParm.h
//  TTVideoEditorDemo
//
//  Created by bytedance on 2020/12/20
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DVEEffectValue.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVETextParm : NSObject

@property (nonatomic, copy) NSString *text;
@property (nonatomic, assign) uint32_t fontSize;
@property (nonatomic, strong) DVEEffectValue *font;
@property (nonatomic, copy) NSArray *textColor;
@property (nonatomic, copy) NSArray *outlineColor;
@property (nonatomic, assign) float outlineWidth;
@property (nonatomic, copy) NSArray *backgroundColor;
@property (nonatomic, assign) float backgroundRoundRadius;
@property (nonatomic, assign) float innerPadding;
@property (nonatomic, strong) DVEEffectValue * alignment;
@property (nonatomic) int typeSettingKind;

@property (nonatomic, assign) float alpha;

/// 是否优先使用花字里的字体颜色，如果用户设置了花字，后设置字体颜色，这个需要置为NO
/// 如果用户点击花字，则这个需要设置为YES
@property (nonatomic, assign) BOOL useEffectDefaultColor;

@property (nonatomic, copy) NSArray *shadowColor;
@property (nonatomic, copy) NSArray *shadowOffset;
@property (nonatomic, assign) float shadowSmoothing;

@property (nonatomic, assign) float boldWidth;
@property (nonatomic, assign) float italicDegree;
@property (nonatomic, assign) BOOL underline;

@property (nonatomic, assign) float charSpacing;
@property (nonatomic, assign) float lineGap;

@property (nonatomic, assign) CGPoint transform;
@property (nonatomic, assign) CGFloat rotation;
@property (nonatomic, assign) CGFloat scale;

- (BOOL)isEqualToParm:(DVETextParm *)parm;

@end

NS_ASSUME_NONNULL_END
