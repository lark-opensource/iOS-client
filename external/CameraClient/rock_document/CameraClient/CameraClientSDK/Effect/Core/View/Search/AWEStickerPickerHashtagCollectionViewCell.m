//
//  AWEStickerPickerHashtagCollectionViewCell.m
//  CameraClient-Pods-Aweme
//
//  Created by Syenny on 2021/5/24.
//

#import "AWEStickerPickerHashtagCollectionViewCell.h"

#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>

@interface AWEStickerPickerHashtagCollectionViewCell ()

@property (nonatomic, strong) UILabel *label;

@end

@implementation AWEStickerPickerHashtagCollectionViewCell

+ (NSString *)identifier
{
    return NSStringFromClass(self);
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupSubviews];
    }
    return self;
}

- (void)configCellWithTitle:(NSString *)title
{
    [self.label setText:title];
}

- (void)setupSubviews
{
    self.contentView.backgroundColor = ACCResourceColor(ACCColorConstBGContainer5);
    self.contentView.layer.cornerRadius = 14;
    self.contentView.layer.masksToBounds = YES;

    UILabel *label = [[UILabel alloc] init];
    self.label = label;
    label.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
    label.textColor = ACCResourceColor(ACCColorConstTextInverse2);
    label.textAlignment = NSTextAlignmentCenter;

    [self.contentView addSubview:self.label];

    ACCMasMaker(self.label, {
        make.top.equalTo(self.mas_top).offset(5);
        make.bottom.equalTo(self.mas_bottom).offset(-6);
        make.leading.equalTo(self.mas_leading).offset(12);
        make.trailing.equalTo(self.mas_trailing).offset(-12);
    });
}

@end
