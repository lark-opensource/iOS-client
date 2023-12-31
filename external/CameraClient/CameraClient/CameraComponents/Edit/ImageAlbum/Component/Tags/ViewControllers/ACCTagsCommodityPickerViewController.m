//
//  ACCTagsCommodityPickerViewController.m
//  CameraClient-Pods-AwemeCore
//
//  Created by HuangHongsen on 2021/9/29.
//

#import "ACCTagsCommodityPickerViewController.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import "ACCTagsListDataController.h"
#import <CreativeKit/UIImage+ACC.h>
#import <CreativeKit/UIImage+CameraClientResource.h>

@interface ACCEditTagsCommodityTableViewCell : UITableViewCell<ACCTagsItemPickerTableViewCellProtocol>
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *tagLabel;
@property (nonatomic, strong) UILabel *tagsCountLabel;
@property (nonatomic, strong) UIView *tagContainer;
@property (nonatomic, strong) UIImage *placeHolderImage;
@property (nonatomic, strong) UIView *iconContainer;
@end

@implementation ACCEditTagsCommodityTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        CGFloat iconImageWidth = 48.f;
        _iconContainer = [[UIView alloc] init];
        _iconContainer.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.06];
        _iconContainer.layer.cornerRadius = 2.f;
        _iconContainer.layer.masksToBounds = YES;
        [self.contentView addSubview:_iconContainer];
        ACCMasMaker(_iconContainer, {
            make.left.equalTo(self.contentView).offset(16.f);
            make.width.height.equalTo(@(iconImageWidth));
            make.top.equalTo(self.contentView).offset(12.5);
        });
        
        _iconImageView = [[UIImageView alloc] init];
        _iconImageView.opaque = NO;
        _iconImageView.backgroundColor = [UIColor clearColor];
        _iconImageView.layer.cornerRadius = 2.f;
        _iconImageView.layer.masksToBounds = YES;
        [_iconContainer addSubview:_iconImageView];
        ACCMasMaker(_iconImageView, {
            make.edges.equalTo(_iconContainer);
        });
        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = ACCResourceColor(ACCColorConstTextInverse);
        _titleLabel.font = [ACCFont() systemFontOfSize:15.f weight:ACCFontWeightMedium];
        [self.contentView addSubview:_titleLabel];
        ACCMasMaker(_titleLabel, {
            make.left.equalTo(self.iconImageView.mas_right).offset(12.f);
            make.top.equalTo(self.iconImageView).offset(2.f);
            make.right.lessThanOrEqualTo(self.contentView).offset(-16.f);
        });
        
        UIView *tagContainer = [[UIView alloc] init];
        tagContainer.backgroundColor = [ACCResourceColor(ACCColorConstBGContainer2) colorWithAlphaComponent:0.06];
        tagContainer.layer.cornerRadius = 2.f;
        tagContainer.layer.masksToBounds = YES;
        _tagContainer = tagContainer;
        [self.contentView addSubview:tagContainer];
        ACCMasMaker(tagContainer, {
            make.left.equalTo(self.titleLabel);
            make.bottom.equalTo(self.iconImageView).offset(-4);
            make.height.equalTo(@14.f);
        });
        
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
    ACCEditCommerceTagsModel *commidty = (ACCEditCommerceTagsModel *)data;
    @weakify(self)
    [ACCWebImage() imageView:self.iconImageView
        setImageWithURLArray:commidty.imageURL.urlList
                 placeholder:self.placeHolderImage
                  completion:^(UIImage * image, NSURL *url, NSError * error){
        @strongify(self);
        if ([commidty.imageURL.urlList containsObject:[url absoluteString]] && image && !error) {
            self.iconImageView.image = image;
            self.iconContainer.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.08];
        } else {
            self.iconImageView.image = ACCResourceImage(@"icon_edit_tag_commodity_default");
            self.iconContainer.backgroundColor = [UIColor clearColor];
        }
    }];
    self.titleLabel.text = commidty.title;
    self.tagLabel.text = [commidty.categories firstObject];
    if (ACC_isEmptyString(self.tagLabel.text)) {
        self.tagContainer.hidden = YES;
        ACCMasReMaker(self.titleLabel, {
            make.left.equalTo(self.iconImageView.mas_right).offset(12.f);
            make.centerY.equalTo(self.iconImageView);
        });
    } else {
        self.tagContainer.hidden = NO;
        ACCMasReMaker(_titleLabel, {
            make.left.equalTo(self.iconImageView.mas_right).offset(12.f);
            make.top.equalTo(self.iconImageView).offset(2.f);
        });
    }
}

