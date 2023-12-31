//
//  ACCEditTagsSearchEmptyView.m
//  CameraClient-Pods-AwemeCore
//
//  Created by HuangHongsen on 2021/10/8.
//

#import "ACCEditTagsSearchEmptyView.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCFontProtocol.h>

@interface ACCEditTagsSearchEmptyView ()
@property (nonatomic, strong) UIButton *actionButton;
@property (nonatomic, strong) UILabel *textLabel;
@end

@implementation ACCEditTagsSearchEmptyView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UITapGestureRecognizer *tapOnEmptyView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapOnEmptyView)];
        [self addGestureRecognizer:tapOnEmptyView];
        CGFloat buttonHeight = 36.f;
        self.actionButton = [[UIButton alloc] init];
        self.actionButton.backgroundColor = ACCResourceColor(ACCColorConstBGContainer5);
        self.actionButton.layer.cornerRadius = buttonHeight / 2.f;
        self.actionButton.layer.masksToBounds = YES;
        self.actionButton.titleEdgeInsets = UIEdgeInsetsMake(9, 24, 9, 24);
        [self.actionButton addTarget:self action:@selector(handleTapOnActionButton) forControlEvents:UIControlEventTouchUpInside];
        
        NSAttributedString *attribtuedTitle = [[NSAttributedString alloc] initWithString:@"创建此标记"
                                                                              attributes:@{
                                                                                  NSFontAttributeName : [ACCFont() systemFontOfSize:13.f weight:ACCFontWeightMedium],
                                                                                  NSForegroundColorAttributeName : ACCResourceColor(ACCColorConstTextInverse2)
                                                                              }];
        [self.actionButton setAttributedTitle:attribtuedTitle forState:UIControlStateNormal];
        [self addSubview:self.actionButton];
        ACCMasMaker(self.actionButton, {
            make.centerX.equalTo(self);
            make.height.equalTo(@(buttonHeight));
            make.bottom.equalTo(self).offset(-(ACC_SCREEN_HEIGHT - 44.f - ACC_IPHONE_X_BOTTOM_OFFSET) / 2);
        });
        
        self.textLabel = [[UILabel alloc] init];
        self.textLabel.font = [ACCFont() systemFontOfSize:15.f];
        self.textLabel.textColor = ACCResourceColor(ACCColorConstTextInverse3);
        [self addSubview:self.textLabel];
        ACCMasMaker(self.textLabel, {
            make.centerX.equalTo(self);
            make.bottom.equalTo(self.actionButton.mas_top).offset(-24.f);
        })
    }
    return self;
}

- (void)updateWithText:(NSString *)text
{
    self.textLabel.text = text;
}

- (void)handleTapOnActionButton
{
    [self.delegate didTapOnActionButtonInEmptyView:self];
}

- (void)handleTapOnEmptyView
{
    [self.delegate didTapOnEmptView:self];
}

@end
