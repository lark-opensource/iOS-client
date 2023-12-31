//
//  CJPayBankCardHeaderSafeBannerViewModel.h
//  Pods
//
//  Created by 孔伊宁 on 2021/8/11.
//

#import "CJPayBaseListViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBankCardHeaderSafeBannerViewModel : CJPayBaseListViewModel

@property (nonatomic, copy) NSDictionary *passParams;

- (void)gotoH5WebView;

@end

NS_ASSUME_NONNULL_END
