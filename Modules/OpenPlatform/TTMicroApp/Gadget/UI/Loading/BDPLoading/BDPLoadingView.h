//
//  BDPLoadingView.h
//  Timor
//
//  Created by liubo on 2018/12/10.
//

#import <UIKit/UIKit.h>
#import <OPFoundation/BDPModel.h>
#import <OPFoundation/BDPModuleEngineType.h>

typedef NS_ENUM(NSInteger, BDPLoadingViewStyle)
{
    BDPLoadingViewStyleInternal = 1,    //SDK内置的加载界面样式
    BDPLoadingViewStyleCustom,          //宿主传入的加载界面样式
};

typedef NS_ENUM(NSInteger, BDPLoadingViewState)
{
    BDPLoadingViewStateLoading = 1,             //加载中
    BDPLoadingViewStateFail,                    //加载失败
    BDPLoadingViewStateFailReload,              //加载失败-附带"重试"按钮
    BDPLoadingViewStateFailReloadImmediately,   //加载失败-立即重试- 附带“点击重试”按钮
    BDPLoadingViewStateSlow,                    //加载过慢
    BDPLoadingViewStateSlowDebug,               //加载过慢-附带"调试"按钮
};

@protocol BDPLoadingViewDelegate <NSObject>
@required

- (void)bdpLoadingViewReloadActionImmediately:(BOOL)immediately;
- (void)bdpLoadingViewDebugAction;

@end

#pragma mark - BDPLoadingView

@interface BDPLoadingView : UIView

@property (nonatomic, readonly) BDPType type;
@property (nonatomic, readonly) BDPLoadingViewStyle style;
@property (nonatomic, readonly) BDPLoadingViewState state;
@property (nonatomic, weak) id<BDPLoadingViewDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame type:(BDPType)type delegate:(id<BDPLoadingViewDelegate>)delegate uniqueID:(BDPUniqueID *)uniqueID;

- (void)updateAppModel:(BDPModel *)newAppModel;
- (void)checkIfNeedCustomLoadingStyleWithUniqueID:(BDPUniqueID *)uniqueID; // 检查小游戏是否需要脱敏loading
- (void)updateLoadPercent:(CGFloat)percent;

- (void)changeToFailState:(BDPLoadingViewState)state withTipInfo:(NSString *)tipInfo;

- (void)startLoading;
- (void)stopLoading;

@end