@end

@interface ACCTagsCommodityPickerViewController ()
@property (nonatomic, strong) NSMutableArray *commodities;
@property (nonatomic, strong) ACCTagsListDataController *dataController;
@property (nonatomic, copy) NSArray *recommendCommodities;
@end

@implementation ACCTagsCommodityPickerViewController

#pragma mark - Data Management

- (void)fetchRecommendData
{
    self.currentKeyword = @"";
    @weakify(self)
    [self.dataController fetchRecommendDataWithCompletion:^(NSArray *result, NSString *keyword, BOOL hasMore) {
        @strongify(self)
        if (ACC_isEmptyString(self.currentKeyword) && ACC_isEmptyArray(self.recommendCommodities)) {
            self.recommendCommodities = [result copy];
        }
        if ([keyword isEqualToString:self.currentKeyword]) {
            self.commodities = [result mutableCopy];
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
            self.commodities = [result mutableCopy];
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
            [self.commodities addObjectsFromArray:result];
            ACCBLOCK_INVOKE(completion, [self.commodities copy], nil, hasMore);
        }
    }];
}

- (void)restoreRecommendData
{
    if (ACC_isEmptyArray(self.recommendCommodities)) {
        [self fetchRecommendData];
    } else {
        self.commodities = [self.recommendCommodities mutableCopy];
        [self handleData:self.commodities error:nil hasMore:NO];
    }
}

#pragma mark - Override

- (NSString *)searchBarPlaceHolder
{
    return @"搜索商品";
}

- (ACCEditTagType)type
{
    return ACCEditTagTypeCommodity;
}

- (Class)cellClass
{
    return [ACCEditTagsCommodityTableViewCell class];
}

- (NSString *)cellIdentifier
{
    return @"ACCEditTagsCommodityTableViewCell";
}

- (CGFloat)cellHeight
{
    return 73.f;
}

- (NSArray *)dataSource
{
    return [self.commodities copy];
}

- (NSString *)emptyResultText
{
    return [NSString stringWithFormat:@"未搜索出相关商品，你可创建此自定义标记"];
}

- (CGFloat)headerHeight
{
    return 22.f;
}

- (NSString *)headerText
{
    return @"热门";
}

- (NSString *)tagTypeString
{
    return @"goods";
}

- (NSDictionary *)itemTrackerParamsForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *dataSource = [self dataSource];
    if (indexPath.row < [dataSource count]) {
        ACCEditCommerceTagsModel *goods = dataSource[indexPath.row];
        return @{
            @"goods_id" : goods.itemID ? : @"",
        };
    }
    return @{};
}

- (AWEInteractionEditTagStickerModel *)tagModelForIndexPath:(NSIndexPath *)indexPath
{
    NSArray *dataSource = [self dataSource];
    if (indexPath.row >= [dataSource count]) {
        return nil;
    }
    ACCEditCommerceTagsModel *commodity = dataSource[indexPath.row];
    AWEInteractionEditTagStickerModel *tagModel = [[AWEInteractionEditTagStickerModel alloc] init];
    AWEInteractionEditTagStickerInfoModel *tagInfo = [[AWEInteractionEditTagStickerInfoModel alloc] init];
    tagInfo.type = [self type];
    tagModel.editTagInfo = tagInfo;
    tagInfo.text = commodity.title;
    AWEInteractionEditTagGoodsTagModel *commodityTagInfo = [[AWEInteractionEditTagGoodsTagModel alloc] init];
    commodityTagInfo.productID = commodity.itemID;
    tagInfo.goodsTag = commodityTagInfo;
    return tagModel;
}

- (NSInteger)indexOfItem:(NSString *)item
{
    NSArray *dataSource = [self dataSource];
    for (NSInteger index = 0; index < [dataSource count]; index++) {
        NSObject *obj = dataSource[index];
        if ([obj isKindOfClass:[ACCEditCommerceTagsModel class]]) {
            ACCEditCommerceTagsModel *commodity = (ACCEditCommerceTagsModel *)obj;
            if ([commodity.itemID isEqualToString:item]) {
                return index;
            }
        }
    }
    return -1;
}

- (BOOL)needFooter
{
    return YES;
}

- (NSString *)itemTitle
{
    return @"商品";
}

#pragma mark - Getter

- (ACCTagsListDataController *)dataController
{
    if (!_dataController) {
        _dataController = [[ACCTagsListDataController alloc] init];
        _dataController.type = ACCTagsCommerceSearchTypeCommodity;
    }
    return _dataController;
}
@end
