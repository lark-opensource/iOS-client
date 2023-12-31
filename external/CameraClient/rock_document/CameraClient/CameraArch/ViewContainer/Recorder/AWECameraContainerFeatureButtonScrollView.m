//
//  AWECameraContainerFeatureButtonScrollView.m
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/5/6.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "AWECameraContainerFeatureButtonScrollView.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/UIDevice+ACCHardware.h>

@interface AWECameraContainerFeatureButtonScrollView ()

@property (nonatomic, strong, readwrite, nullable) NSMutableArray<AWECameraContainerToolButtonWrapView *> *activeButtons;// ordered array for active buttons
@property (nonatomic, strong, readwrite, nullable) NSMutableArray<AWECameraContainerToolButtonWrapView *> *deactiveButtons;// ordered array for deactive buttons
@property (nonatomic, strong) NSMutableArray *maskViews;

@end

@implementation AWECameraContainerFeatureButtonScrollView

#pragma mark - Override
- (instancetype)init
{
    if (self = [super init]) {
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self p_layoutVisibleButtons];
}

#pragma mark - Public

- (void)addFeatureView:(AWECameraContainerToolButtonWrapView *)featureView
{
    NSMutableArray *buttons = [NSMutableArray arrayWithArray:self.allButtons];
    [buttons addObject:featureView];
    self.allButtons = buttons;
    
    [self addSubview:featureView];
    
    if (featureView.isHidden || featureView.alpha == 0 || !featureView.needShow) {
        featureView.hidden = NO;
        featureView.alpha = 0;
        [self.deactiveButtons addObject:featureView];
    } else {
        featureView.hidden = NO;
        featureView.alpha = 1;
        [self.activeButtons addObject:featureView];
    }
    
    //sort and layout
    [self p_sortAllButtons];
    [self p_layoutVisibleButtons];
}

- (AWECameraContainerToolButtonWrapView *)getViewForBarItem:(ACCBarItem *)barItem
{
    if (!barItem) {
        //fallback
        return [AWECameraContainerToolButtonWrapView new];
    }
    
    __block AWECameraContainerToolButtonWrapView *res;
    [self.allButtons enumerateObjectsUsingBlock:^(AWECameraContainerToolButtonWrapView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.itemID == barItem.itemId) {
            res = obj;
            *stop = YES;
        }
    }];
    return res;
}

- (void)insertItem:(ACCBarItem *)item
{
    AWECameraContainerToolButtonWrapView *view = [self getViewForBarItem:item];
    if (view && [self.deactiveButtons containsObject:view]) {
        [self.deactiveButtons removeObject:view];
        [self.activeButtons addObject:view];
        [self p_sortAllButtons];
        [self p_layoutVisibleButtons];
        view.alpha = 1;
    }
}

- (void)removeItem:(ACCBarItem *)item
{
    AWECameraContainerToolButtonWrapView *view = [self getViewForBarItem:item];
    if (view && [self.activeButtons containsObject:view]) {
        [self.activeButtons removeObject:view];
        [self.deactiveButtons addObject:view];
        [self p_sortAllButtons];
        [self p_layoutVisibleButtons];
        view.alpha = 0;
    }
}

- (void)insertMaskViewAboveToolBar:(UIView *)maskView
{
    [self.maskViews addObject:maskView];
    [self p_layoutVisibleButtons];
}

#pragma mark - Private

- (void)p_sortAllButtons
{
    NSArray *toolBarSortItemArray = [self.sortDataSrouce barItemSortArray];
    NSArray<AWECameraContainerToolButtonWrapView *> *(^sort)(NSArray<AWECameraContainerToolButtonWrapView *> *arrayToSort) = ^(NSArray<AWECameraContainerToolButtonWrapView *> *arrayToSort) {
        return [arrayToSort sortedArrayUsingComparator:^NSComparisonResult(AWECameraContainerToolButtonWrapView *obj1, AWECameraContainerToolButtonWrapView *obj2) {
            NSComparisonResult result = NSOrderedSame;
            if (([toolBarSortItemArray indexOfObject:[NSValue valueWithPointer:obj1.itemID]] != NSNotFound) && ([toolBarSortItemArray indexOfObject:[NSValue valueWithPointer:obj2.itemID]] != NSNotFound)) {
                NSNumber *index1 = @([toolBarSortItemArray indexOfObject:[NSValue valueWithPointer:obj1.itemID]]);
                NSNumber *index2 = @([toolBarSortItemArray indexOfObject:[NSValue valueWithPointer:obj2.itemID]]);
                result = [index1 compare:index2];
            }
            return result;
        }];
    };
    
    self.allButtons = sort(self.allButtons);
    self.deactiveButtons = sort(self.deactiveButtons).mutableCopy;
    self.activeButtons = sort(self.activeButtons).mutableCopy;
}

- (void)p_layoutVisibleButtons
{
    __block CGFloat topY = 0;
    [self.visibleButtons enumerateObjectsUsingBlock:^(AWECameraContainerToolButtonWrapView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.acc_top = topY;
        obj.acc_centerX = self.acc_centerX;
        topY += obj.acc_height + [self buttonOffset];
    }];

    [self.maskViews enumerateObjectsUsingBlock:^(UIView *maskView, NSUInteger idx, BOOL * _Nonnull stop) {
        maskView.frame = self.bounds;
        [self addSubview:maskView];
        [self bringSubviewToFront:maskView];
    }];
}

#pragma mark - getter

- (NSArray<AWECameraContainerToolButtonWrapView *> *)allButtons
{
    if (!_allButtons) {
        _allButtons = [NSArray array];
    }
    return _allButtons;
}

- (NSMutableArray<AWECameraContainerToolButtonWrapView *> *)activeButtons
{
    if (!_activeButtons) {
        _activeButtons = @[].mutableCopy;
    }
    return _activeButtons;
}

- (NSArray<AWECameraContainerToolButtonWrapView *> *)deactiveButtons
{
    if (!_deactiveButtons) {
        _deactiveButtons = @[].mutableCopy;
    }
    return _deactiveButtons;
}

- (NSArray<AWECameraContainerToolButtonWrapView *> *)visibleButtons
{
    return self.activeButtons;
}

- (NSMutableArray *)maskViews
{
    if (!_maskViews) {
        _maskViews = @[].mutableCopy;
    }
    return _maskViews;
}

- (CGFloat)buttonOffset
{
    return [UIDevice acc_screenWidthCategory] == ACCScreenWidthCategoryiPhone5 ? 2 : 14;
}

@end
