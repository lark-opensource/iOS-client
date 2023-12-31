//
//  ACCEditTRToolBarContainer.m
//  CameraClient
//
//  Created by wishes on 2020/6/2.
//

#import "ACCEditTRToolBarContainer.h"
#import "AWEEditRightTopVerticalActionContainerView.h"
#import "ACCVideoEditToolBarDefinition.h"
#import "ACCSmartMovieABConfig.h"
#import "ACCStudioGlobalConfig.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCServiceLocator.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CreationKitInfra/ACCConfigManager.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import "ACCFlowerRedPacketHelperProtocol.h"
#import <CreativeKit/NSArray+ACCAdditions.h>

@interface ACCEditTRToolBarContainer ()

@property (nonatomic, strong) AWEEditRightTopVerticalActionContainerView *barContentView;

@property (nonatomic, copy) EditToolBarMoreClickEvent moreClickEvent;
@property (nonatomic, assign) BOOL isFromIM;
@property (nonatomic, assign) BOOL isFromKaraoke;
@property (nonatomic, assign) BOOL isFromCommerce;
@property (nonatomic, assign) BOOL isFromWish;
@property (nonatomic, strong) NSDictionary<NSString *, NSValue *> *barItemMap;
@property (nonatomic, strong) NSSet<NSValue *> *ignoreUnfoldLimitSet;
@property (nonatomic, assign) NSInteger exihibitCount;

@end

@implementation ACCEditTRToolBarContainer

@synthesize contentView = _contentView;
@synthesize sortDataSource = _sortDataSource;
@synthesize maxHeightValue = _maxHeightValue;

- (instancetype)initWithContentView:(UIView *)contentView
                           isFromIM:(BOOL)isFromIM
                      isFromKaraoke:(BOOL)isFromKaraoke
                     isFromCommerce:(BOOL)isFromCommerce
                         isFromWish:(BOOL)isFromWish
{
    if (self = [super initWithContentView:contentView]) {
        self.location = ACCBarItemResourceLocationRight;
        _isFromIM = isFromIM;
        _isFromKaraoke = isFromKaraoke;
        _isFromCommerce = isFromCommerce;
        _isFromWish = isFromWish;
    }
    return self;
}


- (UIView *)barItemContentView {
    return self.barContentView;
}


- (void)containerViewDidLoad {
    [self setUpBarContentView];
}

- (void)resetUpBarContentView {
    [self.barContentView removeFromSuperview];
    self.barContentView = nil;
    [self setUpBarContentView];
}

- (void)resetFoldState {
    [self.barContentView tapToDismiss];
}

- (void)setUpBarContentView {

    NSInteger ignoreUnfoldLimitCount = [self p_getIgnoreUnfoldLimitCount:[self sortedBarItem]];

    const CGFloat kAWEEditAndPublishViewRightTopItemSpace = 12;
    
    NSArray<AWEEditAndPublishViewData *> *viewDataArray = [self adaptBarItemToViewData];
    AWEEditActionContainerViewLayout *layout = [AWEEditActionContainerViewLayout new];
    layout.itemSpacing = kAWEEditAndPublishViewRightTopItemSpace;
    layout.direction = AWEEditActionContainerViewLayoutDirectionVertical;
    layout.foldExihibitCount = self.exihibitCount;
    layout.itemSize = CGSizeMake(56, 50);
    self.barContentView = [[AWEEditRightTopVerticalActionContainerView alloc] initWithItemDatas:viewDataArray containerViewLayout:layout isFromIM:self.isFromIM ignoreUnfoldLimitCount:ignoreUnfoldLimitCount isFromCommerce:self.isFromCommerce];
    [self.contentView addSubview:self.barContentView];

    @weakify(self);
    self.barContentView.moreButtonClickedBlock = ^{
        @strongify(self);
        self.barContentView.folded = !self.barContentView.folded;
        ACCBLOCK_INVOKE(self.moreClickEvent,self.barContentView.folded);
    };
    [self.barContentView.itemViews enumerateObjectsUsingBlock:^(AWEEditActionItemView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.itemViewDidClicked = ^(AWEEditActionItemView * _Nonnull itemView) {
            @strongify(self);
            ACCBLOCK_INVOKE(self.clickCallback, itemView);
            ACCBLOCK_INVOKE(itemView.itemData.actionBlock, self.contentView, itemView);
        };
    }];
    
    CGSize size = self.barContentView.intrinsicContentSize;
    CGFloat topMargin = 22;
    if ([UIDevice acc_isIPhoneX]) {
        if (@available(iOS 11.0, *)) {
            topMargin = ACC_STATUS_BAR_NORMAL_HEIGHT + 2 + kYValueOfRecordAndEditPageUIAdjustment;
        }
    }
    
    self.barContentView.frame = CGRectMake(self.contentView.frame.size.width - size.width, topMargin, size.width, size.height);
    if ([self.barContentView respondsToSelector:@selector(setMaxHeightValue:)]) {
        [self.barContentView setMaxHeightValue:self.maxHeightValue];
    }
}

