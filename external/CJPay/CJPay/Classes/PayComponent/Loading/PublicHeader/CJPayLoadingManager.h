//
//  CJPayLoadingManager.h
//  Pods
//
//  Created by 易培淮 on 2021/8/10.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import "CJPayEnumUtil.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayLoadingManagerProtocol <NSObject>

- (void)addLoadingCount:(CJPayLoadingType)type;
- (void)resetLoadingCount:(CJPayLoadingType)type;

@end

//@protocol CJPayBaseLoadingProtocol <NSObject>
//
//- (void)startLoading;
//- (void)stopLoading;
//
//@optional
//- (void)stopLoadingWithState:(CJPayLoadingQueryState)state;
//
//@end

@protocol CJPayComponentLoadingProtocol <NSObject>

- (void)registerLoading;

@end

@protocol CJPayAdvanceLoadingProtocol <NSObject>

@property (nonatomic, weak) id<CJPayLoadingManagerProtocol> delegate;

- (void)addLoadingCount;
- (void)resetLoadingCount;

@optional
- (void)stopLoading;
- (void)stopLoadingWithState:(CJPayLoadingQueryState)state;
- (void)startLoading;
- (void)startLoadingWithTitle:(NSString *)title;
- (void)startLoadingWithVc:(UIViewController *)vc;
- (void)startLoadingWithVc:(UIViewController *)vc title:(NSString *)title;
- (void)startLoadingWithTitle:(NSString *)title logo:(NSString *)url;
- (void)startLoadingOnView:(UIView *)view;
- (void)startLoadingWithView:(UIView *)view;
- (void)startLoadingWithValidateTimer:(BOOL)isNeedValiteTimer;
- (UIView *)getLoadingView;
+ (CJPayLoadingType)loadingType;

@end

@interface CJPayLoadingShowInfo : JSONModel

@property (nonatomic, copy) NSString *text;
@property (nonatomic, assign) NSInteger minTime;

@end

@interface CJPayLoadingStyleInfo : JSONModel

@property (nonatomic, copy) NSString *loadingStyle;
@property (nonatomic, strong) CJPayLoadingShowInfo *preShowInfo;
@property (nonatomic, strong) CJPayLoadingShowInfo *payingShowInfo;
@property (nonatomic, strong) CJPayLoadingShowInfo *bindCardConfirmPreShowInfo;
@property (nonatomic, strong) CJPayLoadingShowInfo *bindCardCompleteShowInfo;
@property (nonatomic, strong) CJPayLoadingShowInfo *bindCardConfirmPayingShowInfo;
@property (nonatomic, copy) NSString *showPayResult; // 是否展示支付结果gif
@property (nonatomic, strong, nullable) CJPayLoadingShowInfo *nopwdCombinePreShowInfo; //免密接口合并时，用于前置展示loading（“加载中”）
@property (nonatomic, strong, nullable) CJPayLoadingShowInfo *nopwdCombinePayingShowInfo; //免密接口合并时，用于前置展示loading（“免密支付中”）

@property (nonatomic, assign) BOOL isNeedShowPayResult;

@end

@class CJPayTimerManager;
@interface CJPayLoadingManager : NSObject <CJPayLoadingManagerProtocol>//仅管理全屏、半屏Loading

@property (nonatomic, assign) BOOL isDouyinStyleLoading;
@property (nonatomic, strong) CJPayLoadingStyleInfo *loadingStyleInfo;
@property (nonatomic, strong) CJPayLoadingStyleInfo *bindCardLoadingStyleInfo;
@property (nonatomic, strong) CJPayTimerManager *preShowTimerManger;
@property (nonatomic, strong) CJPayTimerManager *payingShowTimerManger;
@property (nonatomic, weak) id<CJPayAdvanceLoadingProtocol> currentLoadingItem;

@property (nonatomic, assign) BOOL isLoadingTitleDowngrade;

+ (instancetype)defaultService;
- (void)stopLoading;
- (void)startLoading:(CJPayLoadingType)type;
- (void)stopLoading:(CJPayLoadingType)type;
- (void)stopLoading:(CJPayLoadingType)type isForce:(BOOL)isForce;
- (void)stopLoadingWithState:(CJPayLoadingQueryState)state;
- (void)startLoading:(CJPayLoadingType)type title:(NSString *)title;
- (void)startLoading:(CJPayLoadingType)type title:(NSString *)title logo:(NSString *)url;
- (void)startLoading:(CJPayLoadingType)type vc:(UIViewController *)vc;
- (void)startLoading:(CJPayLoadingType)type vc:(UIViewController *)vc title:(NSString *)title;
- (void)startLoading:(CJPayLoadingType)type url:(NSString *)url view:(UIView *)view;
- (void)startLoading:(CJPayLoadingType)type withView:(UIView *)view;
- (void)startLoading:(CJPayLoadingType)type isNeedValidateTimer:(BOOL)isNeedValidateTimer;
- (void)startTimer;
- (void)stopTimer;
- (BOOL)isLoading;
- (UIView *)getCurrentHalfLoadingView;

@end

NS_ASSUME_NONNULL_END
