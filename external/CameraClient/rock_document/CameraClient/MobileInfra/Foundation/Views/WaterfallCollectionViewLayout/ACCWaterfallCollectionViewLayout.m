//
//  ACCWaterfallCollectionViewLayout.m
//  CameraClient
//
//  Created by Hsusue on 2020/1/2.
//

#import "ACCWaterfallCollectionViewLayout.h"
#import <objc/runtime.h>

NSString *const ACCNewCollectionViewElementKindSectionHeader = @"ACCNewCollectionViewElementKindSectionHeader";
NSString *const ACCNewCollectionViewElementKindSectionFooter = @"ACCNewCollectionViewElementKindSectionFooter";

@interface ACCWaterfallCollectionViewLayout (PartialRefresh)

@property (nonatomic, copy, nullable) NSDictionary<NSNumber *, NSIndexSet *> *itemsWilldelete;
@property (nonatomic, copy, nullable) NSDictionary<NSNumber *, NSIndexSet *> *itemsWillInsert;
@property (nonatomic, copy, nullable) NSArray<NSIndexPath *> *itemsWillReload;
@property (nonatomic, strong, nullable) NSArray<NSNumber *> *sectionsWillReload;
@property (nonatomic, strong) NSMutableArray<NSMutableArray<NSValue *> *> *cachedItemsSize;

/*
 * Use method bellow to invalidate a part of layout information.
 * Only the last invoke will effective if method below invoked mutiple times (same method or different method) before prepareLayout.
 */

/**
 *  @brief For delete items without recompute whole layout.
 */
- (void)prepareForDeleteItemsAtIndexSets:(NSArray<NSIndexSet *> *)indexSets ofSection:(NSArray<NSNumber *> *)sections;

/**
 *  @brief For insert items without recompute whole layout.
 */
- (void)prepareForInsertItemsAtIndexSets:(NSArray<NSIndexSet *> *)indexSets intoSections:(NSArray<NSNumber *> *)sections;

/**
 *  @brief For Reload items without recompute whole layout.
 */
- (void)prepareForReloadItemAtIndexPaths:(NSArray<NSIndexPath *> *)indexPath;

/**
 *  @brief For Reload section without recompute whole layout.
 */
- (void)prepareForReloadSections:(NSArray<NSNumber *> *)sections;

- (void)p_clearAllInvalidateInfo;

- (BOOL)p_hasInvalidateInfo;

@end

@implementation ACCWaterfallCollectionViewLayout (PartialRefresh)

