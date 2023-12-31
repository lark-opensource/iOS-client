//
//  CAKAlbumSelectAlbumButton.m
//  CreativeAlbumKit
//
//  Created by yuanchang on 2020/12/6.
//

#import "CAKAlbumSelectAlbumButton.h"

#import <Masonry/Masonry.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>

@implementation CAKAlbumSelectAlbumButton

- (instancetype)initWithType:(CAKAnimatedButtonType)btnType
{
    if (self = [super initWithType:btnType]) {
        self.leftLabel = [[UILabel alloc] init];
        self.leftLabel.font = [ACCFont() acc_boldSystemFontOfSize:17];
        
        self.rightImageView = [[UIImageView alloc] init];
        self.rightImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.rightImageView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        
        [self addSubview:self.leftLabel];
        [self addSubview:self.rightImageView];
        
        ACCMasMaker(self.leftLabel, {
            make.left.equalTo(self.mas_left);
            make.right.equalTo(self.rightImageView.mas_left);
            make.height.lessThanOrEqualTo(self);
            make.centerY.equalTo(self.mas_centerY);
        });
        
        ACCMasMaker(self.rightImageView, {
            make.right.equalTo(self.mas_right);
            make.centerY.equalTo(self.mas_centerY);
        });
    }
    return self;
}

- (instancetype)initWithType:(CAKAnimatedButtonType)btnType titleAndImageInterval:(CGFloat)interval
{
    if (self = [super initWithType:btnType]) {
        self.leftLabel = [[UILabel alloc] init];
        self.leftLabel.font = [ACCFont() acc_boldSystemFontOfSize:17];
        
        self.rightImageView = [[UIImageView alloc] init];
        self.rightImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.rightImageView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        
        [self addSubview:self.leftLabel];
        [self addSubview:self.rightImageView];
        
        ACCMasMaker(self.leftLabel, {
            make.left.equalTo(self.mas_left);
            make.right.equalTo(self.rightImageView.mas_left).offset(-interval);
            make.height.lessThanOrEqualTo(self);
            make.centerY.equalTo(self.mas_centerY);
        });
        
        ACCMasMaker(self.rightImageView, {
            make.right.equalTo(self.mas_right);
            make.centerY.equalTo(self.mas_centerY);
        });
    }
    return self;
}

@end
