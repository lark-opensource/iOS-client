//
//  CJPayProtocolDetailViewController.h
//  CJPay
//
//  Created by 张海阳 on 2019/6/25.
//

#import <Foundation/Foundation.h>
#import "CJPayHalfPageBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayProtocolDetailViewController : CJPayHalfPageBaseViewController

@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) void(^agreeCompletionBeforeAnimation)(void);
@property (nonatomic, copy) void(^agreeCompletionAfterAnimation)(void);
@property (nonatomic, assign) BOOL showContinueButton;
@property (nonatomic, copy) NSString *navTitle;

@property (nonatomic,copy) NSString *merchantId;
@property (nonatomic,copy) NSString *appId;
@property (nonatomic,copy) NSString *source;
@property (nonatomic, assign) CGFloat height;

@property (nonatomic, assign) BOOL isShowTitleNubmer; //是否展示书名号，兼容旧逻辑，后续统一成新逻辑后可删除

- (instancetype)initWithHeight:(CGFloat)height;

@end

NS_ASSUME_NONNULL_END
