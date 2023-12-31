//
//  AWEMusicSelectItem.m
//  AWEStudio
//
//  Created by Nero Li on 2019/1/11.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import "AWEMusicSelectItem.h"
#import "AWELyricPattern.h"
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitArch/ACCMusicModelProtocol.h>
#import <CameraClient/ACCVideoMusicProtocol.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <AVFoundation/AVFoundation.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>

@implementation AWEMusicSelectItem
- (instancetype)init
{
    self = [super init];
    if (self) {
        _isRecommended = NO;
    }
    return self;
}

- (BOOL)hasLyric
{
    return [self.lyrics count] > 0;
}

- (NSArray <AWELyricPattern *> *)lyrics
{
    if (_lyrics == nil) {
        if (self.musicModel.lyricType == ACCMusicLyricTypeJSON) {
            NSData *data = [NSData dataWithContentsOfURL:self.localLyricURL];
            NSError *error;
            if (data != nil) {
                NSArray *array = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
                NSMutableArray <AWELyricPattern *>*lyrics = [NSMutableArray new];
                NSMutableDictionary *sameTimes = [NSMutableDictionary new];
                for (NSDictionary *info in array) {
                    AWELyricPattern *lyricPattern = [AWELyricPattern new];
                    if ([info isKindOfClass:NSDictionary.class]) {
                        NSString *text = [info acc_stringValueForKey:@"text"];
                        lyricPattern.lyricText = text;
                        id timeID = [info acc_objectForKey:@"timeId"];
                        if ([timeID isKindOfClass:[NSNumber class]]) {
                            lyricPattern.timeId = [NSString stringWithFormat:@"%f", [timeID floatValue]];
                        } else if ([timeID isKindOfClass:[NSString class]]) {
                            lyricPattern.timeId = timeID;
                        }
                    }
                    NSMutableArray *patterns = [sameTimes objectForKey:lyricPattern.timeId];
                    if (patterns == nil) {
                        patterns = [NSMutableArray new];
                    }
                    [patterns addObject:lyricPattern];
                    [sameTimes setObject:patterns forKey:lyricPattern.timeId];
                }
                
                NSMutableArray *keys = [[sameTimes allKeys] mutableCopy];
                [keys sortUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
                    if ([obj1 doubleValue] >= [obj2 doubleValue]) {
                        return NSOrderedDescending;
                    } else {
                        return NSOrderedAscending;
                    }
                }];
                
                for (NSString *timeID in keys) {
                    NSArray *array = sameTimes[timeID];
                    AWELyricPattern *firstPattern = array.firstObject;
                    if (array.count > 1) {
                        for (int i = 1; i < array.count; ++i) {
                            AWELyricPattern *pattern = array[i];
                            firstPattern.lyricText = [NSString stringWithFormat:@"%@ %@", firstPattern.lyricText, pattern.lyricText];
                        }
                    }
                    [lyrics addObject:firstPattern];
                }
                
                _songTimeLength = lyrics.lastObject.timestamp + 5;
                _lyrics = lyrics;
            } else {
                _lyrics = nil;
            }
        } else if (self.musicModel.lyricType == ACCMusicLyricTypeTXT) {
            NSString *text = [NSString stringWithContentsOfURL:self.localLyricURL encoding:NSUTF8StringEncoding error:NULL];
            if (text.length > 0) {
                AWELyricPattern *lyric = [AWELyricPattern new];
                lyric.lyricText = text;
                lyric.timeId = @"";
                _lyrics = @[lyric];
                _songTimeLength = [self.musicModel.duration doubleValue];
            } else {
                _lyrics = nil;
            }
            
        }
    }
    return _lyrics;
}

- (void)setStartTime:(NSTimeInterval)startTime
{
    _startTime = startTime;
    
    NSUInteger count = self.lyrics.count;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wimplicit-retain-self"
    [self.lyrics enumerateObjectsUsingBlock:^(AWELyricPattern * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.timestamp <= startTime) {
            if (idx + 1 < count) {
                AWELyricPattern *next = self.lyrics[idx + 1];
                if (next.timestamp > startTime) {
                    _startLyricIndex = idx;
                    *stop = YES;
                }
            } else {
                _startLyricIndex = idx;
            }
        }
    }];
#pragma clang diagnostic pop
}

+ (BOOL)canTransMusicItem:(id<ACCMusicModelProtocol>)music {
    if (music == nil) {
        return NO;
    }
    if (music.isLocalScannedMedia) {
        return YES;//本地音频没有musicID 且无需下载
    } else if (!music.isFromImportVideo
               && [music.musicID length]
               && music.musicName.length > 0
               && music.thumbURL.URLList.count > 0) {
        /*
         publishModel.repoMusic.music 里的音乐信息可能只设置了musicId，
         如果这个musicid在返回列表中不存在，同时没有音乐名和音乐封面url，
         就不需要显示，否则就是一个黑块
         */
        return YES;
    }
    return NO;
}

+ (AWEMusicSelectItem *)musicItemForLocalMusicModel:(id<ACCMusicModelProtocol>)model currentPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    AWEMusicSelectItem *musicItem = [[AWEMusicSelectItem alloc] init];
    musicItem.musicModel = model;
    if (!publishModel.repoDraft.isDraft) {
        musicItem.musicModel.loaclAssetUrl = model.originLocalAssetUrl;//单多图进编辑时清空了草稿目录，需要重新更新正确的值
    }
    musicItem.status = AWEPhotoMovieMusicStatusDownloaded;//本地音频无法网络下载
    musicItem.startTime = model.previewStartTime + publishModel.repoMusic.audioRange.location;
    return musicItem;
}

