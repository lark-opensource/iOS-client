//
//  BDXLynxTabbar.m
//  BDXElement
//
//  Created by bytedance on 2020/11/30.
//

#import "BDXLynxTabbarView.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxPropsProcessor.h>
#import <ByteDanceKit/UIColor+BTDAdditions.h>
#import <Lynx/LynxUIMethodProcessor.h>

typedef NS_ENUM(NSInteger, LayoutGravity) {
    LayoutGravityCenter,
    LayoutGravityLeft,
    LayoutGravityFill,
};

#pragma mark -

@interface VernierView : UIView
@property (nonatomic) CGFloat height;
@property (nonatomic) CGFloat width;
@property (nonatomic) CGFloat top;
- (void)updateLocationToCenterX:(CGFloat)centerX width:(CGFloat)width animated:(BOOL)animated;
@end

@interface VernierView ()
@property (nonatomic) NSLayoutConstraint *vernierBottomConstraint;
@property (nonatomic) NSLayoutConstraint *vernierHeightConstraint;
@property (nonatomic) NSLayoutConstraint *vernierLeftConstraint;
@property (nonatomic) NSLayoutConstraint *vernierWidthConstraint;

@property (nonatomic, weak) UICollectionView *associatedCollectionVIew;
@property (nonatomic, weak) UIView *associatedTabbarView;

@property (nonatomic) BOOL isFixedWidth;
@end

@implementation VernierView

- (void)setWidth:(CGFloat)width {
    _width = width;
    self.isFixedWidth = YES;
    if(self.vernierWidthConstraint == nil) return;
    self.vernierWidthConstraint.constant = width;
}

- (void)setHeight:(CGFloat)height {
    _height = height;
    if(self.vernierHeightConstraint == nil) return;
    self.vernierHeightConstraint.constant = height;
}

- (void)setTop:(CGFloat)top {
    _top = top;
    if(self.vernierBottomConstraint == nil) return;
    self.vernierBottomConstraint.constant = -top;
}

- (instancetype) initWithSuperView:(UIView*)sView tabbarView:(UIView*)tabbarView vernierHeight:(CGFloat)height vernierWidth:(CGFloat)width vernierTop:(CGFloat)top color:(UIColor*)color {
    if(self = [super init]) {
        _height = height;
        _width = width;
        _top = top;
        
        self.backgroundColor = color;
        self.layer.cornerRadius = 2;
        self.layer.masksToBounds = YES;

        
        if([sView isKindOfClass:[UICollectionView class]]) {
            self.associatedCollectionVIew = (UICollectionView *)sView;
        }
        self.associatedTabbarView = tabbarView;
    }
    return self;
}

- (void)setupUI {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    if(self.associatedCollectionVIew != nil && self.associatedTabbarView != nil) {
        self.vernierBottomConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.associatedTabbarView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-self.top];
        self.vernierBottomConstraint.active = YES;
        
        self.vernierHeightConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:self.height];
        self.vernierHeightConstraint.active = YES;
        
        self.vernierLeftConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.associatedCollectionVIew attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0];
        self.vernierLeftConstraint.active = YES;
        
        self.vernierWidthConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:(self.isFixedWidth ? self.width : 0)];
        self.vernierWidthConstraint.active = YES;
    }
}

- (void)updateLocationToCenterX:(CGFloat)centerX width:(CGFloat)width animated:(BOOL)animated {
    if(self.vernierLeftConstraint == nil) return;
    if(!self.isFixedWidth) {
        self.vernierLeftConstraint.constant = centerX - width/2;
        self.vernierWidthConstraint.constant = width;
    } else {
        self.vernierLeftConstraint.constant = centerX - self.width/2;
    }
    if(animated) {
        [UIView animateWithDuration:0.25 animations:^{
            [self.associatedCollectionVIew layoutIfNeeded];
        } completion:^(BOOL finished) {
        }];
    }
}

@end

#pragma mark - BDXTabbarViewCell

@interface BDXTabbarViewCell : UICollectionViewCell
@property(nonatomic) NSInteger tabid;
@property(nonatomic) VernierView *associatedVernierView;
- (CGFloat)getCenterX;
- (CGFloat)getWidth;
@end

@implementation BDXTabbarViewCell

- (CGFloat)getCenterX {
    return self.center.x;
}
- (CGFloat)getWidth {
    return self.frame.size.width;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    if(selected){
        [self.associatedVernierView updateLocationToCenterX:self.center.x width:self.frame.size.width animated:YES];
    }else{
        
    }
}

@end

@protocol BDXTabbarViewEventDelegate <NSObject>
@optional
- (void)changeTab:(NSDictionary *)info;
@end

