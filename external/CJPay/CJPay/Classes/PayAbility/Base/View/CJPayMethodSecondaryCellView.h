//
//  CJPaySecondaryCellView.h
//  CJPay
//
//  Created by 王新华 on 9/4/19.
//

#import <UIKit/UIKit.h>
#import "CJPayMehtodDataUpdateProtocol.h"
#import "CJPayStyleImageView.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayPaddingLabel;
@class CJPayMethodCellTagView;
@class MASConstraint;
@interface CJPayMethodSecondaryCellView : UITableViewCell <CJPayMethodDataUpdateProtocol>

@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) CJPayMethodCellTagView *discountView;
@property (nonatomic, strong, readonly) UILabel *subTitleLabel;
@property (nonatomic, strong, readonly) UIView *seperateView;
@property (nonatomic, strong, readonly) CJPayStyleImageView *rightArrowImage;

@property (nonatomic, strong) MASConstraint *titleLabelTopBaseSelfConstraint;
@property (nonatomic, strong) MASConstraint *titleLabelLeftBaseSelfConstraint;
@property (nonatomic, strong, nullable) MASConstraint *titleLabelCenterYBaseSelfConstraint;

- (void)setupUI;

@end

NS_ASSUME_NONNULL_END
