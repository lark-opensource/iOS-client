//
//  ACCSearchStickerViewController.h
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/2/13.
//

#import <UIKit/UIKit.h>
#import "ACCStickerPannelAnimationVC.h"

NS_ASSUME_NONNULL_BEGIN

@class IESInfoStickerModel, ACCSearchStickerViewController;

@protocol ACCSearchStickerVCDelegate <NSObject>

- (void)searchStickerCollectionViewController:(ACCSearchStickerViewController *)stickerCollectionVC didSelectSticker:(IESInfoStickerModel *)sticker indexPath:(NSIndexPath *)indexPath downloadProgressBlock:(void(^)(CGFloat))downloadProgressBlock downloadedBlock:(void(^)(BOOL))downloadedBlock;
- (void)searchStickerCollectionViewControllerWillExit;
- (void)searchTrackEvent:(NSString *)event extraParams:(nullable NSDictionary *)params;

@end

@interface ACCSearchStickerViewController : ACCStickerPannelAnimationVC

@property (nonatomic, weak) id<ACCSearchStickerVCDelegate> delegate;

@property (nonatomic, copy) NSString *uploadFramesURI; // 上传的抽帧资源标志
@property (nonatomic, copy) NSString *creationId;
@property (nonatomic, copy) NSString *enterStatus;
@property (nonatomic, assign) BOOL useAutoSearch; // 联想搜索
@property (nonatomic, copy) NSArray<NSString *> *filterTags;

@end

NS_ASSUME_NONNULL_END
