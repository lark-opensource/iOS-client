//
//  TMAThumnailView.m
//  OPPluginBiz
//
//  Created by houjihu on 2018/8/29.
//

#import "TMAThumnailView.h"
#import <OPFoundation/UIView+BDPExtension.h>
#import <OPFoundation/UIImage+EMA.h>
#import <OPFoundation/BDPNetworking.h>

const CGFloat TMAThumnailViewSize = 44;

@interface TMAThumnailView ()

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) UIButton *deleteButton;

@end

@implementation TMAThumnailView

#pragma mark - life cycle

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupViews];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self setupViews];
    }
    return self;
}

#pragma mark - setup views

- (void)setupViews {
    self.imageView = ({
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.layer.masksToBounds = YES;
        imageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
        imageView.layer.borderWidth = 0.5;
        imageView;
    });
    self.deleteButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.contentMode = UIViewContentModeCenter;
        [button setImage:[UIImage ema_imageNamed:@"tma_thumnail_delete"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(deleteButtonClicked) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    
    [self addSubview:self.imageView];
    [self addSubview:self.deleteButton];
    self.imageView.frame = CGRectMake(0, 0, TMAThumnailViewSize, TMAThumnailViewSize);
    self.deleteButton.bdp_size = CGSizeMake(22, 22);
    self.deleteButton.bdp_top = -2;
    self.deleteButton.bdp_right = self.imageView.bdp_right + 2;
}

#pragma mark - actions

- (void)showImageWithPath:(NSString *)imagePath {
    if (imagePath.length == 0) {
        [self showImage:nil];
        return;
    }
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    if (image) {
        [self showImage:image];
    } else {
        NSURL *url = [NSURL URLWithString:imagePath];
        [BDPNetworking setImageView:self.imageView url:url placeholder:nil];
    }
}

- (void)showImage:(UIImage *)image {
    self.imageView.image = image;
}

- (void)deleteButtonClicked {
    if (self.deleteImageCompletionBlock) {
        self.deleteImageCompletionBlock();
    }
}

@end
