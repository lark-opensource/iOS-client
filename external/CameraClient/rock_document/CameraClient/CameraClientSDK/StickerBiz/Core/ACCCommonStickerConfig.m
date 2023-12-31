//
//  ACCCommonStickerConfig.m
//  CameraClient-Pods-Aweme
//
//  Created by Yangguocheng on 2020/8/3.
//

#import "ACCCommonStickerConfig.h"
#import "ACCStickerBubbleHelper.h"
#import <CreativeKit/ACCMacros.h>

@implementation ACCCommonStickerConfig

+ (Class<ACCStickerBubbleProtocol>)bubbleClass
{
    return [ACCStickerBubbleHelper class];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _preferredContainerFeature = ACCStickerContainerFeatureReserved;
        _deleteable = @(YES);
        _supportedGestureType = ACCStickerGestureTypeTap | ACCStickerGestureTypePan | ACCStickerGestureTypePinch | ACCStickerGestureTypeRotate;
        
        self.supportGesture = ^BOOL(ACCStickerGestureType gestureType, id _Nullable contextId, UIGestureRecognizer *gestureRecognizer) {
            return YES;
        };
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    ACCCommonStickerConfig *config = [super copyWithZone:zone];
    
    config.supportedGestureType = self.supportedGestureType;

    return config;
}

- (ACCStickerBubbleConfig *)deleteConfig
{
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
    return deleteConfig;
}

- (BOOL)hasDeleteFeature
{
    // deleteable null or YES
    return ![self.deleteable isEqual:@NO];
}

@end

@implementation ACCBaseStickerView (CommonStickerConfig)

- (ACCCommonStickerConfig *)bizStickerConfig
{
    if ([self.config isKindOfClass:[ACCCommonStickerConfig class]]) {
        return (ACCCommonStickerConfig *)self.config;
    }
    return nil;
}

@end
