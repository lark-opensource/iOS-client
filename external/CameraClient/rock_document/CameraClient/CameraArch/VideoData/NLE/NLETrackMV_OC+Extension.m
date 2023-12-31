//
//  NLETrackMV_OC+Extension.m
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2021/5/21.
//

#import "NLETrackMV_OC+Extension.h"
#import "NLEResourceAV_OC+Extension.h"
#import "NLETrackSlot_OC+Extension.h"
#import <CreativeKit/NSArray+ACCAdditions.h>

@implementation NLETrackMV_OC (Extension)

+ (instancetype)mvTrackWithPath:(NSString *)modelPath
                  userResources:(NSArray<IESMMMVResource *> *)resources
              resourcesDuration:(nullable NSArray *)resourcesDuration
                    draftFolder:(NSString *)draftFolder
{
    NLETrackMV_OC *mvTrack = [[NLETrackMV_OC alloc] init];
    [mvTrack updateWithModelPath:modelPath
                   userResources:resources
               resourcesDuration:resourcesDuration
                     draftFolder:draftFolder];
    return mvTrack;
}

- (void)updateWithModelPath:(NSString *)modelPath
              userResources:(NSArray<IESMMMVResource *> *)resources
          resourcesDuration:(nullable NSArray *)resourcesDuration
                draftFolder:(NSString *)draftFolder
{
    // 沙盒路径存储绝对路径
    NLEResourceNode_OC *mv = [[NLEResourceNode_OC alloc] init];
    mv.resourceFile = modelPath;

    self.mv = mv;
    self.mainTrack = YES;
    
    // 资源需要拷贝，存储相对路径
    [self setResources:resources resourcesDuration:resourcesDuration draftFolder:draftFolder];
}

- (void)setResources:(NSArray<IESMMMVResource *> *)resources
   resourcesDuration:(nullable NSArray *)resouresDuration
         draftFolder:(NSString *)draftFolder
{
    [self.slots acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        [self removeSlot:obj];
    }];
    
    BOOL useDefaultDuration = (resouresDuration.count != resources.count);
    __block CGFloat startTime = 0;
    [resources acc_forEachWithIndex:^(IESMMMVResource * _Nonnull obj, NSUInteger index) {
        NLETrackSlot_OC *trackSlot = [NLETrackSlot_OC mvTrackSlotWithResouce:obj
                                                                 draftFolder:draftFolder];
        if (useDefaultDuration) {
            trackSlot.startTime = ACCCMTimeMakeSeconds(index * kACCMVDefaultSecond);
            trackSlot.endTime = ACCCMTimeMakeSeconds((index + 1) * kACCMVDefaultSecond);
        } else {
            trackSlot.startTime = ACCCMTimeMakeSeconds(startTime);
            
            CGFloat endTime = startTime + [resouresDuration[index] floatValue];
            trackSlot.endTime = ACCCMTimeMakeSeconds(endTime);
            startTime = endTime;
        }
        [self addSlot:trackSlot];
    }];
}

- (void)configAlgorithmPath:(NSString *)algorithmPath {
    // 沙盒路径存储绝对路径
    NLEResourceNode_OC *algorithm = [[NLEResourceNode_OC alloc] init];
    algorithm.resourceFile = algorithmPath;
    self.algorithm = algorithm;
}

@end
