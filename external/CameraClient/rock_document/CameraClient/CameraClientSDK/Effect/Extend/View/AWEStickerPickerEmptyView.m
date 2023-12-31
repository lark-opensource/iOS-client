//
//  AWEStickerPickerEmptyView.m
//  CameraClient
//
//  Created by zhangchengtao on 2020/4/26.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEStickerPickerEmptyView.h"
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <Masonry/View+MASAdditions.h>

@interface AWEStickerPickerEmptyView ()

@property (nonatomic, strong) UILabel *emptyLabel;

@end

@implementation AWEStickerPickerEmptyView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        
        _emptyLabel = [[UILabel alloc] init];
        _emptyLabel.font = [UIFont systemFontOfSize:15];
        _emptyLabel.numberOfLines = 0;
        _emptyLabel.textColor = ACCResourceColor(ACCUIColorConstTextTertiary4);
        _emptyLabel.textAlignment = NSTextAlignmentCenter;
        _emptyLabel.text = ACCLocalizedString(@"com_mig_you_can_now_add_stickers_to_favorites_to_use_or_find_them_later", nil);
        [self addSubview:_emptyLabel];
        ACCMasMaker(_emptyLabel, {
            make.centerX.equalTo(self);
            make.centerY.equalTo(self);
        });
    }
    return self;
}

@end
