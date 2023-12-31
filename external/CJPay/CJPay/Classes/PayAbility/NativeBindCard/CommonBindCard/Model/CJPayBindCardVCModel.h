//
//  CJPayBindCardVCModel.h
//  Pods
//
//  Created by renqiang on 2021/6/29.
//

#import <Foundation/Foundation.h>
#import "CJPayTrackerProtocol.h"
#import "CJPayBindCardPageBaseModel.h"
#import "CJPayCardManageModule.h"

NS_ASSUME_NONNULL_BEGIN
@class CJPayMemBankSupportListResponse;
@class CJPayBindPageInfoResponse;
@class CJPayQuickBindCardViewController;
@class CJPayQuickBindCardModel;

// params need in commonModel
@interface CJPayBindCardVCDataModel : CJPayBindCardPageBaseModel

@property (nonatomic, copy) NSString *specialMerchantId;
@property (nonatomic, copy) NSString *signOrderNo;
@property (nonatomic, strong) CJPayBindPageInfoResponse *bankListResponse;
@property (nonatomic, assign) BOOL isEcommerceAddBankCardAndPay;

@end

@interface CJPayBindCardVCLoadModel : NSObject

@property (nonatomic, copy) NSArray<CJPayQuickBindCardModel *> *banksList;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subTitle;
@property (nonatomic, assign) BOOL isShowBottomLabel;
@property (nonatomic, assign) NSInteger banksLength;

@end

@interface CJPayBindCardVCModel : NSObject

@property (nonatomic, weak) id<CJPayTrackerProtocol> trackerDelegate;
@property (nonatomic, weak) UIViewController *viewController;

@property (nonatomic, strong) CJPayMemBankSupportListResponse *supportCardListResponse;
@property (nonatomic, strong, readonly) CJPayQuickBindCardViewController *bindCardViewController;
@property (nonatomic, copy) void(^inputCardNoBlock)(void);
@property (nonatomic, copy) void(^abbrevitionViewButtonBlock)(void);
@property (nonatomic, copy) NSArray<CJPayQuickBindCardModel *> *banksList;//埋点用

#pragma mark - flag
@property (nonatomic, assign) CJPayBindCardStyle vcStyle;
@property (nonatomic, assign) CJPayBindCardStyle latestVCStyle;
@property (nonatomic, assign) BOOL isSyncUnionCard;

+ (NSArray <NSString *>*)dataModelKey;
- (instancetype)initWithBindCardDictonary:(NSDictionary *)dict;
- (void)fetchSupportCardlistWithCompletion:(void (^)(NSError * _Nullable, CJPayMemBankSupportListResponse * _Nullable))completion;
- (CGFloat)getBindCardViewModelsHeight:(CJPayMemBankSupportListResponse *)response;
- (void)updateBanksLength: (NSInteger)length;

- (void)rollUpQuickBindCardList;
- (void)rollDownQuickBindCardList;
- (void)reloadQuickBindCardList;
- (void)reloadQuickBindCardListWith:(CJPayMemBankSupportListResponse *)response;
- (void)reloadQuickBindCardListWith:(CJPayMemBankSupportListResponse *)response showBottomLabel:(BOOL)show;

- (BOOL)isShowOneStep;
- (void)abbreviationButtonClick;
- (NSDictionary *)getCommonTrackerParams;
- (void)setQuickBankInfo:(NSDictionary *)bankInfo;

@end

NS_ASSUME_NONNULL_END
