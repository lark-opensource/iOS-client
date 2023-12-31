//
//  ACCTagsBrandPickerViewController.m
//  CameraClient-Pods-AwemeCore
//
//  Created by HuangHongsen on 2021/9/29.
//

#import "ACCTagsBrandPickerViewController.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import "ACCTagsListDataController.h"

@interface ACCEditTagsBrandTableViewCell : UITableViewCell<ACCTagsItemPickerTableViewCellProtocol>
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *tagLabel;
@property (nonatomic, strong) UILabel *tagsCountLabel;
@end

@implementation ACCEditTagsBrandTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        _iconImageView = [[UIImageView alloc] init];
        _iconImageView.backgroundColor = ACCResourceColor(ACCColorConstBGContainer2);
        _iconImageView.layer.cornerRadius = 2.f;
        _iconImageView.layer.masksToBounds = YES;
        [self.contentView addSubview:_iconImageView];
        ACCMasMaker(_iconImageView, {
            make.left.equalTo(self.contentView).offset(16.f);
            make.width.height.equalTo(@48.f);
            make.top.equalTo(self.contentView).offset(12.5);
        });
        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = ACCResourceColor(ACCColorConstTextInverse);
        _titleLabel.font = [ACCFont() systemFontOfSize:15.f weight:ACCFontWeightMedium];
        [self.contentView addSubview:_titleLabel];
        ACCMasMaker(_titleLabel, {
            make.left.equalTo(self.iconImageView.mas_right).offset(12.f);
            make.top.equalTo(self.iconImageView).offset(2.f);
        });
        
        UIView *tagContainer = [[UIView alloc] init];
        tagContainer.backgroundColor = [ACCResourceColor(ACCColorConstBGContainer2) colorWithAlphaComponent:0.06];
        tagContainer.layer.cornerRadius = 2.f;
        tagContainer.layer.masksToBounds = YES;
        [self.contentView addSubview:tagContainer];
        ACCMasMaker(tagContainer, {
            make.left.equalTo(self.titleLabel);
            make.bottom.equalTo(self.iconImageView).offset(-4);
            make.height.equalTo(@14.f);
        })
        
        _tagLabel = [[UILabel alloc] init];
        _tagLabel.font = [ACCFont() systemFontOfSize:10.f];
        _tagLabel.textColor = ACCResourceColor(ACCColorConstTextInverse4);
        [tagContainer addSubview:_tagLabel];
        ACCMasMaker(_tagLabel, {
            make.left.equalTo(tagContainer).offset(3);
            make.right.equalTo(tagContainer).offset(-3);
            make.centerY.equalTo(tagContainer);
        });
    }
    return self;
}

- (void)updateWithData:(NSObject *)data
{
    if (![data isKindOfClass:[ACCEditCommerceTagsModel class]]) {
        return ;
    }
    ACCEditCommerceTagsModel *brand = (ACCEditCommerceTagsModel *)data;
    [ACCWebImage() imageView:self.iconImageView setImageWithURLArray:brand.imageURL.urlList];
    self.titleLabel.text = brand.title;
    self.tagLabel.text = [brand.categories firstObject];
}

@end

@interface ACCTagsBrandPickerViewController ()
@property (nonatomic, strong) NSMutableArray *brandList;
@property (nonatomic, strong) ACCTagsListDataController *dataController;
@end

@implementation ACCTagsBrandPickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark - Data Management

- (void)fetchRecommendData
{
    self.currentKeyword = @"";
    @weakify(self)
    [self.dataController fetchRecommendDataWithCompletion:^(NSArray *result, NSString *keyword, BOOL hasMore) {
        @strongify(self)
        if ([keyword isEqualToString:self.currentKeyword]) {
            self.brandList = [result mutableCopy];
            [self handleData:result error:nil hasMore:hasMore];
        }
    }];
}

