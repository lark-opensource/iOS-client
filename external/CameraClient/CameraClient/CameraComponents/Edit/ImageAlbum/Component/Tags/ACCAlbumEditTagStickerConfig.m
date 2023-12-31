//
//  ACCAlbumEditTagStickerConfig.m
//  CameraClient-Pods-AwemeCore
//
//  Created by yangguocheng on 2021/9/29.
//

#import "ACCAlbumEditTagStickerConfig.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import "ACCStickerBubbleDYConfig.h"

@implementation ACCAlbumEditTagStickerConfig

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.preferredContainerFeature = ACCStickerContainerFeatureSafeArea;
        self.minimumScale = 1;
        self.showSelectedHint = NO;
    }
    return self;
}

- (NSArray<ACCStickerBubbleConfig *> *)bubbleActionList
{
    NSMutableArray *actionList = [NSMutableArray array];
    
    if (![self.editable isEqual:@NO]) {
        [actionList addObject:[self editConfig]];
    }
    
    [actionList acc_addObject:[self changeDirectionConfig]];

    if ([self hasDeleteFeature] && self.deleteAction != nil) {
        [actionList acc_addObject:[self deleteConfig]];
    }

    return [actionList copy];
}

- (ACCStickerBubbleDYConfig *)editConfig
{
    ACCStickerBubbleDYConfig *config = [[ACCStickerBubbleDYConfig alloc] init];
    config.title = @"编辑";
    config.accResourceImageName = @"icCameraStickerEditNew";
    @weakify(self);
    config.callback = ^(ACCStickerBubbleAction actionType) {
        @strongify(self);
        if (self.edit) {
            self.edit();
        }
    };
    return config;
}

- (ACCStickerBubbleDYConfig *)changeDirectionConfig
{
    ACCStickerBubbleDYConfig *config = [[ACCStickerBubbleDYConfig alloc] init];
    config.title = @"调整方向";
    config.accResourceImageName = @"ic_tag_reverse";
    @weakify(self);
    config.callback = ^(ACCStickerBubbleAction actionType) {
        @strongify(self);
        if (self.changeDirection) {
            self.changeDirection();
        }
    };
    return config;
}

@end
