//
//  ACCInfoStickerViewModel.m
//  Pods
//
//  Created by liyingpeng on 2020/7/30.
//

#import "AWERepoContextModel.h"
#import "ACCInfoStickerViewModel.h"
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import <CreationKitArch/ACCChallengeModelProtocol.h>
#import <CreationKitArch/ACCModelFactoryServiceProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CameraClient/AWERepoStickerModel.h>
#import <CreationKitArch/AWEInfoStickerInfo.h>
#import <CreativeKit/NSArray+ACCAdditions.h>

@interface ACCInfoStickerViewModel ()

@property (nonatomic, strong) RACSubject *addStickerFinishedSubject;

@end

@implementation ACCInfoStickerViewModel

- (void)dealloc
{
    [_addStickerFinishedSubject sendCompleted];
}

- (void)finishAddingStickerWithContext:(ACCAddInfoStickerContext *)context
{
    [self.addStickerFinishedSubject sendNext:context];
}

- (void)configChallengeInfo:(IESEffectModel *)sticker {
    if (sticker.challengeID.length <= 0) {
        return;
    }
    
    AWEInfoStickerInfo *info = [AWEInfoStickerInfo new];
    info.challengeID = sticker.challengeID;
    info.stickerID = sticker.effectIdentifier;
    [self.repository.repoSticker.infoStickerArray addObject:info];
    [[NSNotificationCenter defaultCenter] postNotificationName:ACCVideoChallengeChangeKey object:nil];
}

- (NSArray<id<ACCChallengeModelProtocol>> *)currentBindChallenges
{
    if (self.repository.repoContext.isIMRecord) {
        return nil;
    }
    
    NSMutableArray <id<ACCChallengeModelProtocol>> *challenges = [NSMutableArray array];
    [[self.repository.repoSticker.infoStickerArray copy] enumerateObjectsUsingBlock:^(AWEInfoStickerInfo * obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!ACC_isEmptyString(obj.challengeID)) {
            id<ACCChallengeModelProtocol> challengeModel = [self.factoryService createChallengeModelWithItemID:obj.challengeID challengeName:obj.challengeName];
            [challenges acc_addObject:challengeModel];
        }
    }];
    return [challenges copy];
}

- (void)fillChallengeDetailWithChallenge:(id<ACCChallengeModelProtocol>)challenge
{
    [[self.repository.repoSticker.infoStickerArray copy] enumerateObjectsUsingBlock:^(AWEInfoStickerInfo * obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (ACC_isEmptyString(obj.challengeName) &&
            [obj.challengeID isEqualToString:challenge.itemID]) {
            obj.challengeName = challenge.challengeName;
        }
    }];
}

#pragma mark - getter

- (NSMutableDictionary<NSString *,NSString *> *)cacheStickerChallengeNameDict
{
    if (!_cacheStickerChallengeNameDict) {
        _cacheStickerChallengeNameDict = [NSMutableDictionary dictionary];
    }
    return _cacheStickerChallengeNameDict;
}

- (RACSignal<ACCAddInfoStickerContext *> *)addStickerFinishedSignal
{
    return self.addStickerFinishedSubject;
}

- (RACSubject *)addStickerFinishedSubject
{
    if (!_addStickerFinishedSubject) {
        _addStickerFinishedSubject = [RACSubject subject];
    }
    return _addStickerFinishedSubject;
}

@end