- (void)setMoreTouchUpEvent:(EditToolBarMoreClickEvent)event {
    self.moreClickEvent = event;
}

- (void)setMaxHeightValue:(NSNumber *)maxHeightValue
{
    _maxHeightValue = maxHeightValue;
    if ([self.barContentView respondsToSelector:@selector(setMaxHeightValue:)]) {
        [self.barContentView setMaxHeightValue:maxHeightValue];
    }
}

- (AWEEditActionItemView *)moreItemView
{
    return self.barContentView.moreItemView;
}

- (NSArray<AWEEditAndPublishViewData *>*)adaptBarItemToViewData {
    return [super adaptBarItemToViewData];
}

// 读取settings下发的白名单用于排序
- (NSArray<ACCBarItem *> *)sortedBarItem
{
    NSMutableArray<ACCBarItem *> *sortedBarItem = [[super sortedBarItem] mutableCopy];
    
    if (self.isFromWish) {
        NSArray<ACCBarItem *> *barItems = [sortedBarItem acc_filter:^BOOL(ACCBarItem * _Nonnull item) {
            return item.itemId == ACCEditToolBarNewYearModuleContext || item.itemId == ACCEditToolBarNewYearTextContext;
        }];
        if (barItems.count) {
            self.exihibitCount = 2;
            [self p_updateMaxUnfoldCount:2];
            return barItems;
        }
    }
    
    BOOL isLiteSupportEditWithPublish = [[ACCBaseServiceProvider() resolveObject:@protocol(ACCStudioGlobalConfig)] supportEditWithPublish];
    //不适合下发白名单的场景：极速版3变2 和 IM 聊天
    BOOL notSupportScene = isLiteSupportEditWithPublish || self.isFromIM || self.isFromCommerce;

    if (!notSupportScene && ACCConfigBool(kConfigBool_edit_toolbar_use_white_list) && ACCConfigBool(kConfigBool_enable_story_tab_in_recorder)) {
        // 白名单中下发的置顶
        NSArray<NSString *> *pinedItemArray = ACCConfigArray(kConfigArray_edit_toolbar_exhibit_list);

        __block NSInteger exihibitCount = 0;
        [pinedItemArray enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSValue *barItemId = self.barItemMap[obj];
            __block NSInteger index = NSNotFound;
            __block ACCBarItem *barItem = nil;
            [sortedBarItem enumerateObjectsUsingBlock:^(ACCBarItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.itemId == barItemId.pointerValue) {
                    index = idx;
                    barItem = obj;
                    *stop = YES;
                }
            }];
            if (index != NSNotFound) {
                [sortedBarItem removeObjectAtIndex:index];
                [sortedBarItem insertObject:barItem atIndex:0];
                exihibitCount++;
            }
        }];
        self.exihibitCount = exihibitCount;
    }
    if (self.isFromKaraoke) {
        // K歌模式下，快速设置和存草稿需要置底
        sortedBarItem = [self p_resortBarItems:sortedBarItem];
    }
    
    if ([ACCSmartMovieABConfig isOn]) {
        // 智能照片电影开关打开的时候，需要配置按钮的位置
        sortedBarItem = [self p_resortBarItemsInSmartMovie:sortedBarItem];
    }
    
    if ([ACCFlowerRedPacketHelper() isFlowerRedPacketActivityOn]) {
        sortedBarItem = [self p_resortBarItemsInFlower:sortedBarItem];
    }
    
    /* 将标记placeLastUnfold的item放到外露的最后一个 */
    NSInteger ignoreUnfoldLimitCount = [self p_getIgnoreUnfoldLimitCount:sortedBarItem];
    [self p_updateMaxUnfoldCount:ignoreUnfoldLimitCount];
    NSInteger unFoldCount = self.maxUnfoldCount > 0 ? self.maxUnfoldCount : 5;
    unFoldCount -= 1;
    NSArray *sortedBarItemCopied = [sortedBarItem copy];
    [sortedBarItemCopied enumerateObjectsUsingBlock:^(ACCBarItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        if (item.placeLastUnfold && unFoldCount - 1 <= sortedBarItemCopied.count ) {
            [sortedBarItem removeObject:item];
            [sortedBarItem insertObject:item atIndex:unFoldCount - 1];
        }
    }];
    
    return sortedBarItem;
}

