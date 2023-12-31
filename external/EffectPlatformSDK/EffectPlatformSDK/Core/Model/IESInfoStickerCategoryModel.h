//
//  IESInfoStickerCategoryModel.h
//  EffectPlatformSDK
//
//  Created by pengzhenhuan on 2021/2/1.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>
NS_ASSUME_NONNULL_BEGIN

@class IESInfoStickerModel;

@interface IESInfoStickerCategoryModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, readonly, copy) NSString *categoryID;

@property (nonatomic, readonly, copy) NSString *categoryKey;

@property (nonatomic, readonly, copy) NSString *categoryName;

@property (nonatomic, readonly, copy) NSString *iconDownloadURI;

@property (nonatomic, readonly, copy) NSArray<NSString *> *iconDownloadURLs;

@property (nonatomic, readonly, copy) NSString *iconSelectedURI;

@property (nonatomic, readonly, copy) NSArray<NSString *> *iconSelectedURLs;

@property (atomic, readonly, copy) NSArray<IESInfoStickerModel *> *infoStickerList;

@property (atomic, readonly, copy) NSArray<NSString *> *infoStickerIDs;

@property (nonatomic, readonly, copy) NSArray<NSString *> *tags;

@property (nonatomic, readonly ,copy) NSString *tagsUpdatedTime;

@property (nonatomic, readonly, assign) BOOL isDefault;

@property (nonatomic, readonly, copy) NSString *extra;

- (void)fillStickersWithStickersMap:(NSDictionary <NSString *, IESInfoStickerModel *> *)stickersMap;

- (void)replaceWithStickers:(NSArray<IESInfoStickerModel *> *)stickers;

@end

NS_ASSUME_NONNULL_END
