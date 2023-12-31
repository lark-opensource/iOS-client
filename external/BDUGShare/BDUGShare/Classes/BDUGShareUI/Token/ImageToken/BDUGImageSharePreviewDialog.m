//
//  BDUGImageSharePreviewDialog.m
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/5/14.
//

#import "BDUGImageSharePreviewDialog.h"
#import "BDUGImageShareModel.h"
#import "UIColor+UGExtension.h"
#import "BDUGDialogBaseView.h"
#import "BDUGImageShareDialogManager.h"
#import <ByteDanceKit/ByteDanceKit.h>

@interface BDUGImageSharePreviewDialog ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *tipsLabel;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) CAGradientLayer *bottomMaskLayer;
@property (nonatomic, strong) UIScrollView *imageScrollView;

@end

@implementation BDUGImageSharePreviewDialog

#define kBDUGTokenShareDialogTokenFontSize 14
#define kBDUGTokenShareDialogTokenLineHeight 17
static CGFloat const kImagePreviewDialogHeight = 351;

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        [self addSubview:self.titleLabel];
        [self addSubview:self.tipsLabel];
        [self addSubview:self.imageScrollView];
        [self.imageScrollView addSubview:self.imageView];
        //TODO: 这个蒙版。
        //        [self.imageView.layer addSublayer:self.bottomMaskLayer];
    }
    return self;
}

- (void)refreshContent:(BDUGImageShareContentModel *)contentModel {
    self.titleLabel.text = contentModel.originShareInfo.imageTokenTitle;
    self.tipsLabel.text = contentModel.originShareInfo.imageTokenTips;
    self.imageView.image = contentModel.image;
    [self refreshFrame];
}

- (void)refreshFrame {
    self.titleLabel.frame = CGRectMake(0, 0, self.frame.size.width, 25);
    if (self.tipsLabel.text.length > 0) {
        self.tipsLabel.frame = CGRectMake(24, self.titleLabel.btd_bottom + 6, self.btd_width - 2 * 24, 38);
        self.imageScrollView.frame = CGRectMake(40, self.tipsLabel.btd_bottom + 24, 220, 260);
        self.btd_height = kImagePreviewDialogHeight;
    } else {
        self.imageScrollView.frame = CGRectMake(40, self.titleLabel.btd_bottom + 24, 220, 260);
        self.btd_height = kImagePreviewDialogHeight - 6 - 38;
    }
    self.imageView.frame = CGRectMake(0, 0, self.imageScrollView.btd_width, self.imageView.image.size.height / self.imageView.image.size.width * self.imageScrollView.btd_width);
    if (self.imageView.btd_height > self.imageScrollView.btd_height * 1.5) {
        //高度超过1.5，滑动。
        self.imageScrollView.scrollEnabled = YES;
        
        //@qiuqian， 长图从20dp处开始滑动。【375的屏幕】
        CGFloat offset = 20.0 / 375.0 * self.imageView.btd_width;
        self.imageScrollView.contentSize = CGSizeMake(0, self.imageView.btd_height - offset);
        self.imageView.btd_top = -1 * offset;

    } else {
        self.imageScrollView.scrollEnabled = NO;
        if (self.imageView.btd_height < self.imageScrollView.btd_height) {
            //短图，button顶上去。
            self.btd_height -= self.imageScrollView.btd_height - self.imageView.btd_height;
            self.imageScrollView.btd_height = self.imageView.btd_height;
        }
    }
    
    CGFloat gapHeight = CGRectGetMaxY(self.imageView.frame) - self.btd_height;
    self.bottomMaskLayer.frame = CGRectMake(0, self.imageView.btd_height - gapHeight - 17, self.imageView.btd_width, 17);
}

#pragma mark - setter && getter

- (UILabel *)titleLabel {
    if (_titleLabel == nil) {
        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont boldSystemFontOfSize:19];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.textColor = [UIColor colorWithHexString:@"222222"];
    }
    return _titleLabel;
}

- (UILabel *)tipsLabel {
    if (_tipsLabel == nil) {
        _tipsLabel = [UILabel new];
        _tipsLabel.font = [UIFont systemFontOfSize:14];
        _tipsLabel.textColor = [UIColor colorWithHexString:@"999999"];
        _tipsLabel.textAlignment = NSTextAlignmentCenter;
        _tipsLabel.numberOfLines = 2;
    }
    return _tipsLabel;
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [UIImageView new];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
    }
    return _imageView;
}

- (CAGradientLayer *)bottomMaskLayer {
    if (!_bottomMaskLayer) {
        _bottomMaskLayer = [CAGradientLayer layer];
        _bottomMaskLayer.startPoint = CGPointMake(0, 0);
        _bottomMaskLayer.endPoint = CGPointMake(0, 1);
        _bottomMaskLayer.colors = @[
                                    (__bridge id)[[UIColor whiteColor] colorWithAlphaComponent:0.5].CGColor,
                                    (__bridge id)[[UIColor whiteColor] colorWithAlphaComponent:0.0].CGColor,
                                    ];
    }
    return _bottomMaskLayer;
}

- (UIScrollView *)imageScrollView
{
    if (!_imageScrollView) {
        _imageScrollView = [[UIScrollView alloc] init];
        _imageScrollView.showsVerticalScrollIndicator = NO;
        _imageScrollView.showsHorizontalScrollIndicator = NO;
    }
    return _imageScrollView;
}

@end
