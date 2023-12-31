//
//  DVEPreviewStickerViewModel.h
//  Pods
//
//  Created by pengzhenhuan on 2022/1/5.
//

#import <Foundation/Foundation.h>
#import "DVEVCContext.h"
#import <DVETrackKit/DVEEditItem.h>
#import <DVETrackKit/DVEEditBoxCornerInfo.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVEPreviewStickerViewModel : NSObject

@property (nonatomic, strong, readonly) RACSubject *sendStickerItem;

- (instancetype)initWithVCContext:(DVEVCContext *)vcContext;

- (void)updateStickerWithItem:(DVEEditItem *)item size:(CGSize)size endTransform:(BOOL)endTransform;

- (void)updateItem:(DVEEditItem *)item withSize:(CGSize)size;

- (CGSize)originEditItemSizeForSlot:(NLETrackSlot_OC *)slot scale:(float)scale size:(CGSize)size;

- (CGSize)originEditItemSizeWithNormalSize:(CGSize)normaliz scale:(float)scale size:(CGSize)size;

- (void)updateItemLayerWithItems:(NSArray<DVEEditItem *> *)items slotID:(NSString *)slotId;

- (void)updateNormalizSizeWithItem:(DVEEditItem *)item size:(CGSize)size;

- (nullable DVEEditItem *)createEditItemForSlotID:(NSString *)slotId withSize:(CGSize)size;

- (void)updateWithItem:(DVEEditItem *)item cornerType:(DVEEditCornerType)type;

- (BOOL)isCurrentTimeOutOfItemTimeRange:(DVEEditItem *)item;

- (NSArray<DVEEditItem *> *)refreshItemsWithSize:(CGSize)size;

- (void)updateSelectStickerSlotWithId:(NSString *)slotId;


@end

NS_ASSUME_NONNULL_END
