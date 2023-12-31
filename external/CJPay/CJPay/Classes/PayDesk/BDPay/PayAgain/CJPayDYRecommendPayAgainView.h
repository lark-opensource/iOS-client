//
//  CJPayDYRecommendPayAgainView.h
//  Pods
//
//  Created by wangxiaohong on 2022/3/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayHintInfo;
@class CJPayStyleButton;
@class CJPayLoadingButton;
@interface CJPayDYRecommendPayAgainView : UIView

@property (nonatomic, strong, readonly) CJPayStyleButton *confirmButtton;
@property (nonatomic, strong, readonly) CJPayLoadingButton *otherPayButton;

- (void)refreshWithHintInfo:(CJPayHintInfo *)hintInfo;

@end

NS_ASSUME_NONNULL_END
