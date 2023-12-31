//
//  ACCRecordSwitchModeServiceImpl.m
//  CameraClient-Pods-Aweme
//
//  Created by guochenxiang on 2020/11/16.
//

#import "ACCRecordSwitchModeServiceImpl.h"
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/ACCMacros.h>

// AB
#import <CreationKitInfra/ACCConfigManager.h>
#import <CameraClient/ACCConfigKeyDefines.h>

#import <CreationKitRTProtocol/ACCCameraSubscription.h>
#import "ACCRecordContainerMode.h"
#import <CreationKitArch/ACCRepoFlowControlModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import "AWERecorderTipsAndBubbleManager.h"
#import <CameraClient/ACCRecordMode+LiteTheme.h>

@interface ACCRecordSwitchModeServiceImpl()

@property (nonatomic, strong, readwrite) ACCRecordMode *currentRecordMode;

@property (nonatomic, weak, readwrite) ACCRecordMode *changingToMode;

@property (nonatomic, strong, readwrite) NSMutableArray <ACCRecordMode *> *modeArray;

@property (nonatomic, copy, nullable, readwrite) NSArray<AWESwitchModeSingleTabConfig *> *tabConfigArray;

@property (nonatomic, strong) ACCCameraSubscription *subscription;
@property (nonatomic, strong) NSHashTable *lastSubscribers;

@end

@implementation ACCRecordSwitchModeServiceImpl

@synthesize currentRecordMode = _currentRecordMode;
@synthesize changingToMode = _changingToMode;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _modeArray = [NSMutableArray array];
        _lastSubscribers = [[NSHashTable alloc] initWithOptions:NSPointerFunctionsWeakMemory capacity:0];
    }
    return self;
}

- (void)setModeFactory:(id<ACCRecordModeFactory>)modeFactory
{
    _modeFactory = modeFactory;
    [[self.modeFactory displayModesArray] enumerateObjectsUsingBlock:^(ACCRecordMode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self addMode:obj];
    }];
}

- (void)addMode:(ACCRecordMode *)mode {
    if (mode == nil) {
        return;
    }
    
    if (mode.shouldShowBlock && !ACCBLOCK_INVOKE(mode.shouldShowBlock)) {
        return;
    }
    
    if (mode.isExclusive) {
        [self.modeArray removeAllObjects];
        [self.modeArray addObject:mode];
        [self notifyModeArrayChanged];
        return;
    }
    
    if ([self.modeArray containsObject:mode]) {
        return;
    }
    
    if (self.modeArray.count == 1 && self.modeArray.lastObject.isExclusive) {
        return;
    }
    
    [self.modeArray addObject:mode];
    [self notifyModeArrayChanged];
}

- (void)removeMode:(ACCRecordMode *)mode {
    if (mode == nil) {
        return;
    }
    
    if (mode.isExclusive) {
        return;
    }
    
    if (![self.modeArray containsObject:mode]) {
        return;
    }
    
    if (self.modeArray.count == 1) {
        return;
    }
    
    [self.modeArray removeObject:mode];
    [self notifyModeArrayChanged];
}

- (void)updateModesStartWithLengthMode:(ACCRecordLengthMode)lengthMode
{
}

- (void)recoverOriginalModes
{
}

- (void)notifyModeArrayChanged
{
    [self.subscription performEventSelector:@selector(modeArrayDidChanged) realPerformer:^(id<ACCRecordSwitchModeServiceSubscriber> subscriber) {
        [subscriber modeArrayDidChanged];
    }];
}

- (ACCRecordMode *)currentRecordMode
{
    if (_currentRecordMode == nil) {
        _currentRecordMode = [self initialRecordMode];
    }
    return _currentRecordMode;
}

#pragma mark - public

