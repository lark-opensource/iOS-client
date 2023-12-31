//
//  ACCVideoEditInfoStickerViewController.h
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/2/4.
//

#import <UIKit/UIKit.h>
#import "ACCStickerPannelAnimationVC.h"
#import "ACCStickerPannelLogger.h"

NS_ASSUME_NONNULL_BEGIN

@class IESInfoStickerModel, ACCStickerPannelDataConfig, ACCVideoEditInfoStickerViewController;

@protocol ACCStickerPannelFilter;

typedef NS_ENUM(NSInteger, ACCVideoEditInfoStickerCollectionStyle) {
    ACCVideoEditInfoStickerCollectionStyleNone = 0,
    ACCVideoEditInfoStickerCollectionStyleWithFooter = 1,
    ACCVideoEditInfoStickerCollectionStyleWithHeader = 2,
};

@protocol ACCVideoEditInfoStickerVCDelegate <NSObject>

- (ACCStickerPannelDataConfig *)dataConfig;

- (void)modernStickerCollectionVC:(ACCVideoEditInfoStickerViewController *)stickerCollectionVC
                 didSelectSticker:(IESInfoStickerModel *)sticker
                          atIndex:(NSInteger)index
                     categoryName:(NSString *)categoryName
                          tabName:(NSString *)tabName
            downloadProgressBlock:(void(^)(CGFloat))downloadProgressBlock
                  downloadedBlock:(void(^)(void))downloadedBlock;

@end

@class ACCStickerPannelUIConfig, ACCVideoEditInfoStickerBottomBarViewController;

@interface ACCVideoEditInfoStickerViewController : UIViewController

@property (nonatomic, weak) id<ACCVideoEditInfoStickerVCDelegate> delegate;
@property (nonatomic, strong, readonly) ACCVideoEditInfoStickerBottomBarViewController *bottomBarViewController;

@property (nonatomic, strong, readonly) UICollectionView *collectionView;
@property (nonatomic, assign) ACCVideoEditInfoStickerCollectionStyle style;
@property (nonatomic, assign) CGSize itemSize;
@property (nonatomic, assign) CGFloat horizontalInset;

@property (nonatomic, strong) ACCStickerPannelUIConfig *uiConfig;
@property (nonatomic, strong) id<ACCStickerPannelLogger> logger;
@property (nonatomic, strong) id<ACCStickerPannelFilter> pannelFilter;

@property (nonatomic, copy) NSString *videoUploadURI;
@property (nonatomic, copy) NSString *creationId;

@end

NS_ASSUME_NONNULL_END
