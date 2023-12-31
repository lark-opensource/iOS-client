//
//  CJPayFrontCashierResultModel.h
//  CJPay
//
//  Created by 王新华 on 4/2/20.
//

#import <Foundation/Foundation.h>
#import "CJPaySDKDefine.h"

#if __has_include("CJPayHomeVCProtocol.h")
    #import "CJPayHomeVCProtocol.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@class BDPayCreateOrderRresponse;
@class CJPayDefaultChannelShowConfig;
@class CJPayBDCreateOrderResponse;
@protocol CJPayHomeVCProtocol;


@interface CJPayChooseCardResultModel : NSObject

@property (nonatomic, assign) BOOL isCancel;
@property (nonatomic, assign) BOOL isNewCard;
@property (nonatomic, strong, nullable) CJPayDefaultChannelShowConfig *config;

@end

typedef void (^BDChooseCardFinishCompletion)(CJPayChooseCardResultModel *model);
typedef void (^BDChooseCardDismissLoadingBlock)(void);
typedef void (^BDChooseCardBackToMainVCBlock)(void);

@interface BDChooseCardCommonModel: NSObject

@property (nonatomic, copy) NSDictionary *bizParams;
@property (nonatomic, strong) CJPayBDCreateOrderResponse *orderResponse;
@property (nonatomic, copy) NSArray<NSString *> *notSufficientFundsIDs;
@property (nonatomic, strong) CJPayDefaultChannelShowConfig *defaultConfig;
@property (nonatomic, copy) BDChooseCardBackToMainVCBlock backToMainVCBlock;
@property (nonatomic, copy) BDChooseCardFinishCompletion chooseCardCompletion;
@property (nonatomic, copy) BDChooseCardDismissLoadingBlock dismissLoadingBlock;
@property (nonatomic, copy) void(^bindCardBlock)(BDChooseCardDismissLoadingBlock);
@property (nonatomic, assign) CJPayComeFromSceneType comeFromSceneType;

@property (nonatomic, copy) NSDictionary *trackerParams;
@property (nonatomic, assign) BOOL hasSfficientBlockBack;
@property (nonatomic, weak) UIViewController *fromVC;

@end

@class CJPayBDOrderResultResponse;
@class CJPayBDCreateOrderResponse;
@class CJPayCombinePayLimitModel;

@protocol CJPayHomeVCProtocol;
@interface CJPayFrontCashierContext : NSObject

@property (nonatomic, readonly, strong) CJPayBDCreateOrderResponse *orderResponse;
@property (nonatomic, copy) CJPayBDCreateOrderResponse *(^latestOrderResponseBlock)(void);
@property (nonatomic, strong, nullable) CJPayDefaultChannelShowConfig *defaultConfig;
@property (nonatomic, copy) NSDictionary *createOrderParams;
@property (nonatomic, copy) NSDictionary *confirmRequestParams;
@property (nonatomic, copy) void(^changeSelectConfigBlock)(CJPayDefaultChannelShowConfig *); // 前置卡列表需要
@property (nonatomic, copy) void(^gotoCardListBlock)(void);
#if __has_include("CJPayHomeVCProtocol.h")
@property (nonatomic, copy) void(^extCallback)(CJPayHomeVCEvent eventType, _Nullable id value);
#endif
@property (nonatomic, weak) UIViewController<CJPayBaseLoadingProtocol> *homePageVC;
@property (nonatomic, copy) NSArray *(^latestNotSufficientFundIds)(void);
@property (nonatomic, copy) NSDictionary *extParams;

@property (nonatomic, readonly, assign) BOOL isPreStandardDesk; // 标识是否是标准前置收银台
@property (nonatomic, readonly, assign) BOOL isNeedResultPage; // 标识是否需要结果页面
@property (nonatomic, assign) BOOL hasChangePayMethod;          // 标识是否切换过支付方式

@end


@interface CJPayFrontCashierResultModel : NSObject

@property (nonatomic, copy) NSString *tradeStatus;
@property (nonatomic, copy) NSString *processInfoStr;
@property (nonatomic, assign) NSInteger closeAfterTime;
@property (nonatomic, strong) CJPayCombinePayLimitModel *limitModel;
@property (nonatomic, copy) NSString *bankCardId;
@property (nonatomic, copy) NSString *combineType;

@end


NS_ASSUME_NONNULL_END
