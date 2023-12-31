//
//  ACCPollStickerHandler.h
//  CameraClient-Pods-DouYin
//
//  Created by guochenxiang on 2020/9/7.
//

#import <Foundation/Foundation.h>
#import "ACCStickerHandler.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCPollStickerDataProvider;

@class ACCPollStickerView;

@interface ACCPollStickerHandler : ACCStickerHandler

@property (nonatomic, weak) id<ACCPollStickerDataProvider> dataProvider;

@property (nonatomic, copy) void(^editViewOnStartEdit)(NSString *propID);
@property (nonatomic, copy) void(^editViewOnFinishEdit)(NSString *propID);
@property (nonatomic, copy) void(^onStickerWillDelete)(NSString *stickerId);
@property (nonatomic, copy, nullable) void(^onStickerApplySuccess)(void);

- (ACCPollStickerView *)currentPollStickerView;

- (ACCPollStickerView *)addPollStickerWithModel:(AWEInteractionStickerModel *)model;

- (void)editPollStickerView:(ACCPollStickerView *)stickerView;

@end

NS_ASSUME_NONNULL_END
