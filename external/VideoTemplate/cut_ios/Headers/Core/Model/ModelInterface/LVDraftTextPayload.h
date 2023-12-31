//
//  LVDraftTextPayload.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/8/23.
//

#import "LVDraftPayload.h"
#import "LVMediaDraft.h"

NS_ASSUME_NONNULL_BEGIN


//@interface LVDraftTextPayload : LVDraftPayload
@interface LVDraftTextPayload(Interface)

/**
 文本内容
 */
//@property (nonatomic, copy) NSString *content;

/**
 背景颜色，用16进制表示，例如：#f8dd4a
 */
//@property (nonatomic, copy) NSString *backgroundColor;

/**
 背景的透明度 0 ~ 1.0
 */
//@property (nonatomic, assign) CGFloat backgroundAlpha;

/**
 z轴位置
 */
//@property (nonatomic, assign) NSInteger layerWeight;

/**
 字间距
 */
//@property (nonatomic, assign) CGFloat letterSpacing;

/**
 阴影，默认false
 */
//@property (nonatomic, assign) BOOL hasShadow;

/**
阴影颜色，用16进制表示，例如：#f8dd4a
*/
//@property (nonatomic, copy) NSString* shadowColor;

/**
 阴影透明度
 */
//@property (nonatomic, assign) CGFloat shadowAlpha;

/**
 阴影模糊度
 */
//@property (nonatomic, assign) CGFloat shadowSmoothing;

/*
 阴影位置坐标
 */
@property (nonatomic, assign) CGPoint shadowPoint;

/**
 阴影角度
 */
//@property (nonatomic, assign) CGFloat shadowAngle;

/**
 画笔颜色，用16进制表示，例如：#f8dd4a
 */
//@property (nonatomic, copy) NSString *borderColor;

/**
 描边宽度
 */
//@property (nonatomic, assign) CGFloat borderWidth;

/**
 文本样式，对应UI的
 */
//@property (nonatomic, copy) NSString *styleName;

/**
 字体颜色，用16进制表示，例如：#f8dd4a
 */
//@property (nonatomic, copy) NSString *textColor;

/**
 文字的透明度 0~1.0 会影响整个文字（包括文字本身、背景、描边等）
 */
//@property (nonatomic, assign) CGFloat textAlpha;

/**
 字体的effectID
*/
//@property (nonatomic, copy, setter=setFontID:, getter=fontID) NSString *fontEffectID;

/**
 字体的resourceID
*/
//@property (nonatomic, copy) NSString *fontResourceID;

/**
 字体名称
 */
//@property (nonatomic, copy) NSString *fontTitle;

/**
 字体大小
 */
//@property (nonatomic, assign) CGFloat fontSize;

/**
 字体库路径，注意：这个路径应该是草稿目录下的相对路径
 */
//@property (nonatomic, copy, nullable) NSString *fontPath;


/**
 文字排版方式 0: 横排  1：竖排
 */
//@property (nonatomic, assign) NSInteger typesetting;
/**
 文字对齐 0：左 1：中 2：右 3：上 4：下
 */
//@property (nonatomic, assign, getter=alignment, setter=setAlignment:) NSInteger textAlignment;

/**
 是否使用花字默认的颜色
 */
//@property (nonatomic, assign, getter=isUseEffectDefaultColor, setter=setIsUseEffectDefaultColor:) BOOL useEffectDefaultColor;

/**
 气泡是否【左右】翻转
 */
//@property (nonatomic, assign) BOOL shapeFlipX;

/**
气泡是否【上下】翻转
*/
//@property (nonatomic, assign) BOOL shapeFlipY;

//@property (nonatomic, copy) NSString *ktvColor;

/**
 行间距
 */
@property (nonatomic, assign) CGFloat lineGap;
/**
 VE对应的版本
 */
+ (CGFloat)textVEVersion;

@end

NS_ASSUME_NONNULL_END
