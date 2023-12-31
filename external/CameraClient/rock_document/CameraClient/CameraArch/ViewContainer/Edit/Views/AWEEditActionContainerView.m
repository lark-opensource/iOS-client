//
//  AWEEditActionContainerView.m
//  Pods
//
//  Created by resober on 2019/5/8.
//

#import "AWEEditActionContainerView.h"
#import <CreativeKit/ACCMacros.h>

@interface AWEEditActionContainerView ()
@property (nonatomic, copy) NSArray<AWEEditAndPublishViewData *> *itemDatas;
@property (nonatomic, copy) NSArray<AWEEditActionItemView *> *itemViews;
@end

@implementation AWEEditActionContainerView

- (void)dealloc {
    _itemDatas = nil;
}

- (instancetype)initWithItemDatas:(NSArray *)itemDatas containerViewLayout:(nonnull AWEEditActionContainerViewLayout *)containerViewLayout {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.itemDatas = itemDatas;
        _containerViewLayout = containerViewLayout;
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    if (!_itemDatas) {
        return;
    }

    NSMutableArray<AWEEditAndPublishViewData *> *mItemDatas = _itemDatas.mutableCopy;
    NSMutableArray<AWEEditActionItemView *> *vArray = [NSMutableArray new];
    [mItemDatas enumerateObjectsUsingBlock:^(AWEEditAndPublishViewData * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        AWEEditActionItemView *v = [[AWEEditActionItemView alloc] initWithItemData:obj];
        v.itemSpacing = self.containerViewLayout.itemSpacing;
        ACCBLOCK_INVOKE(v.itemData.extraConfigBlock, v);
        [vArray addObject:v];
        [self addSubview:v];
    }];
    _itemViews = vArray;
}

- (void)layoutSubviews {
    __block UIView *lastView = nil;
    [_itemViews enumerateObjectsUsingBlock:^(AWEEditActionItemView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGSize itemSize = [self itemSizeWithItem:obj];
        CGFloat w = itemSize.width;
        CGFloat h = itemSize.height;
        if (self.containerViewLayout.direction == AWEEditActionContainerViewLayoutDirectionHorizontal) {
            CGFloat x = (lastView == nil) ? self.containerViewLayout.contentInset.left : (self.containerViewLayout.itemSpacing + CGRectGetMaxX(lastView.frame));
            CGFloat y = self.containerViewLayout.contentInset.top;
            obj.frame = CGRectMake(x, y, w, h);
        } else {
            CGFloat x = self.containerViewLayout.contentInset.left;
            CGFloat y = (lastView == nil) ? self.containerViewLayout.contentInset.top : (self.containerViewLayout.itemSpacing + CGRectGetMaxY(lastView.frame));
            obj.frame = CGRectMake(x, y, w, h);
        }
        lastView = obj;
    }];
}

- (CGSize)intrinsicContentSize {
    return [self intrinsicContentSizeForItemsInRange:NSMakeRange(0, self.itemViews.count)];
}

- (CGSize)intrinsicContentSizeForItemsInRange:(NSRange)range {
    NSArray *itemViewsSlice;
    if (range.location + range.length > self.itemViews.count) {
        range = NSMakeRange(0, self.itemViews.count);
    }
    itemViewsSlice = [_itemViews subarrayWithRange:range];
    NSInteger count = itemViewsSlice.count;
    CGFloat totalItemsW = 0.f;  ///< 计算横排所有条目占用宽度
    CGFloat totalItemsH = 0.f;  ///< 计算竖排所有条目占用高度
    CGFloat maxRowHeight = 0.f; ///< 计算横排占用最大高度
    CGFloat maxColomnWidth = 0.f;  ///< 计算竖排占用最大宽度
    for (AWEEditActionItemView *obj in itemViewsSlice) {
        CGSize itemSize = [self itemSizeWithItem:obj];
        if (self.containerViewLayout.direction == AWEEditActionContainerViewLayoutDirectionHorizontal) {
            totalItemsW += itemSize.width;
            maxRowHeight = MAX(maxRowHeight, itemSize.height);
        } else {
            totalItemsH += [self itemSizeWithItem:obj].height;
            maxColomnWidth = MAX(maxColomnWidth, itemSize.width);
        }
    }
    if (self.containerViewLayout.direction == AWEEditActionContainerViewLayoutDirectionHorizontal) {
        CGFloat w =
        self.containerViewLayout.contentInset.left +
        totalItemsW +
        (count - 1) * self.containerViewLayout.itemSpacing +
        self.containerViewLayout.contentInset.right;
        CGFloat h = self.containerViewLayout.contentInset.top +
        maxRowHeight +
        self.containerViewLayout.contentInset.bottom;
        return CGSizeMake(w, h);
    } else {
        CGFloat w = self.containerViewLayout.contentInset.left +
        maxColomnWidth +
        self.containerViewLayout.contentInset.right;
        CGFloat h =
        self.containerViewLayout.contentInset.top +
        totalItemsH +
        (count - 1) * self.containerViewLayout.itemSpacing +
        self.containerViewLayout.contentInset.bottom;
        return CGSizeMake(w, h);
    }
}

- (CGSize)itemSizeWithItem:(AWEEditActionItemView *)item {
    CGSize itemSize = self.containerViewLayout.itemSize;
    if (CGSizeEqualToSize(itemSize, CGSizeZero)) {
        itemSize = item.intrinsicContentSize;
    }
    return itemSize;
}

- (AWEEditActionItemView *)findItemViewById:(NSString *)identifier
{
    __block AWEEditActionItemView *itemView = nil;
    [self.itemViews enumerateObjectsUsingBlock:^(AWEEditActionItemView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.identifier isEqual:identifier]) {
            itemView = obj;
        }
    }];
    
    return itemView;
}

@end
