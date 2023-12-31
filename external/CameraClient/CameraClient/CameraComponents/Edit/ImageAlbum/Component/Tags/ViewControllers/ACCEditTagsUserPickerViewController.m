//
//  ACCEditTagsUserPickerViewController.m
//  CameraClient-Pods-AwemeCore
//
//  Created by HuangHongsen on 2021/9/29.
//

#import "ACCEditTagsUserPickerViewController.h"
#import <CreationKitArch/ACCTextInputServiceProtocol.h>
#import <CreativeKit/ACCServiceLocator.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import "ACCUserModelProtocolD.h"

@interface ACCEditTagsUserTableViewCell : UITableViewCell<ACCTagsItemPickerTableViewCellProtocol>
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *userNameLabel;
@property (nonatomic, strong) UILabel *verificationDescriptionLabel;
@property (nonatomic, strong) UIImageView *verificationIcon;
@property (nonatomic, strong) UIImage *placeHolderImage;
@end

@implementation ACCEditTagsUserTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        CGFloat iconImageWidth = 48.f;
        
        self.avatarImageView = [[UIImageView alloc] init];
        self.avatarImageView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.06];
        self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.avatarImageView.layer.cornerRadius = 24.f;
        self.avatarImageView.layer.masksToBounds = YES;
        self.avatarImageView.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.08].CGColor;
        self.avatarImageView.layer.borderWidth = 0.5;
        [self.contentView addSubview:self.avatarImageView];
        ACCMasMaker(self.avatarImageView, {
            make.left.equalTo(self.contentView).offset(16.f);
            make.width.height.equalTo(@(iconImageWidth));
            make.centerY.equalTo(self.contentView);
        });
        
        self.userNameLabel = [[UILabel alloc] init];
        self.userNameLabel.textColor = ACCResourceColor(ACCColorConstTextInverse);
        self.userNameLabel.font = [ACCFont() systemFontOfSize:15.f weight:ACCFontWeightMedium];
        [self.contentView addSubview:self.userNameLabel];
        ACCMasMaker(self.userNameLabel, {
            make.top.equalTo(self.avatarImageView).offset(4);
            make.left.equalTo(self.avatarImageView.mas_right).offset(12);
            make.right.lessThanOrEqualTo(self.contentView).offset(-16.f);
            make.height.equalTo(@21.f);
        });
        
        self.verificationIcon = [[UIImageView alloc] init];
        self.verificationIcon.image = ACCResourceImage(@"icon_edit_tags_bluev");
        [self.contentView addSubview:self.verificationIcon];
        ACCMasMaker(self.verificationIcon, {
            make.left.equalTo(self.userNameLabel);
            make.bottom.equalTo(self.avatarImageView.mas_bottom).offset(-6);
            make.width.height.equalTo(@12);
        });
        
        self.verificationDescriptionLabel = [[UILabel alloc] init];
        self.verificationDescriptionLabel.textColor = ACCResourceColor(ACCColorConstTextInverse4);
        self.verificationDescriptionLabel.font = [ACCFont() systemFontOfSize:13.f];
        [self.contentView addSubview:self.verificationDescriptionLabel];
        ACCMasMaker(self.verificationDescriptionLabel, {
            make.left.equalTo(self.verificationIcon.mas_right).offset(4);
            make.centerY.equalTo(self.verificationIcon);
            make.right.lessThanOrEqualTo(self.contentView).offset(-16.f);
        });
    }
    return self;
}

- (void)updateWithData:(NSObject *)data
{
    if (![data conformsToProtocol:@protocol(ACCUserModelProtocolD)]) {
        return ;
    }
    id<ACCUserModelProtocolD> user = (id<ACCUserModelProtocolD>)data;
    [ACCWebImage() imageView:self.avatarImageView setImageWithURLArray:user.avatarThumb.URLList];
    self.userNameLabel.text = user.socialName;
    if (ACC_isEmptyString(user.enterpriseVerifyInfo)) {
        ACCMasReMaker(self.userNameLabel, {
            make.centerY.equalTo(self.avatarImageView);
            make.left.equalTo(self.avatarImageView.mas_right).offset(12);
        });
        self.verificationDescriptionLabel.hidden = YES;
        self.verificationIcon.hidden = YES;
    } else {
        self.verificationDescriptionLabel.text = user.enterpriseVerifyInfo;
        self.verificationDescriptionLabel.hidden = NO;
        self.verificationIcon.hidden = NO;
        ACCMasReMaker(self.userNameLabel, {
            make.top.equalTo(self.avatarImageView).offset(3);
            make.left.equalTo(self.avatarImageView.mas_right).offset(12);
        });
    }
}

- (UIImage *)placeHolderImage
{
    if (!_placeHolderImage) {
        CGSize size = CGSizeMake(48, 48);
        CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
        UIGraphicsBeginImageContextWithOptions(size, NO, 0.f);               // Create picture
        CGContextRef context = UIGraphicsGetCurrentContext();     // Create picture context
        CGContextSetFillColorWithColor(context, [ACCResourceColor(ACCColorConstBGContainer2) CGColor]); // Sets the graphics context for the current fill color
        CGContextFillRect(context, rect);                         // Fill color
        
        UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        _placeHolderImage = theImage;
    }
    return _placeHolderImage;
}

@end

@interface ACCEditTagsUserPickerViewController ()

