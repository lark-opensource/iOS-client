//
//  IESInfoStickerResponseModel.m
//  EffectPlatformSDK-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/2/17.
//

#import "IESInfoStickerResponseModel.h"

@interface IESInfoStickerResponseModel()

@property (nonatomic, readwrite, strong) NSNumber *cursor;
@property (nonatomic, readwrite, assign) BOOL hasMore;
@property (atomic, readwrite, copy) NSArray<IESInfoStickerModel *> *stickerList;

@end

@implementation IESInfoStickerResponseModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"cursor" : @"cursor",
             @"hasMore" : @"has_more",
             @"stickerList" : @"sticker_list",
             @"title" : @"subtitle",
             };
}

+ (NSValueTransformer *)stickerListJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[IESInfoStickerModel class]];
}

- (void)appendAndUpdateDataWithResponseModel:(IESInfoStickerResponseModel *)model
{
    if (model.stickerList.count) {
        NSMutableArray *tmpStickers = [self.stickerList mutableCopy];
        [tmpStickers addObjectsFromArray:model.stickerList];
        self.stickerList = [tmpStickers copy];
    }
    self.hasMore = model.hasMore;
    self.cursor = model.cursor;
}

@end