- (ACCRecordMode *)initialRecordMode
{
    NSAssert(self.modeArray.count > 0, @"No modes found, you should add mode first");
    
    if (self.modeArray.count == 1 && self.modeArray.lastObject.isExclusive) {
        return self.modeArray.lastObject;
    }
    
    ACCRecordMode *initialMode = [self.modeArray acc_match:^BOOL(ACCRecordMode * _Nonnull item) {
        // 特殊情况：如果item是属于ACCRecordContainerMode这类，item.isInitial == YES
        // 先检查一下是否它的submodes的isInitial也设置为YES
        // 如果没有的话，直接 return item.isInitial

        ACCRecordMode *matchedItem = item;
        if ([item isKindOfClass:[ACCRecordContainerMode class]]) {
            ACCRecordContainerMode *combinedMode = (ACCRecordContainerMode *)item;
            NSArray<ACCRecordMode *> *recordMode = combinedMode.submodes;
            for (int i = 0; i < recordMode.count; i++) {
                if (recordMode[i].isInitial) {
                    matchedItem = recordMode[i];
                    break;
                }
            }
        }
        return matchedItem.isInitial;
    }];
    
    return initialMode ?: self.modeArray.firstObject;
}

- (void)switchMode:(ACCRecordMode *)mode
{
    // before any subscriber's `WillChangeToMode:`
    self.changingToMode = mode;
    
    [self.subscription performEventSelector:@selector(switchModeServiceWillChangeToMode:oldMode:) realPerformer:^(id<ACCRecordSwitchModeServiceSubscriber> subscriber) {
        [subscriber switchModeServiceWillChangeToMode:mode oldMode:self.currentRecordMode];
    }];
    
    // reset to nil before `setCurrentRecordMode:`
    self.changingToMode = nil;
    
    ACCRecordMode *oldMode = self.currentRecordMode;
    self.currentRecordMode = mode;
    
    [self.subscription performEventSelector:@selector(switchModeServiceDidChangeMode:oldMode:) realPerformer:^(id<ACCRecordSwitchModeServiceSubscriber> subscriber) {
        [subscriber switchModeServiceDidChangeMode:mode oldMode:oldMode];
    }];
    
    // this is only for commerce use
    [[NSNotificationCenter defaultCenter] postNotificationName:ACCVideoRecorderViewControllerModeDidChange object:nil userInfo:@{
        ACCNotificationVideoRecorderViewControllerNewModeKey : @(mode.modeId),
        ACCNotificationVideoRecorderViewControllerOldModeKey : @(oldMode.modeId),
    }];
}

- (ACCRecordMode *)getRecordModeForIndex:(NSInteger)index
{
    NSAssert(self.modeArray.count > 0, @"No modes found, you should add mode first");
    
    if ([self.modeArray count] <= index) {
        index = [self.modeArray count] - 1;
    }
    
    if (index < 0) {
        index = 0;
    }

    return [self.modeArray objectAtIndex:index];
}

- (NSInteger)siblingsCountForRecordModeId:(NSInteger)recordModeId
{
    for (NSInteger idx = 0; idx < self.modeArray.count; idx++) {
        ACCRecordMode *mode = self.modeArray[idx];
        if ([mode isKindOfClass:[ACCRecordContainerMode class]]) {
            ACCRecordContainerMode *combinedMode = (ACCRecordContainerMode *)mode;
            NSArray<ACCRecordMode *> *recordModes = combinedMode.submodes;
            for (NSInteger i = 0; i < recordModes.count; i++) {
                if (recordModeId == recordModes[i].modeId) {
                    return recordModes.count;
                }
            }
        } else if (recordModeId == mode.modeId) {
            return self.modeArray.count;
        }
    }
    return 0;
}

- (NSInteger)getIndexForRecordModeId:(NSInteger)recordModeId
{
    NSInteger index = [self indexOfModeWithId:recordModeId];
    if (index == NSNotFound) {
        if (recordModeId == ACCRecordModeMixHoldTapLongVideoRecord || recordModeId == ACCRecordModeMixHoldTap15SecondsRecord) {
            index = [self indexOfModeWithId:ACCRecordModeCombined];
        }
    }
    return index;
}

- (BOOL)isInSegmentMode
{
    return [self isInSegmentMode:self.currentRecordMode];
}

