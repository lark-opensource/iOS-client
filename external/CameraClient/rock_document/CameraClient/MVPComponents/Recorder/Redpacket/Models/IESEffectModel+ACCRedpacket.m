//
//  IESEffectModel+ACCRedpacket.m
//  CameraClient-Pods-Aweme
//
//  Created by Howie He on 2020/11/10.
//

#import "IESEffectModel+ACCRedpacket.h"
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreationKitInfra/NSString+ACCAdditions.h>

@implementation IESEffectModel (ACCRedpacket)

- (BOOL)acc_isTC21Redpacket
{
    return [self.pixaloopSDKExtra acc_boolValueForKey:@"isTC21RedEnvelope"];
}

- (BOOL)acc_supportLiteRedpacket
{
    return [self.acc_analyzeExtra acc_boolValueForKey:@"lite_record_support_gold"];
}

- (BOOL)acc_isLiteRedpacket
{
    return [self acc_isTC21Redpacket] || [self acc_supportLiteRedpacket];
}

- (NSString *)acc_redpacketKey
{
    return [self.pixaloopSDKExtra acc_stringValueForKey:@"red_envelope_key"];
}

- (NSString *)acc_redpacketSubpath
{
    return [self.pixaloopSDKExtra acc_stringValueForKey:@"edit_red_envelope_package_path"];
}

- (NSString *)acc_composerPath
{
    NSString *subpath = [self acc_redpacketSubpath];
    if (subpath.length > 0) {
        return [self.filePath stringByAppendingPathComponent:subpath];
    }
    return nil;
}

- (NSString *)videoGroupID
{
    NSDictionary *extra = [self.extra acc_jsonDictionary];
    return [extra acc_stringValueForKey:@"video_id"];
}

- (BOOL)enableEffectMusicTime
{
    NSDictionary *extra = [self.sdkExtra acc_jsonDictionary];
    return [extra acc_boolValueForKey:@"enable_effect_music_time"];
}

- (BOOL)allowMusicBeatCancelMusic
{
    // flower effect: https://bytedance.feishu.cn/docx/doxcnukCw3nuiY0aJyToDS99VfC
    NSDictionary *extra = [self.sdkExtra acc_jsonDictionary];
    return [extra acc_boolValueForKey:@"music_beat_allow_cancel_music"];
}

@end
