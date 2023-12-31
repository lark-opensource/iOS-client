//
//  CJPayResultDetailItemView.h
//  Pods
//
//  Created by wangxiaohong on 2022/7/19.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayResultDetailItemView : UIView

@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *detailLabel;
@property (nonatomic, assign) BOOL needScaleFont;

- (void)updateWithTitle:(NSString *)titleStr detail:(NSString *)detailStr;
- (void)updateFoldViewWithTitle:(NSString *)titleStr detail:(NSString *)detailStr;
- (void)updateWithTitle:(NSString *)titleStr detail:(NSString *)detailStr iconUrl:(NSString * _Nullable)iconUrlStr;

@end

NS_ASSUME_NONNULL_END
