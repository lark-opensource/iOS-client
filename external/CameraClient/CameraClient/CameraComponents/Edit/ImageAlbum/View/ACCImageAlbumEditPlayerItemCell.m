//
//  ACCImageAlbumEditPlayerItemCell.m
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2020/12/14.
//

#import "ACCImageAlbumEditPlayerItemCell.h"

@interface ACCImageAlbumEditPlayerItemCell ()

@property (nonatomic, weak) UIView *previewView;

@end

@implementation ACCImageAlbumEditPlayerItemCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.contentView.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)reloadCurrentPreviewViewIfNeed
{
    if (self.previewView) {
        [self reloadWithPreviewView:self.previewView];
    }
}

- (void)reloadWithPreviewView:(UIView *)previewView
{
    // remove old, 需要判断当前contentView, 否则可能会在复用的时候意外移除其他cell的previewView
    if (self.previewView.superview == self.contentView) {
        [self.previewView removeFromSuperview];
    }
    self.previewView = previewView;
    [previewView removeFromSuperview];
    
    // add new
    if (previewView) {
        previewView.frame = self.contentView.bounds;
        [self.contentView addSubview:previewView];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (self.previewView.superview == self.contentView) {
        self.previewView.frame = self.contentView.bounds;
    }
}

@end
