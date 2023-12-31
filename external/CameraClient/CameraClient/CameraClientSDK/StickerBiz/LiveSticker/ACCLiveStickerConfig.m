//
//  ACCLiveStickerConfig.m
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/1/4.
//

#import "ACCLiveStickerConfig.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKitSticker/ACCStickerProtocol.h>
#import <CreativeKitSticker/ACCBaseStickerView.h>

@implementation ACCLiveStickerConfig

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.preferredContainerFeature = ACCStickerContainerFeatureAdsorbing | ACCStickerContainerFeatureAngleAdsorbing | ACCStickerContainerFeatureHighlightMoment | ACCStickerContainerFeatureSafeArea;
        self.supportGesture = ^BOOL(ACCStickerGestureType gestureType, id  _Nullable contextId, UIGestureRecognizer * _Nonnull gestureRecognizer) {
            return contextId ? NO : YES;
        };
        self.gestureCanStartCallback = ^BOOL(__kindof ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> * _Nonnull contentView, UIGestureRecognizer * _Nonnull gesture) {
            if ([gesture isKindOfClass:[UIPanGestureRecognizer class]] && (self.preferredContainerFeature & ACCStickerContainerFeatureSafeArea) && (contentView.gestureActiveState & ACCStickerGestureStatePinch || contentView.gestureActiveState & ACCStickerGestureStateRotate)) {
                return NO;
            }
            return YES;
        };
        self.editable = @(YES);
    }
    return self;
}

- (NSArray<ACCStickerBubbleConfig *> *)bubbleActionList
{
    NSMutableArray *actionList = [NSMutableArray array];

    ACCStickerBubbleConfig *config = [[ACCStickerBubbleConfig alloc] init];
    config.actionType = ACCStickerBubbleActionBizEdit;
    @weakify(self);
    config.callback = ^(ACCStickerBubbleAction actionType) {
        if (actionType == ACCStickerBubbleActionBizEdit) {
            @strongify(self);
            ACCBLOCK_INVOKE(self.editLive);
        }
    };
    [actionList addObject:config];
    
    if ([self hasDeleteFeature] && self.deleteAction != nil) {
        [actionList addObject:[self deleteConfig]];
    }

    return [actionList copy];
}

@end
