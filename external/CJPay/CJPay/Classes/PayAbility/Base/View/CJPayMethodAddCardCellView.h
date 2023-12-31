//
//  CJPayMethodAddCardCellView.h
//  CJPay
//
//  Created by 王新华 on 9/3/19.
//

#import <UIKit/UIKit.h>
#import "CJPayMethodTableViewWithArrowCell.h"
#import "CJPayUIMacro.h"

NS_ASSUME_NONNULL_BEGIN
@class MASConstraint;
@class CJPayMethodCellTagView;
@interface CJPayMethodAddCardCellView : CJPayMethodTableViewWithArrowCell <CJPayMethodDataUpdateProtocol>

@property (nonatomic, strong, readonly) UIImageView *addIconImageView;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) CJPayMethodCellTagView *discountView;
@property (nonatomic, strong, readonly) UIView *seperateView;

@property (nonatomic, strong) MASConstraint *titleLabelTopBaseSelfConstraint;
@property (nonatomic, strong) MASConstraint *titleLabelCenterYBaseSelfConstraint;
@property (nonatomic, strong) MASConstraint *titleLabelLeftBaseIconImageConstraint;

- (void)setupUI;

@end

NS_ASSUME_NONNULL_END
