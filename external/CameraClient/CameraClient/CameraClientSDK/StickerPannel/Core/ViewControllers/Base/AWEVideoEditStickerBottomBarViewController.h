//
//  AWEVideoEditStickerBottomBarViewController.h
//  CameraClient
//
//  Created by HuangHongsen on 2020/2/3.
//

#import <UIKit/UIKit.h>
#import <EffectPlatformSDK/IESCategoryModel.h>

@class ACCStickerPannelUIConfig, IESInfoStickerCategoryModel;

NS_ASSUME_NONNULL_BEGIN

@protocol AWEVideoEditStickerBottomBarViewControllerDelegate <NSObject>

- (void)bottomBarViewControllerDidSelectCategory:(IESCategoryModel *)category shouldTrack:(BOOL)shouldTrack;

@end

@protocol ACCVideoEditInfoStickerBottomBarVCDelegate <NSObject>

- (void)bottomBarViewControllerDidSelectCategory:(IESInfoStickerCategoryModel *)category shouldTrack:(BOOL)shouldTrack;

@end


@interface AWEVideoEditStickerBottomBarViewController : UIViewController

@property (nonatomic, copy) NSArray <IESCategoryModel *> *categories;
@property (nonatomic, assign) BOOL showText;
@property (nonatomic, weak) id<AWEVideoEditStickerBottomBarViewControllerDelegate> delegate;
@property (nonatomic, assign) BOOL disableLeftScrollOutOfBounds;
@property (nonatomic, assign) BOOL disableRightScrollOutOfBounds;

@property (nonatomic, strong) ACCStickerPannelUIConfig *uiConfig;

- (void)selectCategory:(IESCategoryModel *)category;

+ (CGFloat)bottomBarHeight;

@end

@interface ACCVideoEditInfoStickerBottomBarViewController : UIViewController
@property (nonatomic, copy) NSArray <IESInfoStickerCategoryModel *> *categories;
@property (nonatomic, assign) BOOL showText;
@property (nonatomic, weak) id<ACCVideoEditInfoStickerBottomBarVCDelegate> delegate;
@property (nonatomic, assign) BOOL disableLeftScrollOutOfBounds;
@property (nonatomic, assign) BOOL disableRightScrollOutOfBounds;

@property (nonatomic, strong) ACCStickerPannelUIConfig *uiConfig;

- (void)selectCategory:(IESInfoStickerCategoryModel *)category;

+ (CGFloat)bottomBarHeight;

@end

NS_ASSUME_NONNULL_END
