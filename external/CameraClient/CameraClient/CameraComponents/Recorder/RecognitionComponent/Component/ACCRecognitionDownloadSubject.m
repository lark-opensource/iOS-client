//
//  ACCRecognitionDownloadSubject.m
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/7/7.
//

#import "ACCRecognitionDownloadSubject.h"
#import <CameraClient/AWEStickerDownloadManager.h>
#import <CameraClient/IESEffectModel+CustomSticker.h>

@interface ACCRecognitionDownloadSubject()<AWEStickerDownloadObserverProtocol>
@property (nonatomic, strong) NSMutableDictionary<NSString *,RACSubject *>*progressSignals;
@property (nonatomic, strong) NSMutableDictionary<NSString *,RACSubject *>*resultSignals;
@end

@implementation ACCRecognitionDownloadSubject

- (instancetype)init
{
    if (self = [super init]){
        _progressSignals = [NSMutableDictionary new];
        _resultSignals = [NSMutableDictionary new];
        [[AWEStickerDownloadManager manager] addObserver:self];
    }
    return self;
}

- (void)willRelease
{
    [[AWEStickerDownloadManager manager] removeObserver:self];
    [_progressSignals enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, RACSubject * _Nonnull obj, BOOL * _Nonnull stop) {
        [obj sendCompleted];
    }];

    [_resultSignals enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, RACSubject * _Nonnull obj, BOOL * _Nonnull stop) {
        [obj sendCompleted];
    }];
}

- (nullable RACSignal *)progressSignalForEffect:(IESEffectModel *)effect
{
    if (effect.effectIdentifier.length == 0) return nil;

    RACSubject *sub = [self.progressSignals valueForKey:effect.effectIdentifier];
    if (!sub){
        sub = [RACSubject subject];
        [self.progressSignals setValue:sub forKey:effect.effectIdentifier];
    }
    return sub;

}
- (nullable RACSignal *)resultSignalForEffect:(IESEffectModel *)effect
{
    if (effect.effectIdentifier.length == 0) return nil;

    RACSubject *sub = [self.resultSignals valueForKey:effect.effectIdentifier];
    if (!sub){
        sub = [RACSubject subject];
        [self.resultSignals setValue:sub forKey:effect.effectIdentifier];
    }
    return sub;
}

- (void)downloadEffect:(IESEffectModel *)effect
{
    if (effect.downloaded){
        [self finishDownloadEffect:effect];
        return;
    }

    [self.progressSignals[effect.effectIdentifier] sendNext:[[AWEStickerDownloadManager manager] stickerDownloadProgress:effect]?:@(0)];

    [[AWEStickerDownloadManager manager] downloadStickerIfNeed:effect];

}

- (void)finishDownloadEffect:(IESEffectModel *)effect
{
    [self.progressSignals[effect.effectIdentifier] sendNext:@1];
    [self.resultSignals[effect.effectIdentifier] sendNext:@YES];
    [self.progressSignals[effect.effectIdentifier] sendCompleted];
    [self.resultSignals[effect.effectIdentifier] sendCompleted];

    [self.progressSignals removeObjectForKey:effect.effectIdentifier];
    [self.resultSignals removeObjectForKey:effect.effectIdentifier];
}

#pragma mark - AWEStickerDownloadObserverProtocol

- (void)stickerDownloadManager:(AWEStickerDownloadManager *)manager sticker:(IESEffectModel *)effect downloadProgressChange:(CGFloat)progress
{
    [self.progressSignals[effect.effectIdentifier] sendNext:@(progress)];
}

- (void)stickerDownloadManager:(AWEStickerDownloadManager *)manager didFinishDownloadSticker:(IESEffectModel *)effect
{
    [self finishDownloadEffect:effect];
}

- (void)stickerDownloadManager:(AWEStickerDownloadManager *)manager didFailDownloadSticker:(IESEffectModel *)effect withError:(NSError *)error
{
    [self.progressSignals[effect.effectIdentifier] sendError:error];
    [self.resultSignals[effect.effectIdentifier] sendError:error];
    [self.progressSignals removeObjectForKey:effect.effectIdentifier];
    [self.resultSignals removeObjectForKey:effect.effectIdentifier];
}

@end
