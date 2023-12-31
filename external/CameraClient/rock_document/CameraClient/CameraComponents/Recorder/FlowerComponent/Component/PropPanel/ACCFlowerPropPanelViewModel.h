//
//  ACCFlowerPropPanelViewModel.h
//  CameraClient-Pods-AwemeCore
//
//  Created by bytedance on 2021/11/14.
//

#import <Foundation/Foundation.h>
#import "ACCPropPickerView.h"
#import "ACCFlowerPanelEffectListModel.h"
#import "ACCFlowerRewardModel.h"
#import "ACCFlowerPropPanelService.h"

FOUNDATION_EXPORT NSInteger const kACCFlowerPanelIndexInvalid;

typedef NSString * ACCFlowerItemType;

FOUNDATION_EXPORT ACCFlowerItemType ACCFlowerItemTypeRecognition;
FOUNDATION_EXPORT ACCFlowerItemType ACCFlowerItemTypeScan;
FOUNDATION_EXPORT ACCFlowerItemType ACCFlowerItemTypePhoto;
FOUNDATION_EXPORT ACCFlowerItemType ACCFlowerItemTypeProp;


@protocol ACCRecordPropService, ACCFlowerService, ACCCameraService;

@interface ACCFlowerPropPanelViewModel : NSObject <ACCFlowerPropPanelService>

@property (nonatomic, assign) BOOL isShowingPanel;

@property (nonatomic, weak, nullable) id<ACCRecordPropService> propService;
@property (nonatomic, weak, nullable) id<ACCFlowerService> flowerService;
@property (nonatomic, weak, nullable) id<ACCCameraService> cameraService;

@property (nonatomic, copy, readonly, nullable) NSArray<ACCFlowerPanelEffectModel *> *items;

// flower shoot prop
@property (nonatomic,   copy, readonly, nullable) NSArray<IESEffectModel *> *shootProps;
@property (nonatomic, assign, readonly) BOOL shootPropLoaded;
@property (nonatomic, assign) BOOL isShootPropPanelShow;

- (void)loadFlowerShootPropDataIfNeed:(NSArray<ACCFlowerPanelEffectModel *> *)flowerModels;

/**
 * @note selectedIndex and selectedItem changes simultaneously
 */
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, strong, readonly, nullable) ACCFlowerPanelEffectModel *selectedItem;

/**
 * @note download progress for the currently selected effect. (downloadProgressPack == nil || downloadProgressPack.count == 2) always equals YES
 */
@property (nonatomic, copy, readonly, nullable) NSArray<NSNumber *> *downloadProgressPack; // [0] = index, [1] = download progress

@property (nonatomic, assign) NSInteger targetIndexUnderLuckyCardStage;

- (void)fetchDailyRewardIfNeededWithCompletion:(void (^)(NSError *_Nullable error,
                                                         ACCFlowerRewardResponse *_Nonnull result,
                                                         NSString *_Nullable showSchema))completion;

- (void)fetchFlowerPropDataWithCompletion:(nullable dispatch_block_t)completion;

/**
 * flowerItem 是指春节面板上的道具类型：groot, scan, photo, prop
 */
- (NSInteger)itemIndexForFlowerItem:(nullable NSString *)flowerItem;
- (NSInteger)itemIndexForFlowerPropID:(nullable NSString *)propID;
- (void)insertItem:(nullable ACCFlowerPanelEffectModel *)item atIndex:(NSInteger)index;

#pragma mark - track

- (void)flowerTrackForPropShow:(NSInteger)index;
- (void)flowerTrackForPropClick:(NSInteger)index enterMethod:(NSString *)enterMethod;
- (void)flowerTrackForEnterShootPropPanel;
- (void)flowerTrackForShootPropShow:(IESEffectModel *)prop index:(NSInteger)index;
- (void)flowerTrackForShootPropClick:(IESEffectModel *)prop enterMethod:(NSString *)enterMethod;
- (void)flowerTrackForEnterTaskEntryView;
- (void)flowerTrackForEnterFlowerCameraTab:(nullable NSString *)enterMethod propID:(nullable NSString *)propID;
- (void)flowerTrackForQuitFlowerCameraTab:(BOOL)isLoadFailed;

#pragma mark - monitor
- (void)trackForFlowerPropDownload:(CFTimeInterval)startTime flowerPropType:(NSInteger)flowerPropType error:(NSError * __nullable)error;

@end
