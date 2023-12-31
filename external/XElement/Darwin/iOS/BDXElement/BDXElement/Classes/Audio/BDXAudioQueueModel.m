//
//  BDXAudioQueueModel.m
//  BDXElement-Pods-BDXme
//
//  Created by DylanYang on 2020/9/28.
//

#import "BDXAudioQueueModel.h"
#import <ByteDanceKit/NSArray+BTDAdditions.h>

@implementation BDXAudioQueueModel

#pragma mark - Public
- (instancetype)initWithModels:(NSArray<BDXAudioModel *> *)models queueId:(NSString *)queueId {
    self = [super init];
    if (self) {
        _queueID = queueId;
        [self setupWithModels:models];
    }
    return self;
}

- (BOOL)canGoPrev;
{
    if (self.loopMode == BDXAudioPlayerQueueLoopModeDefault) {
        if (self.currentIndex == 0) {
            return NO;
        }
    }
    
    if (self.playModelArray.count == 0) {
        return NO;
    }
    
    if ([self findModelWithStep:-1] == nil) {
        return NO;
    }
    
    return YES;
}

- (BOOL)canGoNext;
{
    if (self.loopMode == BDXAudioPlayerQueueLoopModeDefault) {
        if (self.currentIndex >= self.playModelArray.count-1) {
            return NO;
        }
    }
    
    if (self.playModelArray.count == 0) {
        return NO;
    }
    
    if ([self findModelWithStep:+1] == nil) {
        return NO;
    }
    
    return YES;
}

- (void)goPrev;
{
    BDXAudioModel *findM = [self findModelWithStep:-1];
    if (findM) {
        _currentPlayModel = findM;
        _currentIndex = [self.playModelArray indexOfObject:self.currentPlayModel];
    } else {
        return;
    }
}

- (void)goNext;
{
    BDXAudioModel *findM = [self findModelWithStep:+1];
    if (findM) {
        _currentPlayModel = findM;
        _currentIndex = [self.playModelArray indexOfObject:self.currentPlayModel];
    } else {
        return;
    }
}

- (BOOL)updateCurrentModel:(BDXAudioModel *)model {
    if (!model) {
        return NO;
    }
    BOOL contained = [self.playModelArray btd_contains:^BOOL(BDXAudioModel * _Nonnull obj) {
        if ([obj.modelId isEqualToString:model.modelId]) {
            return YES;
        }
        else {
            return NO;
        }
    }];
    
    if (!contained) {
        return NO;
    }
    if (!model.isVerified) {
        return NO;
    }
    
    __block NSInteger currentIdx = NSNotFound;
    [self.playModelArray enumerateObjectsUsingBlock:^(BDXAudioModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.modelId isEqualToString:model.modelId]) {
            currentIdx = idx;
            _currentPlayModel = obj;
        }
    }];
    
    if (currentIdx == NSNotFound) {
        return NO;
    } else {
        _currentIndex = currentIdx;
    }
    return YES;
}

- (void)appendAudioModels:(nonnull NSArray<BDXAudioModel *> *)models {
    if (!models) {
        return;
    }
    if (!self.playModelArray) {
        [self setupWithModels:models];
    }
    NSMutableArray * arr = [self.playModelArray mutableCopy];
    [arr addObjectsFromArray:models];
    _playModelArray = arr;
}

#pragma mark - Private
- (BDXAudioModel* _Nullable)findModelWithStep:(NSInteger)step
{
    NSInteger count = self.playModelArray.count;
    BDXAudioModel *findM = nil;
    for (int i = 1; i <= count; i++) {
        int j = (int)((self.currentIndex + i*step + count) % count);
        BDXAudioModel *m = [self.playModelArray btd_objectAtIndex:j];
        if (!self.isBackground || m.canBackgroundPlay) {
            findM = m;
            break;
        }
    }

    return findM;
}

- (void)setupWithModels:(NSArray<BDXAudioModel *> *)models {
    if (!models || models.count == 0) {
        return;
    }
    _playModelArray = models;
    _currentPlayModel = models.firstObject;
    _currentIndex = 0;
}

@end
