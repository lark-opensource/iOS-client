//  视频回复评论二期
//  ACCVideoReplyCommentStickerConfig.m
//  CameraClient-Pods-Aweme
//
//  Created by lixuan on 2021/10/9.
//

#import "ACCVideoReplyCommentStickerConfig.h"

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>

@interface ACCVideoReplyCommentStickerConfig ()

@end

@implementation ACCVideoReplyCommentStickerConfig


- (instancetype)init
{
    self = [super init];
    if (self) {
        self.preferredContainerFeature = ACCStickerContainerFeatureAdsorbing | ACCStickerContainerFeatureAngleAdsorbing | ACCStickerContainerFeatureHighlightMoment | ACCStickerContainerFeatureSafeArea;
        self.supportGesture = ^BOOL(ACCStickerGestureType gestureType, id _Nullable contextId, UIGestureRecognizer *gestureRecognizer) {
            return YES;
        };
        self.typeId = ACCStickerTypeIdVideoReplyComment;
        self.hierarchyId = @(ACCStickerHierarchyTypeMediumHigh);
        self.minimumScale = 0.6;
        self.showSelectedHint = NO;
    }
    return self;
}

- (NSArray<ACCStickerBubbleConfig *> *)bubbleActionList
{
    NSMutableArray *res = [NSMutableArray array];
    
    if ([self hasDeleteFeature] && self.deleteAction != nil) {
        [res acc_addObject:[self deleteConfig]];
    }
    return [res copy];
}

@end
