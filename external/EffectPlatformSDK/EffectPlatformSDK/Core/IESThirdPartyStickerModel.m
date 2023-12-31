//
//  IESThirdPartyStickerModel.m
//  AFgzipRequestSerializer
//
//  Created by jindulys on 2019/2/25.
//

#import "IESThirdPartyStickerModel.h"

#import <Mantle/MTLJSONAdapter.h>
#import "IESEffectDefines.h"

@implementation IESThirdPartyStickerModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"identifier" : @"id",
             @"title" : @"title",
             @"userName" : @"user_name",
             @"thumbnailSticker" : @"thumbnail_sticker",
             @"sticker" : @"sticker",
             @"clickURL" : @"click_url",
             @"extra" : @"extra"
             };
}

@end

@implementation IESThirdPartyStickerModel (EffectDownloader)

- (NSString *)filePath
{
    NSString *filePath = IESThirdPartyModelPathWithIdentifier(self.sticker.url.lastPathComponent);
    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:nil];
    if (isExist) {
        return filePath;
    }
    else {
        return nil;
    }
}

- (BOOL)downloaded
{
    return self.filePath != nil;
}

@end
