//
//  BDXPageBaseView.m
//  BDXElement
//
//  Created by AKing on 2021/2/6.
//

#import "BDXPageBaseView.h"
#import "BDXPageListView.h"
#import "BDXCategoryTitleView.h"

@interface BDXPageBaseView () <BDXCategoryViewDelegate>

@property (nonatomic,assign) BOOL viewDidLoad;

@end

@implementation BDXPageBaseView
@synthesize listContainerView = _listContainerView;

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.categoryViewHeight =  50;
    }
    self.backgroundColor = UIColor.clearColor;
    return self;
}

- (void)loadView {
    if (self.viewDidLoad) {
        return;
    }
    [self addSubview:self.categoryView];
    if ([_listContainerView isKindOfClass:UIView.class]) {
        UIView *view = (UIView *)_listContainerView;
        [self addSubview:view];
    }
    self.viewDidLoad = YES;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if ([_listContainerView isKindOfClass:BDXCategoryListContainerView.class]) {
        self.categoryView.frame = CGRectMake(0, 0, self.bounds.size.width, [self preferredCategoryViewHeight]);
        UIView *view = (UIView *)_listContainerView;
        view.frame = CGRectMake(0, [self preferredCategoryViewHeight], self.bounds.size.width, self.bounds.size.height - [self preferredCategoryViewHeight]);
    }
}

#pragma mark - Custom Accessors

- (void)setTitles:(NSArray *)titles {
    _titles = titles;
    if ([_categoryView isKindOfClass:BDXCategoryTitleView.class]) {
        BDXCategoryTitleView * titleView = (BDXCategoryTitleView *)_categoryView;
        titleView.titles = _titles;
    }
}

- (void)setListContainerView:(id<BDXCategoryViewListContainer>)listContainerView {
    _listContainerView = listContainerView;
    if (_categoryView != nil) {
        _categoryView.listContainer = _listContainerView;
    }
}

- (void)setCategoryView:(BDXCategoryBaseView *)categoryView {
    _categoryView = categoryView;
    _categoryView.delegate = self;
    _categoryView.listContainer = self.listContainerView;
}


- (id<BDXCategoryViewListContainer>)listContainerView {
    if (!_listContainerView) {
        _listContainerView = [[BDXCategoryListContainerView alloc] initWithType:BDXCategoryListContainerType_CollectionView delegate:self];
    }
    return _listContainerView;
}

#pragma mark - Public

- (BDXCategoryBaseView *)preferredCategoryView {
    return [[BDXCategoryBaseView alloc] init];
}

- (CGFloat)preferredCategoryViewHeight {
    return _categoryViewHeight;
}

#pragma mark - BDXCategoryViewDelegate

- (void)categoryView:(BDXCategoryBaseView *)categoryView didSelectedItemAtIndex:(NSInteger)index {
    if ([self.delegate respondsToSelector:@selector(categoryView:didSelectedItemAtIndex:)]) {
        [self.delegate categoryView:categoryView didSelectedItemAtIndex:index];
    }
}

- (void)categoryView:(BDXCategoryBaseView *)categoryView didScrollSelectedItemAtIndex:(NSInteger)index {
    if ([self.delegate respondsToSelector:@selector(categoryView:didScrollSelectedItemAtIndex:)]) {
        [self.delegate categoryView:categoryView didScrollSelectedItemAtIndex:index];
    }
}

- (void)categoryView:(BDXCategoryBaseView *)categoryView didClickSelectedItemAtIndex:(NSInteger)index {
    if ([self.delegate respondsToSelector:@selector(categoryView:didClickSelectedItemAtIndex:)]) {
        [self.delegate categoryView:categoryView didClickSelectedItemAtIndex:index];
    }
}

- (void)categoryView:(BDXCategoryBaseView *)categoryView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([_delegate respondsToSelector:@selector(categoryView:willDisplayCell:forItemAtIndexPath:)]) {
        [_delegate categoryView:categoryView willDisplayCell:cell forItemAtIndexPath:indexPath];
    }
}

- (void)categoryView:(BDXCategoryBaseView *)categoryView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([_delegate respondsToSelector:@selector(categoryView:didEndDisplayingCell:forItemAtIndexPath:)]) {
        [_delegate categoryView:categoryView didEndDisplayingCell:cell forItemAtIndexPath:indexPath];
    }
}


#pragma mark - BDXCategoryListContainerViewDelegate

- (NSInteger)numberOfListsInlistContainerView:(BDXCategoryListContainerView *)listContainerView {
    if ([self.delegate respondsToSelector:@selector(numberOfListsInlistContainerView:)]) {
        return [self.delegate numberOfListsInlistContainerView:listContainerView];
    }
    return self.titles.count;
}

- (id<BDXCategoryListContentViewDelegate>)listContainerView:(BDXCategoryListContainerView *)listContainerView initListForIndex:(NSInteger)index {
    if ([self.delegate respondsToSelector:@selector(listContainerView:initListForIndex:)]) {
        return [self.delegate listContainerView:listContainerView initListForIndex:index];
    }
    BDXPageListView *list = [[BDXPageListView alloc] init];
    return list;
}

- (void)listContainerViewDidScroll:(UIScrollView *)scrollView {
    if ([_delegate respondsToSelector:@selector(listContainerViewDidScroll:)]) {
        [_delegate listContainerViewDidScroll:scrollView];
    }
}

@end