@interface BDXTabbarView () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic) UICollectionView* collectionView;
@property (nonatomic) NSLayoutConstraint *collectionViewHeightConstraint;
@property (nonatomic) NSUInteger selectedIndex;
@property (nonatomic) BOOL hasFirstTimeAutoSelected;

@property (nonatomic) NSArray<BDXLynxTabbarItemView*> *tabbarItems;
@property (nonatomic) VernierView *vernier;
@property (nonatomic) UIView *bottomBorder;
@property (nonatomic) NSLayoutConstraint *bottomBorderWidthConstraint;
@property (nonatomic) NSLayoutConstraint *bottomBorderHeightConstraint;
@property (nonatomic) NSLayoutConstraint *bottomBorderBottomConstraint;

@property (nonatomic, weak) id<BDXTabbarViewEventDelegate> lynxEventDelegate;
@end

@implementation BDXTabbarView

- (instancetype)init {
    if(self = [super init]) {
        self.backgroundColor = [UIColor whiteColor];
        _tabIndicatorColor = [UIColor redColor];
        _tabInterSpace = 9;
        _tabIndicatorWidth = 20;
        _tabIndicatorHeight = 2;
        _tabIndicatorTop = 0;
        _tabLayoutGravity = LayoutGravityCenter;
        _borderHeight = 1;
        _borderWidth = 100;
        _borderColor = [UIColor blackColor];
        _leftMargin = 0;
        _rightMargin = 0;
        _selectedIndex = 0;
        _hasFirstTimeAutoSelected = NO;
    }
    return self;
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.bounces = NO;
        [_collectionView registerClass:[BDXTabbarViewCell class] forCellWithReuseIdentifier:NSStringFromClass([BDXTabbarViewCell class])];
    }
    return _collectionView;
}

- (void)setupUI {
    [self addSubview:self.collectionView];
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *collectionViewLeftConstraint = [NSLayoutConstraint constraintWithItem:self.collectionView
                                                         attribute:NSLayoutAttributeLeft
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeLeft
                                                        multiplier:1.0
                                                           constant:0.0];
    collectionViewLeftConstraint.active = YES;

    NSLayoutConstraint *collectionViewTopConstraint = [NSLayoutConstraint constraintWithItem:self.collectionView
                                                         attribute:NSLayoutAttributeTop
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeTop
                                                        multiplier:1.0
                                                           constant:0.0];
    collectionViewTopConstraint.active = YES;

    NSLayoutConstraint *collectionViewRightConstraint = [NSLayoutConstraint constraintWithItem:self.collectionView
                                                         attribute:NSLayoutAttributeRight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeRight
                                                        multiplier:1.0
                                                           constant:0.0];
    collectionViewRightConstraint.active = YES;

    self.collectionViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.collectionView
                                                         attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeHeight
                                                        multiplier:1.0
                                                           constant:0.0];
    self.collectionViewHeightConstraint.active = YES;
    
    self.vernier = [[VernierView alloc] initWithSuperView:self.collectionView tabbarView:self  vernierHeight:self.tabIndicatorHeight vernierWidth:self.tabIndicatorWidth vernierTop:self.tabIndicatorTop color:self.tabIndicatorColor];
    [self.collectionView addSubview:self.vernier];
    [self.vernier setupUI];
    
    self.bottomBorder = [[UIView alloc] init];
    [self addSubview: self.bottomBorder];
    self.bottomBorder.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSLayoutConstraint *bottomBorderCenterXConstraint = [NSLayoutConstraint constraintWithItem:self.bottomBorder
                                                         attribute:NSLayoutAttributeCenterX
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeCenterX
                                                        multiplier:1.0
                                                           constant:0.0];
    bottomBorderCenterXConstraint.active = YES;

    self.bottomBorderBottomConstraint = [NSLayoutConstraint constraintWithItem:self.bottomBorder
                                                         attribute:NSLayoutAttributeBottom
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeBottom
                                                        multiplier:1.0
                                                           constant:0];
    self.bottomBorderBottomConstraint.active = YES;

    self.bottomBorderWidthConstraint = [NSLayoutConstraint constraintWithItem:self.bottomBorder
                                                         attribute:NSLayoutAttributeWidth
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                        multiplier:1.0
                                                            constant:self.borderWidth];
    self.bottomBorderWidthConstraint.active = YES;

    self.bottomBorderHeightConstraint = [NSLayoutConstraint constraintWithItem:self.bottomBorder
                                                         attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                         attribute:NSLayoutAttributeHeight
                                                        multiplier:1.0
                                                            constant:self.borderHeight];
    self.bottomBorderHeightConstraint.active = YES;
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.item >= [self.tabbarItems count]) return CGSizeZero;
    return [self.tabbarItems objectAtIndex:indexPath.item].frame.size;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return self.tabInterSpace;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return self.tabInterSpace;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, [self tabsOffsetToCenter] + self.leftMargin, 0, self.rightMargin);
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.tabbarItems count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item >= [self.tabbarItems count]) {
        NSAssert(NO, @"BDXTabbarView cellForItemAtIndexPath out of range");
        return nil;
    }
    BDXTabbarViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([BDXTabbarViewCell class]) forIndexPath:indexPath];
    UIView *view = [self.tabbarItems objectAtIndex:indexPath.item].view;
    cell.associatedVernierView = self.vernier;
    view.frame = view.bounds;
    for(UIView *v in [cell.contentView subviews]) {
        [v removeFromSuperview];
    }
    
    [cell.contentView addSubview:view];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(BDXTabbarViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if(!self.hasFirstTimeAutoSelected && self.selectedIndex == indexPath.item){
        cell.selected = YES;
        self.hasFirstTimeAutoSelected = YES;
    }
}

