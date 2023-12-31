//
//  CJPayProtocolListViewController.h
//  CJPay
//
//  Created by 张海阳 on 2019/6/25.
//

#import "CJPayHalfPageBaseViewController.h"
#import "CJPayQuickPayUserAgreement.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayProtocolListViewController : CJPayHalfPageBaseViewController

@property (nonatomic, copy) NSArray<CJPayQuickPayUserAgreement *> *userAgreements;
@property (nonatomic, copy) void(^agreeCompletion)(void);
@property (nonatomic, assign) BOOL showContinueButton;
@property (nonatomic, copy) void(^protocolListClick)(NSInteger);

@property (nonatomic,copy) NSString *merchantId;
@property (nonatomic,copy) NSString *appId;
@property (nonatomic, assign) BOOL isForBindCardService;
@property (nonatomic, assign) CGFloat height;

@property (nonatomic, assign) BOOL isShowTitleNubmer; //是否展示书名号，兼容旧逻辑，后续统一成新逻辑后可删除

- (instancetype)initWithHeight:(CGFloat)height;

@end

NS_ASSUME_NONNULL_END
