//
//  ACCPublishMusicTrackModel.m
//  CameraClient
//
//  Created by chengfei xiao on 2019/12/30.
//

#import "ACCPublishMusicTrackModel.h"

@implementation ACCPublishMusicTrackModel

- (instancetype)copyWithZone:(NSZone *)zone
{
    ACCPublishMusicTrackModel *model = [[[self class] allocWithZone:zone] init];
    model.musicShowRank = self.musicShowRank;
    model.musicRecType = self.musicRecType;
    model.selectedMusicID = self.selectedMusicID;
    return model;
}


@end
