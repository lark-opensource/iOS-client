//
//  ACCTextStickerCacheHelper.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/3/10.
//

#import "ACCTextStickerCacheHelper.h"

#import <CreativeKit/ACCCacheProtocol.h>

static NSString * const kTextReaderLastSelectedSpeaker = @"com.bytedance.ies.sticker.text_reader";

@implementation ACCTextStickerCacheHelper

+ (void)updateLastSelectedSpeaker:(NSString *)speakerID
{
    [ACCCache() setString:speakerID forKey:kTextReaderLastSelectedSpeaker];
}

+ (nullable NSString *)getLastSelectedSpeaker
{
    NSString *result = [ACCCache() stringForKey:kTextReaderLastSelectedSpeaker];
    if (result == nil || [result isEqualToString:@"none"]) {
        result = @"xiaomei";
    }
    return result;
}

@end