#pragma mark - UICollectionViewDelegate

//- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
//}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.item < [self.tabbarItems count]){
        self.selectedIndex = indexPath.item;
        if([self.lynxEventDelegate respondsToSelector:@selector(changeTab:)]) {
            BDXLynxTabbarItemView *tabItem = [self.tabbarItems objectAtIndex:indexPath.item];
            NSDictionary *info = @{
               
                @"tag" : tabItem.view.tabTag == nil ? @"" : tabItem.view.tabTag,
                @"index" : @(indexPath.item),
                @"scene" : @"click"
            };
            [self.lynxEventDelegate changeTab:info];
        }
        [collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    }
}

- (CGFloat)tabsOriginTotalWidth {
    CGFloat totalWidth = self.leftMargin + self.rightMargin;
    totalWidth += [self.tabbarItems count] > 0 ? ([self.tabbarItems count]-1)*self.tabInterSpace : 0;
    for(BDXTabbarItemView* tabItem in self.tabbarItems){
        totalWidth += tabItem.frame.size.width;
    }
    return totalWidth;
}

- (CGFloat)tabsOffsetToCenter {
    if([self.tabbarItems count] == 0) return 0;
    CGFloat containerWidth = self.collectionView.frame.size.width;
    if([self tabsOriginTotalWidth] >= containerWidth) return 0;
    if(self.tabLayoutGravity == LayoutGravityLeft) return 0;
  
    self.leftMargin = 0;
    self.rightMargin = 0;
    self.tabInterSpace = 0;
    
    CGFloat extraSpacing = containerWidth - [self tabsOriginTotalWidth];
    CGFloat deltaItemSpacing = extraSpacing / [self.tabbarItems count];
    self.tabInterSpace = deltaItemSpacing;
    
    return deltaItemSpacing/2;
}

