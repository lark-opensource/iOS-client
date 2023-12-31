//
//  ACCTextReaderToastView.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/3/3.
//

#import "ACCTextReaderToastView.h"

#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/UIColor+CameraClientResource.h>

#import <CreationKitInfra/UIView+ACCMasonry.h>

CGFloat const kACCTextReaderToastViewLightHeight = 27.68;
CGFloat const kACCTextReaderToastViewDarkHeight = 47;

@interface ACCTextReaderToastView ()

@property (nonatomic, strong) UIImageView *contentImageView;
@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation ACCTextReaderToastView

- (instancetype)initWithType:(ACCTextReaderToastViewType)viewType
{
    self = [super init];
    if (self) {
        [self setUserInteractionEnabled:NO];
        if (viewType == ACCTextReaderToastViewTypeLight) {
            [self p_setupUILight];
        } else if (viewType == ACCTextReaderToastViewTypeDark) {
            [self p_setupUIDark];
        }
    }
    return self;
}

- (void)p_setupUILight
{
    _contentImageView = ({
        UIImageView *imageView = [[UIImageView alloc] init];
        [imageView setImage:[ACCResourceImage(@"ic_bubble_nine_patch_white") resizableImageWithCapInsets:UIEdgeInsetsMake(12, 12, 15.68, 12)
                                                                                            resizingMode:UIImageResizingModeStretch]];
        [imageView setTintColor:ACCResourceColor(ACCColorToastDefault)];
        [self addSubview:imageView];
        
        imageView;
    });
    
    _titleLabel = ({
        UILabel *label = [[UILabel alloc] init];
        [label setTextColor:UIColor.blackColor];
        label.numberOfLines = 1;
        [label setFont:[ACCFont() acc_systemFontOfSize:10.f]];
        label.textAlignment = NSTextAlignmentCenter;
        [self addSubview:label];
        
        label;
    });
    
    ACCMasMaker(self.contentImageView, {
        make.top.leading.bottom.trailing.equalTo(self);
        make.height.equalTo(@(kACCTextReaderToastViewLightHeight));
    });
    
    ACCMasMaker(self.titleLabel, {
        make.top.equalTo(self.contentImageView).offset(5);
        make.leading.equalTo(self.contentImageView).offset(9);
        make.bottom.equalTo(self.contentImageView).offset(-8.68);
        make.trailing.equalTo(self.contentImageView).offset(-9);
    });
}

- (void)p_setupUIDark
{
    _contentImageView = ({
        UIImageView *imageView = [[UIImageView alloc] init];
        [imageView setImage:[ACCResourceImage(@"ic_bubble_nine_patch_black") resizableImageWithCapInsets:UIEdgeInsetsMake(12, 12, 17, 12)
                                                                                 resizingMode:UIImageResizingModeStretch]];
        [imageView setTintColor:ACCResourceColor(ACCColorToastDefault)];
        [self addSubview:imageView];
        
        imageView;
    });
    
    _titleLabel = ({
        UILabel *label = [[UILabel alloc] init];
        [label setTextColor:UIColor.whiteColor];
        label.numberOfLines = 1;
        [label setFont:[ACCFont() acc_systemFontOfSize:13.f]];
        label.textAlignment = NSTextAlignmentCenter;
        [self addSubview:label];
        
        label;
    });
    
    ACCMasMaker(self.contentImageView, {
        make.top.leading.bottom.trailing.equalTo(self);
        make.height.equalTo(@(kACCTextReaderToastViewDarkHeight));
    });
    
    ACCMasMaker(self.titleLabel, {
        make.top.equalTo(self.contentImageView).offset(12);
        make.leading.equalTo(self.contentImageView).offset(12);
        make.bottom.equalTo(self.contentImageView).offset(-17);
        make.trailing.equalTo(self.contentImageView).offset(-12);
    });
}

#pragma mark - Public Methods

- (void)updateTitle:(NSString *)title
{
    self.titleLabel.text = [title copy];
    [self.titleLabel sizeToFit];
}

@end
