//
//  AWETextTopBar.m
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/3/16.
//

#import "AWETextTopBar.h"
#import <Masonry/View+MASAdditions.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCMacros.h>

@interface AWETextTopBar ()

@property (nonatomic, strong) AWETextToolStackView *stackView;


@end

@implementation AWETextTopBar

- (instancetype)initWithBarItemIdentityList:(NSArray<AWETextStackViewItemIdentity> *)itemIdentityList
{
    if (self = [super initWithFrame:CGRectZero]) {
        [self p_setupWithBarItemWithIdentityList:itemIdentityList];
    }
    return self;
}

- (void)p_setupWithBarItemWithIdentityList:(NSArray<AWETextStackViewItemIdentity> *)itemIdentityList
{
    BOOL hasBarItem = !ACC_isEmptyArray(itemIdentityList);
    if (hasBarItem) {
        [self p_setupBarStackViewWithIdentityList:itemIdentityList];
    }
}

- (void)p_setupBarStackViewWithIdentityList:(NSArray<AWETextStackViewItemIdentity> *)itemIdentityList
{
    self.stackView = [[AWETextToolStackView alloc] initWithBarItemIdentityList:itemIdentityList itemViewSize:CGSizeMake(44.f, 44.f) itemSpacing:4.f];
    [self addSubview:self.stackView];
    ACCMasMaker(self.stackView, {
        make.edges.equalTo(self);
    });
}

#pragma mark - AWETextToolStackViewProtocol
- (void)registerItemConfigProvider:(AWETextStackViewItemConfigProvider)provider
                      clickHandler:(AWETextStackViewItemClickHandler)clickHandler
                   forItemIdentity:(AWETextStackViewItemIdentity)itemIdentity
{
    [self.stackView registerItemConfigProvider:provider clickHandler:clickHandler forItemIdentity:itemIdentity];
}

- (void)updateAllBarItems
{
    [self.stackView updateAllBarItems];
}

- (void)updateBarItemWithItemIdentity:(AWETextStackViewItemIdentity)itemIdentity
{
    [self.stackView updateBarItemWithItemIdentity:itemIdentity];
}

- (CGPoint)itemViewCenterOffsetWithItemIdentity:(AWETextStackViewItemIdentity)itemIdentity
{
    return [self.stackView itemViewCenterOffsetWithItemIdentity:itemIdentity];
}
#pragma mark - config
- (CGSize)intrinsicContentSize
{
    return self.stackView.intrinsicContentSize;
}

@end
