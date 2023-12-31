//
//  ACCTagsCustomizeViewController.m
//  CameraClient-Pods-AwemeCore
//
//  Created by HuangHongsen on 2021/9/30.
//

#import "ACCTagsCustomizeViewController.h"
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIButton+ACCAdditions.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreationKitInfra/ACCResponder.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CameraClient/ACCTextInputAlertProcotol.h>

#import "ACCEditCustomizeTagsEmptyView.h"
#import "ACCConfigKeyDefines.h"

static NSString *const kACCCustomTagsHistoryKey = @"tool.edit.kACCCustomTagsHistoryKey";

@class ACCTagsCustomizeTableViewCell;
@protocol ACCTagsCustomizeTableViewCellDelegate<NSObject>
- (void)didDeleteCell:(ACCTagsCustomizeTableViewCell *)cell;
@end

@interface ACCTagsCustomizeTableViewCell : UITableViewCell<ACCTagsItemPickerTableViewCellProtocol>
@property (nonatomic, strong) UILabel *tagNameLabel;
@property (nonatomic, strong) UIButton *removeButton;
@property (nonatomic, weak) id<ACCTagsCustomizeTableViewCellDelegate> delegate;
@end

@implementation ACCTagsCustomizeTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        _removeButton = [[UIButton alloc] init];
        _removeButton.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-16.f, -16.f, -16.f, -16.f);
        [_removeButton addTarget:self action:@selector(handleRemoveCell) forControlEvents:UIControlEventTouchUpInside];
        [_removeButton setImage:ACCResourceImage(@"ic_toast_close") forState:UIControlStateNormal];
        [self.contentView addSubview:_removeButton];
        ACCMasMaker(_removeButton, {
            make.centerY.equalTo(self.contentView);
            make.right.equalTo(self.contentView).offset(-21);
            make.width.height.equalTo(@8.f);
        });
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        _tagNameLabel = [[UILabel alloc] init];
        _tagNameLabel.font = [ACCFont() systemFontOfSize:15.f weight:ACCFontWeightMedium];
        _tagNameLabel.textColor = ACCResourceColor(ACCColorConstTextInverse);
        [self.contentView addSubview:_tagNameLabel];
        ACCMasMaker(_tagNameLabel, {
            make.left.equalTo(self.contentView).offset(16.f);
            make.centerY.equalTo(self.contentView);
            make.right.lessThanOrEqualTo(_removeButton.mas_left).offset(-8.f);
        });
    }
    return self;
}

- (void)updateWithData:(NSObject *)data
{
    if ([data isKindOfClass:[NSString class]]) {
        NSString *text = (NSString *)data;
        self.tagNameLabel.text = text;
    }
}

- (void)handleRemoveCell
{
    [self.delegate didDeleteCell:self];
}

@end

@interface ACCTagsCustomizeViewController ()<ACCTagsCustomizeTableViewCellDelegate, ACCEditCustomizeTagsEmptyViewDelegate>

@property (nonatomic, strong) NSMutableArray *customTags;
@property (nonatomic, strong) ACCEditCustomizeTagsEmptyView *emptyView;
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, assign) BOOL isFromEdit;
@end

@implementation ACCTagsCustomizeViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.showCreateCustomAlertOnAppear) {
        self.showCreateCustomAlertOnAppear = NO;
        [self showCreateCustomAlert];
    }
}

- (void)scrollToItem:(NSString *)itemID
{
    [super scrollToItem:itemID];
    self.isFromEdit = YES;
    // show reEdit view on next appear
    if (self.view.window == nil) {
        self.showCreateCustomAlertOnAppear = YES;
        self.defaultCustomTag = itemID;
    } else {
        self.defaultCustomTag = itemID;
        [self showCreateCustomAlert];
    }
}
    
#pragma mark - Data Management

- (void)fetchRecommendData
{
    self.customTags = [[ACCCache() arrayForKey:kACCCustomTagsHistoryKey] mutableCopy] ? : [NSMutableArray array];
    [self handleData:self.customTags error:nil hasMore:NO];
}