- (void)setItemsWilldelete:(NSDictionary<NSNumber *,NSIndexSet *> *)itemsWilldelete {
    objc_setAssociatedObject(self, @selector(itemsWilldelete), itemsWilldelete, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSDictionary<NSNumber *,NSIndexSet *> *)itemsWilldelete {
    return objc_getAssociatedObject(self, @selector(itemsWilldelete));
}

- (void)setItemsWillInsert:(NSDictionary<NSNumber *,NSIndexSet *> *)itemsWillInsert {
    objc_setAssociatedObject(self, @selector(itemsWillInsert), itemsWillInsert, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSDictionary<NSNumber *,NSIndexSet *> *)itemsWillInsert {
    return objc_getAssociatedObject(self, @selector(itemsWillInsert));
}

- (void)setItemsWillReload:(NSArray<NSIndexPath *> *)itemsWillReload {
    objc_setAssociatedObject(self, @selector(itemsWillReload), itemsWillReload, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSArray<NSIndexPath *> *)itemsWillReload {
    return objc_getAssociatedObject(self, @selector(itemsWillReload));
}

- (void)setSectionsWillReload:(NSArray<NSNumber *> *)sectionsWillReload {
    objc_setAssociatedObject(self, @selector(sectionsWillReload), sectionsWillReload, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSArray<NSNumber *> *)sectionsWillReload {
    return objc_getAssociatedObject(self, @selector(sectionsWillReload));
}

- (void)setCachedItemsSize:(NSMutableArray<NSMutableArray<NSValue *> *> *)cachedItemsSize {
    objc_setAssociatedObject(self, @selector(cachedItemsSize), cachedItemsSize, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableArray<NSMutableArray<NSValue *> *> *)cachedItemsSize {
    return objc_getAssociatedObject(self, @selector(cachedItemsSize));
}

/**
 *  @brief For delete items without recompute whole layout.
 */
- (void)prepareForDeleteItemsAtIndexSets:(NSArray<NSIndexSet *> *)indexSets ofSection:(NSArray<NSNumber *> *)sections
{
    [self p_clearAllInvalidateInfo];
    NSParameterAssert(indexSets.count == sections.count);
    if (indexSets.count != sections.count) {
        return ;
    }
    
    NSMutableDictionary *dic = @{}.mutableCopy;
    [sections enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        dic[obj] = indexSets[idx];
    }];
    self.itemsWilldelete = dic.copy;
}

/**
 *  @brief For insert items without recompute whole layout.
 */
- (void)prepareForInsertItemsAtIndexSets:(NSArray<NSIndexSet *> *)indexSets intoSections:(NSArray<NSNumber *> *)sections
{
    [self p_clearAllInvalidateInfo];
    NSParameterAssert(indexSets.count == sections.count);
    if (indexSets.count != sections.count) {
        return ;
    }
    
    NSMutableDictionary *dic = @{}.mutableCopy;
    [sections enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        dic[obj] = indexSets[idx];
    }];
    self.itemsWillInsert = dic.copy;
}

/**
 *  @brief For Reload items without recompute whole layout.
 */
- (void)prepareForReloadItemAtIndexPaths:(NSArray<NSIndexPath *> *)indexPath
{
    [self p_clearAllInvalidateInfo];
    self.itemsWillReload = indexPath;
}

/**
 *  @brief For Reload section without recompute whole layout.
 */
- (void)prepareForReloadSections:(NSArray<NSNumber *> *)sections
{
    [self p_clearAllInvalidateInfo];
    self.sectionsWillReload = sections;
}

- (void)p_clearAllInvalidateInfo
{
    self.sectionsWillReload = nil;
    self.itemsWillReload = nil;
    self.itemsWillInsert = nil;
    self.itemsWilldelete = nil;
}

- (BOOL)p_hasInvalidateInfo
{
    return
    self.sectionsWillReload || self.itemsWillReload || self.itemsWillInsert || self.itemsWilldelete;
}

@end

@interface ACCWaterfallCollectionViewLayout ()
/// The delegate will point to collection view's delegate automatically.
@property (nonatomic, weak) id <ACCNewCollectionDelegateWaterfallLayout> delegate;
/// Array to store height for each column
@property (nonatomic, strong) NSMutableArray *columnHeights;
/// Array of arrays. Each array stores item attributes for each section
@property (nonatomic, strong) NSMutableArray *sectionItemAttributes;
/// Array to store attributes for all items includes headers, cells, and footers
@property (nonatomic, strong) NSMutableArray *allItemAttributes;
/// Dictionary to store section headers' attribute
@property (nonatomic, strong) NSMutableDictionary *headersAttribute;
/// Dictionary to store section footers' attribute
@property (nonatomic, strong) NSMutableDictionary *footersAttribute;
/// Array to store union rectangles
@property (nonatomic, strong) NSMutableArray *unionRects;

@end

@implementation ACCWaterfallCollectionViewLayout

/// How many items to be union into a single rectangle
static const NSInteger unionSize = 20;

static CGFloat ACCFloorCGFloat(CGFloat value) {
    CGFloat scale = [UIScreen mainScreen].scale;
    return floor(value * scale) / scale;
}

#pragma mark - Public Accessors
- (void)setColumnCount:(NSInteger)columnCount {
    if (_columnCount != columnCount) {
        _columnCount = columnCount;
        [self invalidateLayout];
    }
}

- (void)setMinimumColumnSpacing:(CGFloat)minimumColumnSpacing {
    if (_minimumColumnSpacing != minimumColumnSpacing) {
        _minimumColumnSpacing = minimumColumnSpacing;
        [self invalidateLayout];
    }
}

- (void)setMinimumInteritemSpacing:(CGFloat)minimumInteritemSpacing {
    if (_minimumInteritemSpacing != minimumInteritemSpacing) {
        _minimumInteritemSpacing = minimumInteritemSpacing;
        [self invalidateLayout];
    }
}

- (void)setHeaderHeight:(CGFloat)headerHeight {
    if (_headerHeight != headerHeight) {
        _headerHeight = headerHeight;
        [self invalidateLayout];
    }
}

- (void)setFooterHeight:(CGFloat)footerHeight {
    if (_footerHeight != footerHeight) {
        _footerHeight = footerHeight;
        [self invalidateLayout];
    }
}

- (void)setHeaderInset:(UIEdgeInsets)headerInset {
    if (!UIEdgeInsetsEqualToEdgeInsets(_headerInset, headerInset)) {
        _headerInset = headerInset;
        [self invalidateLayout];
    }
}

- (void)setFooterInset:(UIEdgeInsets)footerInset {
    if (!UIEdgeInsetsEqualToEdgeInsets(_footerInset, footerInset)) {
        _footerInset = footerInset;
        [self invalidateLayout];
    }
}

- (void)setSectionInset:(UIEdgeInsets)sectionInset {
    if (!UIEdgeInsetsEqualToEdgeInsets(_sectionInset, sectionInset)) {
        _sectionInset = sectionInset;
        [self invalidateLayout];
    }
}

- (void)setItemRenderDirection:(ACCWaterfallCollectionViewLayoutItemRenderDirection)itemRenderDirection {
    if (_itemRenderDirection != itemRenderDirection) {
        _itemRenderDirection = itemRenderDirection;
        [self invalidateLayout];
    }
}

- (NSInteger)columnCountForSection:(NSInteger)section {
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:columnCountForSection:)]) {
        return [self.delegate collectionView:self.collectionView layout:self columnCountForSection:section];
    } else {
        return self.columnCount;
    }
}

