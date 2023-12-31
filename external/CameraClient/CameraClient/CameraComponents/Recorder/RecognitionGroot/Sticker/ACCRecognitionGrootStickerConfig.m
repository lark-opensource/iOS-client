//
//  ACCRecognitionGrootStickerConfig.m
//  CameraClient-Pods-Aweme
//
//  Created by Ryan Yan on 2021/8/23.
//

#import "ACCRecognitionGrootStickerConfig.h"

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>

@interface ACCRecognitionGrootStickerConfig ()

@property (nonatomic, assign) ACCRecognitionGrootStickerConfigOptions options;

@end

@implementation ACCRecognitionGrootStickerConfig

- (instancetype)init
{
    return [self initWithOption:ACCRecognitionGrootStickerConfigOptionsNone];
}

- (instancetype)initWithOption:(ACCRecognitionGrootStickerConfigOptions)options
{
    self = [super init];
    if (self) {
        self.options = options;
        self.preferredContainerFeature = ACCStickerContainerFeatureAdsorbing | ACCStickerContainerFeatureAngleAdsorbing | ACCStickerContainerFeatureHighlightMoment | ACCStickerContainerFeatureSafeArea;
        self.supportGesture = ^BOOL(ACCStickerGestureType gestureType, id _Nullable contextId, UIGestureRecognizer *gestureRecognizer) {
            return YES;
        };
    }
    return self;
}

- (NSArray<ACCStickerBubbleConfig *> *)bubbleActionList
{
    NSMutableArray *res = [NSMutableArray array];
    
    if (self.options & ACCRecognitionGrootStickerConfigOptionsSelectTime) {
        ACCStickerBubbleConfig *selectTimeConfig = [[ACCStickerBubbleConfig alloc] init];
        selectTimeConfig.actionType = ACCStickerBubbleActionBizSelectTime;
        selectTimeConfig.callback = ^(ACCStickerBubbleAction actionType) {
            if (actionType == ACCStickerBubbleActionBizSelectTime) {
                ACCBLOCK_INVOKE(self.onSelectTimeCallback);
            }
        };
        [res acc_addObject:selectTimeConfig];
    }
    
    if ([self hasDeleteFeature] && self.deleteAction != nil) {
        [res acc_addObject:[self deleteConfig]];
    }

    return [res copy];
}

@end
