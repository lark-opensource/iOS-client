//
//  BDXPopupSchemaParam.h
//  Bullet-Pods-AwemeLite
//
//  Created by 王丹阳 on 2020/11/2.
//

#import <Foundation/Foundation.h>
#import "BDXViewSchemaParam.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BDXPopupType) {
    BDXPopupTypeDialog = 0,   // 弹窗/浮窗（居中样式为主）
    BDXPopupTypeBottomIn = 1, // 底边贴屏幕底部的 半屏弹窗
    BDXPopupTypeRightIn = 2,  // push样式
};

typedef NS_ENUM(NSInteger, BDXPopupBehavior) {
    // close origin panel
    BDXPopupBehaviorClose = 0,
    // hide origin panel, it will be restored when it's on top
    BDXPopupBehaviorHide = 1,
    // do nothing
    BDXPopupBehaviorNone = 2,
};

@interface BDXPopupSchemaParam : BDXViewSchemaParam<BDXPopupSchemaParamProtocol>

/// 容器弹出类型
@property(nonatomic) BDXPopupType type;
/// 容器打开方式
@property(nonatomic) BDXPopupBehavior behavior; // trigger origin
/// 当type为BDXPopupTypeDialog时，键盘弹出时候距离键盘顶部的距离
@property(nonatomic, nullable) NSNumber *keyboardOffset;
/// 当type为BDXPopupTypeDialog时，距离容器顶部的距离。与bottomOffset同时不存在时居中。
@property(nonatomic, nullable) NSNumber *topOffset;
/// 当type为BDXPopupTypeDialog时，距离容器底部的距离。与topOffset同时不存在时居中。
@property(nonatomic, nullable) NSNumber *bottomOffset;
/// 容器宽度
@property(nonatomic, strong) NSNumber *width;
/// 容器高度
@property(nonatomic, strong) NSNumber *height;
/// 容器宽度百分比
@property(nonatomic, assign) NSInteger widthPercent;
/// 容器高度百分比
@property(nonatomic, assign) NSInteger heightPercent;
/// 容器高度计算优先级
@property(nonatomic, strong) NSNumber *aspectRatio;
/// 半屏圆角半径
@property(nonatomic, strong) NSNumber *radius;
/// 容器mask颜色，默认透明
@property(nonatomic, copy, nullable) NSString *maskColorString; //#ARGB
/// 是否点击mask容器
@property(nonatomic) BOOL closeByMask;
/// 是否通过手势关闭容器
@property(nonatomic) BOOL closeByGesture;
/// 调用者的container_id
@property(nonatomic, copy) NSString *originContainerID; // origin panel

@property(nonatomic, assign) BOOL maskCanCloseUntilLoaded;

@property(nonatomic) BOOL dragByGesture;
@property(nonatomic) BOOL dragBack;
@property(nonatomic) BOOL dragFollowGesture;
@property(nonatomic, strong) NSNumber *dragHeight;
@property(nonatomic, assign) NSInteger dragHeightPercent;

#pragma mark - 其他参数
/// 要附加到特定的VC上
@property(nonatomic, weak) UIViewController *preferViewController;

@end

NS_ASSUME_NONNULL_END