- (NSMutableArray<ACCBarItem *> *)p_resortBarItems:(NSArray<ACCBarItem *> *)sortedItems
{
    // 需要后置的选项
    NSMutableArray<ACCBarItem *> *rearedBarItems = [[NSMutableArray alloc] init];
    NSMutableArray<ACCBarItem *> *restoredBarItems = [sortedItems mutableCopy];
    [sortedItems enumerateObjectsUsingBlock:^(ACCBarItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj && ([self.ignoreUnfoldLimitSet containsObject:[NSValue valueWithPointer:obj.itemId]] || obj.itemId == ACCEditToolBarPublishSettingsContext || obj.itemId == ACCEditToolBarSaveDraftContext)) {
            [rearedBarItems addObject:obj];
            [restoredBarItems removeObject:obj];
        }
    }];
    [restoredBarItems addObjectsFromArray:rearedBarItems];
    return restoredBarItems;
}

/// 春节bar item需要动态可配
- (NSMutableArray<ACCBarItem *> *)p_resortBarItemsInFlower:(NSArray<ACCBarItem *> *)sortedItems
{
    NSMutableArray <ACCBarItem *> *ret = [sortedItems mutableCopy];
    
    [sortedItems.copy enumerateObjectsUsingBlock:^(ACCBarItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (obj.itemId == ACCEditToolBarRedpacketContext) {
            NSInteger itemIndex = [ACCFlowerRedPacketHelper() flowerRedPacketBarItemIndex];
            if (itemIndex >= sortedItems.count) {
                itemIndex = 0;
            }
            [ret acc_removeObject:obj];
            [ret acc_insertObject:obj atIndex:itemIndex];
            *stop = YES;
        }
    }];
    return ret;
}

- (NSMutableArray<ACCBarItem *> *)p_resortBarItemsInSmartMovie:(NSArray<ACCBarItem *> *)sortedItems
{
    NSMutableArray<ACCBarItem *> *restoredBarItems = [sortedItems mutableCopy];
    __block NSInteger insertIndx = NSNotFound;
    __block ACCBarItem *smBarItem = nil;
    [sortedItems enumerateObjectsUsingBlock:^(ACCBarItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj) {
            // 插到变图集/变视频的下面
            if (obj.itemId == ACCEditToolBarVideo2ImageContext ||
                obj.itemId == ACCEditToolBarImage2VideoContext) {
                insertIndx = idx + 1;
            }
            if (obj.itemId == ACCEditToolBarSmartMovieContext) {
                smBarItem = obj;
                [restoredBarItems removeObject:obj];
            }
        }
    }];
    
    if (!smBarItem || insertIndx == NSNotFound) {
        return sortedItems.mutableCopy;
    }
    if (insertIndx < sortedItems.count) {
        [restoredBarItems btd_insertObject:smBarItem atIndex:insertIndx];
    } else {
        [restoredBarItems btd_addObject:smBarItem];
    }
    return restoredBarItems;
}

- (NSInteger)p_getIgnoreUnfoldLimitCount:(NSArray *)sortedBarItem
{
    NSInteger ignoreUnfoldLimitCount = 0;
    if (!ACCConfigBool(ACCConfigBool_meteor_mode_on)) {
        for (ACCBarItem *item in sortedBarItem) {
            if ([self.ignoreUnfoldLimitSet containsObject:[NSValue valueWithPointer:item.itemId]]) {
                BOOL shouldShow = item.needShowBlock ? ACCBLOCK_INVOKE(item.needShowBlock) : YES;
                if (shouldShow) {
                    ++ignoreUnfoldLimitCount;
                }
            }
        }
    }
    return ignoreUnfoldLimitCount;
}

