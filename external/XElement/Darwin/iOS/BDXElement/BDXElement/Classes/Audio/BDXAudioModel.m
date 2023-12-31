//
//  BDXAudioModel.m
//  BDXElement-Pods-Aweme
//
//  Created by DylanYang on 2020/9/28.
//

#import "BDXAudioModel.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

@implementation BDXAudioModel

- (instancetype)initWithJSONDict:(NSDictionary *)jsonDict {
    self = [super init];
    if (self) {
        self.modelId = [jsonDict btd_stringValueForKey:@"id"];
        self.title = [jsonDict btd_stringValueForKey:@"title"];
        self.artist = [jsonDict btd_stringValueForKey:@"artist"];
        self.albumTitle = [jsonDict btd_stringValueForKey:@"album_title"];
        self.playbackDuration = [jsonDict btd_doubleValueForKey:@"playback_duration"] / 1000.0;
        self.albumCoverUrl = [jsonDict btd_stringValueForKey:@"artwork_url"];
        self.playUrl = [jsonDict btd_stringValueForKey:@"play_url"];
        self.canBackgroundPlay = [jsonDict btd_boolValueForKey:@"can_background_play"];
        self.localPath = [jsonDict btd_arrayValueForKey:@"local_path"];
        self.eventData = [jsonDict btd_dictionaryValueForKey:@"event_data"];
        self.playActionTimes = 0;
        NSDictionary* playModelDic = [jsonDict btd_dictionaryValueForKey:@"play_model"];
        if (playModelDic && playModelDic.allKeys.count > 0) {
            self.playModel = [[BDXAudioVideoModel alloc] initWithJSONDict:playModelDic];
        }
    }
    return self;
}

- (BOOL)isVerified {
    if (self.modelId && self.modelId.length > 0) {
        if (self.playUrl && self.playUrl.length > 0) {
            return YES;
        }
        if (self.localPath && self.localPath.count > 0) {
            return YES;
        }
        if (self.playModel != nil || self.playModel.encryptType) {
            return YES;
        }
    }
    return NO;
}

@end


@implementation BDXAudioVideoModel

- (instancetype)initWithJSONDict:(NSDictionary *)jsonDict {
    self = [super init];
    if (self) {
        self.encryptType = [self _encryptType: [jsonDict btd_stringValueForKey:@"type"]];
        self.quality = [self _quality: [jsonDict btd_stringValueForKey:@"quality"]];
        
        if (self.encryptType == BDXAudioPlayerEncryptTypeModel) {
            NSDictionary* videoModel = [jsonDict btd_dictionaryValueForKey:@"video_model"];
            self.videoEngineModel = [TTVideoEngineModel videoModelWithDict:videoModel];
        }
    }
    return self;
}

- (BDXAudioPlayerEncryptType)_encryptType:(NSString*)value {
    if ([@"vide_model" isEqualToString:value]) {
        return BDXAudioPlayerEncryptTypeModel;
    }
    return BDXAudioPlayerEncryptTypeModel;
}

- (TTVideoEngineResolutionType)_quality:(NSString*)value {
    if ([@"excellent" isEqualToString:value]) {
        return TTVideoEngineResolutionTypeFullHD;
    } else if ([@"good" isEqualToString:value]) {
        return TTVideoEngineResolutionTypeHD;
    } else if ([@"regular" isEqualToString:value]) {
        return TTVideoEngineResolutionTypeSD;
    }
    return TTVideoEngineResolutionTypeSD;
}

@end
