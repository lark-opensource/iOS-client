//
//  CJPayBioGuideFigureViewController.h
//  Pods
//
//  Created by 利国卿 on 2021/12/13.
//

#import "CJPayHalfPageBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayBaseVerifyManager;
@class CJPayResultPageGuideInfoModel;

@interface CJPayBioGuideFigureViewController : CJPayHalfPageBaseViewController<CJPayBaseLoadingProtocol>

@property (nonatomic, strong) CJPayBaseVerifyManager *verifyManager;
@property (nonatomic, strong) CJPayResultPageGuideInfoModel *model;

@property (nonatomic, assign) BOOL isTradeCreateAgain;

+ (instancetype)createWithWithParams:(NSDictionary *)params
                     completionBlock:(void (^)(void))completionBlock;

- (instancetype)initWithGuideInfoModel:(CJPayResultPageGuideInfoModel *)model;


@end

NS_ASSUME_NONNULL_END
