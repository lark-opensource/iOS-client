//
//  NLEBingoManager.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/5/23.
//

#import <Foundation/Foundation.h>
#import "NLEClipBeatResult.h"
#if __has_include(<TTVideoEditor/IESMMBingoManager.h>)
#import <TTVideoEditor/IESMMBingoManager.h>

NS_ASSUME_NONNULL_BEGIN

/*
 ---------- 供业务侧音乐卡点调用 ----------
 */

@interface NLEBingoManager : NSObject

- (void)setMusic:(NSString *)musicPath;

- (void)changeMusic:(NSTimeInterval)startTime
           duration:(NSTimeInterval)duration
         completion:(void (^)(int))completion;

- (void)setStoredBeats:(IESMMBingoBeats *)beats
            completion:(void (^)(int))completion;

- (void)insertPic:(NSString *)picPath
      picDuration:(float)picDuration
              pos:(int)pos
       completion:(void (^)(NSString * _Nonnull))completion;

- (void)insertVideo:(NSString *)videoPath
                pos:(int)pos
         completion:(void (^)(NSString * _Nonnull))completion;

- (void)deleteVideoWithPos:(NSInteger)pos
                completion:(void (^)(bool))completion;

- (void)moveVideoInPos:(NSInteger)oldPos
                 toPos:(NSInteger)newPos
            completion:(void (^)(bool))completion;

- (void)generateVideo:(NSString *)key
                range:(CMTimeRange)range
             interval:(NSTimeInterval)interval
             progress:(void (^)(float))progress
           completion:(IESMMBingoGenertorBlock)completion;

- (void)cancleGenerateVideo:(NSString *)key;

- (void)getRandomReslove:(void (^)(NLEClipBeatResult *))completion;

- (void)getReslove:(void (^)(NLEClipBeatResult *))completion;

- (AVPlayerItem *)makeItemWithVideodata:(HTSVideoData *)videoData;

- (int)saveInterimScoresToFile:(NSString *)filePath;

- (int)checkScoreFile:(NSString *)filePath;

@end

NS_ASSUME_NONNULL_END


#endif
