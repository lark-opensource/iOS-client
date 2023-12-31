//
//  CJPayBizWebRiskBannerView.h
//  CJPayBizWebRiskBannerView
//
//  Created by pay_ios_wxh on 2021/9/26.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBizWebRiskBannerView : UIView

@property (nonatomic, copy) void(^closeBlock)(void);

- (void)updateWarnContent:(NSString *)content;

@end

NS_ASSUME_NONNULL_END
