//
//  AWEStickerPickerSearchView.m
//  CameraClient-Pods-Aweme
//
//  Created by Syenny on 2021/5/17.
//

#import "AWEStickerPickerSearchView.h"
#import "AWEStickerPickerHashtagView.h"
#import "AWEStickerPickerCollectionViewCell.h"
#import "AWEStickerPickerStickerBaseCell.h"
#import "ACCConfigKeyDefines.h"
#import "AWEStickerPickerSearchBar.h"
#import "ACCPropExploreExperimentalControl.h"

#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreationKitInfra/ACCLoadingViewProtocol.h>
#import <CreationKitInfra/ACCRACWrapper.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>

static const CGFloat kAWESticerPickerCollectionViewTopConstraint = 64; // 16 + searchBar's height

static inline BOOL useSearchOptimization() {
    return ACCConfigBool(kConfigBool_studio_optimize_prop_search_experience);
}

@interface AWEStickerPickerSearchView ()
<
AWEStickerPickerSearchBarDelegate,
UICollectionViewDataSource,
UICollectionViewDelegate,
AWEStickerPickerCollectionViewCellDelegate,
AWEStickerPickerHashtagViewDelegate
>

@property (nonatomic, strong) AWEStickerPickerSearchBar *searchBar;

@property (nonatomic, strong) UIView<ACCLoadingViewProtocol> *loadingView;

@property (nonatomic, strong) UIView *loadingContainerView;

@property (nonatomic, strong) UILabel *emptyLabel;

@property (nonatomic, strong) AWEStickerPickerHashtagView *hashtagsView;

@property (nonatomic, strong) UICollectionView *collectionView; // sticker collection view

@property (nonatomic, strong) id<AWEStickerPickerUIConfigurationProtocol> UIConfig;

@property (nonatomic, strong) AWEStickerPickerStickerBaseCell *currentSelectedCell;

@property (nonatomic, assign) BOOL isTab;

@property (nonatomic, assign) BOOL isUseHot;

@property (nonatomic, assign) BOOL isFirst;

@end

@implementation AWEStickerPickerSearchView

