//
//  VEDMaskEditViewConfig.h
//  NLEEditor
//
//  Created by bytedance on 2021/4/11.
//

#import <Foundation/Foundation.h>
#import "VEDMaskShapeType.h"






NS_ASSUME_NONNULL_BEGIN

@interface VEDMaskDataModel : NSObject

@property (nonatomic, assign) VEDMaskShapeType type;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, assign) CGFloat rotation;
@property (nonatomic, assign) CGFloat roundCorner;
@property (nonatomic, assign) CGFloat feather;
@property (nonatomic, assign) CGPoint center;
@property (nonatomic, copy) NSString *svgFilePath;

- (instancetype)initWithType:(VEDMaskShapeType)type
                       width: (CGFloat)width
                      height: (CGFloat)height
                      center: (CGPoint)center
                    rotation: (CGFloat)rotation
                 roundCorner: (CGFloat)roundCorner
                     feather: (CGFloat)feather
                 svgFilePath: (NSString *)svgFilePath;


@end

@interface VEDMaskUIModel : NSObject

// 圆角调整的范围
@property (nonatomic, assign) CGFloat roundCornerMaxSpace;
// 圆角调整的范围角度
@property (nonatomic, assign) CGFloat roundCornerMaxAngle;
// 羽化调整的范围
@property (nonatomic, assign) CGFloat featherMaxSpace;
// 中心点的半径
@property (nonatomic, assign) CGFloat centerCicleCornerRadius;
// 绘制线宽度
@property (nonatomic, assign) CGFloat lineWidth;
// 绘制线宽度
@property (nonatomic, assign) CGFloat centerIconLineWidth;
// icon的最小的间距
@property (nonatomic, assign) CGFloat iconSpace;

// 边框最大宽度
@property (nonatomic, assign) CGFloat maxWidth;
// 边框最大高度
@property (nonatomic, assign) CGFloat maxHeight;
// 边框最小宽度
@property (nonatomic, assign) CGFloat minWidth;
// 边框最小高度
@property (nonatomic, assign) CGFloat minHeight;
// icon最小间距
@property (nonatomic, assign) CGFloat minIconSpace;


@property (nonatomic, strong)  UIImage *horizontalPanImage;

@property (nonatomic, strong)  UIImage *verticalPanImage;

@property (nonatomic, strong)  UIImage *roundCornerPanImage;

@property (nonatomic, strong)  UIImage *featherPanImage;

// 绘制线颜色
@property (nonatomic, strong) UIColor *lineColor;



@end



@interface VEDMaskEditViewConfig : NSObject

@property (nonatomic, strong) VEDMaskDataModel *data;

@property (nonatomic, strong) VEDMaskUIModel *ui;

- (instancetype)initWithDataModel:(VEDMaskDataModel *)data UIModel:(VEDMaskUIModel *)ui;


@end

NS_ASSUME_NONNULL_END
