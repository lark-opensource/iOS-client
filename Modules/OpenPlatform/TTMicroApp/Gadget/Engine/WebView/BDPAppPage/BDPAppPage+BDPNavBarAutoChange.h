//
//  BDPAppPage+BDPNavBarAutoChange.h
//  Timor
//
//  Created by 李论 on 2019/8/12.
//

#import <UIKit/UIKit.h>
#import "BDPAppPage.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^BDPAppPageWebDidScroll)(UIScrollView *scroll);
typedef void(^BDPAppPageNavBarUpdate)(CGFloat alpha, BOOL transparnt);

typedef NS_ENUM(NSInteger, BDPAppScrollViewMoveType)
{
    BDPAppScrollViewMoveType_MoveNone = 0,
    BDPAppScrollViewMoveType_MoveIn,
    BDPAppScrollViewMoveType_MoveOut,
};

///  非BDPAppPage请勿调用这里的方法，在方法里已经加了assert，log，注释，一旦不听劝阻强行调用，需要revert代码，提交lb，编写case study，并且复盘
@interface BDPAppPage (BDPNavBarAutoChange)

///滑动多大距离自动变色
@property (nonatomic, assign) NSInteger bap_scrollOffsetGap;
///标记是否已经打开导航栏自动变色
@property (nonatomic, assign) BOOL bap_enableNavBarStyleAutoChange;
///当前web scrollview 滑动的状态
@property (nonatomic, assign, readonly) BDPAppScrollViewMoveType bap_curWebScrollStatus;
///当前web scrollview 滑动的状态，滑动距离占scrollOffsetGap的百分比，小于0时为0，大于1时为1
@property (nonatomic, assign, readonly) CGFloat bap_scrollGapPercentage;
///状态栏应该变化时候的回调
@property (nonatomic, copy) BDPAppPageNavBarUpdate bap_updateCallBack;


///启用滑动监控后，导航栏颜色渐变,返回值：是否启用监控成功
- (BOOL)bdp_enableNavBarAutoChangeIfNeed;
///目标导航栏中文字颜色，根据当前配置，web滑动状态变化
- (BOOL)bap_navBarItemColorShouldReverse;

@end

NS_ASSUME_NONNULL_END