- (BDXTabbarViewCell *)getCell:(NSUInteger)index {
    return (BDXTabbarViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
}

- (void)scrollToTargetIndex:(NSUInteger)targetIndex sourceIndex:(NSUInteger)sourceIndex percent:(CGFloat)percent {
    BDXTabbarViewCell *sourceCell = [self getCell:sourceIndex];
    BDXTabbarViewCell *targetCell = [self getCell:targetIndex];
    if(sourceCell != nil && targetCell != nil) {
        CGFloat percentCenterX = [sourceCell getCenterX] + ([targetCell getCenterX] - [sourceCell getCenterX]) * percent;
        CGFloat percentWidth = [sourceCell getWidth] + ([targetCell getWidth] - [sourceCell getWidth]) * percent;
        [self.vernier updateLocationToCenterX:percentCenterX width:percentWidth animated:NO];
        if(percent == 1.0) {
            [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:targetIndex inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
            if([self.lynxEventDelegate respondsToSelector:@selector(changeTab:)]) {
                BDXLynxTabbarItemView *tabItem = [self.tabbarItems objectAtIndex:targetIndex];
                NSDictionary *info = @{
                    
                    @"tag" : tabItem.view.tabTag == nil ? @"" : tabItem.view.tabTag,
                    @"index" : @(targetIndex),
                    @"scene" : @"slide"
                };
                [self.lynxEventDelegate changeTab:info];
            }
        }
    }
}

- (void)reselectSelectedIndex {
    if(self.selectedIndex < [self.tabbarItems count]) {
        self.selectedIndex = self.selectedIndex;
    }
}

- (BOOL)directSetSelectedIndex:(NSInteger)index {
    if(index<0 || index >= [self.tabbarItems count]){
        return NO;
    }
    [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
    self.selectedIndex = index;
    return YES;
}

#pragma mark - Setter

- (void)setTabLayoutGravity:(NSInteger)tabLayoutGravity {
    _tabLayoutGravity = tabLayoutGravity;
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)setTabInterSpace:(CGFloat)tabInterSpace {
    _tabInterSpace = tabInterSpace;
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)setTabIndicatorColor:(UIColor *)tabIndicatorColor {
    _tabIndicatorColor = tabIndicatorColor;
    self.vernier.backgroundColor = tabIndicatorColor;
}

- (void)setTabIndicatorWidth:(CGFloat)tabIndicatorWidth {
    _tabIndicatorWidth = tabIndicatorWidth;
    self.vernier.width = tabIndicatorWidth;
}

- (void)setTabIndicatorHeight:(CGFloat)tabIndicatorHeight {
    _tabIndicatorHeight = tabIndicatorHeight;
    self.vernier.height = tabIndicatorHeight;
}

- (void)setTabIndicatorTop:(CGFloat)tabIndicatorTop {
    _tabIndicatorTop = tabIndicatorTop;
    self.vernier.top = tabIndicatorTop;
}

- (void)setBorderHeight:(CGFloat)borderHeight {
    _borderHeight = borderHeight;
    self.bottomBorderHeightConstraint.constant = borderHeight;
}

- (void)setBorderDistanceToBottom:(CGFloat)borderBottomMargin {
    self.bottomBorderBottomConstraint.constant = borderBottomMargin;
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    _borderWidth = borderWidth;
    self.bottomBorderWidthConstraint.constant = borderWidth;
}

- (void)setBorderColor:(UIColor *)borderColor {
    _borderColor = borderColor;
    self.bottomBorder.backgroundColor = borderColor;
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex {
    if(self.delegate != nil)
    {
        if([(NSObject *)self.delegate respondsToSelector:@selector(tabbarViewDidSelectedItemAtIndex:)])
        {
            [self.delegate tabbarViewDidSelectedItemAtIndex:selectedIndex];
        }
    }
}

@end

#pragma mark - BDXLynxTabbar

@interface BDXLynxTabbar () <BDXTabbarViewEventDelegate>
@property (nonatomic) BOOL hasDataChanged;
@end

@implementation BDXLynxTabbar

- (instancetype)init {
    if(self = [super init]) {
        _defaultSelectedIndex = 0;
    }
    return self;
}

- (UIView *)createView {
    BDXTabbarView * view = [[BDXTabbarView alloc] init];
    view.lynxEventDelegate = self;
    [view setupUI];
    return view;
}

- (NSMutableArray<BDXLynxTabbarItemView *> *)tabItems {
    if(_tabItems == nil) {
        _tabItems = [[NSMutableArray alloc] init];
    }
    return _tabItems;
}

- (void)insertChild:(id)child atIndex:(NSInteger)index {
    [super didInsertChild:child atIndex:index];
    if([child isKindOfClass:[BDXLynxTabbarItemView class]]) {
        BDXLynxTabbarItemView *item = (BDXLynxTabbarItemView *)child;
        [self.tabItems insertObject:item atIndex:index];
    }
    self.hasDataChanged = YES;
}

- (void)removeChild:(id)child atIndex:(NSInteger)index {
    [super removeChild:child atIndex:index];
    [self.tabItems removeObjectAtIndex:index];
    self.hasDataChanged = YES;
}

- (void)layoutDidFinished {
    if(self.hasDataChanged) {
        [self view].tabbarItems = self.tabItems;
        [[self view].collectionView.collectionViewLayout invalidateLayout];
        [[self view].collectionView reloadData];
        _hasDataChanged = NO;
    }
}

- (void)propsDidUpdate {
    [super propsDidUpdate];
    _hasDataChanged = YES;
}

#pragma mark - BDXTabbarViewEventDelegate

- (void)changeTab:(NSDictionary *)info {
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:@"change" targetSign:[self sign] detail:info];
    [self.context.eventEmitter sendCustomEvent:event];
}

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-tabbar")
#else
LYNX_REGISTER_UI("x-tabbar")
#endif

- (id<LynxEventTarget>)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    CGPoint tp = [[self view] convertPoint:point toView:[self view].collectionView];
    NSIndexPath *indexPath = [[self view].collectionView indexPathForItemAtPoint:tp];
    NSLog(@"debug: LynxUI indexPath:(%ld,%ld)", (long)indexPath.item, (long)indexPath.section);
    NSLog(@"debug: LynxUI tp hittest:(%f,%f)", tp.x, tp.y);
    NSLog(@"debug: LynxUI point hittest:(%f,%f)", point.x, point.y);
    
    if(indexPath != nil) {
        UICollectionViewCell *cell = [[self view].collectionView cellForItemAtIndexPath:indexPath];
        if(cell == nil) {
            return self;
        }
        CGPoint subPoint = [[self view] convertPoint:point toView:cell];
        LynxUI *hit = (LynxUI *)[[self.tabItems objectAtIndex:indexPath.item] hitTest:subPoint withEvent:event];
        return hit;
    }else{
        return self;
    }
}

//tabbar settings
LYNX_PROP_SETTER("tabbar-background", tabbarBackground, NSString *) {
    _tabbarBackground = [UIColor btd_colorWithHexString:value];
    [self.view.delegate tabbarViewDidChangeProps:self.view];
}

LYNX_PROP_SETTER("background", background , NSString *) {
    _tabbarBackground = [UIColor btd_colorWithHexString:value];
    [self.view.delegate tabbarViewDidChangeProps:self.view];
}

LYNX_PROP_SETTER("tab-layout-gravity", tabLayoutGravity, NSString *) {
    _tabLayoutGravity = value;
    LayoutGravity mode = LayoutGravityCenter;
    if([value isEqual: @"left"]) mode = LayoutGravityLeft;
    else if([value isEqual: @"fill"]) mode = LayoutGravityFill;
    self.view.tabLayoutGravity = mode;
    [self.view.delegate tabbarViewDidChangeProps:self.view];
}

LYNX_PROP_SETTER("tab-inter-space", tabInterSpace, CGFloat) {
    _tabInterSpace = value;
    self.view.tabInterSpace = value;
    [self.view.delegate tabbarViewDidChangeProps:self.view];
}

LYNX_PROP_SETTER("tab-indicator-top", tabIndicatorTop, CGFloat) {
    _tabIndicatorTop = value;
    self.view.tabIndicatorTop = value;
    [self.view.delegate tabbarViewDidChangeProps:self.view];
}

LYNX_PROP_SETTER("tab-indicator-color", tabIndicatorColor, NSString *) {
    _tabIndicatorColor = [UIColor btd_colorWithHexString:value];
    self.view.tabIndicatorColor = _tabIndicatorColor;
    [self.view.delegate tabbarViewDidChangeProps:self.view];
}

LYNX_PROP_SETTER("tab-indicator-width", tabIndicatorWidth, CGFloat) {
    _tabIndicatorWidth = value;
    self.view.tabIndicatorWidth = value;
    [self.view.delegate tabbarViewDidChangeProps:self.view];
}

LYNX_PROP_SETTER("tab-indicator-height", tabIndicatorHeight, CGFloat) {
    _tabIndicatorHeight = value;
    self.view.tabIndicatorHeight = value;
    [self.view.delegate tabbarViewDidChangeProps:self.view];
}

LYNX_PROP_SETTER("border-color", borderColor, NSString *) {
    _borderColor = [UIColor btd_colorWithHexString:value];
    self.view.borderColor = _borderColor;
    [self.view.delegate tabbarViewDidChangeProps:self.view];
}

LYNX_PROP_SETTER("border-width", borderWidth, CGFloat) {
    _borderWidth = value;
    self.view.borderWidth = value;
    [self.view.delegate tabbarViewDidChangeProps:self.view];
}

LYNX_PROP_SETTER("border-height", borderHeight, CGFloat) {
    _borderHeight = value;
    self.view.borderHeight = value;
    [self.view.delegate tabbarViewDidChangeProps:self.view];
}

LYNX_PROP_SETTER("border-top", borderMarginBottom, CGFloat) {
    _borderMarginBottom = value;
    self.view.borderDistanceToBottom = value;
    [self.view.delegate tabbarViewDidChangeProps:self.view];
}

LYNX_PROP_SETTER("hide-indicator", hideIndicator, BOOL) {
    _hideIndicator = value;
    [self.view.delegate tabbarViewDidChangeProps:self.view];
}

LYNX_UI_METHOD(selectTab) {
    BOOL success = NO;
    NSString *msg;
    if ([[params allKeys] containsObject:@"index"]) {
        NSInteger index = [[params objectForKey:@"index"] intValue];
        if([self.view directSetSelectedIndex:index]){
            success = YES;
            msg = @"";
        }else{
            success = NO;
            msg = @"index out of bounds";
        }
    }else{
        success = NO;
        msg = @"no index key";
    }
    callback(
      kUIMethodSuccess, @{
          @"success": @(success),
          @"msg": msg,
      });
}
@end
