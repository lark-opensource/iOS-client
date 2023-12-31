//
//  CJPayCardUpdateViewController.h
//  CJPay
//
//  Created by wangxiaohong on 2020/3/30.
//

#import "CJPayFullPageBaseViewController.h"
#import "CJPayDefaultChannelShowConfig.h"
#import "CJPayTrackerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^CJPayCardUpdateSuccessCompletion)(BOOL isSuccess);

@class CJPayCardUpdateModel;
@interface CJPayCardUpdateViewController : CJPayFullPageBaseViewController

- (instancetype)initWithCardUpdateModel:(CJPayCardUpdateModel *)cardUpdateModel;

@property (nonatomic, copy) CJPayCardUpdateSuccessCompletion cardUpdateSuccessCompletion;

@property (nonatomic, weak) id<CJPayTrackerProtocol> trackDelegate;

@end

NS_ASSUME_NONNULL_END
