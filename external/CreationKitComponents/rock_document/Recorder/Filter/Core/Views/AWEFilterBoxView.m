//
//  AWEFilterBoxView.m
//  Pods
//
//  Created by zhangchengtao on 2019/5/7.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEFilterBoxView.h"

#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/ACCLoadingViewProtocol.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreationKitInfra/ACCRecordFilterDefines.h>
#import "ACCFilterConfigKeyDefines.h"
#import <CreationKitInfra/ACCConfigManager.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIFont+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>

///Classification cell
@interface AWEFilterBoxCategoryCell : UITableViewCell

@property (nonatomic, strong) UILabel *categoryNameLabel;

@property (nonatomic, strong) IESCategoryModel *categoryModel;

@end

@implementation AWEFilterBoxCategoryCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        _categoryNameLabel = [[UILabel alloc] init];
        _categoryNameLabel.font = ACCResourceFontSize(ACCFontPrimary, 15.f);
        UIColor *textColor = ACCResourceColor(ACCUIColorConstTextInverse3);
        _categoryNameLabel.textColor = [textColor colorWithAlphaComponent:0.5f];
        _categoryNameLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_categoryNameLabel];
        ACCMasMaker(_categoryNameLabel, {
            make.left.equalTo(@(20));
            make.right.equalTo(@(-20));
            make.top.equalTo(@(17));
            make.bottom.equalTo(@(-17));
        });
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    UIColor *textColor = ACCResourceColor(ACCUIColorConstTextInverse3);
    if (selected) {
        self.categoryNameLabel.font = ACCResourceFontSize(ACCFontPrimary, 15.f);
        self.categoryNameLabel.textColor = [textColor colorWithAlphaComponent:1.0f];
    } else {
        self.categoryNameLabel.font = ACCResourceFontSize(ACCFontPrimary, 15.f);
        self.categoryNameLabel.textColor = [textColor colorWithAlphaComponent:0.5f];
    }
}

- (void)setCategoryModel:(IESCategoryModel *)categoryModel
{
    _categoryModel = categoryModel;
    
    self.categoryNameLabel.text = categoryModel.categoryName;
}

@end

///Filter cell
@interface AWEFilterBoxFilterCell : UITableViewCell

@property (nonatomic, strong) UIImageView *filterImageView;

@property (nonatomic, strong) UILabel *filterNameLabel;

@property (nonatomic, strong) UIImageView *checkImageView;

@property (nonatomic, strong) IESEffectModel *filterModel;

@property (nonatomic, assign) AWEFilterCellIconStyle iconStyle;

@end

@implementation AWEFilterBoxFilterCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleDefault;
        self.selectedBackgroundView = [[UIView alloc] init];
        self.selectedBackgroundView.backgroundColor = ACCResourceColor(ACCUIColorConstBGContainerInverse);
        
        _filterImageView = [[UIImageView alloc] init];
        _filterImageView.layer.cornerRadius = 14.0f;
        _filterImageView.clipsToBounds = YES;
        [self.contentView addSubview:_filterImageView];
        ACCMasMaker(_filterImageView, {
            make.left.equalTo(@(28));
            make.width.equalTo(_filterImageView.mas_height);
            make.top.equalTo(@(12));
            make.bottom.equalTo(@(-12));
        });
        
        _filterNameLabel = [[UILabel alloc] init];
        _filterNameLabel.font = ACCResourceFontSize(ACCFontPrimary, 14.f);
        UIColor *textColor = ACCResourceColor(ACCUIColorConstTextInverse3);
        _filterNameLabel.textColor = [textColor colorWithAlphaComponent:1.0f];
        _filterNameLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_filterNameLabel];
        ACCMasMaker(_filterNameLabel, {
            make.left.equalTo(_filterImageView.mas_right).offset(12);
            make.centerY.equalTo(self.contentView.mas_centerY);
            make.height.equalTo(@(16));
        });
        
        _checkImageView = [[UIImageView alloc] init];
        [self.contentView addSubview:_checkImageView];
        ACCMasMaker(_checkImageView, {
            make.width.height.equalTo(@(20));
            make.right.equalTo(@(-20));
            make.centerY.equalTo(self.contentView.mas_centerY);
        });
    }
    return self;
}

- (void)setFilterModel:(IESEffectModel *)filterModel
{
    _filterModel = filterModel;
    [ACCWebImage() imageView:self.filterImageView setImageWithURLArray:filterModel.iconDownloadURLs];
    self.filterNameLabel.text = filterModel.effectName;
    
    if (filterModel.isBuildin) {
        self.checkImageView.image = ACCResourceImage(@"icon_filter_box_buildin");
    } else {
        if (filterModel.isChecked) {
            self.checkImageView.image = ACCResourceImage(@"icon_filter_box_check");
        } else {
            self.checkImageView.image = ACCResourceImage(@"icon_filter_box_uncheck");
        }
    }
}

