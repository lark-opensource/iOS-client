//
//  ACCSocialStickerConfig.m
//  CameraClient-Pods-Aweme-CameraResource_base
//
//  Created by qiuhang on 2020/8/5.
//

#import "ACCSocialStickerConfig.h"
#import <CreativeKit/ACCMacros.h>

@implementation ACCSocialStickerConfig

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

    ACCStickerBubbleConfig *selectTimeConfig = [[ACCStickerBubbleConfig alloc] init];
    selectTimeConfig.actionType = ACCStickerBubbleActionBizSelectTime;
    @weakify(self);
    selectTimeConfig.callback = ^(ACCStickerBubbleAction actionType) {
        if (actionType == ACCStickerBubbleActionBizSelectTime) {
            @strongify(self);
            ACCBLOCK_INVOKE(self.selectTime);
        }
    };
    [bubbleActionList addObject:selectTimeConfig];

    ACCStickerBubbleConfig *eidtConfig = [[ACCStickerBubbleConfig alloc] init];
    eidtConfig.actionType = ACCStickerBubbleActionBizEdit;
    eidtConfig.callback = ^(ACCStickerBubbleAction actionType) {
        if (actionType == ACCStickerBubbleActionBizEdit) {
            @strongify(self);
            ACCBLOCK_INVOKE(self.editText);
        }
    };
    [bubbleActionList addObject:eidtConfig];
    
    if ([self hasDeleteFeature] && self.deleteAction != nil) {
        [bubbleActionList addObject:[self deleteConfig]];
    }

    return [bubbleActionList copy];
}

@end
