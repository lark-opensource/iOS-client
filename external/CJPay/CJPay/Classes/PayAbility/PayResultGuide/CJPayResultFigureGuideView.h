//
//  CJPayResultFigureGuideView.h
//  Pods
//
//  Created by 利国卿 on 2021/12/8.
//

#import <UIKit/UIKit.h>
#import "CJPayUIMacro.h"
#import "CJPayCommonProtocolView.h"
#import "CJPayStyleButton.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayResultPageGuideInfoModel;
@interface CJPayResultFigureGuideView : UIView

@property (nonatomic, copy) void(^confirmBlock)(void);
@property (nonatomic, copy) void(^protocolClickBlock)(void);

@property (nonatomic, strong) UILabel *mainGuideLabel;
@property (nonatomic, strong) UILabel *subGuideLabel;
@property (nonatomic, strong) UIImageView *guideFigure;
@property (nonatomic, strong) CJPayStyleButton *confirmButton;
@property (nonatomic, strong) CJPayCommonProtocolView *protocolView;
@property (nonatomic, strong) UIImageView *iconImage;
@property (nonatomic, strong) UILabel *voucherAmountLabel;
@property (nonatomic, strong) UIImageView *flickView;

- (instancetype)initWithGuideInfoModel:(CJPayResultPageGuideInfoModel *)model;
- (instancetype)initWithGuideInfoModel:(CJPayResultPageGuideInfoModel *)model showBackView:(BOOL)showBackView;
- (void)confirmButtonAnimation;

@end

NS_ASSUME_NONNULL_END
