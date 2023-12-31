//
//  EMALoadingView.h
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/11/3.
//

#import <UIKit/UIKit.h>
@class OPAppUniqueID;
@class OPLoadingAnimationView;
NS_ASSUME_NONNULL_BEGIN

@class UDEmpty;

@interface OPLoadingView : UIView
//外部只读，用来存储原始 BDPLoadingView 中的状态
@property (nonatomic, assign, readonly) int failState;

// 用于加载出错时，显示在导航栏标题位置处的应用名称
@property (nonatomic, strong, readonly) UILabel *topTitleView;
@property (nonatomic, strong, readonly) UIImageView *logoView;
@property (nonatomic, strong, readonly) UILabel *titleView;

@property (nonatomic, strong, readonly) OPAppUniqueID *uniqueID;
@property (nonatomic, strong, readonly) OPLoadingAnimationView *loadingView;
// 用于显示当前加载错误信息的emptyView
@property (nonatomic, strong, readonly) UDEmpty *emptyView;
- (void)updateLoadingViewWithIconUrl:(NSString *)iconUrl appName:(NSString *)appName;

- (void)hideLoadingView;

- (void)changeToFailState:(int)state withTipInfo:(NSString *)tipInfo;
/// 将loadingView变换为显示为可恢复错误提示+重试按钮的样式
- (void)changeToFailRetryStateWith:(NSString * _Nonnull )tipInfo uniqueID:(OPAppUniqueID *)uniqueID;

- (void)stopAnimation;


/// 绑定uniqueID,用于swift extension
/// @param uniqueID uniqueID
- (void)bindUniqueID:(OPAppUniqueID *)uniqueID;

/// 切换到UD统一错误页,用于swift extension
/// @param emptyView 错误页面
- (void)changeToEmptyView:(UDEmpty *)emptyView;

@end

NS_ASSUME_NONNULL_END
