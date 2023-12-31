//
//  ACCSocialStickerEditToolbar.m
//  CameraClient-Pods-Aweme
//
//  Created by qiuhang on 2020/8/6.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import "ACCSocialStickerEditToolbar.h"
#import <CreativeKit/ACCMacros.h>
#import <Masonry/Masonry.h>
#import "ACCSocialStickerEditToolbarItemView.h"
#import <CreationKitArch/ACCChallengeModelProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitInfra/ACCConfigManager.h>
#import "ACCConfigKeyDefines.h"
#import "ACCPersonalRecommendWords.h"

typedef NS_ENUM(NSUInteger, ACCSocialStickerToobarLoadStatus) {
    
    ACCSocialStickerToobarLoadStatusNone,         // idle: init or canceled
    ACCSocialStickerToobarLoadStatusOnLoading,    // loading data
    ACCSocialStickerToobarLoadStatusOnData,       // load succeed
    ACCSocialStickerToobarLoadStatusOnError,      // error or empty
};

@interface ACCSocialStickerEditToolbar ()
<
UICollectionViewDelegate,
UICollectionViewDataSource,
UICollectionViewDelegateFlowLayout
>

/// public setter
@property (nonatomic,   copy) NSString *searchKeyWord;
@property (nonatomic, strong) ACCSocialStickeMentionBindingModel *selectMentionBindingModel;
@property (nonatomic, weak) AWEVideoPublishViewModel *publishModel;

/// data
@property (nonatomic, strong) id<ACCTextInputUserServiceProtocol> userService;
@property (nonatomic, assign) ACCSocialStickerToobarLoadStatus loadStatus;
@property (nonatomic, assign) BOOL isLoadingMore;
@property (nonatomic, assign) BOOL isFetchingRecommendUser;
@property (nonatomic, assign) BOOL didFetchRecommendUserSucceedOnceFlag;
@property (nonatomic,   copy) void (^lastWaitFetchRecommendUserResultHandler)(BOOL succeed);
@property (nonatomic, copy) NSDictionary *logPassback;
/// model
@property (nonatomic,   copy) NSArray<id<ACCUserModelProtocol>> *users;
@property (nonatomic,   copy) NSArray<id<ACCChallengeModelProtocol>> *challenges;

/// view
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UILabel *titleLabel;

///track
@property (nonatomic, strong) NSMutableSet *videoAtListShowTrackedUser;

@end

@implementation ACCSocialStickerEditToolbar

#pragma mark - life cycle
- (instancetype)initWithFrame:(CGRect)frame
                 publishModel:(nonnull AWEVideoPublishViewModel *)publishModel{
    
    if (self = [super initWithFrame:frame]) {
        _publishModel = publishModel;
        [self setupData];
        [self setupUI];
    }
    return self;
}

#pragma mark - public
- (void)setStickerType:(ACCSocialStickerType)stickerType {
    
    if (_stickerType != stickerType) {
        _stickerType = stickerType;
        [self cancelSearch];
        [self remakeLayout];
    }
}

- (void)searchWithKeyword:(NSString *)keyword {
    
    // user fetch datasource will crash if keyword is nil
    keyword = keyword ? : @"";
    
    // ignore case : equal string
    BOOL needReloadSameKey = (self.loadStatus == ACCSocialStickerToobarLoadStatusNone ||
                              self.loadStatus == ACCSocialStickerToobarLoadStatusOnError);
    
    if ([self.searchKeyWord isEqualToString:keyword] && !needReloadSameKey) {
        return;
    }

    self.searchKeyWord = [keyword copy];
    self.isLoadingMore = NO;
    
    [self cleanFetchedData];
    [self updateLoadStatus:ACCSocialStickerToobarLoadStatusOnLoading];
    
    @weakify(self);
    if (self.stickerType == ACCSocialStickerTypeMention) {
        [self fetchRecommendUsersThen:^(BOOL succeed) {
            @strongify(self);
            [self.userService searchUsersWithKeyword:keyword];
        }];
    } else if (self.stickerType == ACCSocialStickerTypeHashTag) {
        [IESAutoInline(ACCBaseServiceProvider(), ACCTextInputServiceProtocol) fetchHashtagsWithKeyword:keyword
                                         completion:^(NSArray<id<ACCChallengeModelProtocol>> *challenges, NSError *error) {
             @strongify(self);
            [self handleHashTagFetchSucceed:challenges keyword:keyword];
        }];
    }
}

