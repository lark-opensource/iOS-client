//
//  ACCEditTRToolBarContainer.m
//  CameraClient
//
//  Created by wishes on 2020/6/2.
//

#import "ACCEditToolBarContainer.h"
#import "ACCEditBarItemLottieExtraData.h"
#import <CreativeKit/ACCResourceHeaders.h>

ACCContextId(ACCEditToolBarMusicContext)
ACCContextId(ACCEditToolBarMusicCutContext)
ACCContextId(ACCEditToolBarSoundContext)
ACCContextId(ACCEditToolBarVideoEnhanceContext)
ACCContextId(ACCEditToolBarInfoStickerContext)
ACCContextId(ACCEditToolBarVoiceChangeContext)
ACCContextId(ACCEditToolBarAutoCaptionContext)
ACCContextId(ACCEditToolBarEffectContext)
ACCContextId(ACCEditToolBarVideoDubContext)
ACCContextId(ACCEditToolBarStatusBgImageContext)
ACCContextId(ACCEditToolBarTextContext)
ACCContextId(ACCEditToolBarClipContext)
ACCContextId(ACCEditToolBarFilterContext)
ACCContextId(ACCEditToolBarBeautyContext)
ACCContextId(ACCEditToolBarLocationContext)
ACCContextId(ACCEditToolBarPrivacyContext)
ACCContextId(ACCEditToolBarMoreActionsContext)
ACCContextId(ACCEditToolBarSaveDraftContext)
ACCContextId(ACCEditToolBarSelectTemplateContext)
ACCContextId(ACCEditToolBarQuickSaveDraftContext)
ACCContextId(ACCEditToolBarQuickSavePrivateContext)
ACCContextId(ACCEditToolBarQuickSaveAlbumContext)
ACCContextId(ACCEditToolBarImage2VideoContext)
ACCContextId(ACCEditToolBarVideo2ImageContext)
ACCContextId(ACCEditToolBarTagsContext)
ACCContextId(ACCEditToolBarCropImageContext)
ACCContextId(ACCEditToolBarKaraokeConfigContext)
ACCContextId(ACCEditToolBarKaraokeBGConfigContext)
ACCContextId(ACCEditToolBarPublishSettingsContext)
ACCContextId(ACCEditToolBarMeteorModeContext)
ACCContextId(ACCEditToolBarSmartMovieContext)
ACCContextId(ACCEditToolBarRedpacketContext)

ACCContextId(ACCEditToolBarNewYearModuleContext)
ACCContextId(ACCEditToolBarNewYearTextContext)

@interface ACCEditToolBarContainer ()

@property (nonatomic, strong) NSMutableArray<ACCBarItem*> *barItems;

@property (nonatomic, strong) NSMutableDictionary *barItemDictionary;

@property (nonatomic, strong) NSMapTable *viewCache;

@end

@implementation ACCEditToolBarContainer

@synthesize sortDataSource = _sortDataSource;
@synthesize delegate = _delegate;
@synthesize contentView = _contentView;
@synthesize location = _location;
@synthesize clickCallback;

- (instancetype)initWithContentView:(UIView *)contentView
{
    if (self = [super init]) {
        self.contentView = contentView;
        self.barItems = [NSMutableArray new];
        self.barItemDictionary = [NSMutableDictionary new];
        self.viewCache = [NSMapTable strongToWeakObjectsMapTable];
    }
    return self;
}

- (BOOL)addBarItem:(nonnull ACCBarItem<ACCEditBarItemExtraData *> *)item {
     NSValue *barItemKey = [NSValue valueWithPointer:item.itemId];
     if (![self.barItemDictionary.allKeys containsObject:barItemKey]) {
         [self.barItemDictionary setObject:item forKey:barItemKey];
         [self.barItems addObject:item];
         return YES;
     }
     return NO;
}

- (UIView *)barItemContentView {
    return nil;
}

- (AWEEditActionItemView *)viewWithBarItemID:(void *)itemId {
    AWEEditActionItemView* itemV = [self.viewCache objectForKey:[NSValue valueWithPointer:itemId]];
    return itemV;
}