+ (AWEMusicSelectItem *)musicItemForModel:(id<ACCMusicModelProtocol>)model currentPublishModel:(AWEVideoPublishViewModel *)publishModel musicStartTime:(NSTimeInterval)startTime
{
    AWEMusicSelectItem *musicItem = [AWEMusicSelectItem new];
    musicItem.isRecommended = model.showRecommendLabel;
    musicItem.musicModel = model;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *url = [ACCVideoMusic() localURLForMusic:musicItem.musicModel];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[url path]] && !(publishModel.repoDraft.isDraft && [model.musicID isEqualToString:publishModel.repoMusic.music.musicID])) {
        musicItem.musicModel.loaclAssetUrl = url;
        if (model.lyricUrl.length > 0) {
            NSURL *localLyricURL = [ACCVideoMusic() localLyricURLForMusic:model];
            if ([fileManager fileExistsAtPath:[localLyricURL path]]) {
                musicItem.localLyricURL = localLyricURL;
                musicItem.status = AWEPhotoMovieMusicStatusDownloaded;
                musicItem.startTime = model.previewStartTime + startTime;
            } else {
                musicItem.status = AWEPhotoMovieMusicStatusNotDownload;
            }
        } else {
            musicItem.status = AWEPhotoMovieMusicStatusDownloaded;
        }
    } else if (publishModel.repoDraft.isDraft && [model.musicID isEqualToString:publishModel.repoMusic.music.musicID]) {
        //变声不会对audioAsset添加音效资源，选择音乐后和常规拍摄后的audioAssets内容一致均只有一个audioAsset资源
        //合拍抢镜audioAsset保存了合拍与被合拍的mp4，无选择音乐入口且即使选择了带音乐的道具或者挑战也不会应用音乐
        //配音用LV新框架，LV新框架下videoData的audioAsset的第一个段音频不能当做音乐资源，将draft.bgmURL转换为publishModel的bgmAsset
        //老框架下若选择了音乐默认audioAsset第一段为音乐资源，更换音乐则replace掉audioAssets中的音乐asset，详情见IESMMRecoder[-setMusicWithURL]];因此在新框架下可使用bgmAsset的URL，老框架下使用第一段audioAsset的localAssetURL作为musicModel的localAssetURL，此处参考AWEVideoRouter.m line-2086，ACCRecordSelectMusicComponent[-musicAsset]等
        AVURLAsset *asset = (AVURLAsset *)publishModel.repoMusic.bgmAsset;
        if ([asset respondsToSelector:@selector(URL)]) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:[asset.URL path]]) {
                musicItem.status = AWEPhotoMovieMusicStatusDownloaded;
                musicItem.musicModel.loaclAssetUrl = asset.URL;;
            } else {
                musicItem.status = AWEPhotoMovieMusicStatusNotDownload;
            }
        }
    } else {
        musicItem.status = AWEPhotoMovieMusicStatusNotDownload;
    }
    return musicItem;
}

#pragma mark - public

+ (NSMutableArray <AWEMusicSelectItem *> *)itemsForMusicList:(NSArray<id<ACCMusicModelProtocol>> *)musicList currentPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    return [self itemsForMusicList:musicList currentPublishModel:publishModel musicListExiestMusicOnTop:YES];
}

+ (NSMutableArray <AWEMusicSelectItem *> *)itemsForMusicList:(NSArray<id<ACCMusicModelProtocol>> *)musicList currentPublishModel:(AWEVideoPublishViewModel *)publishModel musicListExiestMusicOnTop:(BOOL)musicOnTop {
    id<ACCMusicModelProtocol> currentMusic = publishModel.repoMusic.music;
    BOOL canTransMusicItem = [self canTransMusicItem:currentMusic];
    
    NSMutableArray *result = [NSMutableArray new];
    __block NSInteger selectedMusicIndex = -1;
    [musicList enumerateObjectsUsingBlock:^(id<ACCMusicModelProtocol> music, NSUInteger idx, BOOL * _Nonnull stop) {
        CGFloat musicStartTime = 0;
        if ([music.musicID isEqualToString:currentMusic.musicID] && [currentMusic.musicID length]) {
            selectedMusicIndex = idx;
            musicStartTime = publishModel.repoMusic.audioRange.location;
        }
        AWEMusicSelectItem *musicItem = [self musicItemForModel:music currentPublishModel:publishModel musicStartTime:musicStartTime];
        if (musicItem != nil) {
            [result addObject:musicItem];
        }
    }];
    if (selectedMusicIndex > 0 && musicOnTop) { // 音乐列表中已存在的音乐是否需要置顶
        AWEMusicSelectItem *item = result[selectedMusicIndex];
        [result removeObjectAtIndex:selectedMusicIndex];
        [result insertObject:item atIndex:0];
    } else if (selectedMusicIndex < 0 && canTransMusicItem) {
        if (currentMusic.isLocalScannedMedia) {
            AWEMusicSelectItem *musicItem = [self musicItemForLocalMusicModel:currentMusic currentPublishModel:publishModel];
            [result btd_insertObject:musicItem atIndex:0];
        } else {
            AWEMusicSelectItem *musicItem = [self musicItemForModel:currentMusic currentPublishModel:publishModel musicStartTime:0];
            [result btd_insertObject:musicItem atIndex:0];
        }
    }
    return result;
}

@end