- (void)cancelSearch {

    self.isLoadingMore = NO;
    self.searchKeyWord = nil;
    [self cleanFetchedData];
    [self updateLoadStatus:ACCSocialStickerToobarLoadStatusNone];
    [self reloadView];
}

- (void)updateSelectedMention:(ACCSocialStickeMentionBindingModel *)selectMentionBindingModel {
    _selectMentionBindingModel = selectMentionBindingModel;
    [self reloadView];
}

+ (CGFloat)defaulBarHeight {
    return 77.f;
}

#pragma mark - data
- (void)fetchMoreUser {
    self.isLoadingMore = YES;
    [self.userService loadMoreUser];
}

- (void)fetchRecommendUsersThen:(void (^)(BOOL succeed))then {
    
    self.lastWaitFetchRecommendUserResultHandler = then;
    
    if (self.didFetchRecommendUserSucceedOnceFlag) {
        ACCBLOCK_INVOKE(self.lastWaitFetchRecommendUserResultHandler, YES);
        return;
    }
    
    if (self.isFetchingRecommendUser) {
        return;
    }
    
    self.isFetchingRecommendUser = YES;
    
    @weakify(self);
    [self.userService fetchUsersWithCompletion:^(NSError *error) {
        @strongify(self);
        self.isFetchingRecommendUser = NO;
        if (!error) {
            self.didFetchRecommendUserSucceedOnceFlag = YES;
        }
        ACCBLOCK_INVOKE(self.lastWaitFetchRecommendUserResultHandler, !error);
    }];
}

- (void)handleUserDataFetchSucceed:(NSArray<id<ACCUserModelProtocol>> *)users keyword:(NSString *)keyword {

    if (self.stickerType != ACCSocialStickerTypeMention ||
        ![self needHandleDataCallbackWithKeyword:keyword]) {
        return;
    }
    
    self.isLoadingMore = NO;
    self.users = users;
    [self updateLoadStatus:ACC_isEmptyArray(users) ? ACCSocialStickerToobarLoadStatusOnError : ACCSocialStickerToobarLoadStatusOnData];
}

- (void)handleHashTagFetchSucceed:(NSArray<id<ACCChallengeModelProtocol>> *)challenges keyword:(NSString *)keyword {
    
    if (self.stickerType != ACCSocialStickerTypeHashTag||
        ![self needHandleDataCallbackWithKeyword:keyword]) {
        return;
    }
    
    self.challenges = challenges;
    [self updateLoadStatus:ACC_isEmptyArray(challenges) ? ACCSocialStickerToobarLoadStatusOnError : ACCSocialStickerToobarLoadStatusOnData];
}

- (BOOL)needHandleDataCallbackWithKeyword:(NSString *)keywork {
    return [self.searchKeyWord isEqualToString:keywork];
}

#pragma mark - update
- (void)updateLoadStatus:(ACCSocialStickerToobarLoadStatus)loadStatus {
    self.loadStatus = loadStatus;
    [self reloadView];
    [self updateTitleShowStatus];
}

- (void)cleanFetchedData {
    self.users = nil;
    self.challenges = nil;
}

- (void)reloadView {
    [self.collectionView reloadData];
    // FIX : AME-87366  reset collectionView's offset to init status when loading
    [self.collectionView layoutIfNeeded];
    if (self.loadStatus == ACCSocialStickerToobarLoadStatusOnLoading) {
        [self.collectionView setContentOffset:CGPointZero animated:NO];
    }
}

- (void)remakeLayout {
    
    CGFloat height = (self.isMentionSticker ?
                      [ACCSocialStickerEditToobarMentionItemCell maxContentDisplaySize].height :
                      [ACCSocialStickerEditToolbarHashTagItemCell maxContentDisplaySize].height);
    
    ACCMasUpdate(self.collectionView, {
        make.height.mas_equalTo(height);
    });
}

- (void)updateTitleShowStatus
{
    BOOL shouldShowTitle = NO;
    if (self.stickerType == ACCSocialStickerTypeHashTag &&
        self.loadStatus==ACCSocialStickerToobarLoadStatusOnData &&
        !ACC_isEmptyArray(self.challenges)) {
        
        shouldShowTitle = YES;
    }
    self.titleLabel.hidden = !shouldShowTitle;
}

