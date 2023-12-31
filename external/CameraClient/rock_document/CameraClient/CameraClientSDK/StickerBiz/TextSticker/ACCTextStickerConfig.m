//
//  ACCTextStickerConfig.m
//  CameraClient
//
//  Created by Yangguocheng on 2020/7/20.
//

#import "ACCTextStickerConfig.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import "ACCConfigKeyDefines.h"

@implementation ACCTextStickerConfig

- (instancetype)init
{
    self = [super init];
    if (self) {
        _needBubble = YES;
        self.preferredContainerFeature = ACCStickerContainerFeatureAdsorbing | ACCStickerContainerFeatureAngleAdsorbing | ACCStickerContainerFeatureHighlightMoment;
        
        self.supportGesture = ^BOOL(ACCStickerGestureType gestureType, id _Nullable contextId, UIGestureRecognizer *gestureRecognizer) {
            return YES;
        };
        self.maximumScale = 20;
        self.minimumScale = 0.3;
        self.editable = @(YES);
    }
    return self;
}

- (NSArray<ACCStickerBubbleConfig *> *)bubbleActionList
{
    if (!self.needBubble) {
        return nil;
    }
    
    NSMutableArray *actionList = [NSMutableArray array];
    if (self.type != ACCTextStickerConfigType_AlbumImage) {
        if (self.textReadAction == ACCStickerBubbleActionBizTextRead || self.textReadAction == ACCStickerBubbleActionBizTextReadCancel) {
            [actionList addObject:[self textReadConfig]];
        }
        [actionList addObject:[self selectTimeConfig]];
    }
    if (![self.editable isEqual:@NO]) {
        [actionList addObject:[self editConfig]];
    }
    
    if ([self hasDeleteFeature] && self.deleteAction != nil) {
        // 图文放第一个
        if (self.type == ACCTextStickerConfigType_AlbumImage &&
            ACCConfigBool(kConfigBool_enable_image_album_story)) {
            [actionList acc_insertObject:[self deleteConfig] atIndex:0];
        } else {
            [actionList acc_addObject:[self deleteConfig]];
        }
    }
    
    return actionList;
}

#pragma mark - Getter

- (ACCStickerBubbleConfig *)editConfig
{
    ACCStickerBubbleConfig *editConfig = [[ACCStickerBubbleConfig alloc] init];
    editConfig.actionType = ACCStickerBubbleActionBizEdit;
    @weakify(self);
    editConfig.callback = ^(ACCStickerBubbleAction actionType) {
        if (actionType == ACCStickerBubbleActionBizEdit) {
            @strongify(self);
            if (self.editText) {
                self.editText();
            }
        }
    };
    return editConfig;
}

- (ACCStickerBubbleConfig *)textReadConfig
{
    ACCStickerBubbleConfig *textReadConfig = [[ACCStickerBubbleConfig alloc] init];
    textReadConfig.actionType = self.textReadAction;
    @weakify(self);
    textReadConfig.callback = ^(ACCStickerBubbleAction actionType) {
        if (actionType == ACCStickerBubbleActionBizTextRead) {
            @strongify(self);
            if (self.readText) {
                self.readText();
            }
        }
    };
    return textReadConfig;
}

- (ACCStickerBubbleConfig *)selectTimeConfig
{
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
    return selectTimeConfig;
}

@end
