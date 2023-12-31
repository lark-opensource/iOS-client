//
//  IESThirdPartyResponseModel.m
//  EffectPlatformSDK
//
//  Created by jindulys on 2019/2/26.
//

#import "IESThirdPartyResponseModel.h"

@interface IESThirdPartyResponseModel()

@property (nonatomic, readwrite, assign) NSInteger cursor;
@property (nonatomic, readwrite, assign) BOOL hasMore;
@property (nonatomic, readwrite, copy) NSArray<IESThirdPartyStickerModel *> *stickerList;

@end

@implementation IESThirdPartyResponseModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"searchTips" : @"search_tips",
             @"cursor" : @"cursor",
             @"hasMore" : @"has_more",
             @"stickerList" : @"sticker_list",
             @"title" : @"subtitle",
             @"gifsResponseModel" : @"gifs",
             };
}

+ (NSValueTransformer *)stickerListJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[IESThirdPartyStickerModel class]];
}

- (void)appendAndUpdateDataWithResponseModel:(IESThirdPartyResponseModel *)model
{
    NSMutableArray *tmpStickers = [self.stickerList mutableCopy];
    [tmpStickers addObjectsFromArray:model.stickerList];
    self.stickerList = tmpStickers;
    self.hasMore = model.hasMore;
    self.cursor = model.cursor;
}

@end
