//
//  AWETextToolStackView.m
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/3/16.
//

#import "AWETextToolStackView.h"
#import <Masonry/View+MASAdditions.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCAnimatedButton.h>
#import <CreativeKit/NSArray+ACCAdditions.h>

@interface AWETextToolStackViewItemWrap : NSObject

@property (nonatomic, copy) AWETextStackViewItemIdentity itemIdentity;
@property (nonatomic, strong) ACCAnimatedButton *itemView;
@property (nonatomic, copy) AWETextStackViewItemConfigProvider configProvider;
@property (nonatomic, copy) AWETextStackViewItemClickHandler clickHandler;
@property (nonatomic, strong) AWETextStackViewItemConfig *itemConfig;
@property (nonatomic, assign) NSInteger index;

@end

@interface AWETextToolStackView ()

@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, assign) CGSize stackViewSize;
@property (nonatomic, assign) CGSize itemViewSize;
@property (nonatomic, assign) CGFloat itemSpacing;

@property (nonatomic, copy) NSArray<AWETextToolStackViewItemWrap *> *itemWraps;

@end

@implementation AWETextToolStackView

#pragma mark - life cycle
- (instancetype)initWithBarItemIdentityList:(NSArray *)itemIdentityList
                               itemViewSize:(CGSize)itemViewSize
                                itemSpacing:(CGFloat)itemSpacing
{
   
    if (self = [super initWithFrame:CGRectZero]) {
        [self p_setupWithStackViewWithIdentityList:itemIdentityList
                                      itemViewSize:itemViewSize
                                       itemSpacing:itemSpacing];
    }
    return self;
}

#pragma mark - public
- (void)updateAllBarItems
{
    [self.itemWraps enumerateObjectsUsingBlock:^(AWETextToolStackViewItemWrap * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self p_updateBarItemWithItemWrap:obj];
    }];
}

- (void)updateBarItemWithItemIdentity:(AWETextStackViewItemIdentity)itemIdentity
{
    [self p_updateBarItemWithItemWrap:[self p_findItemConfigWithItemIdentity:itemIdentity]];
}

- (void)registerItemConfigProvider:(AWETextStackViewItemConfigProvider)provider
                      clickHandler:(AWETextStackViewItemClickHandler)clickHandler
                   forItemIdentity:(AWETextStackViewItemIdentity)itemIdentity
{
    AWETextToolStackViewItemWrap *itemWrap = [self p_findItemConfigWithItemIdentity:itemIdentity];
    itemWrap.configProvider = provider;
    itemWrap.clickHandler = clickHandler;
}

- (CGPoint)itemViewCenterOffsetWithItemIdentity:(AWETextStackViewItemIdentity)itemIdentity
{
    AWETextToolStackViewItemWrap *itemWrap = [self p_findItemConfigWithItemIdentity:itemIdentity];
    if (!itemWrap) {
        return CGPointZero;
    }
    
    CGFloat px =  itemWrap.index * (self.itemViewSize.width + self.itemSpacing);
    CGFloat centerX =  px + self.itemViewSize.width / 2.f;
    CGFloat centerXOffset = centerX - self.stackViewSize.width / 2.f;
    return CGPointMake(centerXOffset, 0);
}

#pragma mark - private
- (void)p_updateBarItemWithItemWrap:(AWETextToolStackViewItemWrap *)itemWrap
{
    if (!itemWrap || itemWrap.configProvider == nil) {
        return;
    }
    
    itemWrap.configProvider(self, itemWrap.itemConfig);
    
    [itemWrap.itemView setEnabled:itemWrap.itemConfig.enable];
    [itemWrap.itemView setImage:itemWrap.itemConfig.iconImage forState:UIControlStateNormal];
    if (!ACC_isEmptyString(itemWrap.itemConfig.title)) {
        itemWrap.itemView.accessibilityLabel = itemWrap.itemConfig.title;
        itemWrap.itemView.accessibilityTraits = UIAccessibilityTraitButton;
    }
}

