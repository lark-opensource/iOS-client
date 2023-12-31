//
//  ACCVideoEditTipsService.h
//  CameraClient
//
//  Created by yangying on 2020/12/14.
//
#import <CameraClient/AWEVideoEditDefine.h>
#import <CameraClient/AWEImageAndTitleBubble.h>
#import <CameraClient/ACCBubbleDefinition.h>
#import <CreationKitInfra/ACCRACWrapper.h>

#ifndef ACCVideoEditTipsService_h
#define ACCVideoEditTipsService_h

typedef NS_ENUM(NSInteger, ACCMusicBubbleType) {
    ACCNormalMusicBubble = 1,
    ACCAIMusicBubble
};

@protocol ACCVideoEditTipsService;

@protocol ACCVideoEditTipsServiceSubscriber <NSObject>

@optional
- (void)tipService:(id<ACCVideoEditTipsService>)tipService didTappedImageBubbleWithFunctionType:(AWEStudioEditFunctionType)type;
- (void)tipService:(id<ACCVideoEditTipsService>)tipService didTappedFunctionBubbleWithFunctionType:(AWEStudioEditFunctionType)type;

- (void)tipService:(id<ACCVideoEditTipsService>)tipService didShowImageBubbleWithFunctionType:(AWEStudioEditFunctionType)type;
- (void)tipService:(id<ACCVideoEditTipsService>)tipService didShowFunctionBubbleWithFunctionType:(AWEStudioEditFunctionType)type;

@end

@protocol ACCVideoEditTipsService <NSObject>

@property (nonatomic, strong, readonly) RACSignal *showMusicBubbleSignal;
@property (nonatomic, strong, readonly) RACSignal *showQuickPublishBubbleSignal;
@property (nonatomic, strong, readonly) RACSignal *showCanvasInteractionGudeSignal;
@property (nonatomic, strong, readonly) RACSignal *showImageAlbumSwitchModeBubbleSignal;
@property (nonatomic, strong, readonly) RACSignal *showImageAlbumSlideGuideSignal;
@property (nonatomic, strong, readonly, nonnull) RACSignal *showSmartMovieBubbleSignal;

/*  just a work around for tip component, which need to access and change the show value, but that logic should be sink to service, so this can be move to the service impl in the future. */
@property (nonatomic, assign) NSInteger showedValue;

- (void)showFunctionBubbleWithContent:(NSString *)content
                              forView:(UIView *)view
                        containerView:(UIView *)containerView
                            mediaView:(UIView *)mediaView
                     anchorAdjustment:(CGPoint)adjustment
                          inDirection:(ACCBubbleManagerDirection)bubbleDirection
                         functionType:(AWEStudioEditFunctionType)type;

- (void)showImageBubble:(UIImage *)image
                forView:(UIView *)targetView
          containerView:(UIView *)containerView
              mediaView:(UIView *)mediaView
            inDirection:(AWEImageAndTitleBubbleDirection)direction
               subtitle:(NSString *)title
           functionType:(AWEStudioEditFunctionType)type;


- (void)addSubscriber:(id<ACCVideoEditTipsServiceSubscriber>)subscriber;

- (void)dismissFunctionBubbles;
- (void)saveShowedFunctionsByType:(AWEStudioEditFunctionType)type;

@end

#endif /* ACCVideoEditTipsService_h */