- (CGFloat)itemWidthInSectionAtIndex:(NSInteger)section {
    UIEdgeInsets sectionInset;
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:insetForSectionAtIndex:)]) {
        sectionInset = [self.delegate collectionView:self.collectionView layout:self insetForSectionAtIndex:section];
    } else {
        sectionInset = self.sectionInset;
    }
    CGFloat width = self.collectionView.bounds.size.width - sectionInset.left - sectionInset.right;
    NSInteger columnCount = [self columnCountForSection:section];
    
    CGFloat columnSpacing = self.minimumColumnSpacing;
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:minimumColumnSpacingForSectionAtIndex:)]) {
        columnSpacing = [self.delegate collectionView:self.collectionView layout:self minimumColumnSpacingForSectionAtIndex:section];
    }
    
    return ACCFloorCGFloat((width - (columnCount - 1) * columnSpacing) / columnCount);
}

#pragma mark - Private Accessors
- (NSMutableDictionary *)headersAttribute {
    if (!_headersAttribute) {
        _headersAttribute = [NSMutableDictionary dictionary];
    }
    return _headersAttribute;
}

- (NSMutableDictionary *)footersAttribute {
    if (!_footersAttribute) {
        _footersAttribute = [NSMutableDictionary dictionary];
    }
    return _footersAttribute;
}

- (NSMutableArray *)unionRects {
    if (!_unionRects) {
        _unionRects = [NSMutableArray array];
    }
    return _unionRects;
}

- (NSMutableArray *)columnHeights {
    if (!_columnHeights) {
        _columnHeights = [NSMutableArray array];
    }
    return _columnHeights;
}

- (NSMutableArray *)allItemAttributes {
    if (!_allItemAttributes) {
        _allItemAttributes = [NSMutableArray array];
    }
    return _allItemAttributes;
}

- (NSMutableArray *)sectionItemAttributes {
    if (!_sectionItemAttributes) {
        _sectionItemAttributes = [NSMutableArray array];
    }
    return _sectionItemAttributes;
}

- (id <ACCNewCollectionDelegateWaterfallLayout> )delegate {
    return (id <ACCNewCollectionDelegateWaterfallLayout> )self.collectionView.delegate;
}

#pragma mark - Init
- (void)commonInit {
    _columnCount = 2;
    _minimumColumnSpacing = 10;
    _minimumInteritemSpacing = 10;
    _headerHeight = 0;
    _footerHeight = 0;
    _sectionInset = UIEdgeInsetsZero;
    _headerInset  = UIEdgeInsetsZero;
    _footerInset  = UIEdgeInsetsZero;
    _itemRenderDirection = ACCWaterfallCollectionViewLayoutItemRenderDirectionShortestFirst;
    self.cachedItemsSize = [NSMutableArray array];
}

- (instancetype)init {
    if (self = [super init]) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self commonInit];
    }
    return self;
}

