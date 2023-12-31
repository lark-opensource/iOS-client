//
//  AWEStickerMusicManager.m
//  Pods
//
//  Created by homeboy on 2019/8/12.
//

#import "AWEStickerMusicManager.h"
#import <CreationKitInfra/ACCLogProtocol.h>
#import "ACCMusicModelProtocol.h"
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <EffectPlatformSDK/IESEffectModel.h>
#import <EffectPlatformSDK/EffectPlatform.h>
#import <CreationKitInfra/NSDictionary+ACCAddBaseApiPropertyKey.h>
#import <CreativeKit/ACCMacrosTool.h>

static NSMutableDictionary<NSString *, NSNumber *> *forceBindMusicDownloadFailedDic;

@interface AWEStickerMusicManager()

@end

@implementation AWEStickerMusicManager

+ (void)setForceBindMusicDownloadFailedWithEffectIdentifier:(NSString *)effectIdentifier
{
    if (!forceBindMusicDownloadFailedDic) {
        forceBindMusicDownloadFailedDic = [@{} mutableCopy];
    }
    [forceBindMusicDownloadFailedDic setObject:@(YES) forKey:effectIdentifier ?: @""];
}

+ (BOOL)getForceBindMusicDownloadFailed:(NSString *)effectID
{
   return [[forceBindMusicDownloadFailedDic objectForKey:effectID] boolValue];
}

+ (void)initializeForceBindMusicDownloadFailed
{
    // Reset the status of panel sticker download failure
    [forceBindMusicDownloadFailedDic removeAllObjects];
}

+ (BOOL)musicIsForceBindStickerWithExtra:(NSString *)extra {
    if (ACC_isEmptyString(extra)) {
        return NO;
    }
    NSData *data = [extra dataUsingEncoding:NSUTF8StringEncoding];
    if (data == nil) {
        return NO;
    }
    if ([NSJSONSerialization isValidJSONObject:data]) {
        return NO;
    }

    NSError *error = nil;
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error != nil) {
        AWELogToolError2(@"prop", AWELogToolTagRecord, @"prop extra serialization failed: %@", error);
        return NO;
    }

    if (![jsonDict isKindOfClass:[NSDictionary class]]) {
        return NO;
    }

    return [jsonDict acc_boolValueForKey:@"music_is_force_bind"] || [jsonDict acc_boolValueForKey:@"is_music_beat"];
}

@end
