//
//  ACCVideoCommentStickerConfig.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/3/18.
//

#import "ACCVideoCommentStickerConfig.h"

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>

@interface ACCVideoCommentStickerConfig ()

@property (nonatomic, assign) ACCVideoCommentStickerConfigOptions options;

@end

@implementation ACCVideoCommentStickerConfig

- (instancetype)init
{
    return [self initWithOption:ACCVideoCommentStickerConfigOptionsNone];
}

- (instancetype)initWithOption:(ACCVideoCommentStickerConfigOptions)options
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
    
    if (self.options & ACCVideoCommentStickerConfigOptionsSelectTime) {
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
        [res addObject:[self deleteConfig]];
    }

    return [res copy];
}

@end
