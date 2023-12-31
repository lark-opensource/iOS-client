//
//  AWEIMGuideSelectionImageView.m
//  CameraClient-Pods-Aweme
//
//  Created by liujingchuan on 2021/9/1.
//

#import "AWEIMGuideSelectionImageView.h"
#import <CreativeKit/UIImage+CameraClientResource.h>


@interface AWEIMGuideSelectionImageView()

@property (strong, nonatomic) UITapGestureRecognizer *selectionTap;

@end

@implementation AWEIMGuideSelectionImageView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.isSelected = YES;
    self.backgroundColor = nil;
    self.userInteractionEnabled = YES;
    self.selectionTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeSelected)];
    self.selectionTap.numberOfTapsRequired = 1;
    self.selectionTap.enabled = YES;
    [self addGestureRecognizer:self.selectionTap];

}

- (void)setIsSelected:(BOOL)isSelected {
    _isSelected = isSelected;
    self.image = isSelected ? [UIImage acc_imageWithName:@"ic_circle_image_selected"] : [UIImage acc_imageWithName:@"ic_circle_image_unselected"];
}

- (void)changeSelected {
    self.isSelected = !self.isSelected;
    if ([self.delegate respondsToSelector:@selector(selectionImageViewDidChangeSelected:)]) {
        [self.delegate selectionImageViewDidChangeSelected:self.isSelected];
    }
}



@end
