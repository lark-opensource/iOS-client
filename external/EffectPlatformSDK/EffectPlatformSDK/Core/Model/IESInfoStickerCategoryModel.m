//
//  IESInfoStickerCategoryModel.m
//  EffectPlatformSDK
//
//  Created by pengzhenhuan on 2021/2/1.
//

#import "IESInfoStickerCategoryModel.h"
#import "IESInfoStickerModel.h"

@interface IESInfoStickerCategoryModel()

@property (atomic, readwrite, copy) NSArray<IESInfoStickerModel *> *infoStickerList;

@property (atomic, readwrite, copy) NSArray<NSString *> *infoStickerIDs;

@end

@implementation IESInfoStickerCategoryModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"categoryID":@"id",
        @"categoryKey":@"key",
        @"categoryName":@"name",
        @"iconDownloadURI":@"icon.uri",
        @"iconDownloadURLs":@"icon.url_list",
        @"iconSelectedURI":@"icon_selected.uri",
        @"iconSelectedURLs":@"icon_selected.url_list",
        @"infoStickerIDs":@"effects",
        @"tags":@"tags",
        @"tagsUpdatedTime":@"tags_updated_at",
        @"isDefault":@"is_default",
        @"extra":@"extra"
    };
}

- (void)fillStickersWithStickersMap:(NSDictionary <NSString *, IESInfoStickerModel *> *)stickersMap
{
    NSMutableArray *stickersArray = [NSMutableArray array];
    [self.infoStickerIDs enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        IESInfoStickerModel *sticker = stickersMap[obj];
        if (sticker) {
            [stickersArray addObject:sticker];
        }
    }];
    self.infoStickerList = [stickersArray copy];
}

- (void)replaceWithStickers:(NSArray<IESInfoStickerModel *> *)stickers
{
    NSMutableArray *stickerIdsArray = [NSMutableArray array];
    [stickers enumerateObjectsUsingBlock:^(IESInfoStickerModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.stickerIdentifier) {
            [stickerIdsArray addObject:obj.stickerIdentifier];
        }
    }];
    self.infoStickerIDs = [stickerIdsArray copy];
    self.infoStickerList = stickers;
}

@end