- (instancetype)initWithIsTab:(BOOL)isTab
{
    self = [super init];
    if (self) {
        self.isTab = isTab;
        self.isFirst = YES;
        self.source = AWEStickerPickerSearchViewHideKeyboardSourceNone;

        [self setupSubviews];
        [self addNotifications];

    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setModel:(AWEStickerPickerModel *)model
{
    _model = model;
    [_model fetchHashtagsListWithIsTextFieldFirstResponder:self.textField.isFirstResponder];
}

- (void)trackRecommendedListDidShow
{
    if (self.isFirst) {
        [self.model trackRecommendationListDidShowWithIsFirstResponder:self.textField.isFirstResponder];
        self.isFirst = NO;
    }
}

- (void)updateUIConfig:(id<AWEStickerPickerUIConfigurationProtocol>)config
{
    NSAssert([config conformsToProtocol:@protocol(AWEStickerPickerUIConfigurationProtocol)], @"config is invalid!!!");
    self.UIConfig = config;
}

- (void)updateSearchSource:(AWEStickerPickerSearchViewHideKeyboardSource)source
{
    self.source = source;
}

- (void)updateSearchText:(NSString *)searchText
{
    [self.searchBar setText:searchText];
}

- (void)updateCategoryModel:(AWEStickerCategoryModel *)categoryModel isUseHot:(BOOL)isUseHot;
{
    self.categoryModel = categoryModel;
    self.isUseHot = isUseHot;

    [self needsShowCollectionView];
    [self.collectionView reloadData];
}

- (void)needsShowCollectionView
{
    if (!self.model.isCompleted) {
        return;
    }

    if (!self.textField.isFirstResponder) {
        if (self.isUseHot) {
            // if is using hot category and the source is from 'return'
            if (self.source == AWEStickerPickerSearchViewHideKeyboardSourceReturn || self.source == AWEStickerPickerSearchViewHideKeyboardSourceClearBG) {
                // show empty label and update collection view's top constraint
                [self showEmptyView:YES];
                [self showHashtagsView:NO];
                [self showCollectionView:YES];
            } else {
                // the source is not from 'return'
                [self showEmptyView:NO];
                [self showHashtagsView:YES];
                [self showCollectionView:NO];
            }
        } else {
            if (self.categoryModel && !ACC_isEmptyArray(self.categoryModel.stickers)) {
                [self showEmptyView:NO];
                [self showHashtagsView:NO];
                [self showCollectionView:YES];
            } else {
                // searchTab and empty model
                // hashtagsView will show based on if current query is empty (for error case)
                NSString *searchText = self.textField.text;
                BOOL showHashtagsView = !searchText || [searchText isEqualToString:@""];
                [self showEmptyView:NO];
                [self showHashtagsView:showHashtagsView];
                [self showCollectionView:NO];
            }
        }
    } else {
        if (self.isUseHot) {
            [self showEmptyView:NO];
            [self showHashtagsView:NO];
            [self showCollectionView:NO];
        } else if (self.categoryModel && !ACC_isEmptyArray(self.categoryModel.stickers)) {
            // has categoryModel, but not using hot category
            [self showEmptyView:NO];
            [self showHashtagsView:NO];
            [self showCollectionView:YES];
        } else {
            // searchView and empty model
            // hashtagsView will show based on if current query is empty (for error case)
            NSString *searchText = self.textField.text;
            BOOL showHashtagsView = !searchText || [searchText isEqualToString:@""];
            [self showEmptyView:NO];
            [self showHashtagsView:showHashtagsView];
            [self showCollectionView:NO];
        }
    }

    [self layoutIfNeeded];
}

- (void)showHashtagsView:(BOOL)show
{
    self.hashtagsView.hidden = YES;
    if (show) {
        self.hashtagsView.hashtagsList = self.model.recommendationList;
        self.hashtagsView.hidden = NO;
    }
}

- (void)showCollectionView:(BOOL)show
{
    self.collectionView.hidden = YES;
    if (show) {
        self.collectionView.hidden = NO;
    }
}

- (void)showEmptyView:(BOOL)show
{
    self.emptyLabel.hidden = YES;
    [self.emptyLabel removeFromSuperview];

    NSString *emptyLabelText = self.model.searchTips;
    if (!emptyLabelText || [emptyLabelText isEqualToString:@""]) {
        [self.emptyLabel setText:@"没有搜索到结果，试试以下热门道具"];
    } else {
        [self.emptyLabel setText:emptyLabelText];
    }

    if (show) {
        self.emptyLabel.hidden = NO;
        [self addSubview:self.emptyLabel];
        ACCMasMaker(self.emptyLabel, {
            make.top.equalTo(self.mas_top).offset(kAWESticerPickerCollectionViewTopConstraint + 8);
            make.left.right.equalTo(self);
            make.height.equalTo(@(18));
        });
    }

    // show : 64 + 8 + label's height
    // not show : 16 + searchBar's height
    CGFloat shift = show ? (8 + 18) : 0;
    CGFloat offset = kAWESticerPickerCollectionViewTopConstraint + shift;
    ACCMasUpdate(self.collectionView, {
        make.top.equalTo(self.mas_top).offset(offset);
    });
}

- (void)updateSubviewsAlpha:(CGFloat)alpha
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.searchBar.alpha = alpha;
    self.emptyLabel.alpha = alpha;
    self.hashtagsView.alpha = alpha;
    self.collectionView.alpha = alpha;
    self.loadingContainerView.alpha = alpha;
    [CATransaction commit];
}

- (void)enableCollectionViewToScroll:(BOOL)enabled
{
    AWEStickerPickerCollectionViewCell *cell = [self.collectionView visibleCells].firstObject;
    if (cell) {
        cell.stickerCollectionView.scrollEnabled = useSearchOptimization() ? YES : !self.textField.isFirstResponder;
    }
}

- (void)onClearBGClicked
{
    self.source = AWEStickerPickerSearchViewHideKeyboardSourceClearBG;

    if (self.textField.isFirstResponder) {
        [self triggerKeyboardToHide];
    }
}

#pragma mark - Sticker Handler

- (void)updateSelectedStickerForId:(NSString *)identifier
{
    NSArray<AWEStickerPickerCollectionViewCell *> *cells = [self.collectionView visibleCells];

    if (ACC_isEmptyArray(cells)) {
        return;
    }

    [self.currentSelectedCell setStickerSelected:NO animated:NO];
    self.currentSelectedCell = nil;

    [cells enumerateObjectsUsingBlock:^(AWEStickerPickerCollectionViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray<AWEStickerPickerStickerBaseCell *> *stickerCells = [obj.stickerCollectionView visibleCells];
        [stickerCells enumerateObjectsUsingBlock:^(AWEStickerPickerStickerBaseCell * _Nonnull stickerCell, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([identifier isEqualToString:stickerCell.sticker.effectIdentifier]) {
                [stickerCell setStickerSelected:YES animated:YES];
                self.currentSelectedCell = stickerCell;
            } else {
                [stickerCell setStickerSelected:NO animated:NO];
            }
        }];
    }];
}

#pragma mark - Private

- (void)setupSubviews
{
    [self addSubview:self.searchBar];
    ACCMasMaker(self.searchBar, {
        make.top.equalTo(self.mas_top).offset(16);  // 12 + 4 (inner)
        make.height.equalTo(@(48));
        make.left.equalTo(self.mas_left).offset(16);
        make.right.equalTo(self);
    });

    [self addSubview:self.collectionView];
    ACCMasMaker(self.collectionView, {
        make.top.equalTo(self.mas_top).offset(kAWESticerPickerCollectionViewTopConstraint);
        make.bottom.left.right.equalTo(self);
    });

    [self addSubview:self.hashtagsView];
    ACCMasMaker(self.hashtagsView, {
        make.top.equalTo(self.mas_top).offset(kAWESticerPickerCollectionViewTopConstraint + 8); // 64 + 8
        make.height.equalTo(@([self firstResponderHeight]));
        make.left.right.equalTo(self);
    });

    [self addSubview:self.loadingContainerView];
    ACCMasMaker(self.loadingContainerView, {
        make.top.equalTo(self.mas_top).offset(kAWESticerPickerCollectionViewTopConstraint);
        make.height.equalTo(@([self firstResponderHeight]));
        make.left.right.equalTo(self);
    });
}

- (void)addNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    // 兼容ipad浮动键盘
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameChange:) name:UIKeyboardDidChangeFrameNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    if (!self.searchBar.textField.isFirstResponder) {
        return;
    }
    self.source = AWEStickerPickerSearchViewHideKeyboardSourceNone;

    CGRect keyboardBounds;
    [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardBounds];
    [self.model showKeyboardWithNotification:notification];
}