@property (nonatomic, strong) id<ACCTextInputUserServiceProtocol> userService;
@property (nonatomic, strong) NSMutableArray *users;
@property (nonatomic, copy) ACCTagSearchCompletion searchCompletion;
@property (nonatomic, copy) ACCTagSearchCompletion loadMoreCompletion;
@property (nonatomic, assign) BOOL isFromLoadMore;
@property (nonatomic, assign) BOOL didFetchRecommendUserSucceedOnceFlag;

@property (nonatomic, copy) NSArray *recommendedUsers;
@property (nonatomic, copy) NSString *currentResultKeyword;

@end

@implementation ACCEditTagsUserPickerViewController


- (void)fetchRecommendData
{
    self.userService = [IESAutoInline(ACCBaseServiceProvider(), ACCTextInputServiceProtocol) creatUserServiceInstance];
    @weakify(self)
    self.userService.searchUserCompletion = ^(NSArray<id<ACCUserModelProtocol>> *users, NSString *keyword) {
        @strongify(self);
        if (!self.didFetchRecommendUserSucceedOnceFlag && ACC_isEmptyString(keyword)) {
            self.didFetchRecommendUserSucceedOnceFlag = YES;
            self.users = [users mutableCopy];
            self.recommendedUsers = [users copy];
            [self handleData:users error:nil hasMore:[self.userService hasMoreUsers]];
        } else if ([keyword isEqualToString:self.currentKeyword]) {
            if ([self.currentResultKeyword isEqualToString:keyword] && !ACC_isEmptyArray(self.users)) {
                return ;
            }
            self.currentResultKeyword = keyword;
            [self handleUserDataFetchSucceed:users keyword:keyword fromLoadMore:self.isFromLoadMore];
        }
    };
    [self.userService fetchUsersWithCompletion:^(NSError *error) {
        @strongify(self)
        [self.userService searchUsersWithKeyword:@""];
    }];
}

- (void)handleUserDataFetchSucceed:(NSArray <id<ACCUserModelProtocol>> *)users keyword:(NSString *)keyword fromLoadMore:(BOOL)isFromLoadMore
{
    self.users = [users mutableCopy];
    if (isFromLoadMore) {
        ACCBLOCK_INVOKE(self.loadMoreCompletion, users, nil, [self.userService hasMoreUsers]);
    } else {
        ACCBLOCK_INVOKE(self.searchCompletion, users, nil, [self.userService hasMoreUsers]);
    }
}

- (void)restoreRecommendData
{
    self.users = [self.recommendedUsers mutableCopy];
    [self handleData:self.recommendedUsers error:nil hasMore:NO];
}

#pragma mark - Override

- (void)searchWithKeyword:(NSString *)searchWithKeyword completion:(ACCTagSearchCompletion)completion
{
    self.currentKeyword = searchWithKeyword;
    self.searchCompletion = completion;
    self.isFromLoadMore = NO;
    [self.userService searchUsersWithKeyword:searchWithKeyword];
}

- (void)loadMoreWithKeyword:(NSString *)searchWithKeyword completion:(ACCTagSearchCompletion)completion
{
    self.isFromLoadMore = YES;
    self.loadMoreCompletion = completion;
    [self.userService loadMoreUser];
}

- (NSString *)searchBarPlaceHolder
{
    return @"搜索用户";
}

- (ACCEditTagType)type
{
    return ACCEditTagTypeUser;
}


- (NSString *)cellIdentifier
{
    return @"ACCEditTagsUserTableViewCell";
}

- (CGFloat)cellHeight
{
    return 72.f;
}

- (Class)cellClass
{
    return [ACCEditTagsUserTableViewCell class];
}

- (NSArray *)dataSource
{
    return [self.users copy];
}

- (NSString *)emptyResultText
{
    return @"未搜索出相关用户，你可创建此自定义标记";
}

- (BOOL)needCreateCustomTagFooter
{
    return NO;
}

- (NSString *)tagTypeString
{
    return @"user";
}

- (NSDictionary *)itemTrackerParamsForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *dataSource = [self dataSource];
    if (indexPath.row < [dataSource count]) {
        id<ACCUserModelProtocol> user = dataSource[indexPath.row];
        return @{
            @"author_id" : user.userID ? : @"",
            @"relation_tag" : @(user.followStatus),
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
    id<ACCUserModelProtocol> user = dataSource[indexPath.row];
    AWEInteractionEditTagStickerModel *tagModel = [[AWEInteractionEditTagStickerModel alloc] init];
    AWEInteractionEditTagStickerInfoModel *tagInfo = [[AWEInteractionEditTagStickerInfoModel alloc] init];
    tagInfo.type = [self type];
    tagInfo.text = user.nickname;
    AWEInteractionEditTagUserTagModel *userTagModel = [[AWEInteractionEditTagUserTagModel alloc] init];
    userTagModel.userID = user.userID;
    userTagModel.secUID = user.secUserID;
    tagInfo.userTag = userTagModel;
    tagModel.editTagInfo = tagInfo;
    return tagModel;
}

- (NSInteger)indexOfItem:(NSString *)item
{
    NSArray *dataSource = [self dataSource];
    for (NSInteger index = 0; index < [dataSource count]; index++) {
        NSObject *obj = dataSource[index];
        if ([obj conformsToProtocol:@protocol(ACCUserModelProtocol)]) {
            id<ACCUserModelProtocol> user = (id<ACCUserModelProtocol>)obj;
            if ([user.userID isEqualToString:item]) {
                return index;
            }
        }
    }
    return -1;
}

- (NSString *)itemTitle
{
    return @"用户";
}

- (BOOL)needNoMoreFooterText
{
    return YES;
}

@end
