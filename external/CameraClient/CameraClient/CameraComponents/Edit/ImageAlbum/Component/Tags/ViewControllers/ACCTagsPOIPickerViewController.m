//
//  ACCTagsPOIPickerViewController.m
//  CameraClient-Pods-AwemeCore
//
//  Created by HuangHongsen on 2021/9/29.
//

#import "ACCTagsPOIPickerViewController.h"
#import <CreativeKit/UISearchBar+ACCAdditions.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreationKitInfra/ACCResponder.h>
#import <CreationKitInfra/ACCConfigManager.h>
#import "ACCPOIServiceProtocol.h"
#import "ACCEditTagsPOISearchTypeSelectionView.h"
#import "ACCConfigKeyDefines.h"

static const CGFloat kACCTagsPOIPickerHeaderViewHeight = 22.f;

@interface ACCTagsPOIPickerTableViewCell : UITableViewCell<ACCTagsItemPickerTableViewCellProtocol>
@property (nonatomic, strong) UILabel *poiTitleLabel;
@property (nonatomic, strong) UILabel *poiAddressLabel;
@property (nonatomic, strong) UILabel *distanceLabel;
@end

@implementation ACCTagsPOIPickerTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        _poiTitleLabel = [[UILabel alloc] init];
        _poiTitleLabel.textColor = ACCResourceColor(ACCColorConstTextInverse);
        _poiTitleLabel.font = [ACCFont() systemFontOfSize:15.f];
        [self.contentView addSubview:_poiTitleLabel];
        ACCMasMaker(_poiTitleLabel, {
            make.left.equalTo(self.contentView).offset(16.f);
            make.right.lessThanOrEqualTo(self.contentView).offset(-16.f);
            make.top.equalTo(self.contentView).offset(16.f);
        });
        
        _distanceLabel = [[UILabel alloc] init];
        _distanceLabel.textColor = ACCResourceColor(ACCColorConstTextInverse4);
        _distanceLabel.font = [ACCFont() systemFontOfSize:13.f];
        [self.contentView addSubview:_distanceLabel];
        ACCMasMaker(_distanceLabel, {
            make.right.equalTo(self.contentView).offset(-16.f);
            make.bottom.equalTo(self.contentView).offset(-16.f);
        });
        
        _poiAddressLabel = [[UILabel alloc] init];
        _poiAddressLabel.textColor = ACCResourceColor(ACCColorConstTextInverse4);
        _poiAddressLabel.font = [ACCFont() systemFontOfSize:13.f];
        [self.contentView addSubview:_poiAddressLabel];
        ACCMasMaker(_poiAddressLabel, {
            make.left.equalTo(self.poiTitleLabel);
            make.bottom.equalTo(self.contentView).offset(-16.f);
            make.right.lessThanOrEqualTo(_distanceLabel.mas_left).offset(-8.f);
        });
    }
    return self;
}

- (void)updateWithData:(NSObject *)data
{
    if ([data conformsToProtocol:@protocol(ACCPOIInfoModelProtocol)]) {
        id <ACCPOIInfoModelProtocol> poiModel = (id<ACCPOIInfoModelProtocol>)data;
        self.poiTitleLabel.text = poiModel.poiName;
        self.poiAddressLabel.text = poiModel.poiAddress;
        self.distanceLabel.text = poiModel.distance;
        if (ACC_isEmptyString(poiModel.distance)) {
            ACCMasReMaker(self.distanceLabel, {
                make.right.equalTo(self.contentView).offset(-16.f);
                make.bottom.equalTo(self.contentView).offset(-16.f);
                make.width.equalTo(@0);
            });
            ACCMasReMaker(self.poiAddressLabel, {
                make.left.equalTo(self.poiTitleLabel);
                make.bottom.equalTo(self.contentView).offset(-16.f);
                make.right.lessThanOrEqualTo(_distanceLabel.mas_left);
            });
        } else {
            ACCMasReMaker(self.distanceLabel, {
                make.right.equalTo(self.contentView).offset(-16.f);
                make.bottom.equalTo(self.contentView).offset(-16.f);
            });
            ACCMasReMaker(self.poiAddressLabel, {
                make.left.equalTo(self.poiTitleLabel);
                make.bottom.equalTo(self.contentView).offset(-16.f);
                make.right.lessThanOrEqualTo(_distanceLabel.mas_left).offset(-8.f);
            });
        }
    }
}

@end