- (void)searchWithKeyword:(NSString *)searchWithKeyword completion:(ACCTagSearchCompletion)completion
{
    self.currentKeyword = searchWithKeyword;
    @weakify(self)
    [self.dataController searchWithKeyword:searchWithKeyword completion:^(NSArray *result, NSString *keyword, BOOL hasMore) {
        @strongify(self)
        if ([keyword isEqualToString:self.currentKeyword]) {
            self.brandList = [result mutableCopy];
            ACCBLOCK_INVOKE(completion, result, nil, hasMore);
        }
    }];
}

- (void)loadMoreWithKeyword:(NSString *)searchWithKeyword completion:(ACCTagSearchCompletion)completion
{
    self.currentKeyword = searchWithKeyword;
    @weakify(self)
    [self.dataController loadMoreWithKeyword:searchWithKeyword completion:^(NSArray *result, NSString *keyword, BOOL hasMore) {
        @strongify(self);
        if ([keyword isEqualToString:self.currentKeyword]) {
            [self.brandList addObjectsFromArray:result];
            ACCBLOCK_INVOKE(completion, [self.brandList copy], nil, hasMore);
        }
    }];
}

#pragma mark - Override

- (NSString *)searchBarPlaceHolder
{
    return @"搜索品牌";
}

- (ACCEditTagType)type
{
    return ACCEditTagTypeBrand;
}

- (Class)cellClass
{
    return [ACCEditTagsBrandTableViewCell class];
}

- (NSString *)cellIdentifier
{
    return @"ACCEditTagsBrandTableViewCell";
}

- (CGFloat)cellHeight
{
    return 73.f;
}

- (CGFloat)headerHeight
{
    return 22.f;
}

- (NSString *)headerText
{
    return @"热门";
}

- (NSArray *)dataSource
{
    return [self.brandList copy];
}

- (BOOL)needFooter
{
    return NO;
}

- (NSString *)emptyResultText
{
    return [NSString stringWithFormat:@"未搜索出相关品牌，你可创建此自定义标记"];
}

- (AWEInteractionEditTagStickerModel *)tagModelForIndexPath:(NSIndexPath *)indexPath
{
    NSArray *dataSource = [self dataSource];
    if (indexPath.row >= [dataSource count]) {
        return nil;
    }
    ACCEditCommerceTagsModel *brand = dataSource[indexPath.row];
    AWEInteractionEditTagStickerModel *tagModel = [[AWEInteractionEditTagStickerModel alloc] init];
    AWEInteractionEditTagStickerInfoModel *tagInfo = [[AWEInteractionEditTagStickerInfoModel alloc] init];
    tagInfo.type = [self type];
    tagModel.editTagInfo = tagInfo;
    tagInfo.text = brand.title;
    AWEInteractionEditTagBrandTagModel *brandTagInfo = [[AWEInteractionEditTagBrandTagModel alloc] init];
    brandTagInfo.brandID = brand.itemID;
    tagInfo.brandTag = brandTagInfo;
    return tagModel;
}

- (NSInteger)indexOfItem:(NSString *)item
{
    NSArray *dataSource = [self dataSource];
    for (NSInteger index = 0; index < [dataSource count]; index++) {
        NSObject *obj = dataSource[index];
        if ([obj isKindOfClass:[ACCEditCommerceTagsModel class]]) {
            ACCEditCommerceTagsModel *brand = (ACCEditCommerceTagsModel *)obj;
            if ([brand.itemID isEqualToString:item]) {
                return index;
            }
        }
    }
    return -1;
}

- (NSString *)itemTitle
{
    return @"品牌";
}

-(NSString *)tagTypeString
{
    return @"brand";
}

- (NSDictionary *)itemTrackerParamsForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *dataSource = [self dataSource];
    if (indexPath.row < [dataSource count]) {
        ACCEditCommerceTagsModel *brand = dataSource[indexPath.row];
        return @{
            @"brand_id" : brand.itemID ? : @"",
        };
    }
    return @{};
}

#pragma mark - Getter

- (ACCTagsListDataController *)dataController
{
    if (!_dataController) {
        _dataController = [[ACCTagsListDataController alloc] init];
        _dataController.type = ACCTagsCommerceSearchTypeBrand;
    }
    return _dataController;
}
@end