- (void)p_onBarItemSelect:(UIButton *)btn
{
    
    __block AWETextToolStackViewItemWrap *itemWrap;
    [self.itemWraps enumerateObjectsUsingBlock:^(AWETextToolStackViewItemWrap * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.itemView == btn) {
            itemWrap = obj;
            *stop = YES;
        }
    }];
    
    ACCBLOCK_INVOKE(itemWrap.clickHandler, self);
    
    [self p_updateBarItemWithItemWrap:itemWrap];
}

- (AWETextToolStackViewItemWrap *)p_findItemConfigWithItemIdentity:(AWETextStackViewItemIdentity)itemIdentity
{
    if (ACC_isEmptyString(itemIdentity)) {
        return nil;
    }
    
    __block AWETextToolStackViewItemWrap *itemWrap;
    [self.itemWraps enumerateObjectsUsingBlock:^(AWETextToolStackViewItemWrap * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (AWETextStackViewItemIdentityEqual(itemIdentity, obj.itemIdentity)) {
            itemWrap = obj;
            *stop = YES;
        }
    }];
    
    return itemWrap;
}

#pragma mark - setup
- (void)p_setupWithStackViewWithIdentityList:(NSArray<AWETextStackViewItemIdentity> *)itemIdentityList
                                itemViewSize:(CGSize)itemViewSize
                                 itemSpacing:(CGFloat)itemSpacing
{
    self.itemSpacing = itemSpacing;
    self.itemViewSize = itemViewSize;
    
    if (ACC_isEmptyArray(itemIdentityList)) {
        self.stackViewSize = CGSizeZero;
        return;
    }
    
    NSInteger itemCount = itemIdentityList.count;
    CGFloat stackViewWith = itemCount * itemViewSize.width + (itemCount - 1) * itemSpacing;
    self.stackViewSize = CGSizeMake(MAX(0, stackViewWith), itemViewSize.height);
    
    NSMutableArray <AWETextToolStackViewItemWrap *> *itemWraps =  [NSMutableArray array];
    
    [itemIdentityList enumerateObjectsUsingBlock:^(AWETextStackViewItemIdentity  _Nonnull identity, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (!ACC_isEmptyString(identity)) {
            
            ACCAnimatedButton *view = [[ACCAnimatedButton alloc] init];
            view.imageView.contentMode = UIViewContentModeCenter;
            [view addTarget:self action:@selector(p_onBarItemSelect:) forControlEvents:UIControlEventTouchUpInside];

            view.isAccessibilityElement = YES;
            view.accessibilityTraits = UIAccessibilityTraitButton;
            AWETextToolStackViewItemWrap *itemWrap = [[AWETextToolStackViewItemWrap alloc] init];
            itemWrap.itemIdentity = identity;
            itemWrap.itemView = view;
            itemWrap.itemConfig = [AWETextStackViewItemConfig new];
            itemWrap.index = idx;
            [itemWraps addObject:itemWrap];
        } else {
            NSAssert(NO, @"identity should not be empty");
        }
    }];
    
    self.itemWraps = [itemWraps copy];
    
    NSArray <UIView *> *arrangedSubviews = [self.itemWraps acc_mapObjectsUsingBlock:^UIView * _Nonnull(AWETextToolStackViewItemWrap * _Nonnull obj, NSUInteger idex) {
        return obj.itemView;
    }];
    
    self.stackView = ({
        
        UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:[arrangedSubviews copy]];
        [self addSubview:stackView];
        ACCMasMaker(stackView, {
            make.edges.equalTo(self);
        });
        stackView.axis = UILayoutConstraintAxisHorizontal;
        stackView.alignment = UIStackViewAlignmentFill;
        stackView.distribution = UIStackViewDistributionFillEqually;
        stackView.spacing = itemSpacing;
        stackView;
    });

    self.stackView.isAccessibilityElement = NO;
}

- (CGSize)intrinsicContentSize
{
    return self.stackViewSize;
}

@end

@implementation AWETextStackViewItemConfig

+ (instancetype)configWithIconImage:(UIImage *)iconImage enable:(BOOL)enable
{
    AWETextStackViewItemConfig *config = [AWETextStackViewItemConfig new];
    config.iconImage = iconImage;
    config.enable = enable;
    return config;
}

@end


@implementation AWETextToolStackViewItemWrap



@end