- (void)p_updateMaxUnfoldCount:(NSInteger)ignoreUnfoldLimitCount
{
    self.maxUnfoldCount = [AWEEditRightTopVerticalActionContainerView containerViewMaxItemCount:self.exihibitCount
                                                                           maxUnfoldedItemCount:[AWEEditRightTopVerticalActionContainerView containerViewMaxUnfoldedItemCount:self.isFromIM]
                                                                         ignoreUnfoldLimitCount:ignoreUnfoldLimitCount
                                                                                ignoreWhitelist:self.isFromCommerce || self.isFromIM];
}

- (NSDictionary<NSString *, NSValue *> *)barItemMap
{
    if (!_barItemMap) {
        _barItemMap = @{
            @"red_packet" : [NSValue valueWithPointer:ACCEditToolBarRedpacketContext],
            @"wish_module" : [NSValue valueWithPointer:ACCEditToolBarNewYearModuleContext],
            @"wish_text" : [NSValue valueWithPointer:ACCEditToolBarNewYearTextContext],
            @"ktv_tuning" : [NSValue valueWithPointer:ACCEditToolBarKaraokeConfigContext],
            @"ktv_change_template" : [NSValue valueWithPointer:ACCEditToolBarKaraokeBGConfigContext],
            @"quick_save_draft": [NSValue valueWithPointer:ACCEditToolBarQuickSaveDraftContext],
            @"quick_publish_private": [NSValue valueWithPointer:ACCEditToolBarQuickSavePrivateContext],
            @"quick_save_album": [NSValue valueWithPointer:ACCEditToolBarQuickSaveAlbumContext],
            @"music": [NSValue valueWithPointer:ACCEditToolBarMusicContext],
            @"volume": [NSValue valueWithPointer:ACCEditToolBarSoundContext],
            @"video_enhance": [NSValue valueWithPointer:ACCEditToolBarVideoEnhanceContext],
            @"sticker": [NSValue valueWithPointer:ACCEditToolBarInfoStickerContext],
            @"voice_change": [NSValue valueWithPointer:ACCEditToolBarVoiceChangeContext],
            @"auto_caption": [NSValue valueWithPointer:ACCEditToolBarAutoCaptionContext],
            @"effect": [NSValue valueWithPointer:ACCEditToolBarEffectContext],
            @"text": [NSValue valueWithPointer:ACCEditToolBarTextContext],
            @"clip": [NSValue valueWithPointer:ACCEditToolBarClipContext],
            @"filter": [NSValue valueWithPointer:ACCEditToolBarFilterContext],
            @"beauty": [NSValue valueWithPointer:ACCEditToolBarBeautyContext],
            @"smart_movie": [NSValue valueWithPointer:ACCEditToolBarSmartMovieContext],
            @"select_template": [NSValue valueWithPointer:ACCEditToolBarSelectTemplateContext],
            @"image_to_video": [NSValue valueWithPointer:ACCEditToolBarImage2VideoContext],
            @"video_to_image": [NSValue valueWithPointer:ACCEditToolBarVideo2ImageContext],
            @"tags": [NSValue valueWithPointer:ACCEditToolBarTagsContext],
            @"crop_image": [NSValue valueWithPointer:ACCEditToolBarCropImageContext],
            @"publish_settings": [NSValue valueWithPointer:ACCEditToolBarPublishSettingsContext],
        };
    }
    return _barItemMap;
}

- (NSSet<NSValue *> *)ignoreUnfoldLimitSet
{
    if (!_ignoreUnfoldLimitSet) {
        NSMutableSet *set = [NSMutableSet set];
        [set addObject:[NSValue valueWithPointer:ACCEditToolBarQuickSaveDraftContext]];
        [set addObject:[NSValue valueWithPointer:ACCEditToolBarQuickSavePrivateContext]];
        [set addObject:[NSValue valueWithPointer:ACCEditToolBarQuickSaveAlbumContext]];
        [set addObject:[NSValue valueWithPointer:ACCEditToolBarPublishSettingsContext]];
        _ignoreUnfoldLimitSet = [set copy];
    }
    return _ignoreUnfoldLimitSet;
}

@end

