//
//  ACCGrootStickerConfig.m
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/5/14.
//

#import "ACCGrootStickerConfig.h"
#import <CreativeKit/ACCMacros.h>
#import "ACCConfigKeyDefines.h"
#import <CreativeKit/NSArray+ACCAdditions.h>

@implementation ACCGrootStickerConfig

- (instancetype)init {
    if (self = [super init]) {
        self.preferredContainerFeature = (ACCStickerContainerFeatureAdsorbing |
                                          ACCStickerContainerFeatureAngleAdsorbing |
                                          ACCStickerContainerFeatureHighlightMoment);
        
        self.supportGesture = ^BOOL(ACCStickerGestureType gestureType, id _Nullable contextId, UIGestureRecognizer *gestureRecognizer) {
            return YES;
        };
        self.maximumScale = 20.f;
        self.minimumScale = 0.3f;
        self.editable = @YES;
    }
    return self;
}

- (NSArray<ACCStickerBubbleConfig *> *)bubbleActionList {
    NSMutableArray *bubbleActionList = [NSMutableArray array];
    if (ACCConfigBool(kConfigBool_sticker_support_groot)) {
        @weakify(self);
        ACCStickerBubbleConfig *eidtConfig = [[ACCStickerBubbleConfig alloc] init];
        eidtConfig.actionType = ACCStickerBubbleActionBizEdit;
        eidtConfig.callback = ^(ACCStickerBubbleAction actionType) {
            if (actionType == ACCStickerBubbleActionBizEdit) {
                @strongify(self);
                ACCBLOCK_INVOKE(self.editText);
            }
        };
        [bubbleActionList  acc_addObject:eidtConfig];
        
        if ([self hasDeleteFeature] && self.deleteAction != nil) {
            [bubbleActionList acc_addObject:[self deleteConfig]];
        }
    }
    return [bubbleActionList copy];
}

@end