- (void)keyboardFrameChange:(NSNotification *)notification
{
    if (![UIDevice acc_isIPad]) {
        return;
    }
    
    CGRect keyboardBounds;
    [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardBounds];
    // ipad浮动键盘展开/收起不会触发KeyboardWillShow/KeyboardWillHideNotification，使用DidFrameChange判断键盘状态
    if (keyboardBounds.size.width < ACC_SCREEN_WIDTH - 1) {
        if (keyboardBounds.size.height > ACC_FLOAT_ZERO) {
            self.source = AWEStickerPickerSearchViewHideKeyboardSourceNone;
            [self.model showKeyboardWithNotification:notification];
            [self.collectionView reloadData];
        } else {
            [self.model hideKeyboardWithNotification:notification source:self.source];
        }
    }
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    if (!self.searchBar.textField.isFirstResponder) {
        return;
    }
    CGRect keyboardBounds;
    [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardBounds];
    if ([UIDevice acc_isIPad] && keyboardBounds.size.width < ACC_SCREEN_WIDTH - 1) {
        // ipad从普通键盘切换到浮动键盘，会调用KeyboardWillHideNotification，故提前return维持键盘展开状态
        return;
    }
    
    [self.model hideKeyboardWithNotification:notification source:self.source];
}

- (void)p_cancelSearch
{
    NSMutableDictionary *params = @{ @"is_panel_unfold": (self.textField.isFirstResponder) ? @(1) : @(0) }.mutableCopy;
    [self.model trackWithEventName:@"prop_search_cancel" params:params];

    self.source = AWEStickerPickerSearchViewHideKeyboardSourceCancel;

    if (self.textField.isFirstResponder) {
        [self triggerKeyboardToHide];
    } else {
        if (useSearchOptimization()) {
            [self.model updateSearchPanelToPackUp];
        }
    }
}

- (void)p_clearSearchText
{
    NSMutableDictionary *params = @{ @"is_panel_unfold": (self.textField.isFirstResponder) ? @(1) : @(0) }.mutableCopy;
    [self.model trackWithEventName:@"clear_prop_search_text" params:params];
    [self.model searchTextDidChange:nil isTab:!self.textField.isFirstResponder];
    [self.model shouldTriggerKeyboardToShowIfIsTab:self.isTab source:self.source];
}

- (void)p_hideIpadKeyboard
{
    if ([UIDevice acc_isIPad]) {
        self.source = AWEStickerPickerSearchViewHideKeyboardSourceReturn;
        [self triggerKeyboardToHide];
    }
}

- (void)triggerKeyboardToHide
{
    [self.model shouldTriggerKeyboardToHide:!self.isTab source:self.source];
}

- (void)showLoadingView:(BOOL)show
{
    self.loadingContainerView.hidden = !show;
    [self p_configLoading:show];
}

