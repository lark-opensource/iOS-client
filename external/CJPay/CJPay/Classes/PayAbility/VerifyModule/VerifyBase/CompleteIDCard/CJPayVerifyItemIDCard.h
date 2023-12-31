//
//  CJPayVerifyItemIDCard.h
//  CJPay
//
//  Created by liyu on 2020/3/27.
//

#import "CJPayVerifyItem.h"
#import "CJPayStyleErrorLabel.h"
#import "CJPayVerifyIDVCProtocol.h"

NS_ASSUME_NONNULL_BEGIN
@class CJPayFullPageBaseViewController;
@interface CJPayVerifyItemIDCard : CJPayVerifyItem

- (CJPayFullPageBaseViewController<CJPayVerifyIDVCProtocol> *)createVerifyVC;

@end

NS_ASSUME_NONNULL_END
