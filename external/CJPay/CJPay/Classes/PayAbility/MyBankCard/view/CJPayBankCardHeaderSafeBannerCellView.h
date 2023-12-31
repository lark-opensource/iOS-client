//
//  CJPayBankCardHeaderSafeBannerCellView.h
//  Pods
//
//  Created by 孔伊宁 on 2021/8/11.
//

#import "CJPayStyleBaseListCellView.h"

@class CJPayBankCardHeaderSafeBannerViewModel;

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBankCardHeaderSafeBannerCellView : CJPayStyleBaseListCellView

@property (nonatomic, strong) CJPayBankCardHeaderSafeBannerViewModel *safeBannerViewModel;

- (void)updateSafeString:(NSString *)str;

@end

NS_ASSUME_NONNULL_END
