//
//  CJPayUnionBindCardChooseHeaderView.h
//  Pods
//
//  Created by wangxiaohong on 2021/9/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayUnionPaySignInfo;
@interface CJPayUnionBindCardChooseHeaderView : UIView

@property (nonatomic, strong, readonly) UILabel *titleLabel;

- (void)updateWithUnionPaySignInfo:(CJPayUnionPaySignInfo *)payInfo;
- (void)updateTitle:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
