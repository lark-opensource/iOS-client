//
//  ACCVideoReplyStickerConfig.m
//  CameraClient-Pods-Aweme
//
//  视频评论视频
//
//  Created by Daniel on 2021/7/27.
//

#import "ACCVideoReplyStickerConfig.h"

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>

@interface ACCVideoReplyStickerConfig ()

@property (nonatomic, assign) ACCVideoReplyStickerConfigOptions options;

@end

@implementation ACCVideoReplyStickerConfig

- (instancetype)initWithOption:(ACCVideoReplyStickerConfigOptions)options
{
    self = [super init];
    if (self) {
        self.options = options;
        self.preferredContainerFeature = ACCStickerContainerFeatureAdsorbing | ACCStickerContainerFeatureAngleAdsorbing | ACCStickerContainerFeatureHighlightMoment | ACCStickerContainerFeatureSafeArea;
        self.supportGesture = ^BOOL(ACCStickerGestureType gestureType, id _Nullable contextId, UIGestureRecognizer *gestureRecognizer) {
            return YES;
        };
        self.typeId = ACCStickerTypeIdVideoReply;
        self.hierarchyId = @(ACCStickerHierarchyTypeMediumHigh);
        self.minimumScale = 0.6;
    }
    return self;
}

- (NSArray<ACCStickerBubbleConfig *> *)bubbleActionList
{
    NSMutableArray *res = [NSMutableArray array];
    
    if (self.options & ACCVideoReplyStickerConfigOptionsPreview) {
        ACCStickerBubbleConfig *watchVideoConfig = [[ACCStickerBubbleConfig alloc] init];
        watchVideoConfig.actionType = ACCStickerBubbleActionBizPreview;
        @weakify(self);
        watchVideoConfig.callback = ^(ACCStickerBubbleAction actionType) {
            @strongify(self);
            if (actionType == ACCStickerBubbleActionBizPreview) {
                ACCBLOCK_INVOKE(self.onPreviewCallback);
            }
        };
        [res acc_addObject:watchVideoConfig];
    }
    
    if ([self hasDeleteFeature] && self.deleteAction != nil) {
        [res acc_addObject:[self deleteConfig]];
    }
    
    if (ACC_isEmptyArray(res)) {
        self.showSelectedHint = NO;
    } else {
        self.showSelectedHint = YES;
    }
    
    return [res copy];
}

@end