- (BOOL)isInSegmentMode:(ACCRecordMode *)mode
{
    NSInteger modeId = mode.modeId;
    BOOL isInSegmentMode =
        modeId == ACCRecordModeMixHoldTap15SecondsRecord || modeId == ACCRecordModeMixHoldTapLongVideoRecord ||
        modeId == ACCRecordModeMixHoldTap60SecondsRecord || modeId == ACCRecordModeMixHoldTap3MinutesRecord;
    return isInSegmentMode;
}

- (BOOL)isVideoCaptureMode
{
    ACCRecordMode *mode = self.currentRecordMode;
    if (mode.modeId == ACCRecordModeAudio) {
        return NO;
    }
    return (mode.isPhoto || mode.isVideo) && (mode.additionIsVideoBlock ? mode.additionIsVideoBlock() : mode.modeId != ACCRecordModeTheme);
}

- (void)updateTabConfigForModeId:(NSInteger)modeId Block:(void (^)(AWESwitchModeSingleTabConfig * _Nonnull))updateBlock {
    for (AWESwitchModeSingleTabConfig *tabConfig in self.tabConfigArray) {
        if (tabConfig.recordModeId == modeId && updateBlock != nil) {
            updateBlock(tabConfig);
            [self.subscription performEventSelector:@selector(tabConfigDidUpdatedWithModeId:) realPerformer:^(id<ACCRecordSwitchModeServiceSubscriber> subscriber) {
                [subscriber tabConfigDidUpdatedWithModeId:modeId];
            }];
        }
    }
}

- (NSArray<AWESwitchModeSingleTabConfig *> *)tabConfigArray {
    NSMutableArray *tabConfigArray = [NSMutableArray array];
    [self.modeArray enumerateObjectsUsingBlock:^(ACCRecordMode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        AWESwitchModeSingleTabConfig *config = obj.tabConfig;
        if (config) {
            if (config) {
                [tabConfigArray addObject:config];
            }
        }
    }];
    _tabConfigArray = tabConfigArray.copy;
    return _tabConfigArray;
}


- (void)updateModeSelection:(BOOL)initial
{
    ACCRecordMode *recordMode = [self initialRecordMode];
    NSInteger index = [self getIndexForRecordModeId:recordMode.modeId];

    if ([self currentIsDraftOrBackup]) {
        if ([self.modeFactory respondsToSelector:@selector(modeWithButtonType:)]) {
            recordMode = [self.modeFactory modeWithButtonType:self.repository.repoFlowControl.videoRecordButtonType];
        }
        
        if ([self containsModeWithId:recordMode.modeId]) {
            index = [self indexOfModeWithId:recordMode.modeId];
        } else {
            // 如果现有的录制模式不包含存草稿时的录制模式，那么就是用初始的录制模式，所以要将recordMode恢复成初始的录制模式
            // ⚠️ 没有用到暂时注释掉
            //            recordMode = [self getRecordModeForIndex:index];
        }
    } else {
        if (recordMode.modeId == ACCRecordModeMixHoldTapRecord || recordMode.modeId == ACCRecordModeMixHoldTap15SecondsRecord || recordMode.modeId == ACCRecordModeMixHoldTapLongVideoRecord) {
            self.repository.repoFlowControl.videoRecordButtonType = recordMode.buttonType;
        }
    }
    
    [self.subscription performEventSelector:@selector(didUpdatedSelectedIndex:isInitial:) realPerformer:^(id<ACCRecordSwitchModeServiceSubscriber> subscriber) {
        [subscriber didUpdatedSelectedIndex:index isInitial:initial];
    }];
}