@interface ACCTagsPOIPickerViewController ()<ACCEditTagsPOISearchTypeSelectionViewDelegate>
@property (nonatomic, strong) NSMutableArray<id<ACCPOIInfoModelProtocol>> *poiList;
@property (nonatomic, strong) UIImageView *arrowImageView;
@property (nonatomic, strong) UILabel *searchTypeLabel;
@property (nonatomic, strong) CAShapeLayer *maskLayer;
@property (nonatomic, strong) ACCEditTagsPOISearchType *currentSearchType;
@property (nonatomic, strong) ACCEditTagsPOISearchTypeSelectionView *searchTypeSelectionView;
@property (nonatomic, assign) BOOL isFirstAppear;
@property (nonatomic, strong) NSArray<ACCEditTagsPOISearchType *> *searchTypes;
@property (nonatomic, strong) id<ACCPOIServiceProtocol> poiService;
@end

@implementation ACCTagsPOIPickerViewController

IESAutoInject(ACCBaseServiceProvider(), poiService, ACCPOIServiceProtocol)

- (void)viewDidLoad {
    [super viewDidLoad];
    self.currentSearchType = [[self searchTypes] firstObject];
    [self setupSearchTypePicker];
}

#pragma mark - Data Management

- (void)fetchRecommendData
{
    @weakify(self)
    [self searchWithKeyword:@"" completion:^(NSArray *result, NSError *error, BOOL hasMore) {
        @strongify(self)
        [self handleData:result error:error hasMore:hasMore];
    }];
}

- (void)searchWithKeyword:(NSString *)searchWithKeyword completion:(ACCTagSearchCompletion)completion
{
    @weakify(self)
    self.currentKeyword = searchWithKeyword;
    [self.poiService searchPOIWithKeyword:searchWithKeyword searchType:self.currentSearchType.searchType completion:^(NSArray<id<ACCPOIInfoModelProtocol>> * result, NSString * keyword, BOOL hasMore) {
        @strongify(self)
        self.poiList = [result mutableCopy];
        if ([keyword isEqualToString:self.currentKeyword]) {
            ACCBLOCK_INVOKE(completion, result, nil, hasMore);
        }
    }];
}

- (void)loadMoreWithKeyword:(NSString *)searchWithKeyword completion:(ACCTagSearchCompletion)completion
{
    @weakify(self)
    [self.poiService loadMorePOIWithKeyword:searchWithKeyword searchType:self.currentSearchType.searchType completion:^(NSArray<id<ACCPOIInfoModelProtocol>> * _Nonnull result, NSString * _Nonnull keyword, BOOL hasMore) {
        @strongify(self)
        if ([keyword isEqualToString:self.currentKeyword]) {
            [self.poiList addObjectsFromArray:result];
            ACCBLOCK_INVOKE(completion, result, nil, hasMore);
        }
    }];
}

- (void)restoreRecommendData
{
    @weakify(self)
    [self searchWithKeyword:@"" completion:^(NSArray *result, NSError *error, BOOL hasMore) {
        @strongify(self)
        [self handleData:result error:error hasMore:hasMore];
    }];
}

#pragma mark - ACCEditTagsPOISearchTypeSelectionViewDelegate

- (void)searchTypeSelectionView:(ACCEditTagsPOISearchTypeSelectionView *)searchTypeSelectionView didSelectSearchType:(ACCEditTagsPOISearchType *)searchType
{
    [self.searchBar resignFirstResponder];
    [self hideCancelButton];
    [self handleSelectionViewWillDismiss];
    if (searchType.searchType == self.currentSearchType.searchType) {
        return ;
    }
    self.currentSearchType = searchType;
    self.searchTypeLabel.text = searchType.searchTypeName;
    [self updateHeaderView];
    self.loadStatus = ACCTagsItemPickerLoadStatusLoading;
    @weakify(self)
    [self searchWithKeyword:self.currentKeyword completion:^(NSArray *result, NSError *error, BOOL hasMore) {
        @strongify(self)
        [self handleData:result error:error hasMore:hasMore];
    }];
}

- (void)searchTypeSelectionViewWillDismiss:(ACCEditTagsPOISearchTypeSelectionView *)searchTypeSelectionView
{
    [self handleSelectionViewWillDismiss];
}

- (void)handleSelectionViewWillDismiss
{
    self.searchTypeSelectionView.userInteractionEnabled = NO;
    [UIView animateWithDuration:[self.searchTypeSelectionView animationDuration] animations:^{
        self.arrowImageView.transform = CGAffineTransformIdentity;
        self.tableView.alpha = 1.f;
        self.tableView.backgroundColor = [UIColor clearColor];
    } completion:^(BOOL finished) {
        self.searchTypeSelectionView.userInteractionEnabled = YES;
        [self.searchTypeSelectionView removeFromSuperview];
    }];
    
    UIBezierPath *toPath = [UIBezierPath bezierPathWithRect:self.normalView.bounds];
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
    animation.fromValue = (id)self.maskLayer.path;
    animation.toValue = (id)toPath.CGPath;
    animation.duration = [self.searchTypeSelectionView animationDuration];
    [self.maskLayer addAnimation:animation forKey:@"path"];
    
    [CATransaction begin];
    self.maskLayer.path = toPath.CGPath;
    [CATransaction commit];
}

