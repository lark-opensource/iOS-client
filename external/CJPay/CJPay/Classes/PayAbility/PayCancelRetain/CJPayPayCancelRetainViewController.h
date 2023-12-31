//
//  CJPayPayCancelRetainViewController.h
//  Pods
//
//  Created by chenbocheng on 2021/8/9.
//

#import "CJPayPopUpBaseViewController.h"
#import "CJPayRetainInfoModel.h"
#import "CJPayEnumUtil.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayPayCancelRetainViewController : CJPayPopUpBaseViewController

@property (nonatomic, assign) BOOL isDescTextAlignmentLeft; // default is NO, text AlignmentCenter

- (instancetype)initWithRetainInfoModel:(CJPayRetainInfoModel *)model;

@end

NS_ASSUME_NONNULL_END