- (void)switchToLengthMode:(ACCRecordLengthMode)lengthMode
{
    BOOL isStory = self.currentRecordMode.isStoryStyleMode;
    
    // 非快拍模式 || 快拍模式下命中相机高级设置面板实验
    BOOL needShowTip = !isStory || (isStory && ACCConfigBool(kConfigBool_tools_shoot_advanced_setting_panel));
    
    [AWERecorderTipsAndBubbleManager shareInstance].actureRecordBtnMode = lengthMode;
    self.repository.repoContext.videoLenthMode = lengthMode;
    [self.videoConfig updateCurrentVideoLenthMode:lengthMode];
    [self.configService configPublishModelMaxDurationWithAsset:self.repository.repoMusic.musicAsset showRecordLengthTipBlock:needShowTip isFirstEmbed:NO];
    [self.subscription performEventSelector:@selector(lengthModeDidChanged) realPerformer:^(id<ACCRecordSwitchModeServiceSubscriber> subscriber) {
        [subscriber lengthModeDidChanged];
    }];
}

#pragma mark - private

//当前是草稿、备份
- (BOOL)currentIsDraftOrBackup
{
    return self.repository.repoDraft.isDraft || self.repository.repoDraft.isBackUp;
}

- (BOOL)containsModeWithId:(NSInteger)modeId
{
    ACCRecordMode *mode = [self.modeArray acc_match:^BOOL(ACCRecordMode * _Nonnull item) {
        ACCRecordMode *matchedItem = item;
        if ([item isKindOfClass:[ACCRecordContainerMode class]]) {
            ACCRecordContainerMode *combinedMode = (ACCRecordContainerMode *)item;
            NSArray<ACCRecordMode *> *recordMode = combinedMode.submodes;
            for (int i = 0; i < recordMode.count; i++) {
                if (recordMode[i].modeId == modeId) {
                    matchedItem = recordMode[i];
                    break;
                }
            }
            // if id not match submodes in container mode, will compare the real mode id of container.
            if (matchedItem == item) {
                return combinedMode.realModeId == modeId;
            }
        }
        return matchedItem.modeId == modeId;
    }];
    return mode != nil;
}

- (NSInteger)indexOfModeWithId:(NSInteger)modeId
{
    __block NSInteger index = NSNotFound;
    [self.modeArray enumerateObjectsUsingBlock:^(ACCRecordMode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {

        // self.modeArray = [ACCRecordMode, ACCRecordContainerMode, ACCRecordMode, ACCRecordMode, .... ]
        // 先检查obj是否属于ACCRecordContainerMode这类
        // 例如：分段拍是属于ACCRecordContainerMode，里面有分成三种videoLengtMode = [3分钟, 60秒, 15秒]

        if ([obj isKindOfClass:[ACCRecordContainerMode class]]) {
            ACCRecordContainerMode *combinedMode = (ACCRecordContainerMode *)obj;
            NSArray<ACCRecordMode *> *recordMode = combinedMode.submodes;
            for (int i = 0; i < recordMode.count; i++) {
                if (recordMode[i].modeId == modeId) {
                    index = idx;
                    *stop = YES;
                    break;
                }
            }
        } else if (obj.modeId == modeId) {
            index = idx;
            *stop = YES;
        }
    }];
    return index;
}

#pragma mark - subscription

- (ACCCameraSubscription *)subscription
{
    if (!_subscription) {
        _subscription = [[ACCCameraSubscription alloc] init];
    }
    return _subscription;
}

- (void)addSubscriber:(id<ACCRecordSwitchModeServiceSubscriber>)subscriber
{
    [self.subscription addSubscriber:subscriber];
    
    if (self.lastSubscribers.count > 0 && ![self isLastSubscriber:subscriber]) {
        for (id<ACCRecordSwitchModeServiceSubscriber> subscriber in self.lastSubscribers) {
            [self.subscription removeSubscriber:subscriber];
            [self.subscription addSubscriber:subscriber];
        }
    }
    
    if ([self isLastSubscriber:subscriber]) {
        [self.lastSubscribers addObject:subscriber];
    }
}

- (BOOL)isLastSubscriber:(id<ACCRecordSwitchModeServiceSubscriber>)subscriber
{
    if ([subscriber respondsToSelector:@selector(shouldCalledLast)] && [subscriber shouldCalledLast]) {
        return YES;
    }
    return NO;
}


@end