#pragma mark - Private Helper

- (void)setupSearchTypePicker
{
    ACCEditTagsPOISearchTypeSelectionView *searchTypeSelectionView = [[ACCEditTagsPOISearchTypeSelectionView alloc] init];
    searchTypeSelectionView.delegate = self;
    [searchTypeSelectionView updateWithSearchTypes:[self searchTypes] selectedType:self.currentSearchType ? : [[self searchTypes] firstObject]];
    searchTypeSelectionView.frame = CGRectMake(0, 0, ACC_SCREEN_WIDTH, ACC_SCREEN_HEIGHT);
    self.searchTypeSelectionView = searchTypeSelectionView;
}

- (UIView *)searchBarLeftView
{
    UIView *leftActionView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 63, [self.searchBar searchBarHeight])];
    UITapGestureRecognizer *tapOnActionView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showSearchTypePicker)];
    [leftActionView addGestureRecognizer:tapOnActionView];
    
    UILabel *textLabel = [[UILabel alloc] init];
    textLabel.text = [self.searchTypes firstObject].searchTypeName;
    textLabel.textColor = ACCResourceColor(ACCColorConstTextInverse5);
    textLabel.font = [ACCFont() systemFontOfSize:15.f];
    [textLabel sizeToFit];
    self.searchTypeLabel = textLabel;
    [leftActionView addSubview:textLabel];
    ACCMasMaker(textLabel, {
        make.left.equalTo(leftActionView).offset(12.f);
        make.centerY.equalTo(leftActionView);
    });

    UIImageView *arrowImageView = [[UIImageView alloc] init];
    arrowImageView.image = ACCResourceImage(@"icon_edit_tags_arrow_down");
    self.arrowImageView = arrowImageView;
    [leftActionView addSubview:arrowImageView];
    ACCMasMaker(arrowImageView, {
        make.width.height.equalTo(@16.f);
        make.left.equalTo(textLabel.mas_right);
        make.centerY.equalTo(textLabel);
    });

    UIView *separator = [[UIView alloc] init];
    separator.backgroundColor = ACCResourceColor(ACCColorConstTextInverse5);
    [leftActionView addSubview:separator];
    ACCMasMaker(separator, {
        make.left.equalTo(arrowImageView.mas_right).offset(4.f);
        make.width.equalTo(@1);
        make.height.equalTo(@16.f);
        make.centerY.equalTo(arrowImageView);
    });
    return leftActionView;
}

- (void)showSearchTypePicker
{
    if (self.loadStatus == ACCTagsItemPickerLoadStatusLoading) {
        return ;
    }
    [self.searchTypeSelectionView updateWithSearchTypes:[self searchTypes] selectedType:self.currentSearchType];
    CGRect searchBarFrameInTopView = [self.searchBar convertRect:self.searchBar.textField.frame toView:[ACCResponder topView]];
    [self.searchTypeSelectionView setTopInset:CGRectGetMaxY(searchBarFrameInTopView)];
    [self.searchTypeSelectionView showOnView:[ACCResponder topView]];
    self.searchTypeSelectionView.userInteractionEnabled = NO;
    [UIView animateWithDuration:[self.searchTypeSelectionView animationDuration] animations:^{
        self.arrowImageView.transform = CGAffineTransformRotate(CGAffineTransformIdentity, M_PI);
        self.tableView.alpha = 0.6;
        self.tableView.backgroundColor = [UIColor blackColor];
    } completion:^(BOOL finished) {
        self.searchTypeSelectionView.userInteractionEnabled = YES;
    }];
    
    self.maskLayer = [CAShapeLayer layer];
    self.maskLayer.frame = self.normalView.bounds;
    CGRect initialPath = self.normalView.bounds;
    self.maskLayer.path = [UIBezierPath bezierPathWithRect:initialPath].CGPath;
    self.currentView.layer.mask = self.maskLayer;
    
    UIBezierPath *toPath = [UIBezierPath bezierPathWithRect:CGRectMake(initialPath.origin.x, initialPath.origin.y + [self.searchTypeSelectionView menuHeight], initialPath.size.width, initialPath.size.height - [self.searchTypeSelectionView menuHeight])];
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
    animation.fromValue = (id)self.maskLayer.path;
    animation.toValue = (id)toPath.CGPath;
    animation.duration = [self.searchTypeSelectionView animationDuration];
    [self.maskLayer addAnimation:animation forKey:@"path"];
    
    [CATransaction begin];
    self.maskLayer.path = toPath.CGPath;
    [CATransaction commit];
}