- (void)setCheckImageViewChecked:(BOOL)checked
{
    if (checked) {
        self.checkImageView.image = ACCResourceImage(@"icon_filter_box_check");
    } else {
        self.checkImageView.image = ACCResourceImage(@"icon_filter_box_uncheck");
    }
}

- (void)setIconStyle:(AWEFilterCellIconStyle)iconStyle
{
    if (_iconStyle != iconStyle) {
        _iconStyle = iconStyle;
        [self configWithIconStyle: iconStyle];
    }
}

- (void)configWithIconStyle:(AWEFilterCellIconStyle)iconStyle
{
    switch (iconStyle) {
        case AWEFilterCellIconStyleRound:
            [self configWithRoundStyle];
            break;
        case AWEFilterCellIconStyleSquare:
            [self configWithSquareStyle];
            break;
        default:
            break;
    }
}

- (void)configWithRoundStyle
{
    _filterImageView.layer.cornerRadius = 14.0;
}

- (void)configWithSquareStyle
{
    _filterImageView.layer.cornerRadius = 2;
}


@end

@interface AWEFilterBoxView () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, copy) NSArray<IESCategoryModel *> *filterCategorys; //Classified data
@property (nonatomic, strong) IESCategoryModel *currentCategory; //Currently selected category

@property (nonatomic, strong) UITableView *categoryTableView; //Filter classification list
@property (nonatomic, strong) UITableView *filterTableView; //Filter list

@property (nonatomic, strong) NSMutableSet *checkSet;
@property (nonatomic, strong) NSMutableSet *uncheckSet;

@property (nonatomic, strong) UIView<ACCLoadingViewProtocol> *loadingView;
@property (nonatomic, strong) UIView *categoryBackgroundView;

@end

@implementation AWEFilterBoxView

- (instancetype)init
{
    if (self = [super init]) {
        self.backgroundColor = [ACCResourceColor(ACCColorBGCreation2) colorWithAlphaComponent:0.8];
        [self acc_addBlurEffect];
        
        [self addSubview:self.categoryBackgroundView];
        [self.categoryBackgroundView addSubview:self.categoryTableView];
        [self addSubview:self.filterTableView];
        
        ACCMasMaker(self.categoryBackgroundView, {
            make.left.bottom.top.equalTo(self);
            make.width.equalTo(@(120));
        });
        ACCMasMaker(self.categoryTableView, {
            make.left.bottom.equalTo(self.categoryBackgroundView);
            make.top.equalTo(self.categoryBackgroundView).offset(10);
            make.width.equalTo(@(120));
        });
        
        ACCMasMaker(self.filterTableView, {
            make.right.bottom.equalTo(self);
            make.top.equalTo(self).offset(10);
            make.left.equalTo(self.categoryTableView.mas_right);
        });
    }
    return self;
}

#pragma mark - Getter

- (UIView *)categoryBackgroundView
{
    if (!_categoryBackgroundView) {
        _categoryBackgroundView = [[UIView alloc] init];
        _categoryBackgroundView.backgroundColor = ACCResourceColor(ACCColorSDSecondary);
    }
    return _categoryBackgroundView;
}

- (UITableView *)categoryTableView
{
    if (!_categoryTableView) {
        _categoryTableView = [[UITableView alloc] init];
        _categoryTableView.backgroundColor = [UIColor clearColor];
        _categoryTableView.dataSource = self;
        _categoryTableView.delegate = self;
        _categoryTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _categoryTableView.tableFooterView = [UIView new];
        [_categoryTableView registerClass:[AWEFilterBoxCategoryCell class] forCellReuseIdentifier:NSStringFromClass([AWEFilterBoxCategoryCell class])];
    }
    return _categoryTableView;
}

- (UITableView *)filterTableView
{
    if (!_filterTableView) {
        _filterTableView = [[UITableView alloc] init];
        _filterTableView.backgroundColor = [UIColor clearColor];
        _filterTableView.dataSource = self;
        _filterTableView.delegate = self;
        _filterTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _filterTableView.tableFooterView = [UIView new];
        [_filterTableView registerClass:[AWEFilterBoxFilterCell class] forCellReuseIdentifier:NSStringFromClass([AWEFilterBoxFilterCell class])];
    }
    return _filterTableView;
}

- (NSMutableSet *)checkSet
{
    if (!_checkSet) {
        _checkSet = [[NSMutableSet alloc] init];
    }
    return _checkSet;
}