#pragma mark - ACCEditTagsSelfDefineTableViewCellDelegate

- (void)didDeleteCell:(ACCTagsCustomizeTableViewCell *)cell
{
    self.tableView.userInteractionEnabled = NO;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];

    if (indexPath && indexPath.row < [self.customTags count] && indexPath.row >= 0) {
        [self removeCustomTag:self.customTags[indexPath.row]];
    }
    self.tableView.userInteractionEnabled = YES;
}

#pragma mark - ACCEditCustomizeTagsEmptyViewDelegate

- (void)didTapOnActionButtonInEmptyView:(ACCEditCustomizeTagsEmptyView *)emptyView
{
    [self showCreateCustomAlert];
}

#pragma mark - Getters

- (ACCEditCustomizeTagsEmptyView *)emptyView
{
    if (!_emptyView) {
        _emptyView = [[ACCEditCustomizeTagsEmptyView alloc] init];
        _emptyView.delegate = self;
    }
    return _emptyView;
}

#pragma mark - Private Helper

- (id<ACCTextInputAlertViewProtocol>)showCreateCustomAlert
{
    NSString *fromTagTypeString = self.fromTagTypeString ? : @"custom";
    if (self.isFromEdit) {
        self.isFromEdit = NO;
    } else {
        NSMutableDictionary *params = [self.trackerParams mutableCopy];
        [params setValue:fromTagTypeString forKey:@"tag_type"];
        [ACCTracker() trackEvent:@"click_create_new_tag" params:params];
    }
    
    id<ACCTextInputAlertViewProtocol> alert = [ACCTextInputAlert() inputTextAlertView];
    alert.titleLabel.text = @"输入标记名称";
    NSInteger maxLength = ACCConfigInt(kConfigInt_tag_custom_tag_length_limit);
    alert.textMaxLength = maxLength;
    [alert setConfirmButtonTitle:@"添加"];
    alert.cancelBlock = ^(NSString *content){
        NSMutableDictionary *params = [self.trackerParams mutableCopy];
        [params setValue:@"close" forKey:@"click_type"];
        [params setValue:fromTagTypeString forKey:@"tag_type"];
        [ACCTracker() trackEvent:@"add_tag_option"
                          params:params];
    };
    if (!ACC_isEmptyString(self.defaultCustomTag)) {
        NSString *defaultTag = self.defaultCustomTag;
        if ([defaultTag length] > maxLength) {
            defaultTag = [defaultTag substringToIndex:maxLength];
        }
        alert.defaultValue = defaultTag;
    }
    self.defaultCustomTag = @"";
    self.fromTagTypeString = nil;
    self.fromTagType = ACCEditTagTypeNone;
    @weakify(self)
    alert.confirmBlock = ^(NSString *content) {
        if (!ACC_isEmptyString(content)) {
            @strongify(self)
            [self addCustomTag:content];
            NSMutableDictionary *params = [self.trackerParams mutableCopy];
            [params setValue:@"add" forKey:@"click_type"];
            [params setValue:fromTagTypeString forKey:@"tag_type"];
            [ACCTracker() trackEvent:@"add_tag_option"
                              params:params];
            [self.delegate tagsItemPicker:self didSelectItem:[self tagModelForCustomTag:content] referExtra:@{@"custom_id" : content, @"tag_source": @"tag_custom"}];
        }
    };
    [alert showOnView:[ACCResponder topView]];
    return alert;
}

- (void)addCustomTag:(NSString *)tag
{
    if (tag) {
        [self.customTags addObject:tag];
        [ACCCache() setArray:self.customTags forKey:kACCCustomTagsHistoryKey];
        [self handleData:[self.customTags copy] error:nil hasMore:NO];
    }
}

- (void)removeCustomTag:(NSString *)tag
{
    if (tag) {
        [self.customTags removeObject:tag];
        [ACCCache() setArray:self.customTags forKey:kACCCustomTagsHistoryKey];
        [self handleData:[self.customTags copy] error:nil hasMore:NO];
    }
}

#pragma mark - Override

