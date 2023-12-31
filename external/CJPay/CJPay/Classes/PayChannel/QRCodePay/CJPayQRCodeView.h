//
// Created by 易培淮 on 2020/10/27.
//

#import "CJPayButton.h"
#import "CJPayCounterLabel.h"
#import "CJPayQRCodeModel.h"

NS_ASSUME_NONNULL_BEGIN
@protocol CJPayQRCodeViewDelegate <NSObject>

- (void)saveImage;
- (void)reloadImage;

@end

@interface CJPayQRCodeView : UIView

@property (nonatomic, strong) CJPayQRCodeModel *qrCodeModel;
@property (nonatomic, strong) CJPayCounterLabel *payAmountLabel;
@property (nonatomic, strong) UILabel *unitLabel;
@property (nonatomic, strong) UILabel *payAmountDiscountLabel;
@property (nonatomic, strong) UILabel *tradeNameLabel;
@property (nonatomic, strong) UILabel *saveLabel;
@property (nonatomic, strong) UIImageView *tbPayIconView;
@property (nonatomic, strong) UIImageView *weBayIconView;
@property (nonatomic, strong) UIView      *imageContainerView;
@property (nonatomic, strong) UIImageView *qrCodeImageView;
@property (nonatomic, strong) UIImageView *faviconView;
@property (nonatomic, strong) UIImageView *loadingView;
@property (nonatomic, strong) UILabel *alertLabel;
@property (nonatomic, strong) UIView  *payMethodBackgroundView;
@property (nonatomic, strong) UILabel *tipsLabel;
@property (nonatomic, strong) CJPayButton *reloadButton;

@property (nonatomic, weak) id<CJPayQRCodeViewDelegate> delegate;

- (UIImage *)getQRCodeImage;
- (instancetype)initWithData:(CJPayQRCodeModel*)model;

@end

NS_ASSUME_NONNULL_END