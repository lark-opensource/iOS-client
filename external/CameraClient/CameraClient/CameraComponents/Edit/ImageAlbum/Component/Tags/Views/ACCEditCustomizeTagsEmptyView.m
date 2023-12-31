//
//  ACCEditCustomizeTagsEmptyView.m
//  CameraClient-Pods-AwemeCore
//
//  Created by HuangHongsen on 2021/10/8.
//

#import "ACCEditCustomizeTagsEmptyView.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>

@interface ACCEditCustomizeTagsEmptyView()
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UIButton *actionButton;
@end

@implementation ACCEditCustomizeTagsEmptyView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        CGFloat actionButtonHeight = 44.f;
        _actionButton = [ACCEditCustomizeTagsEmptyView generateNewTagActionButtonWithHeight:actionButtonHeight];
        [_actionButton addTarget:self action:@selector(handleTapOnActionButton) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:_actionButton];
        ACCMasMaker(_actionButton, {
            make.center.equalTo(self);
            make.width.equalTo(@187);
            make.height.equalTo(@(actionButtonHeight));
        });
        
        _textLabel = [[UILabel alloc] init];
        _textLabel.textColor = ACCResourceColor(ACCColorConstTextInverse3);
        _textLabel.font = [ACCFont() systemFontOfSize:15.f];
        _textLabel.text = @"快来创建属于你的自定义标记吧！";
        [self addSubview:_textLabel];
        ACCMasMaker(_textLabel, {
            make.bottom.equalTo(self.actionButton.mas_top).offset(-24);
            make.centerX.equalTo(self.actionButton);
        });
        
        _iconImageView = [[UIImageView alloc] init];
        _iconImageView.backgroundColor = [UIColor clearColor];
        _iconImageView.image = ACCResourceImage(@"icon_edit_tags_custom_empty");
        [self addSubview:_iconImageView];
        ACCMasMaker(_iconImageView, {
            make.bottom.equalTo(self.textLabel.mas_top).offset(-24);
            make.centerX.equalTo(self.textLabel).offset(-2);
            make.width.equalTo(@103);
            make.height.equalTo(@93);
        });
    }
    return self;
}

- (void)handleTapOnActionButton
{
    [self.delegate didTapOnActionButtonInEmptyView:self];
}

+ (UIButton *)generateNewTagActionButtonWithHeight:(CGFloat)actionButtonHeight
{
    UIButton *actionButton = [[UIButton alloc] init];
    actionButton.backgroundColor = ACCResourceColor(ACCColorConstBGContainer5);
    actionButton.layer.cornerRadius = actionButtonHeight / 2.f;
    actionButton.layer.masksToBounds = YES;
    UIImageView *buttonIcon = [[UIImageView alloc] init];
    buttonIcon.image = ACCResourceImage(@"icon_edit_tags_create");
    
    [actionButton addSubview:buttonIcon];
    
    ACCMasMaker(buttonIcon, {
        make.centerY.equalTo(actionButton);
        make.width.height.equalTo(@20);
        make.left.equalTo(actionButton).offset(40.f);
    });
    
    UILabel *textLabel = [[UILabel alloc] init];
    textLabel.textColor = ACCResourceColor(ACCColorConstTextInverse);
    textLabel.font = [ACCFont() systemFontOfSize:14.f weight:ACCFontWeightMedium];
    textLabel.text = @"创建新标记";
    
    [actionButton addSubview:textLabel];
    ACCMasMaker(textLabel, {
        make.centerY.equalTo(actionButton);
        make.left.equalTo(buttonIcon.mas_right).offset(4);
    });
    
    return actionButton;
}

@end
