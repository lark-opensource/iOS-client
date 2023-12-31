//
//  BDXTabBarCategoryView.m
//  BDXElement
//
//  Created by hanzheng on 2021/3/5.
//

#import "BDXTabBarCategoryView.h"
#import "BDXTabBarCell.h"
#import "BDXTabBarCellModel.h"
#import "BDXLynxTabBarPro.h"
#import "BDXLynxTabbarItemPro.h"

@interface BDXTabBarCategoryView() <BDXTabbarItemProViewDelegate>

@property (nonatomic, assign) LynxBorderRadii borderRadii;
@property (nonatomic, assign) CGRect lastRect;

@end

@implementation BDXTabBarCategoryView

- (void)layoutSubviews {
    [super layoutSubviews];
    
    LynxBorderRadii radii = self.lynxTabbar.backgroundManager.borderRadius;
    if (LynxHasBorderRadii(radii) && !CGRectEqualToRect(self.bounds, self.lastRect)) {
        LynxBorderRadii currentRadii = self.borderRadii;
        BOOL change = ![NSStringFromLynxBorderRadii(&radii) isEqualToString:NSStringFromLynxBorderRadii(&currentRadii)];
        if (!change) {
            return;
        }
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        CGPathRef layerPath = [LynxBackgroundUtils createBezierPathWithRoundedRect:self.bounds
                                                                  borderRadii:radii];
        shapeLayer.path = layerPath;
        CGPathRelease(layerPath);
        self.layer.mask = shapeLayer;
        self.lastRect = self.bounds;
    }
}

- (void)insertSubview:(UIView *)view atIndex:(NSInteger)index {
    [super insertSubview:view atIndex:index];
}

- (Class)preferredCellClass {
    return [BDXTabBarCell class];
}
- (CGFloat)preferredCellWidthAtIndex:(NSInteger)index {
    if (index < _lynxTabbar.tabItems.count) {
        BDXLynxTabbarItemPro *item = [_lynxTabbar.tabItems objectAtIndex:index];
        return item.view.frame.size.width;
    } else {
        return 0;
    }
}

- (void)refreshDataSource {
    NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity: _lynxTabbar.tabItems.count];
    for (int i = 0; i < _lynxTabbar.tabItems.count; i++) {
        BDXTabBarCellModel *cellModel = [[BDXTabBarCellModel alloc] init];
        [tempArray addObject:cellModel];
    }
    self.dataSource = [NSArray arrayWithArray:tempArray];
}


- (void)refreshCellModel:(BDXCategoryBaseCellModel *)cellModel index:(NSInteger)index {
    [super refreshCellModel:cellModel index:index];
    if (index < _lynxTabbar.tabItems.count) {
        BDXLynxTabbarItemPro *item = [_lynxTabbar.tabItems objectAtIndex:index];
        BDXTabBarCellModel* tabbarModel = (BDXTabBarCellModel* )cellModel;
        item.view.delegate = self;
        tabbarModel.tabbarItem = item;
    } else {
        return;
    }
}

- (BOOL)selectCellAtIndex:(NSInteger)index selectedType:(BDXCategoryCellSelectedType)selectedType {
    BOOL result = [super selectCellAtIndex:index selectedType:selectedType];
    if (!result) {
        return NO;
    }
    if(index < [_lynxTabbar.tabItems count] && _lynxTabbar!=nil) {
        NSString * scene = (selectedType == BDXCategoryCellSelectedTypeClick) ? @"click" : @"slide";
        NSDictionary *info = @{
            @"tag" :  _lynxTabbar.tabItems[index].tabTag ? : @"",
            @"index" : @(index),
            @"scene" : scene
        };
        LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:@"change" targetSign:[_lynxTabbar sign] detail:info];
        [_lynxTabbar.context.eventEmitter sendCustomEvent:event];
    }
    return result;
}

- (void)widthDidChanged:(BDXTabbarItemProView *)view {
    [self refreshState];
    [self.collectionView.collectionViewLayout invalidateLayout];
}

@end
