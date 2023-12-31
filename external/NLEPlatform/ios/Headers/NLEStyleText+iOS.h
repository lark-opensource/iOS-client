//
//  NLEStyleText+iOS.h
//  NLEPlatform
//
//  Created by bytedance on 2020/12/8.
//

#import <Foundation/Foundation.h>
#import "NLEResourceNode+iOS.h"
#import "NLENode+iOS.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLEStyleText_OC : NLENode_OC

/// 字体大小，行高，单位 pt，转换： px = pt / 72*300
@property (nonatomic, assign) uint32_t fontSize;

/// 背景标签的颜色, 0xFFFFFFFF -> AARRGGBB, Alpha, Red, Green, Blue
@property (nonatomic, assign) uint32_t backgroundColor;

///是否背景开启背景圆角
@property (nonatomic, assign) BOOL backgroundRoundCorner;

///背景圆角半径
@property (nonatomic, assign) float backgroundRoundRadius;

/// 描边颜色，rgba4分量描述（花字开启后，此选项失效）
@property (nonatomic, assign) uint32_t outlineColor;

/// 文字显示颜色, 0xFFFFFFFF -> AARRGGBB, Alpha, Red, Green, Blue
@property (nonatomic, assign) uint32_t textColor;

/// 对齐方式
/*
 AlignType_LEFT = 0;
 AlignType_CENTER = 1;
 AlignType_RIGHT = 2;
 AlignType_TOP = 3;
 AlignType_BOTTOM = 4;
 */
@property (nonatomic, assign) int alignType;
@property (nonatomic, assign) int typeSettingKind; // 横竖排

/// 阴影的颜色，, 0xFFFFFFFF -> AARRGGBB, Alpha, Red, Green, Blue（花字开启后，此选项失效）
@property (nonatomic, assign) uint32_t shadowColor;

/// 代表阴影的模糊半径，单位是相对于文字行高的比例值。比如0.1代表模糊半径会是行高的0.1倍。
/// shadowSmoothing越大，阴影边缘看起来越模糊。shadowSmoothing如果是0，阴影就
/// 会和本体一样的形状。（花字开启后，此选项失效）
@property (nonatomic, assign) float shadowSmoothing;

/// 代表阴影相对于文字本体的偏移量，xy两个分量。单位是相对于文
/// 字行高的比例值。[0.1, -0.1]会使阴影往右下角偏移。（花字开启后，此选项失效）
@property (nonatomic, assign) float shadowOffsetX;
@property (nonatomic, assign) float shadowOffsetY;

/// 加粗
@property (nonatomic, assign) BOOL bold;

/// 粗体宽度，单位是相对于文字行高的比例值。范围-0.05～0.05，为0时为正常样式，大于0时变粗，小于0时变细。
@property (nonatomic, assign) float boldWidth;

/// 斜体倾斜角度，范围0～45度，为0时为正常样式。
@property (nonatomic, assign) uint32_t italicDegree;

/// true代表开启下划线
@property (nonatomic, assign) BOOL underline;

/// 下划线宽度，单位是相对于文字行高的比例值。范围0.0～1.0
@property (nonatomic, assign) float underlineWidth;

/// 下划线偏移基线的距离，单位是相对于文字行高的比例值。范围0.0～1.0
@property (nonatomic, assign) float underlineOffset;

/// 排版的行间距，单位是相对于文字行高的比例值。0倍行距代表上下两行文字是依据行高紧密依靠的
@property (nonatomic, assign) float lineGap;

/// 字符间距，单位是相对于文字行高的比例值。0倍间距代表每行前后两个字符会按照标准排版紧密排列。
/// 英文单词是以单个letter为单位受影响的。中文则是一个汉字
@property (nonatomic, assign) float charSpacing;

/// 内边距，单位是相对于文字行高的比例值。编辑框会比文字内容的最小包围盒外扩内边距大小。
/// 内边距如果是0，编辑框会在上下左右四个方向紧贴文字内容。文字内容的最小包围盒是不考虑文字描边，阴影这些带来的影响。
/// 所以内边距为0且同时设置了一定描边宽度，会导致描边内容在编辑框范围外。如果此时开启了背景标签效果，则描边内容也会超出背景标签。
/// 客户端需要自行设置innerPadding>=outlineWidth来保证描边始终在编辑框内部。
@property (nonatomic, assign) float innerPadding;

/// true代表开启轮廓效果（花字开启后，此选项失效）
@property (nonatomic, assign) BOOL outline;

/// 描边宽度，单位是相对于文字行高的比例值。0.1会使文字具有0.1倍行高的描边。描边上限宽度是0.2（花字开启后，此选项失效）
@property (nonatomic, assign) float outlineWidth;

