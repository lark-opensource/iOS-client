//
//  ACCToolBarScrollStackView.m
//  ScrollSideBar
//
//  Created by bytedance on 2021/6/16.
//

#import "ACCToolBarScrollStackView.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>

@interface ACCToolBarScrollStackView ()

@end

@implementation ACCToolBarScrollStackView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

-(void) setupUI
{
    self.clipsToBounds = YES;
    _stackView = [[UIStackView alloc] init];
    [self addSubview:_stackView];

    ACCMasMaker(_stackView, {
        make.edges.equalTo(self);
        make.width.equalTo(self);
    });
}

@end
