//
//  BDXPageSchemaParam.h
//  BDXContainer
//
//  Created by bill on 2021/3/14.
//

#import <Foundation/Foundation.h>
#import "BDXViewSchemaParam.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSInteger
{
    BDXNavigationButtonTypeNone,   //没有导航栏右侧按钮
    BDXNavigationButtonTypeShare,  //导航栏右侧按钮为share类型
    BDXNavigationButtonTypeReport, //导航栏右侧按钮为Report类型
} BDXNavigationButtonType;

@interface BDXPageSchemaParam : BDXViewSchemaParam<BDXPageSchemaParamProtocol>

//导航栏显示隐藏控制
@property(nonatomic, assign) BOOL hideNavBar;
// 状态栏显示隐藏控制
@property(nonatomic, assign) BOOL hideStatusBar;
//导航栏标题
@property(nonatomic, copy) NSString *title;
//导航栏标题字体颜色
@property(nonatomic, strong) UIColor *titleColor;
//导航栏背景颜色
@property(nonatomic, strong) UIColor *navBarColor;
//是否全屏(会展示状态栏图标)
@property(nonatomic, assign) BOOL transStatusBar;
/// 是否禁止右滑退出页面，默认为NO
@property(nonatomic, assign) BOOL disableSwipe;

//导航栏右侧按钮类型
@property(nonatomic, assign) BDXNavigationButtonType navigationButtonType;
//导航栏右侧按钮是否是“more”类型
@property(nonatomic, assign) BOOL showMoreButton;
//隐藏复制链接按钮
@property(nonatomic, assign) BOOL copyLinkAction;

@property(nonatomic, assign) CGSize preferredSize;

@end

NS_ASSUME_NONNULL_END
