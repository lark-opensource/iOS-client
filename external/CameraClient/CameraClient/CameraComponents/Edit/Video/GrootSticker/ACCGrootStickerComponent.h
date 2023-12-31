//
//  ACCGrootStickerComponent.h
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/5/14.
//

#import <CreativeKit/ACCFeatureComponent.h>
#import "ACCGrootStickerViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@class AWEInteractionStickerLocationModel;
@class ACCGrootStickerModel;
@class ACCGrootStickerViewModel;

@protocol ACCGrootStickerInputDelegate;

@interface ACCGrootStickerComponent : ACCFeatureComponent

@property (nonatomic, strong, readonly) ACCGrootStickerViewModel *grootViewModel;
@property (nonatomic, weak  ) id<ACCGrootStickerInputDelegate> inputDelegate;

- (void)addGrootStickerWithStickerID:(NSString *)stickerID
                            location:(nullable AWEInteractionStickerLocationModel *)locationModel
                        stickerModel:(nullable ACCGrootStickerModel *)stickerModel
                            autoEdit:(BOOL)autoEdit;

@end

NS_ASSUME_NONNULL_END
