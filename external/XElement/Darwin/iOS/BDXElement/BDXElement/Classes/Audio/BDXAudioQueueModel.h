//
//  BDXAudioQueueModel.h
//  BDXElement-Pods-BDXme
//
//  Created by DylanYang on 2020/9/28.
//

#import <Foundation/Foundation.h>
#import "BDXAudioModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BDXAudioPlayerQueueLoopMode) {
    BDXAudioPlayerQueueLoopModeDefault,
    BDXAudioPlayerQueueLoopModeSingle,
    BDXAudioPlayerQueueLoopModeList,
    BDXAudioPlayerQueueLoopModeShuffle,     // 暂不支持
};

@interface BDXAudioQueueModel : NSObject

@property (nonatomic, strong, readonly) NSString *queueID;
@property (nonatomic, strong, readonly) BDXAudioModel *currentPlayModel;
@property (nonatomic, strong, readonly) NSArray<BDXAudioModel*> *playModelArray;
@property (nonatomic, assign, readonly) NSInteger currentIndex;
@property (nonatomic, assign) BDXAudioPlayerQueueLoopMode loopMode;

@property (nonatomic, assign) BOOL isBackground;

- (BOOL)canGoPrev;
- (BOOL)canGoNext;

- (void)goPrev;
- (void)goNext;

- (instancetype)initWithModels:(NSArray<BDXAudioModel *> *)models queueId:(NSString *)queueId;
- (BOOL)updateCurrentModel:(BDXAudioModel *)model;
- (void)appendAudioModels:(nonnull NSArray<BDXAudioModel *> *)models;

@end

NS_ASSUME_NONNULL_END
