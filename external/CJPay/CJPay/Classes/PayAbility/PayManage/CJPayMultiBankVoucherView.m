//
//  CJPayMultiBankVoucherView.m
//  Pods
//
//  Created by youerwei on 2021/9/6.
//

#import "CJPayMultiBankVoucherView.h"
#import "CJPayUIMacro.h"

@interface CJPayMultiBankVoucherView ()

@property (nonatomic, strong) UIView *multiBankView;
@property (nonatomic, strong) UILabel *voucherLabel;

@end

@implementation CJPayMultiBankVoucherView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _iconRadius = 8;
        [self p_setupUI];
    }
    return self;
}

- (void)updateWithUrls:(NSArray *)urls voucherDesc:(NSString *)voucherDesc voucherDetail:(NSString *)voucherDetail voucherColor:(UIColor *)color {
    [self updateWithUrls:urls voucherDesc:voucherDesc voucherDescColor:nil voucherDetail:voucherDetail voucherDetailColor:color voucherFont:nil];
}

- (void)updateWithUrls:(NSArray *)urls
           voucherDesc:(NSString *)voucherDesc
      voucherDescColor:(UIColor *)voucherDescColor
         voucherDetail:(NSString *)voucherDetail
    voucherDetailColor:(UIColor *)voucherDetailColor
           voucherFont:(UIFont *)font {
    [self.multiBankView cj_removeAllSubViews];
    self.multiBankView.bounds = CGRectMake(0, 0, 44, 16);
    [urls enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            NSURL *url = [NSURL URLWithString:obj];
            UIImageView *imageView = [UIImageView new];
            imageView.layer.cornerRadius = self.iconRadius;
            imageView.alpha = 0.75;
            imageView.clipsToBounds = YES;
            [imageView cj_setImageWithURL:url];
            [self.multiBankView addSubview:imageView];
            CGFloat x = 0 + 14 * idx;
            CGFloat y = 0;
            imageView.frame = CGRectMake(x, y, 16, 16);
            [self p_addCornerBackgroundViewToView:imageView];
        }
    }];

    UIColor *voucherStrColor = [UIColor cj_161823WithAlpha:0.75];
    UIColor *voucherDetailStrColor = [UIColor cj_161823WithAlpha:0.75];
    UIFont *voucherFont = [UIFont cj_boldFontOfSize:14];
    if (voucherDescColor) {
        voucherStrColor = voucherDescColor;
    }
    
    if (voucherDetailColor) {
        voucherDetailStrColor = voucherDetailColor;
    }
    if (font) {
        voucherFont = font;
    }
    // 将view转化为image
    UIImage *multiBankImage = [self p_snapShotImageWithView:self.multiBankView];
    dispatch_queue_t processQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(processQueue, ^{
        NSAttributedString *voucher = [self p_getAttributedStringWithImage:multiBankImage voucherDesc:voucherDesc voucherDescColor:voucherStrColor voucherDetail:voucherDetail voucherDetailColor:voucherDetailStrColor voucherFont:voucherFont];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.voucherLabel.attributedText = voucher;
            self.voucherLabel.textAlignment = NSTextAlignmentCenter;
        });
    });
    
}

- (NSMutableAttributedString *) p_getAttributedStringWithImage:(UIImage *)image
                                                voucherDesc:(NSString *)voucherDesc
                                           voucherDescColor:(UIColor *)voucherStrColor
                                              voucherDetail:(NSString *)voucherDetail
                                         voucherDetailColor:(UIColor *)voucherDetailStrColor
                                                voucherFont:(UIFont *)voucherFont {

    // 创建带图片的富文本
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    attachment.image = image;
    attachment.bounds = CGRectMake(0, -3, 44, 16);
    NSAttributedString *imageAttr = [NSAttributedString attributedStringWithAttachment:attachment];
    
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    paragraphStyle.minimumLineHeight = 21;
    NSMutableAttributedString *voucherStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:CJPayLocalizedStr(@" %@"), voucherDesc] attributes:@{
        NSFontAttributeName : [UIFont cj_fontOfSize:14],
        NSForegroundColorAttributeName : voucherStrColor,
        NSParagraphStyleAttributeName:paragraphStyle
    }];
    NSMutableAttributedString *voucherDetailStr = [[NSMutableAttributedString alloc]initWithString:voucherDetail attributes:@{
        NSFontAttributeName : voucherFont,
        NSForegroundColorAttributeName : voucherDetailStrColor,
        NSParagraphStyleAttributeName:paragraphStyle
    }];
    
    NSMutableAttributedString *voucher = [[NSMutableAttributedString alloc] init];
    [voucher appendAttributedString:imageAttr];
    [voucher appendAttributedString:voucherStr];
    [voucher appendAttributedString:voucherDetailStr];
    
    return voucher;
}

- (void)p_setupUI {
    [self addSubview:self.voucherLabel];
    CJPayMasMaker(self.voucherLabel, {
        make.edges.equalTo(self);
    });
}

- (UIImage *)p_snapShotImageWithView:(UIView *)view {
    BOOL opaque = view.isOpaque;
    view.opaque = NO;
    UIImage *snapshotImage = [view btd_snapshotImage];
    view.opaque = opaque;
    return snapshotImage;
}

- (void)p_addCornerBackgroundViewToView:(UIView *)currentView {
    UIView *bgView = [UIView new];
    bgView.backgroundColor = self.iconBgColor;
    bgView.layer.cornerRadius = self.iconRadius + 1;
    [self.multiBankView insertSubview:bgView belowSubview:currentView];
    
    bgView.frame = CGRectMake(currentView.frame.origin.x - 1, currentView.frame.origin.y - 1, currentView.cj_width, currentView.cj_height);
}

- (UIView *)multiBankView {
    if (!_multiBankView) {
        _multiBankView = [UIView new];
    }
    return _multiBankView;
}

- (UILabel *)voucherLabel {
    if (!_voucherLabel) {
        _voucherLabel = [UILabel new];
        _voucherLabel.numberOfLines = 0;
    }
    return _voucherLabel;
}

- (UIColor *)iconBgColor {
    if (!_iconBgColor) {
        _iconBgColor = [UIColor whiteColor];
    }
    return _iconBgColor;
}


@end
