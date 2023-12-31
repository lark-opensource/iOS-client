//
//  CJPaySignCardView.h
//  CJPaySandBox
//
//  Created by 王晓红 on 2023/7/26.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPaySignCardInfo;
@class CJPayStyleButton;
@class CJPayButton;
@interface CJPaySignCardView : UIView

@property (nonatomic, strong, readonly) CJPayStyleButton *confirmButton;
@property (nonatomic, strong, readonly) CJPayButton *closeButton;

- (void)updateWithSignCardInfo:(CJPaySignCardInfo *)signCardInfo;

@end

NS_ASSUME_NONNULL_END