#pragma mark - Layout Methods to Override
- (void)prepareLayout {
    [super prepareLayout];
    
    BOOL isScopeUpdate = self.enableCacheItems && [self p_hasInvalidateInfo] && self.cachedItemsSize.count;
    
    [self.headersAttribute removeAllObjects];
    [self.footersAttribute removeAllObjects];
    [self.unionRects removeAllObjects];
    [self.allItemAttributes removeAllObjects];
    [self.sectionItemAttributes removeAllObjects];
    [self.columnHeights removeAllObjects];
    if (!isScopeUpdate) {
        [self.cachedItemsSize removeAllObjects];
    }
    
    NSInteger numberOfSections = isScopeUpdate ? self.cachedItemsSize.count : [self.collectionView numberOfSections];
    if (numberOfSections == 0) {
        return;
    }
    
    NSAssert([self.delegate conformsToProtocol:@protocol(ACCNewCollectionDelegateWaterfallLayout)], @"UICollectionView's delegate should conform to ACCCollectionViewDelegateWaterfallLayout protocol");
    NSAssert(self.columnCount > 0 || [self.delegate respondsToSelector:@selector(collectionView:layout:columnCountForSection:)], @"UICollectionViewWaterfallLayout's columnCount should be greater than 0, or delegate must implement columnCountForSection:");
    
    // Initialize variables
    NSInteger idx = 0;
    
    if (isScopeUpdate) {
        NSMutableArray *cachedItemsSize = self.cachedItemsSize;
        if (self.itemsWillInsert) {
            for (NSNumber *section in self.itemsWillInsert.allKeys) {
                if (section.integerValue < cachedItemsSize.count && section.integerValue >= 0) {
                    NSIndexSet *indexset = self.itemsWillInsert[section];
                    NSMutableArray *sectionHeights = cachedItemsSize[section.integerValue];
                    NSMutableArray *objects = @[].mutableCopy;
                    [indexset enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                        [objects addObject:[NSNull null]];
                    }];
                    [sectionHeights insertObjects:objects atIndexes:indexset];
                }
            }
        } else if (self.itemsWilldelete) {
            for (NSNumber *section in self.itemsWilldelete.allKeys) {
                if (section.integerValue < cachedItemsSize.count && section.integerValue >= 0) {
                    NSMutableArray *sectionHeights = cachedItemsSize[section.integerValue];
                    [sectionHeights removeObjectsAtIndexes:self.itemsWilldelete[section]];
                }
            }
        } else if (self.itemsWillReload) {
            for (NSIndexPath *indexPath in self.itemsWillReload) {
                NSInteger row = indexPath.row;
                NSInteger section = indexPath.section;
                
                if (section < cachedItemsSize.count && section >= 0) {
                    NSMutableArray *sectionHeights = cachedItemsSize[section];
                    if (row < sectionHeights.count && row >= 0) {
                        sectionHeights[row] = [NSNull null];
                    }
                }
            }
        } else if (self.sectionsWillReload) {
            for (NSNumber *section in self.sectionsWillReload) {
                if (section.integerValue < cachedItemsSize.count && section.integerValue >= 0) {
                    NSInteger itemCount = [self.collectionView numberOfItemsInSection:section.integerValue];
                    NSMutableArray *sectionItemsHeight = [NSMutableArray arrayWithCapacity:itemCount];
                    for (idx = 0; idx < itemCount; idx++) {
                        [sectionItemsHeight addObject:[NSNull null]];
                    }
                    cachedItemsSize[section.integerValue] = sectionItemsHeight;
                }
            }
        }
        [self p_clearAllInvalidateInfo];
    } else if (self.enableCacheItems) {
        for (NSInteger section = 0; section < numberOfSections; section++) {
            NSInteger itemCount = [self.collectionView numberOfItemsInSection:section];
            NSMutableArray *sectionItemsHeight = [NSMutableArray arrayWithCapacity:itemCount];
            for (idx = 0; idx < itemCount; idx++) {
                [sectionItemsHeight addObject:[NSNull null]];
            }
            [self.cachedItemsSize addObject:sectionItemsHeight];
        }
    }
    
    for (NSInteger section = 0; section < numberOfSections; section++) {
        NSInteger columnCount = [self columnCountForSection:section];
        NSMutableArray *sectionColumnHeights = [NSMutableArray arrayWithCapacity:columnCount];
        for (idx = 0; idx < columnCount; idx++) {
            [sectionColumnHeights addObject:@(0)];
        }
        [self.columnHeights addObject:sectionColumnHeights];
    }
    
    // Create attributes
    CGFloat top = 0;
    UICollectionViewLayoutAttributes *attributes;
    
    for (NSInteger section = 0; section < numberOfSections; ++section) {
        /*
         * 1. Get section-specific metrics (minimumInteritemSpacing, sectionInset)
         */
        CGFloat minimumInteritemSpacing;
        if ([self.delegate respondsToSelector:@selector(collectionView:layout:minimumInteritemSpacingForSectionAtIndex:)]) {
            minimumInteritemSpacing = [self.delegate collectionView:self.collectionView layout:self minimumInteritemSpacingForSectionAtIndex:section];
        } else {
            minimumInteritemSpacing = self.minimumInteritemSpacing;
        }
        
        CGFloat columnSpacing = self.minimumColumnSpacing;
        if ([self.delegate respondsToSelector:@selector(collectionView:layout:minimumColumnSpacingForSectionAtIndex:)]) {
            columnSpacing = [self.delegate collectionView:self.collectionView layout:self minimumColumnSpacingForSectionAtIndex:section];
        }
        
        UIEdgeInsets sectionInset;
        if ([self.delegate respondsToSelector:@selector(collectionView:layout:insetForSectionAtIndex:)]) {
            sectionInset = [self.delegate collectionView:self.collectionView layout:self insetForSectionAtIndex:section];
        } else {
            sectionInset = self.sectionInset;
        }
        
        CGFloat width = self.collectionView.bounds.size.width - sectionInset.left - sectionInset.right;
        NSInteger columnCount = [self columnCountForSection:section];
        CGFloat itemWidth;
        
        /*
         * 2. Section header
         */
        CGFloat headerHeight;
        if ([self.delegate respondsToSelector:@selector(collectionView:layout:heightForHeaderInSection:)]) {
            headerHeight = [self.delegate collectionView:self.collectionView layout:self heightForHeaderInSection:section];
        } else {
            headerHeight = self.headerHeight;
        }
        
        UIEdgeInsets headerInset;
        if ([self.delegate respondsToSelector:@selector(collectionView:layout:insetForHeaderInSection:)]) {
            headerInset = [self.delegate collectionView:self.collectionView layout:self insetForHeaderInSection:section];
        } else {
            headerInset = self.headerInset;
        }
        
        top += headerInset.top;
        
        if (headerHeight > 0) {
            attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:ACCNewCollectionViewElementKindSectionHeader withIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
            attributes.frame = CGRectMake(headerInset.left,
                                          top,
                                          self.collectionView.bounds.size.width - (headerInset.left + headerInset.right),
                                          headerHeight);
            
            self.headersAttribute[@(section)] = attributes;
            [self.allItemAttributes addObject:attributes];
            
            top = CGRectGetMaxY(attributes.frame) + headerInset.bottom;
        }
        
        top += sectionInset.top;
        for (idx = 0; idx < columnCount; idx++) {
            self.columnHeights[section][idx] = @(top);
        }
        
        /*
         * 3. Section items
         */
        
        NSInteger itemCount = 0;
        if (self.enableCacheItems) {
            itemCount = self.cachedItemsSize[section].count;
        } else {
            itemCount = [self.collectionView numberOfItemsInSection:section];
        }
        NSMutableArray *itemAttributes = [NSMutableArray arrayWithCapacity:itemCount];
        // Item will be put into shortest column.
        for (idx = 0; idx < itemCount; idx++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:idx inSection:section];
            NSUInteger columnIndex = 0;
            CGFloat xOffset = 0;
            CGSize itemSize = CGSizeZero;
            if (self.enableCacheItems) {
                NSValue *cachedSize = self.cachedItemsSize[section][idx];
                if ((id)cachedSize != [NSNull null]) {
                    itemSize = cachedSize.CGSizeValue;
                } else {
                    itemSize = [self.delegate collectionView:self.collectionView layout:self sizeForItemAtIndexPath:indexPath];
                    self.cachedItemsSize[section][idx] = [NSValue valueWithCGSize:itemSize];
                }
            } else {
                itemSize = [self.delegate collectionView:self.collectionView layout:self sizeForItemAtIndexPath:indexPath];
            }
            BOOL isFullWidthCell = self.supportsFullWidthCell && itemSize.width == self.collectionViewContentSize.width;
            if (isFullWidthCell) {
                columnIndex = [self longestColumnIndexInSection:section];
                itemWidth = itemSize.width;
                xOffset = 0;
            } else {
                columnIndex = [self nextColumnIndexForItem:idx inSection:section];
                itemWidth = ACCFloorCGFloat((width - (columnCount - 1) * columnSpacing) / columnCount);
                xOffset = sectionInset.left + (itemWidth + columnSpacing) * columnIndex;
            }
            CGFloat yOffset = [self.columnHeights[section][columnIndex] floatValue];

            CGFloat itemHeight = 0;
            if (itemSize.height > 0 && itemSize.width > 0) {
                itemHeight = ACCFloorCGFloat(itemSize.height * itemWidth / itemSize.width);
            }
            
            attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            attributes.frame = CGRectMake(xOffset, yOffset, itemWidth, itemHeight);
            [itemAttributes addObject:attributes];
            [self.allItemAttributes addObject:attributes];
            
            if (isFullWidthCell) {
                for (NSInteger i = 0; i < columnCount; ++i) {
                    self.columnHeights[section][i] = @(CGRectGetMaxY(attributes.frame) + minimumInteritemSpacing);
                }
            } else {
                self.columnHeights[section][columnIndex] = @(CGRectGetMaxY(attributes.frame) + minimumInteritemSpacing);
            }
        }
        
        [self.sectionItemAttributes addObject:itemAttributes];
        
        /*
         * 4. Section footer
         */
        CGFloat footerHeight;
        NSUInteger columnIndex = [self longestColumnIndexInSection:section];
        if (((NSArray *)self.columnHeights[section]).count > 0) {
            top = [self.columnHeights[section][columnIndex] floatValue] - minimumInteritemSpacing + sectionInset.bottom;
        } else {
            top = 0;
        }
        
        if ([self.delegate respondsToSelector:@selector(collectionView:layout:heightForFooterInSection:)]) {
            footerHeight = [self.delegate collectionView:self.collectionView layout:self heightForFooterInSection:section];
        } else {
            footerHeight = self.footerHeight;
        }
        
        UIEdgeInsets footerInset;
        if ([self.delegate respondsToSelector:@selector(collectionView:layout:insetForFooterInSection:)]) {
            footerInset = [self.delegate collectionView:self.collectionView layout:self insetForFooterInSection:section];
        } else {
            footerInset = self.footerInset;
        }
        
        top += footerInset.top;
        
        if (footerHeight > 0) {
            attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:ACCNewCollectionViewElementKindSectionHeader withIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
            attributes.frame = CGRectMake(footerInset.left,
                                          top,
                                          self.collectionView.bounds.size.width - (footerInset.left + footerInset.right),
                                          footerHeight);
            
            self.footersAttribute[@(section)] = attributes;
            [self.allItemAttributes addObject:attributes];
            
            top = CGRectGetMaxY(attributes.frame) + footerInset.bottom;
        }
        
        for (idx = 0; idx < columnCount; idx++) {
            self.columnHeights[section][idx] = @(top);
        }
    } // end of for (NSInteger section = 0; section < numberOfSections; ++section)

    // Build union rects
    idx = 0;
    NSInteger itemCounts = [self.allItemAttributes count];
    while (idx < itemCounts) {
        CGRect unionRect = ((UICollectionViewLayoutAttributes *)self.allItemAttributes[idx]).frame;
        NSInteger rectEndIndex = MIN(idx + unionSize, itemCounts);
        
        for (NSInteger i = idx + 1; i < rectEndIndex; i++) {
            unionRect = CGRectUnion(unionRect, ((UICollectionViewLayoutAttributes *)self.allItemAttributes[i]).frame);
        }
        
        idx = rectEndIndex;
        
        [self.unionRects addObject:[NSValue valueWithCGRect:unionRect]];
    }
}