#pragma mark - configs
- (BOOL)isMentionSticker {
    return (self.stickerType == ACCSocialStickerTypeMention);
}

- (BOOL)isSelectedUserWithTargetUserModel:(id<ACCUserModelProtocol>)userModel {
    return (userModel &&
            self.selectMentionBindingModel &&
            [self.selectMentionBindingModel.userId isEqualToString:userModel.userID]);
}

#pragma mark collection view delegate
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    
    if (self.loadStatus == ACCSocialStickerToobarLoadStatusOnLoading) {
        return 10; // placeholders
    }
    
    if (self.loadStatus == ACCSocialStickerToobarLoadStatusOnData) {
         return self.isMentionSticker ? self.users.count : self.challenges.count;
    }
    
    // PM: show nothing if status is None or OnError
    return 0;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isMentionSticker) {
        id<ACCUserModelProtocol> user = [self.users acc_objectAtIndex:indexPath.row];
        if (!ACC_isEmptyString(user.userID) && ![self.videoAtListShowTrackedUser containsObject:user.userID]) {
            [self.videoAtListShowTrackedUser addObject:user.userID];
            NSString *imprId = @"";
            if (!ACC_isEmptyDictionary(user.logPassback))
            {
                imprId = [user.logPassback acc_objectForKey:@"impr_id"];
            }
            [ACCTracker() trackEvent:@"video_at_show"
                          params:@{
                                      @"search_keyword" : self.searchKeyWord ?: @"",
                                      @"to_user_id"     : user.userID,
                                      @"impr_id"        : imprId ?: @"",
                                      @"impr_position"  : @(indexPath.row + 1),
                                      @"relation_tag"   : @(user.followStatus),
                                  }
                                   ];
        }
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.isMentionSticker) {
        return [ACCSocialStickerEditToobarMentionItemCell sizeWithUser:[self.users acc_objectAtIndex:indexPath.item]];
    }else {
        return [ACCSocialStickerEditToolbarHashTagItemCell sizeWithHashTag:[self.challenges acc_objectAtIndex:indexPath.item]];
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.isMentionSticker) {
        
        ACCSocialStickerEditToobarMentionItemCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(ACCSocialStickerEditToobarMentionItemCell.class) forIndexPath:indexPath];
        id<ACCUserModelProtocol> userModel = [self.users acc_objectAtIndex:indexPath.row];
        [cell configWithUser:userModel isSelected:[self isSelectedUserWithTargetUserModel:userModel]];
        return cell;
        
    } else {
        
        ACCSocialStickerEditToolbarHashTagItemCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(ACCSocialStickerEditToolbarHashTagItemCell.class) forIndexPath:indexPath];
        [cell configWithHashTag:[self.challenges acc_objectAtIndex:indexPath.item]];
        return cell;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.loadStatus == ACCSocialStickerToobarLoadStatusOnLoading) {
        return;
    }
    
    if (self.isMentionSticker) {
        
        id<ACCUserModelProtocol> userModel = [self.users acc_objectAtIndex:indexPath.row];
        if (!userModel) {
            return;
        }
        
        // 视频发布页
        NSString *imprId = @"";
        if (!ACC_isEmptyDictionary(userModel.logPassback)) {
            imprId = [userModel.logPassback acc_stringValueForKey:@"impr_id"];
        }
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
            @"search_keyword" : self.searchKeyWord ? : @"",
            @"enter_from"     : @"video_edit_page",
            @"to_user_id"     : userModel.userID ? : @"",
            @"enter_method"   : @"click_button",
            @"relation_tag"   : @(userModel.followStatus),
            @"creation_id"    : self.publishModel.repoContext.createId?:@"",
            @"impr_id"         : imprId ? : @"",
            @"impr_position" : @(indexPath.row + 1),
        }];
        [params addEntriesFromDictionary:self.trackInfo ?: @{}];
        [ACCTracker() trackEvent:@"add_video_at"
                          params:[params copy]];
        
        // PM : show nickname for list, use username for sticker
        ACCSocialStickeMentionBindingModel *mentionModel =  [ACCSocialStickeMentionBindingModel modelWithSecUserId:userModel.secUserID userId:userModel.userID userName:userModel.nickname followStatus:userModel.followStatus];
        ACCBLOCK_INVOKE(self.onSelectMention, mentionModel);
        
    } else {

        id<ACCChallengeModelProtocol> chanllengeModel = [self.challenges acc_objectAtIndex:indexPath.item];
        if (!chanllengeModel) {
            return;
        }
        
        ACCSocialStickeHashTagBindingModel *hashTagModel = [ACCSocialStickeHashTagBindingModel modelWithHashTagName:chanllengeModel.challengeName];
        ACCBLOCK_INVOKE(self.onSelectHashTag, hashTagModel);
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    
    CGFloat hInset = self.isMentionSticker ? 11.f : 12.f;
    return UIEdgeInsetsMake(0, hInset, 0, hInset);
}


- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return  self.isMentionSticker ? 14.f : 4.f;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // load more
    if ([self isMentionSticker] &&
        self.loadStatus == ACCSocialStickerToobarLoadStatusOnData &&
        !self.isLoadingMore) {
        
        if (scrollView.contentOffset.x + CGRectGetWidth(scrollView.frame) >= (scrollView.contentSize.width - 100.f)) {
            [self fetchMoreUser];
        }
    }
}

#pragma mark - setup
- (void)setupData {
    
    @weakify(self);
    [IESAutoInline(ACCBaseServiceProvider(), ACCTextInputServiceProtocol) configWithPublishViewModel:self.publishModel];
    
    self.userService = [IESAutoInline(ACCBaseServiceProvider(), ACCTextInputServiceProtocol) creatUserServiceInstance];
    self.userService.searchUserCompletion = ^(NSArray<id<ACCUserModelProtocol>> *users, NSString *keyword) {
        @strongify(self);
        // 命中缓存实验，统一由该回调处理，不用区分是默认列表还是搜索列表
        if (ACCConfigBool(kConfigBool_is_mention_cache_ailab_data)) {
            self.didFetchRecommendUserSucceedOnceFlag = YES;
            self.isFetchingRecommendUser = NO;
        }
        
        [self handleUserDataFetchSucceed:users keyword:keyword];
    };
    
    [self fetchRecommendUsersThen:nil];
}

- (void)setupUI {
    
    self.backgroundColor = [UIColor clearColor];
    
    self.titleLabel = ({
        
        UILabel *label = [[UILabel alloc] init];
        [self addSubview:label];
        ACCMasMaker(label, {
            make.top.equalTo(self);
            make.left.equalTo(self).inset(12.f);
        });
        label.font = [ACCFont() systemFontOfSize:12 weight:ACCFontWeightMedium];
        label.textColor = ACCResourceColor(ACCColorConstTextInverse2);
        label.text = ACCPersonalRecommendGetWords(@"social_sticker_hashtag_header");
        label.hidden = YES;
        label;
    });
    
    self.collectionView = ({
        
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:({
            UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
            flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
            flowLayout;
        })];
        collectionView.backgroundColor = [UIColor clearColor];
        [self addSubview:collectionView];
        ACCMasMaker(collectionView, {
            make.left.right.bottom.equalTo(self);
            make.height.mas_equalTo(0.f);
        });
        collectionView.showsHorizontalScrollIndicator = NO;
        collectionView.showsVerticalScrollIndicator   = NO;
        collectionView;
    });
    
    [self remakeLayout];
    [self registerCollectionView];
}

- (void)registerCollectionView {
    
    [self.collectionView registerClass:[ACCSocialStickerEditToolbarHashTagItemCell class] forCellWithReuseIdentifier:NSStringFromClass([ACCSocialStickerEditToolbarHashTagItemCell class])];
    
    [self.collectionView registerClass:[ACCSocialStickerEditToobarMentionItemCell class] forCellWithReuseIdentifier:NSStringFromClass([ACCSocialStickerEditToobarMentionItemCell class])];
     
    self.collectionView.delegate   = self;
    self.collectionView.dataSource = self;
}

#pragma mark - Getter

- (NSMutableSet *)videoAtListShowTrackedUser
{
    if (!_videoAtListShowTrackedUser) {
        _videoAtListShowTrackedUser = [[NSMutableSet alloc] init];
    }
    return  _videoAtListShowTrackedUser;
}

@end
