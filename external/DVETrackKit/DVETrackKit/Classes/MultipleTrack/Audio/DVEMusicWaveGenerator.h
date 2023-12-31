//
//  DVEMusicWaveGenerator.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/28.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <NLEPlatform/NLEModel+iOS.h>
#import <NLEPlatform/NLEInterface.h>
#import <ReactiveObjC/ReactiveObjC.h>

typedef NS_ENUM(NSUInteger, DVEMusicWaveErrorCode) {
    DVEMusicWaveErrorGenerateWave,
    DVEMusicWaveErrorInvalidePath,
};

NS_ASSUME_NONNULL_BEGIN

@interface DVEMusicWaveGenerator : NSObject

+ (nullable instancetype)shared;

- (NSArray<NSNumber *> * _Nullable)generatePointsWithAsset:(AVURLAsset *)asset
                                                     count:(NSInteger)count;

- (NSArray<NSNumber *> * _Nullable)generatePointsWithPayload:(NLESegmentAudio_OC *)payload
                                                       count:(NSInteger)count
                                                        path:(NSString *)path;

- (RACSignal<NSArray<NSNumber *> *> *)generateWave:(NLESegmentAudio_OC *)payload
                                      requireCount:(NSInteger)requireCount
                                              path:(NSString *)path;

- (RACSignal<NSArray<NSNumber *> *> *)generateWave:(NSURL *)audioUrl
                                               fps:(NSInteger)fps;

@end

NS_ASSUME_NONNULL_END
