//
//  AWEMusicSelectItem.h
//  AWEStudio
//
//  Created by Nero Li on 2019/1/11.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AWEPhotoMovieMusicStatus.h"

NS_ASSUME_NONNULL_BEGIN
@protocol ACCMusicModelProtocol;
@class AWELyricPattern;
@class AWEVideoPublishViewModel;
@interface AWEMusicSelectItem : NSObject
@property (nonatomic, assign) BOOL isRecommended;
@property (nonatomic, strong) id<ACCMusicModelProtocol> musicModel;
@property (nonatomic, assign) AWEPhotoMovieMusicStatus status;
@property (nonatomic, assign) BOOL fromLibrary;
@property (nonatomic, assign) NSTimeInterval startTime;
@property (nonatomic, assign, readonly) NSUInteger startLyricIndex;
@property (nonatomic, assign, readonly) NSTimeInterval songTimeLength;
@property (nonatomic, strong) NSArray <AWELyricPattern *> *lyrics;
@property (nonatomic, strong) NSURL *localLyricURL;
@property (nonatomic, assign, readonly) BOOL hasLyric;

+ (NSMutableArray <AWEMusicSelectItem *> *)itemsForMusicList:(NSArray<id<ACCMusicModelProtocol>> *)musicList currentPublishModel:(AWEVideoPublishViewModel *)publishModel musicListExiestMusicOnTop:(BOOL)musicOnTop;

+(NSMutableArray <AWEMusicSelectItem *> *)itemsForMusicList:(NSArray<id<ACCMusicModelProtocol>> *)musicList currentPublishModel :(nullable AWEVideoPublishViewModel *)publishModel;

+ (BOOL)canTransMusicItem:(id<ACCMusicModelProtocol>)music;

@end

NS_ASSUME_NONNULL_END