- (CGSize)collectionViewContentSize {
    NSInteger numberOfSections = [self.collectionView numberOfSections];
    if (numberOfSections == 0) {
        return CGSizeZero;
    }
    
    CGSize contentSize = self.collectionView.bounds.size;
    contentSize.height = [[[self.columnHeights lastObject] firstObject] floatValue];
    
    if (contentSize.height < self.minimumContentHeight) {
        contentSize.height = self.minimumContentHeight;
    }
    
    return contentSize;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)path {
    if (path.section >= [self.sectionItemAttributes count]) {
        return nil;
    }
    if (path.item >= [self.sectionItemAttributes[path.section] count]) {
        return nil;
    }
    return (self.sectionItemAttributes[path.section])[path.item];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attribute = nil;
    if ([kind isEqualToString:ACCNewCollectionViewElementKindSectionHeader]) {
        attribute = self.headersAttribute[@(indexPath.section)];
    } else if ([kind isEqualToString:ACCNewCollectionViewElementKindSectionFooter]) {
        attribute = self.footersAttribute[@(indexPath.section)];
    }
    return attribute;
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSInteger i;
    NSInteger begin = 0, end = self.unionRects.count;
    NSMutableDictionary *cellAttrDict = [NSMutableDictionary dictionary];
    NSMutableDictionary *supplAttrDict = [NSMutableDictionary dictionary];
    NSMutableDictionary *decorAttrDict = [NSMutableDictionary dictionary];
    
    for (i = 0; i < self.unionRects.count; i++) {
        if (CGRectIntersectsRect(rect, [self.unionRects[i] CGRectValue])) {
            begin = i * unionSize;
            break;
        }
    }
    for (i = self.unionRects.count - 1; i >= 0; i--) {
        if (CGRectIntersectsRect(rect, [self.unionRects[i] CGRectValue])) {
            end = MIN((i + 1) * unionSize, self.allItemAttributes.count);
            break;
        }
    }
    for (i = begin; i < end; i++) {
        UICollectionViewLayoutAttributes *attr = self.allItemAttributes[i];
        if (CGRectIntersectsRect(rect, attr.frame)) {
            switch (attr.representedElementCategory) {
                case UICollectionElementCategorySupplementaryView:
                    supplAttrDict[attr.indexPath] = attr;
                    break;
                case UICollectionElementCategoryDecorationView:
                    decorAttrDict[attr.indexPath] = attr;
                    break;
                case UICollectionElementCategoryCell:
                    cellAttrDict[attr.indexPath] = attr;
                    break;
            }
        }
    }
    
    NSArray *result = [cellAttrDict.allValues arrayByAddingObjectsFromArray:supplAttrDict.allValues];
    result = [result arrayByAddingObjectsFromArray:decorAttrDict.allValues];
    return result;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    CGRect oldBounds = self.collectionView.bounds;
    if (CGRectGetWidth(newBounds) != CGRectGetWidth(oldBounds)) {
        return YES;
    }
    return NO;
}