- (NSMutableSet *)uncheckSet
{
    if (!_uncheckSet) {
        _uncheckSet = [[NSMutableSet alloc] init];
    }
    return _uncheckSet;
}

- (AWEFilterCellIconStyle)p_cellIconStyle
{
    return ACCConfigInt(kConfigInt_filter_icon_style) == AWEFilterCellIconStyleRound ? AWEFilterCellIconStyleRound: AWEFilterCellIconStyleSquare;
}

#pragma mark - Public

- (NSArray *)checkArray
{
    return [self.checkSet allObjects];
}

- (NSArray *)uncheckArray
{
    return [self.uncheckSet allObjects];
}

- (void)setCategories:(NSArray<IESCategoryModel *> *)categories
{
    _categories = [categories copy];
    self.filterCategorys = _categories;
    self.currentCategory = _categories.firstObject;
    [self.categoryTableView reloadData]; //The first category is selected by default
    if (self.filterCategorys.count > 0) {
        NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.categoryTableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    [self.filterTableView reloadData]; //The data of the first category is displayed by default
}

- (void)setCurrentCategory:(IESCategoryModel *)currentCategory
{
    if (_currentCategory != currentCategory) {
        _currentCategory = currentCategory;
        [self.filterTableView reloadData];
        if ([self.filterTableView numberOfRowsInSection:0] > 0) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            [self.filterTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
        }
    }
}

- (void)showLoading:(BOOL)showOrHide
{
    if (showOrHide) {
        [self.loadingView removeFromSuperview];
        self.loadingView = nil;
        self.loadingView = [ACCLoading() showLoadingOnView:self];
    } else {
        [self.loadingView dismissWithAnimated:YES];
        self.loadingView = nil;
    }
}

- (void)showError:(BOOL)showOrHide
{
    [ACCToast() show:ACCLocalizedCurrentString(@"com_mig_network_error")];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.categoryTableView == tableView) {
        return self.filterCategorys.count;
    } else if (self.filterTableView == tableView) {
        return self.currentCategory.effects.count;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.categoryTableView == tableView) {
        AWEFilterBoxCategoryCell *categoryCell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([AWEFilterBoxCategoryCell class])];
        [categoryCell setCategoryModel:[self.filterCategorys objectAtIndex:indexPath.row]];
        return categoryCell;
    } else if (self.filterTableView == tableView) {
        AWEFilterBoxFilterCell *filterCell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([AWEFilterBoxFilterCell class])];
        [filterCell setFilterModel:[self.currentCategory.effects objectAtIndex:indexPath.row]];
        filterCell.iconStyle = [self p_cellIconStyle];
        return filterCell;
    }
    
    return [UITableViewCell new];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.categoryTableView == tableView) {
        return 52.0f;
    } else if (self.filterTableView == tableView) {
        return 52.0f;
    }
    
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.categoryTableView == tableView) {
        self.currentCategory = [self.filterCategorys objectAtIndex:indexPath.row];
        [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    } else if (self.filterTableView == tableView) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        IESEffectModel *filterModel = [self.currentCategory.effects objectAtIndex:indexPath.row];
        if (filterModel.isBuildin) {
            //Built in cannot be checked or deselected
            
            if (self.selectionBlock) {
                self.selectionBlock(filterModel);
            }
        } else {
            if (filterModel.isChecked) {
                filterModel.isChecked = NO;
                AWEFilterBoxFilterCell *filterCell = [tableView cellForRowAtIndexPath:indexPath];
                [filterCell setCheckImageViewChecked:NO];
                if (filterModel.effectIdentifier) {
                    if ([self.checkSet containsObject:filterModel.effectIdentifier]) {
                        [self.checkSet removeObject:filterModel.effectIdentifier];
                    } else {
                        [self.uncheckSet addObject:filterModel.effectIdentifier];
                    }
                }
                
                //Deselect filter
                if (self.unselectionBlock) {
                    self.unselectionBlock(filterModel);
                }
            } else {
                filterModel.isChecked = YES;
                AWEFilterBoxFilterCell *filterCell = [tableView cellForRowAtIndexPath:indexPath];
                [filterCell setCheckImageViewChecked:YES];
                if (filterModel.effectIdentifier) {
                    if ([self.uncheckSet containsObject:filterModel.effectIdentifier]) {
                        [self.uncheckSet removeObject:filterModel.effectIdentifier];
                    } else {
                        [self.checkSet addObject:filterModel.effectIdentifier];
                    }
                }
                
                if (self.selectionBlock) {
                    self.selectionBlock(filterModel);
                }
            }
        }
    }
}

@end