- (ACCBarItem<ACCEditBarItemExtraData *> *)barItemWithItemId:(nonnull void *)itemId {
    return [self.barItemDictionary objectForKey:[NSValue valueWithPointer:itemId]];
}

- (NSArray<ACCBarItem<ACCEditBarItemExtraData *> *> *)barItems {
    return _barItems;
}

- (void)containerViewDidLoad {

}

- (NSArray<AWEEditAndPublishViewData *>*)adaptBarItemToViewData {
    NSMutableArray *viewDatas = [NSMutableArray new];
    @weakify(self);
    [[self sortedBarItem] enumerateObjectsUsingBlock:^(ACCBarItem<ACCEditBarItemExtraData *> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL shouldShow = obj.needShowBlock ? obj.needShowBlock() : YES;
        AWEEditAndPublishViewData *data = [AWEEditAndPublishViewData dataWithTitle:obj.title
                                                                             image:ACCResourceImage(obj.imageName)
                                                                     selectedImage:ACCResourceImage(obj.selectedImageName)
                                                                              show:shouldShow
                                                                       actionBlock:^(UIView *editAndPublishView, AWEEditActionItemView *itemView) {
            ACCBLOCK_INVOKE(obj.barItemActionBlock,itemView);
            if ([self.delegate respondsToSelector:@selector(barItemContainer:didClickedBarItem:)]) {
                [self.delegate barItemContainer:self didClickedBarItem:obj.itemId];
            }
        } buttonClass:obj.extraData.buttonClass extraConfigBlock:^(AWEEditActionItemView *itemView) {
            ACCBLOCK_INVOKE(obj.barItemViewConfigBlock,itemView);
            @strongify(self);
            [self.viewCache setObject:itemView forKey:[NSValue valueWithPointer:obj.itemId]];
        }];
        if (data.shouldShow) {
            [viewDatas addObject:data];
        }
    }];
    return viewDatas;
}

- (NSArray<ACCBarItem*> *)sortedBarItem
{
    NSArray *toolBarSortItemArray = [self.sortDataSource barItemSortArray];
    __block NSArray<ACCBarItem*> *sortedArr = [self.barItems sortedArrayUsingComparator:^NSComparisonResult(ACCBarItem*  _Nonnull obj1, ACCBarItem*  _Nonnull obj2) {
        NSComparisonResult result = NSOrderedSame;
        if (([toolBarSortItemArray indexOfObject:[NSValue valueWithPointer:obj1.itemId]] != NSNotFound) && ([toolBarSortItemArray indexOfObject:[NSValue valueWithPointer:obj2.itemId]] != NSNotFound)) {
            NSNumber *index1 = @([toolBarSortItemArray indexOfObject:[NSValue valueWithPointer:obj1.itemId]]);
            NSNumber *index2 = @([toolBarSortItemArray indexOfObject:[NSValue valueWithPointer:obj2.itemId]]);
            result = [index1 compare:index2];
        }
        return result;
    }];
    
    NSInteger unFoldCount = self.maxUnfoldCount > 0 ? self.maxUnfoldCount : 5;
    unFoldCount = MAX(1, MIN(unFoldCount, sortedArr.count));
    NSMutableArray<ACCBarItem *> *tempArrs = sortedArr.mutableCopy;
    [sortedArr.copy enumerateObjectsUsingBlock:^(ACCBarItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        if (item.placeLastUnfold && unFoldCount - 1 <= tempArrs.count ) {
            [tempArrs removeObject:item];
            [tempArrs insertObject:item atIndex:unFoldCount - 1];
        }
    }];
    sortedArr = [tempArrs copy];
    return sortedArr;
}

- (void)removeBarItem:(nonnull void *)itemId {
    NSAssert(NO, @"Not realize in Editor");
}

- (void)updateAllBarItems {
    NSAssert(NO, @"Not realize in Editor");
}

- (void)updateBarItemWithItemId:(nonnull void *)itemId {
    NSAssert(NO, @"Not realize in Editor");
}

@end