- (void)p_configLoading:(BOOL)show
{
    /**
     Hide collectionView and recommendationView
     */
    [self.loadingView dismiss];
    if (show) {
        self.collectionView.hidden = YES;
        self.hashtagsView.hidden = YES;
        self.emptyLabel.hidden = YES;
        self.loadingView = [ACCLoading() showLoadingOnView:self.loadingContainerView];
    }
}

#pragma mark - ACCCommonSearchBarDelegate

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    return YES;
}

- (void)textFieldBecomeFirstResponder
{
    [self.textField becomeFirstResponder];
}

- (void)textFieldResignFirstResponder
{
    if (self.textField.isFirstResponder) {
        [self.textField resignFirstResponder];
        [self.textField endEditing:YES];
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{

}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    self.source = AWEStickerPickerSearchViewHideKeyboardSourceReturn;
    [self triggerKeyboardToHide];
    return YES;
}

- (void)searchBar:(AWEStickerPickerSearchBar *)searchBar textDidChange:(NSString *)searchText
{
    UITextRange *markedRange = self.textField.markedTextRange;
    if (markedRange) {
        return;
    }

    [self.model searchTextDidChange:searchText isTab:!self.textField.isFirstResponder];
}

#pragma mark - AWEStickerPickerCollectionViewCellDelegate

- (BOOL)stickerPickerCollectionViewCell:(AWEStickerPickerCollectionViewCell *)cell isStickerSelected:(IESEffectModel *)sticker
{
    return [self.model isStickerSelected:sticker];
}

- (void)stickerPickerCollectionViewCell:(AWEStickerPickerCollectionViewCell *)cell
                     willDisplaySticker:(IESEffectModel *)sticker
                              indexPath:(NSIndexPath *)indexPath
{
    [self.model willDisplaySticker:sticker indexPath:indexPath];
}

- (void)stickerPickerCollectionViewCell:(AWEStickerPickerCollectionViewCell *)cell
                       didSelectSticker:(IESEffectModel *)sticker
                               category:(AWEStickerCategoryModel *)category
                              indexPath:(nonnull NSIndexPath *)indexPath
{
    [self.model didSelectSticker:sticker category:category indexPath:indexPath];
    if (self.textField.isFirstResponder) {
        self.source = AWEStickerPickerSearchViewHideKeyboardSourceReturn;
        [self.model shouldTriggerKeyboardToHide:!self.isTab source:self.source];
    } else if (useSearchOptimization()) {
        [self.model updateSearchPanelToPackUp];
    }
}

- (void)stickerPickerCollectionViewCell:(AWEStickerPickerCollectionViewCell *)cell
            scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (!useSearchOptimization()) {
        return;
    }
    
    if (self.textField.isFirstResponder) {
        self.source = AWEStickerPickerSearchViewHideKeyboardSourceScroll;
        [self.model shouldTriggerKeyboardToHide:!self.isTab source:self.source];
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 1;
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    AWEStickerPickerCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[AWEStickerPickerCollectionViewCell identifier] forIndexPath:indexPath];

    if (cell) {
        [cell updateUIConfig:self.UIConfig.effectUIConfig];
        cell.categoryModel = self.categoryModel;

        cell.stickerCollectionView.scrollEnabled = useSearchOptimization() ? YES : !self.textField.isFirstResponder;
        [cell.stickerCollectionView layoutIfNeeded];
        [cell.stickerCollectionView setContentOffset:CGPointZero animated:NO];
    }
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    AWEStickerPickerCollectionViewCell *stickerPickerCollectionViewCell = ACCDynamicCast(cell, AWEStickerPickerCollectionViewCell);
    if (stickerPickerCollectionViewCell) {
        stickerPickerCollectionViewCell.delegate = self;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.collectionView.bounds.size;
}

#pragma mark - AWEStickerPickerHashtagViewDelegate

- (void)stickerPickerHashtagView:(AWEStickerPickerHashtagView *)hashtagView didSelectCellWithTitle:(NSString *)title indexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *params = @{
        @"words_position": @(indexPath.item),
        @"word_name": title,
        @"is_panel_unfold" : (self.textField.isFirstResponder) ? @(1) : @(0),
        @"previous_page" : @"prop_main_panel",
    }.mutableCopy;

    [self.model trackWithEventName:@"prop_trending_words_click" params:params];
    [self.model didTapHashtag:title];
    [self.model shouldTriggerKeyboardToShowIfIsTab:self.isTab source:self.source];
}

# pragma mark - Search Tab Handlers

- (void)didTapSearchTabTextField:(UITextField *)textField
{
    [self.model shouldTriggerKeyboardToShowIfIsTab:self.isTab source:self.source];
}

#pragma mark - UI

- (CGFloat)panelHeight
{
    CGFloat height = [self.UIConfig.effectUIConfig effectListViewHeight] - kAWESticerPickerCollectionViewTopConstraint;
    return height;
}

