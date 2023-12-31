//
//  ACCMusicEditInfo.m
//  CameraClient-Pods-Aweme
//
//  Created by Lemonior on 2020/11/20.
//

#import "ACCMusicEditInfo.h"

@implementation ACCMusicInfo

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"musicID" : @"music_id",
        @"musicUrl" : @"music_url",
    };
}

- (id)copyWithZone:(NSZone *)zone
{
    ACCMusicInfo *copy = [[ACCMusicInfo alloc] init];
    copy.musicID = self.musicID;
    copy.musicUrl = self.musicUrl;
    return copy;
}

- (NSDictionary *)acc_musicInfoDict {
    return @{
        @"music_id": self.musicID ?: @"",
        @"music_url": self.musicUrl ?: @""
    };
}

@end

@implementation ACCMusicEditInfo

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"musicInfo" : @"music_info",
        @"startTime" : @"start_time",
        @"duration" : @"duration",
        @"speed" : @"speed",
    };
}

- (id)copyWithZone:(NSZone *)zone
{
    ACCMusicEditInfo *copy = [[ACCMusicEditInfo alloc] init];
    copy.musicInfo = [self.musicInfo copy];
    copy.startTime = self.startTime;
    copy.duration = self.duration;
    copy.speed = self.speed;
    return copy;
}

@end
