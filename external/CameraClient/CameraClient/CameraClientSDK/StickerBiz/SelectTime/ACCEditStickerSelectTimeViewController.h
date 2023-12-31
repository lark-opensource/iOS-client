//
//  ACCEditStickerSelectTimeViewController.h
//  CameraClient-Pods-Aweme
//
//  Created by guochenxiang on 2020/8/23.
//

#import <UIKit/UIKit.h>
#import <CameraClient/ACCEditTransitionServiceProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@class ACCStickerContainerView, AWEVideoImageGenerator;

@protocol ACCStickerProtocol, ACCStickerPlayerApplying, ACCStickerSelectTimeConfig, ACCEditServiceProtocol;

@protocol ACCStickerSelectTimeVCDelegate <NSObject>

- (void)imageGenerator:(AWEVideoImageGenerator *)imageGenerator
         requestImages:(NSUInteger)count
                  step:(CGFloat)step
                  size:(CGSize)size
                 array:(NSMutableArray *)previewImageDictArray
            completion:(void(^)(void))complete;

- (void)didUpdateStickerContainer:(ACCStickerContainerView *)stickerContainer;

@optional
- (void)didCancelStickerContainer:(ACCStickerContainerView *)stickerContainer;

@end

@interface ACCEditStickerSelectTimeInputData : NSObject

@property (nonatomic, weak) id<ACCEditTransitionServiceProtocol> transitionService;
@property (nonatomic, weak) id<ACCStickerSelectTimeVCDelegate> delegate;
@property (nonatomic, strong) id<ACCStickerPlayerApplying> player;
@property (nonatomic, strong) UIView<ACCStickerProtocol> *stickerView;
@property (nonatomic, strong) ACCStickerContainerView *stickerContainer;
@property (nonatomic, assign) CGRect playerRect;
@property (nonatomic, strong) id<ACCEditServiceProtocol> editService;

@end

@interface ACCEditStickerSelectTimeViewController : UIViewController

- (instancetype)initWithConfig:(id<ACCStickerSelectTimeConfig>)config
                     inputData:(ACCEditStickerSelectTimeInputData *)inputData;

@end

NS_ASSUME_NONNULL_END
