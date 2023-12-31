//
//  IESEffectUIConfig.h
//  EffectPlatformSDK
//
//  Created by Kun Wang on 2018/3/6.
//

#import <Foundation/Foundation.h>

@interface IESEffectUIConfig : NSObject
@property (nonatomic, strong) UIColor *backgroundColor;
// 背景是否采用毛玻璃效果，默认 YES
// 如果为 YES，在 iOS 9 及其以上系统会使用毛玻璃，以下会使用背景色
@property (nonatomic, assign) BOOL blurBackground;
// 是否在分类面板最左端显示删除按钮，默认 NO
@property (nonatomic, assign) BOOL showClearInCategory;

// 是否显示分类，若为 YES， 显示带分类的两级特效，若为 NO，显示全部特效， 默认为 NO
// 若数据中不包含分类，改属性无效
@property (nonatomic, strong) UIImage *categoryCleanImage;
@property (nonatomic, strong) NSString *categoryCleanTitle;
@property (nonatomic, assign) BOOL showCategory;
// 顶部分类 section 的高度， 默认为 38
@property (nonatomic, assign) CGFloat sectionHeight;
// 顶部分类 section 的最小宽度， 默认为 56
@property (nonatomic, assign) CGFloat sectionMinWidth;
// 顶部分类字体
@property (nonatomic, strong) UIFont *sectionTextFont;
// 顶部分类 section 背景颜色，默认透明（同背景色）
@property (nonatomic, strong) UIColor *sectionBackgroundColor;
// 顶部分类文字颜色
@property (nonatomic, strong) UIColor *sectionTitleUnSelectedColor;
@property (nonatomic, strong) UIColor *sectionTitleSelectedColor;
// 面板内容整体高度， 默认为 200
@property (nonatomic, assign) CGFloat contentHeight;
// 分类 section 和内容面板分割线高度，默认 1
@property (nonatomic, assign) CGFloat sectionSeperatorHeight;
// 分类 section 分割线颜色 默认白色
@property (nonatomic, strong) UIColor *sectionSeperatorColor;
// 面板中内边距 默认 16 16 16 16
@property (nonatomic, assign) UIEdgeInsets contentInsets;
// 是否允许滑动，默认 YES
@property (nonatomic, assign) BOOL contentScrollEnable;
// 面板中每个元素的水平间距 默认 16
@property (nonatomic, assign) CGFloat horizonInterval;
// 面板中每个元素的垂直间距 默认 16
@property (nonatomic, assign) CGFloat verticalInterval;
// 面板中每行的元素个数 默认 5
@property (nonatomic, assign) NSUInteger numberOfItemPerRow;
// 下载 icon 图标
@property (nonatomic, strong) UIImage *downloadImage;
// 删除按钮图标
@property (nonatomic, strong) UIImage *cleanImage;
// 图标占位图
@property (nonatomic, strong) UIImage *placeHolderImage;
// 选中后边框属性
// 默认 宽2 颜色 ff2200 圆角 8
@property (nonatomic, strong) UIColor *selectedBorderColor;
@property (nonatomic, assign) CGFloat selectedBorderWidth;
@property (nonatomic, assign) CGFloat selectedBorderRadius;
// 对应红点的 tag 默认 new
@property (nonatomic, strong) NSString *redDotTagForCategory;
@property (nonatomic, strong) NSString *redDotTagForEffect;
+ (IESEffectUIConfig *)sharedInstance;
@end
