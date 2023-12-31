//
//  AWELiveDuetPostureViewController.h
//  CameraClient-Pods-Aweme
//
//  Created by Syenny on 2021/1/14.
//

#import "AWEStudioBaseViewController.h"
#import "ACCPropSelection.h"
#import <CreationKitRTProtocol/ACCCameraService.h>

#import <UIKit/UIKit.h>
#import <CreativeKit/ACCPanelViewProtocol.h>

FOUNDATION_EXPORT void * const ACCRecordDuetPosturePanelContext;

typedef void(^AWELiveDuetPostureVCDismissBlock)(void);

NS_ASSUME_NONNULL_BEGIN

@protocol AWELiveDuetPostureViewControllerDelegate <NSObject>

- (void)updateSelectedIndex:(NSInteger)selectedIndex;

@end

@interface AWELiveDuetPostureViewController : AWEStudioBaseViewController

@property (nonatomic, assign, readonly) NSInteger selectedIndex;
@property (nonatomic, weak) id<AWELiveDuetPostureViewControllerDelegate> delegate;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, UIImage *> *imageDictionary;
@property (nonatomic, copy) AWELiveDuetPostureVCDismissBlock dismissBlock;

/**
 *@param imagesFolderPath 是图片文件夹的路径。
 */
- (void)prepareForImageDataWithFolderPath:(NSString *)imagesFolderPath;

/**
 *@param cameraService 不能为nil。
*/
- (void)prepareForCameraService:(id<ACCCameraService> _Nonnull)cameraService;

/**
 *@param effectModel 当前的道具不能为nil。
 */
- (void)updateRenderImageKeyWithEffectModel:(IESEffectModel * _Nonnull)effectModel;

/**
 *@param selectedIndex 当选的index。
 */
- (void)renderPicImageWithIndex:(NSInteger)selectedIndex;

/**
 * @param view 容器视图，不能为nil。
 * @param animated 是否使用动画，如果为YES，道具面板从底部上滑出现。
 * @param completion show结束后回调
 */
- (void)showOnView:(UIView * _Nonnull)superview animated:(BOOL)animated completion:(void (^ __nullable)(void))completion;

@end

NS_ASSUME_NONNULL_END
