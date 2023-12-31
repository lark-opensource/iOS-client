//
//  ACCInfoStickerConfig.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/9/18.
//

#import "ACCInfoStickerConfig.h"
#import <CreativeKit/ACCMacros.h>

@implementation ACCInfoStickerConfig

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.preferredContainerFeature = ACCStickerContainerFeatureAdsorbing | ACCStickerContainerFeatureAngleAdsorbing | ACCStickerContainerFeatureHighlightMoment;
        self.minimumScale = 0.5;
        self.pinable = YES;
    }
    return self;
}

- (NSArray<ACCStickerBubbleConfig *> *)bubbleActionList
{
    NSMutableArray *actionList = [NSMutableArray array];
    
    if (self.isImageAlbum) {
        ACCStickerBubbleConfig *deleteConfig = [[ACCStickerBubbleConfig alloc] init];
        deleteConfig.actionType = ACCStickerBubbleActionBizDelete;
        @weakify(self);
        deleteConfig.callback = ^(ACCStickerBubbleAction actionType) {
            if (actionType == ACCStickerBubbleActionBizDelete) {
                @strongify(self);
                if (self.deleteAction) {
                    self.deleteAction();
                }
            }
        };
        
        [actionList addObject:deleteConfig];
    }
    
    if (!self.isImageAlbum &&
        self.pinable) {
        ACCStickerBubbleConfig *pinConfig = [[ACCStickerBubbleConfig alloc] init];
        pinConfig.actionType = ACCStickerBubbleActionBizPin;
        @weakify(self);
        pinConfig.callback = ^(ACCStickerBubbleAction actionType) {
            if (actionType == ACCStickerBubbleActionBizPin) {
                @strongify(self);
                if (self.pinAction) {
                    self.pinAction();
                }
            }
        };
        [actionList addObject:pinConfig];
    }

    if (!self.isImageAlbum) {
        ACCStickerBubbleConfig *selectTimeConfig = [[ACCStickerBubbleConfig alloc] init];
        selectTimeConfig.actionType = ACCStickerBubbleActionBizSelectTime;
        @weakify(self);
        selectTimeConfig.callback = ^(ACCStickerBubbleAction actionType) {
            if (actionType == ACCStickerBubbleActionBizSelectTime) {
                @strongify(self);
                if (self.selectTime) {
                    self.selectTime();
                }
            }
        };
        [actionList addObject:selectTimeConfig];
    }
    
    if (!self.isImageAlbum && [self hasDeleteFeature] && self.deleteAction != nil) {
        [actionList addObject:[self deleteConfig]];
    }
    
    return [actionList copy];
}

@end