- (NSArray <ACCEditTagsPOISearchType *> *)searchTypes
{
    if (!_searchTypes) {
        NSMutableArray *dataSource = [NSMutableArray array];
        ACCEditTagsPOISearchType *local = [[ACCEditTagsPOISearchType alloc] init];
        local.searchType = 0;
        local.searchTypeName = @"本地";
        [dataSource addObject:local];
        
        ACCEditTagsPOISearchType *domestic = [[ACCEditTagsPOISearchType alloc] init];
        domestic.searchType = 2;
        domestic.searchTypeName = @"国内";
        [dataSource addObject:domestic];
        
        if ([self enableOverSea]) {
            ACCEditTagsPOISearchType *abroad = [[ACCEditTagsPOISearchType alloc] init];
            abroad.searchType = 3;
            abroad.searchTypeName = @"海外";
            [dataSource addObject:abroad];
        }
        _searchTypes = [dataSource copy];
    }
    return _searchTypes;
}

- (BOOL)enableOverSea
{
    return ACCConfigBool(kConfigBool_poi_tag_enable_global_search);
}

#pragma mark - Override

- (NSString *)searchBarPlaceHolder
{
    return @"搜索位置";
}

- (ACCEditTagType)type
{
    return ACCEditTagTypePOI;
}

- (Class)cellClass
{
    return [ACCTagsPOIPickerTableViewCell class];
}

- (NSString *)cellIdentifier
{
    return @"ACCTagsPOIPickerTableViewCell";
}

- (NSString *)emptyResultText
{
    return @"未搜索出相关位置，你可创建此自定义标记";
}

- (NSString *)headerText
{
    if (self.currentSearchType.searchType != 0) {
        return @"输入城市名+关键字可更准确的查找地点";
    } else {
        return @"";
    }
}

- (CGFloat)headerHeight
{
    if (self.currentSearchType.searchType != 0) {
        return kACCTagsPOIPickerHeaderViewHeight;
    } else {
        return 0.f;
    }
}

- (NSDictionary *)itemTrackerParamsForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *dataSource = [self dataSource];
    if (indexPath.row < [dataSource count]) {
        id<ACCPOIInfoModelProtocol> poi = dataSource[indexPath.row];
        return @{
            @"poi_id" : poi.poiId ? : @"",
        };
    }
    return @{};
}

- (CGFloat)cellHeight
{
    return 72;
}

- (NSArray *)dataSource
{
    return [self.poiList copy];
}

- (AWEInteractionEditTagStickerModel *)tagModelForIndexPath:(NSIndexPath *)indexPath
{
    NSArray *dataSource = [self dataSource];
    if (indexPath.row >= [dataSource count]) {
        return nil;
    }
    id<ACCPOIInfoModelProtocol> poi = dataSource[indexPath.row];
    AWEInteractionEditTagStickerModel *tagModel = [[AWEInteractionEditTagStickerModel alloc] init];
    AWEInteractionEditTagStickerInfoModel *tagInfo = [[AWEInteractionEditTagStickerInfoModel alloc] init];
    tagInfo.type = [self type];
    tagModel.editTagInfo = tagInfo;
    tagInfo.text = poi.poiName;
    AWEInteractionEditTagPOITagModel *poiTagModel = [[AWEInteractionEditTagPOITagModel alloc] init];
    poiTagModel.POIID = poi.poiId;
    tagInfo.POITag = poiTagModel;
    return tagModel;
}

- (NSInteger)indexOfItem:(NSString *)item
{
    NSArray *dataSource = [self dataSource];
    for (NSInteger index = 0; index < [dataSource count]; index++) {
        NSObject *obj = dataSource[index];
        if ([obj conformsToProtocol:@protocol(ACCPOIInfoModelProtocol)]) {
            id<ACCPOIInfoModelProtocol> poi = (id<ACCPOIInfoModelProtocol>)obj;
            if ([poi.poiId isEqualToString:item]) {
                return index;
            }
        }
    }
    return -1;
}

- (NSString *)itemTitle
{
    return @"位置";
}

- (NSString *)tagTypeString
{
    return @"poi";
}

- (void)setLoadStatus:(ACCTagsItemPickerLoadStatus)loadStatus
{
    [super setLoadStatus:loadStatus];
    if (loadStatus == ACCTagsItemPickerLoadStatusSuccess) {
        self.currentView.layer.mask = self.maskLayer;
    }
}

@end
