//
//  CJPayQuickBindCardManager.h
//  Pods
//
//  Created by xutianxi on 2022/01/26.
//

#import <Foundation/Foundation.h>
#import "CJPayBindCardSharedDataModel.h"
#import "CJPayBindCardPageBaseModel.h"
#import "CJPayCreateOneKeySignOrderResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDPayQuickBindCardSignOrderModel : CJPayBindCardPageBaseModel

@property (nonatomic, assign) CJPayCardBindSourceType cardBindSource;
@property (nonatomic, strong) CJPayProcessInfo *processInfo;
@property (nonatomic, assign) BOOL isQuickBindCard;
@property (nonatomic, strong) CJPayQuickBindCardModel *quickBindCardModel; // 一键绑卡时 model
@property (nonatomic, copy) NSString *specialMerchantId;
@property (nonatomic, strong) CJPayUserInfo *userInfo;
@property (nonatomic, copy) NSString *signOrderNo;
@property (nonatomic, copy) NSString *frontIndependentBindCardSource;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subTitle;
@property (nonatomic, copy) NSDictionary *bindCardInfo;
@property (nonatomic, copy) NSDictionary *trackerParams;
@property (nonatomic, assign) BOOL isShowAddCardLabel;
// @"DEBIT" 或者 "CREDIT"
@property (nonatomic, copy) NSString *selectedCardType;

@end

@interface CJPayQuickBindCardManager : NSObject

+ (instancetype)shared;

- (void)bindCardWithCommonModel:(CJPayBindCardSharedDataModel *)bindCardCommonModel
                completionBlock:(nonnull void (^)(BOOL isOpenedSuccess, UIViewController *firstVC))completionBlock;

- (void)startOneKeySignOrderFromVC:(UIViewController *)fromVC
                    signOrderModel:(BDPayQuickBindCardSignOrderModel *)model
                         extParams:(NSDictionary *)extDict
         createSignOrderCompletion:(void (^)(CJPayCreateOneKeySignOrderResponse *))createSignOrderCompletion
                        completion:(void (^)(BOOL))completion;

- (void)queryOneKeySignState;
- (void)queryOneKeySignStateAppDidEnterForground;

@end

NS_ASSUME_NONNULL_END
