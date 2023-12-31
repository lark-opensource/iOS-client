//
//  ACCEditLyricStickerViewModel.m
//  Pods
//
//  Created by liyingpeng on 2020/8/7.
//

#import "ACCEditLyricStickerViewModel.h"
#import <CreationKitArch/ACCMusicModelProtocol.h>

#import <TTVideoEditor/IESInfoSticker.h>
#import <CameraClient/AWERepoVideoInfoModel.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>

@interface ACCEditLyricStickerViewModel ()

@property (nonatomic, strong) RACSubject *addClipViewSubject;
@property (nonatomic, strong) RACSubject *showClipViewSubject;
@property (nonatomic, strong) RACSubject<RACTwoTuple<NSValue *, NSNumber *> *> *didFinishCutMusicSubject;

@property (nonatomic, strong) RACSubject<id<ACCMusicModelProtocol>> *didSelectMusicSubject;

@property (nonatomic, strong) RACSubject *updateMusicRelateUISubject;
@property (nonatomic, strong) RACSubject<NSNumber *> *updateLyricsStickerButtonSubject;

@property (nonatomic, strong, readwrite) RACSignal *willShowLyricMusicSelectPanelSignal;
@property (nonatomic, strong, readwrite) RACSubject *willShowLyricMusicSelectPanelSubject;

@property (nonatomic, strong, readwrite) RACSignal *didCancelLyricMusicSelectSignal;
@property (nonatomic, strong, readwrite) RACSubject *didCancelLyricMusicSelectSubject;

@end

@implementation ACCEditLyricStickerViewModel

- (instancetype)initWithRepositry:(AWEVideoPublishViewModel *)repositry
{
    self = [super init];
    if (self) {
        _repository = repositry;
    }
    return self;
}

- (void)dealloc
{
    [_addClipViewSubject sendCompleted];
    [_showClipViewSubject sendCompleted];
    [_didFinishCutMusicSubject sendCompleted];
    [_didSelectMusicSubject sendCompleted];
    [_updateMusicRelateUISubject sendCompleted];
    [_updateLyricsStickerButtonSubject sendCompleted];
    [_willShowLyricMusicSelectPanelSubject sendCompleted];
    [_didCancelLyricMusicSelectSubject sendCompleted];
}

#pragma mark - Public

- (BOOL)hasAlreadyAddLyricSticker
{
    return [self.repository.repoVideoInfo.video.infoStickers btd_contains:^BOOL(IESInfoSticker * _Nonnull obj) {
        return obj.isSrtInfoSticker;
    }];
}

- (void)sendAddClipViewSignal
{
    [self.addClipViewSubject sendNext:nil];
}

- (void)sendShowClipViewSignal
{
    [self.showClipViewSubject sendNext:nil];
}

- (void)sendDidFinishCutMusicSignal:(HTSAudioRange)range repeatCount:(NSInteger)repeatCount
{
    [self.didFinishCutMusicSubject sendNext:RACTuplePack(@(range), @(repeatCount))];
}

- (void)sendDidSelectMusicSignal:(id<ACCMusicModelProtocol>)music
{
    [self.didSelectMusicSubject sendNext:music];
}

- (void)sendUpdateMusicRelateUISignal
{
    [self.updateMusicRelateUISubject sendNext:nil];
}

- (void)sendUpdateLyricsStickerButtonSignal:(ACCMusicPanelLyricsStickerButtonChangeType)changeType
{
    [self.updateLyricsStickerButtonSubject sendNext:@(changeType)];
}

- (void)sendWillShowLyricMusicSelectPanelSignal
{
    [self.willShowLyricMusicSelectPanelSubject sendNext:nil];
}

- (void)sendDidCancelLyricMusicSelectSignal
{
    [self.didCancelLyricMusicSelectSubject sendNext:nil];
}

#pragma mark - Getters

- (RACSignal *)addClipViewSignal
{
    return self.addClipViewSubject;
}

- (RACSubject *)addClipViewSubject
{
    if (!_addClipViewSubject) {
        _addClipViewSubject = [RACSubject subject];
    }
    return _addClipViewSubject;
}

- (RACSignal *)showClipViewSignal
{
    return self.showClipViewSubject;
}

- (RACSubject *)showClipViewSubject
{
    if (!_showClipViewSubject) {
        _showClipViewSubject = [RACSubject subject];
    }
    return _showClipViewSubject;
}

- (RACSignal<RACTwoTuple<NSValue *, NSNumber *> *> *)didFinishCutMusicSignal
{
    return self.didFinishCutMusicSubject;
}

- (RACSubject *)didFinishCutMusicSubject
{
    if (!_didFinishCutMusicSubject) {
        _didFinishCutMusicSubject = [RACSubject subject];
    }
    return _didFinishCutMusicSubject;
}

- (RACSignal<id<ACCMusicModelProtocol>> *)didSelectMusicSignal
{
    return self.didSelectMusicSubject;
}

- (RACSubject<id<ACCMusicModelProtocol>> *)didSelectMusicSubject
{
    if (!_didSelectMusicSubject) {
        _didSelectMusicSubject = [RACSubject subject];
    }
    return _didSelectMusicSubject;
}

- (RACSignal *)updateMusicRelateUISignal
{
    return self.updateMusicRelateUISubject;
}

- (RACSubject *)updateMusicRelateUISubject
{
    if (!_updateMusicRelateUISubject) {
        _updateMusicRelateUISubject = [RACSubject subject];
    }
    return _updateMusicRelateUISubject;
}

- (RACSignal<NSNumber *> *)updateLyricsStickerButtonSignal
{
    return self.updateLyricsStickerButtonSubject;
}

- (RACSubject<NSNumber *> *)updateLyricsStickerButtonSubject
{
    if (!_updateLyricsStickerButtonSubject) {
        _updateLyricsStickerButtonSubject = [RACSubject subject];
    }
    return _updateLyricsStickerButtonSubject;
}

- (RACSignal *)willShowLyricMusicSelectPanelSignal
{
    return self.willShowLyricMusicSelectPanelSubject;
}

- (RACSubject *)willShowLyricMusicSelectPanelSubject
{
    if (!_willShowLyricMusicSelectPanelSubject) {
        _willShowLyricMusicSelectPanelSubject = [RACSubject subject];
    }
    return _willShowLyricMusicSelectPanelSubject;
}

- (RACSignal *)didCancelLyricMusicSelectSignal
{
    return self.didCancelLyricMusicSelectSubject;
}

- (RACSubject *)didCancelLyricMusicSelectSubject
{
    if (!_didCancelLyricMusicSelectSubject) {
        _didCancelLyricMusicSelectSubject = [RACSubject subject];
    }
    return _didCancelLyricMusicSelectSubject;
}

@end