- (CGFloat)firstResponderHeight
{
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat itemHeight = screenWidth * 71.5 / 375.0f;
    CGFloat insetHeight = (screenWidth - itemHeight * 5) / 2.0f;

    if ([UIDevice acc_isIPad]) {
        itemHeight = 414.0f * 71.5 / 375.0f;
        insetHeight = (414.0f - itemHeight * 5) / 2.0f;
    }

    return insetHeight + itemHeight + 14.0; // 14.0 is for prop name label height
}

- (UITextField *)textField
{
    return self.searchBar.textField;
}

- (AWEStickerPickerSearchBar *)searchBar
{
    if (!_searchBar) {
        _searchBar = [[AWEStickerPickerSearchBar alloc] init];
        _searchBar.isTab = self.isTab;
        NSDictionary *attributes = @{
            NSForegroundColorAttributeName : ACCResourceColor(ACCUIColorConstTextInverse3),
            NSFontAttributeName : [ACCFont() systemFontOfSize:15]
        };
        NSAttributedString *placeHolderString = [[NSAttributedString alloc] initWithString:@"搜索道具名称、元素、风格、玩法" attributes:attributes];
        _searchBar.attributedPlaceHolder = placeHolderString;
        _searchBar.textColor = [UIColor whiteColor];
        _searchBar.type = AWEStickerPickerSearchBarTypeRightButtonShow;
        _searchBar.delegate = self;
        _searchBar.userInteractionEnabled = YES;
        _searchBar.textField.returnKeyType = UIReturnKeySearch;
        _searchBar.textField.enablesReturnKeyAutomatically = YES;

        if (self.isTab) {
            UIView *dummyView = [[UIView alloc] init];
            dummyView.backgroundColor = [UIColor clearColor];
            _searchBar.textField.inputView = dummyView;
            _searchBar.searchTintColor = [UIColor clearColor];
            _searchBar.type = AWEStickerPickerSearchBarTypeRightButtonHidden;
            [_searchBar setIsHiddenRightButton:YES];
        }

        @weakify(self);
        _searchBar.rightButtonClickedBlock = ^{
            @strongify(self);
            [self p_cancelSearch];
        };

        _searchBar.clearButtonClickedBlock = ^{
            @strongify(self);
            [self p_clearSearchText];
        };

        _searchBar.didTapTextFieldBlock = ^{
            @strongify(self);
            [self didTapSearchTabTextField:self.searchBar.textField];
        };
    }
    return _searchBar;
}

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.sectionInset = UIEdgeInsetsZero;
        layout.minimumLineSpacing = 0;
        layout.minimumInteritemSpacing = 0;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.contentInset = UIEdgeInsetsZero;

        [_collectionView registerClass:[AWEStickerPickerCollectionViewCell class] forCellWithReuseIdentifier:[AWEStickerPickerCollectionViewCell identifier]];

        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.pagingEnabled = YES;
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        if (@available(iOS 10.0, *)) {
            _collectionView.prefetchingEnabled = NO;
        }

        if (@available(iOS 11.0, *)) {
            _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        _collectionView.hidden = YES;   // initial state
    }

    return _collectionView;
}

- (AWEStickerPickerHashtagView *)hashtagsView
{
    if (!_hashtagsView) {
        _hashtagsView = [[AWEStickerPickerHashtagView alloc] init];
        _hashtagsView.delegate = self;
    }
    return _hashtagsView;
}

- (UIView *)loadingContainerView
{
    if (!_loadingContainerView) {
        _loadingContainerView = [[UIView alloc] init];
        _loadingContainerView.hidden = YES;
    }

    return _loadingContainerView;
}

- (UILabel *)emptyLabel
{
    if (!_emptyLabel) {
        _emptyLabel = [[UILabel alloc] init];
        _emptyLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:13];
        _emptyLabel.textColor = ACCResourceColor(ACCUIColorConstTextTertiary4);
        _emptyLabel.textAlignment = NSTextAlignmentCenter;
        _emptyLabel.text = @"没有搜索到贴纸，你可以试试以下贴纸";
        _emptyLabel.hidden = YES;
    }

    return _emptyLabel;
}

#pragma mark - AB Experiments

- (ACCPropPanelSearchEntranceType)shouldSupportSearchFeature
{
    if ([[ACCPropExploreExperimentalControl sharedInstance] hiddenSearchEntry])  {
        return ACCPropPanelSearchEntranceTypeNone;
    }
    return ACCConfigEnum(kConfigInt_new_search_effect_config, ACCPropPanelSearchEntranceType);
}

@end
