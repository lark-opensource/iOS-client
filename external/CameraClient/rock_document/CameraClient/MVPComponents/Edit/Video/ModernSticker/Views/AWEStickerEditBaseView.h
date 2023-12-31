//
//  AWEStickerEditBaseView.h
//  Pods
//
//  Created by li xingdong on 2019/5/5.
//

#import <UIKit/UIKit.h>
#import <CameraClient/AWEInteractionStickerModel+DAddition.h>
#import <CreativeKitSticker/ACCStickerSelectTimeRangeProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWEStickerEditBaseView : UIImageView <ACCStickerSelectTimeRangeProtocol>

@property (nonatomic, strong) AWEInteractionStickerLocationModel *stickerLocation;

//backup
@property (nonatomic, strong, readonly) AWEInteractionStickerLocationModel *backupStickerLocation;
@property (nonatomic, assign, readonly) CGPoint backupCenter;
@property (nonatomic, assign, readonly) CGAffineTransform backupTransform;

- (void)backupLocation;

@end

NS_ASSUME_NONNULL_END