- (ACCEditTagType)type
{
    return ACCEditTagTypeSelfDefine;
}

- (Class)cellClass
{
    return [ACCTagsCustomizeTableViewCell class];
}

- (NSString *)cellIdentifier
{
    return @"ACCTagsCustomizeTableViewCell";
}

- (CGFloat)cellHeight
{
    return 44.f;
}

- (NSString *)tagTypeString
{
    return @"custom";
}

- (BOOL)needSearchBar
{
    return NO;
}

- (NSDictionary *)itemTrackerParamsForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *dataSource = [self dataSource];
    if (indexPath.row < [dataSource count]) {
        NSString *tag = dataSource[indexPath.row];
        return @{
            @"custom_id" : tag ? : @"",
        };
    }
    return @{};
}

- (NSArray *)dataSource
{
    return [self.customTags copy];
}

- (void)configCell:(UITableViewCell *)cell
{
    if ([cell isKindOfClass:[ACCTagsCustomizeTableViewCell class]]) {
        ACCTagsCustomizeTableViewCell *customCell = (ACCTagsCustomizeTableViewCell *)cell;
        customCell.delegate = self;
    }
}

- (UIView *)emptyStateView
{
    return self.emptyView;
}

- (BOOL)needFooter
{
    return NO;
}

- (CGFloat)headerHeight
{
    return 22.f;
}

- (NSString *)headerText
{
    return @"添加过的";
}

- (CGFloat)bottomViewHeight
{
    return ACC_IPHONE_X_BOTTOM_OFFSET + 40 + 44 + 20;
}

- (UIView *)bottomView
{
    if (!_bottomView) {
        _bottomView = [[UIView alloc] init];
        UIButton *actionButton = [ACCEditCustomizeTagsEmptyView generateNewTagActionButtonWithHeight:44.f];
        [actionButton addTarget:self action:@selector(showCreateCustomAlert) forControlEvents:UIControlEventTouchUpInside];
        [_bottomView addSubview:actionButton];
        ACCMasMaker(actionButton, {
            make.center.equalTo(_bottomView);
            make.width.equalTo(@187.f);
            make.height.equalTo(@44.f);
        });
    }
    return _bottomView;
}

- (AWEInteractionEditTagStickerModel *)tagModelForIndexPath:(NSIndexPath *)indexPath
{
    NSArray *dataSource = [self dataSource];
    if (indexPath.row >= [dataSource count]) {
        return nil;
    }
    NSString *tag = dataSource[indexPath.row];
    return [self tagModelForCustomTag:tag];
}

- (AWEInteractionEditTagStickerModel *)tagModelForCustomTag:(NSString *)content
{
    AWEInteractionEditTagStickerModel *tagModel = [[AWEInteractionEditTagStickerModel alloc] init];
    AWEInteractionEditTagStickerInfoModel *tagInfo = [[AWEInteractionEditTagStickerInfoModel alloc] init];
    tagInfo.type = [self type];
    tagModel.editTagInfo = tagInfo;
    tagInfo.text = content;
    AWEInteractionEditTagCustomTagModel *customTagInfo = [[AWEInteractionEditTagCustomTagModel alloc] init];
    customTagInfo.name = content;
    tagInfo.customTag = customTagInfo;
    return tagModel;
}

- (NSString *)itemTitle
{
    return @"自定义";
}

- (NSString *)tagSource
{
    return @"tag_history";
}

- (void)trackCellDisplayAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *dataSource = [[self dataSource] copy];
    if (indexPath.row <= [dataSource count]) {
        NSMutableDictionary *params = [[self itemTrackerParamsForItemAtIndexPath:indexPath] mutableCopy];
        [params addEntriesFromDictionary:[self trackerParams]];
        [params setValue:[self tagTypeString] forKey:@"tag_type"];
        [ACCTracker() trackEvent:@"history_tag_show" params:params];
    }
}

- (BOOL)needNoMoreFooterText
{
    return NO;
}

- (BOOL)needNetworkRequest
{
    return NO;
}

- (BOOL)needToTrackClickEvent
{
    return NO;
}

@end
