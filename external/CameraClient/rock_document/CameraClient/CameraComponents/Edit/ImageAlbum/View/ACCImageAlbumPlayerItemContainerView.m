//
//  ACCImageAlbumPlayerItemContainerView.m
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/8/25.
//

#import "ACCImageAlbumPlayerItemContainerView.h"
#import "ACCImageAlbumEditorGeometry.h"

@interface ACCImageAlbumPlayerItemContainerView ()

@property (nonatomic, assign) CGSize containerSize;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIView *editingView;

@end

@implementation ACCImageAlbumPlayerItemContainerView

- (instancetype)initWithContainerSize:(CGSize)containerSize
{
    if (self = [super initWithFrame:CGRectMake(0, 0, containerSize.width, containerSize.height)]) {
        
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = YES;
        _containerSize = containerSize;
        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        [self addSubview:_imageView];
        _customerContentView = [[UIView alloc] initWithFrame:self.bounds];
        [self addSubview:_customerContentView];
    }
    return self;
}

- (void)updateRenderImage:(UIImage *)image
{
    _renderedImage = image;
    self.imageView.image = image;

    if (image) {
        self.imageView.contentMode = ACCImageEditGetWidthFitImageDisplayContentMode(image.size, self.containerSize);
    }
}

- (void)updateEditingView:(UIView *)editingView
{
    if (editingView != self.editingView &&
        self.editingView.superview == self) {
        [self.editingView removeFromSuperview];
    }
    self.editingView = editingView;
    if (editingView && editingView.superview != self) {
        [editingView removeFromSuperview];
        editingView.frame = self.bounds;
        self.editingView = editingView;
        [self insertSubview:editingView belowSubview:self.customerContentView];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (self.editingView.superview == self) {
        self.editingView.frame = self.bounds;
    }
    self.imageView.frame = self.bounds;
    self.customerContentView.frame = self.bounds;
}

@end