/// true代表气泡图片X轴翻转
@property (nonatomic, assign) BOOL shapeFlipX;

/// true代表气泡图片Y轴翻转
@property (nonatomic, assign) BOOL shapeFlipY;

/// 卡拉ok效果的变化后字体颜色，必须配合卡拉ok脚本资源才会生效
@property (nonatomic, assign) uint32_t KTVColor;

/// 卡拉ok效果的变化后描边颜色，必须配合卡拉ok脚本资源才会生效
@property (nonatomic, assign) uint32_t KTVOutlineColor;

/// 卡拉ok效果的变化后阴影颜色，必须配合卡拉ok脚本资源才会生效
@property (nonatomic, assign) uint32_t KTVShadowColor;

/// 是不是开启 一行自动截断模式，到达自动换行宽度后会自动截断文字并填充尾字符串
@property (nonatomic, assign) BOOL oneLineTruncated;

/// true 代表启用背景标签，背景标签是在文字的编辑框内填上特定颜色背景
@property (nonatomic, assign) BOOL background;

/// true 代表开启阴影效果（花字开启后，此选项失效）
@property (nonatomic, assign) BOOL shadow;

/// 自动换行宽度，显示窗口宽度的百分比，-1代表永远不会自动换行（实际上是内部有一个较大值4000像素）。
/// 横排时超过最大宽度会自动换行到下一行。竖排时超过最大宽度会自动换列到下一列。（>0显示窗口宽度的百分比，<0不限制）
@property (nonatomic, assign) float lineMaxWidth;

@property (nonatomic, copy) NSString *truncatedPostfix;

/// 字体路径，字体文件的绝对路径（ttf，otf，ttc均支持）Loki后台下载字体资源包先解压，然后填写到后缀是.ttf .otf .ttc的路径。
/// ios端可以填空字符串代表使用系统默认字体，android端必须填有效值，否则显示无效果。
@property (nonatomic, strong) NLEResourceNode_OC *font;

/// 回退字体路径，字体文件的绝对路径（ttf，otf，ttc均支持），首选字体查找字形数据失败时的回退方案。
/// Loki后台下载字体资源包先解压，然后填写到后缀是.ttf .otf .ttc的路径。
/// ios端可以填空字符串代表使用系统默认字体，android端必须填有效值，否则显示无效果。
@property (nonatomic, strong) NLEResourceNode_OC *fallbackFont;

/// 气泡包绝对路径，填写解压后资源根目录。一旦填入有效气泡包那么排版将会执行固定框排版模式，文字将会自适应调整字体大小到充满气泡内部。
/// 编辑框也会永远等于气泡所标定的框大小。  附上气泡资源制作文档气泡资源制作
@property (nonatomic, strong) NLEResourceNode_OC *shape;

/// 花字特效包绝对路径，填写解压后资源根目录。
/// 一旦填入有效花字特效包那么渲染效果就会走花字渲染，那么之前的shadow相关参数，outline相关参数均失效。
@property (nonatomic, strong) NLEResourceNode_OC *flower;


/// true代表花字效果将会使用花字包内的默认初始颜色。用户使用花字包之后是依然可以更改文本颜色的。
/// 更改文本颜色会使花字特效以一种特定方式产生变化。
/// 用户首次应用花字的时候往往希望使用花字包内的默认初始颜色，但是后续使用过程以及从草稿箱恢复时均需要此参数进行配合。
/// 剪映产品中此功能使用率不高，绝大多数用户仅会想使用花字包内的默认初始颜色。
/// 因此建议其他客户端接入此功能时，useEffectDefaultColor常置true。
@property (nonatomic, assign) BOOL useFlowerDefaultColor;

+ (instancetype)textStyleWithJSONString:(NSString *)JSONString;

/// 回退字体路径列表，字体文件的绝对路径（ttf，otf，ttc均支持），首选字体查找字形数据失败时的回退方案
- (NSMutableArray<NLEResourceNode_OC*>*)getFallbackFontList;

- (NSMutableArray*)getOutlineColors;
- (void)setOutlineColors:(NSMutableArray*)rgba;

- (NSMutableArray*)getTextColors;
- (void)setTextColors:(NSMutableArray*)rgba;

- (NSMutableArray*)GetShadowColors;
- (void)setShadowColors:(NSMutableArray*)rgba;

- (NSMutableArray*)getKTVColors;
- (void)setKTVColors:(NSMutableArray*)rgba;

- (NSMutableArray*)getKTVOutlineColors;
- (void)setKTVOutlineColors:(NSMutableArray*)rgba;

- (NSMutableArray*)getKTVShadowColors;
- (void)setKTVShadowColors:(NSMutableArray*)rgba;


- (NSMutableArray *)getBackgourndColors;

@end

NS_ASSUME_NONNULL_END