#pragma mark - Private Methods

/**
 *  Find the shortest column.
 *
 *  @return index for the shortest column
 */
- (NSUInteger)shortestColumnIndexInSection:(NSInteger)section {
    __block NSUInteger index = 0;
    __block CGFloat shortestHeight = MAXFLOAT;
    
    [self.columnHeights[section] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CGFloat height = [obj floatValue];
        if (height < shortestHeight) {
            shortestHeight = height;
            index = idx;
        }
    }];
    
    return index;
}

/**
 *  Find the longest column.
 *
 *  @return index for the longest column
 */
- (NSUInteger)longestColumnIndexInSection:(NSInteger)section {
    __block NSUInteger index = 0;
    __block CGFloat longestHeight = 0;
    
    [self.columnHeights[section] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CGFloat height = [obj floatValue];
        if (height > longestHeight) {
            longestHeight = height;
            index = idx;
        }
    }];
    
    return index;
}

/**
 *  Find the index for the next column.
 *
 *  @return index for the next column
 */
- (NSUInteger)nextColumnIndexForItem:(NSInteger)item inSection:(NSInteger)section {
    NSUInteger index = 0;
    NSInteger columnCount = [self columnCountForSection:section];
    switch (self.itemRenderDirection) {
        case ACCWaterfallCollectionViewLayoutItemRenderDirectionShortestFirst:
            index = [self shortestColumnIndexInSection:section];
            break;
            
        case ACCWaterfallCollectionViewLayoutItemRenderDirectionLeftToRight:
            index = (item % columnCount);
            break;
            
        case ACCWaterfallCollectionViewLayoutItemRenderDirectionRightToLeft:
            index = (columnCount - 1) - (item % columnCount);
            break;
            
        default:
            index = [self shortestColumnIndexInSection:section];
            break;
    }
    return index;
}

@end
