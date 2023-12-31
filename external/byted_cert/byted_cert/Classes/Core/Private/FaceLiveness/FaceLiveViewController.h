//
//  BytedLivenessVC.h
//  BytedLivenessVC
//
//

#import "BDCTBaseCameraViewController.h"
#import "BytedCertUIConfig.h"
#import "BytedCertWrapper.h"
#import "BDCTAlignLabel.h"
#import "BytedCertWrapper.h"
#import "BDCTImageManager.h"
#import "BDCTFlowContext.h"
#import "BDCTFlow.h"

@class LivenessTC, FaceLiveViewController, BytedCertError;

NS_ASSUME_NONNULL_BEGIN

@protocol BDCTFaceLiveViewControllerDelegate <NSObject>

- (void)faceViewController:(FaceLiveViewController *)faceViewController faceCompareWithPackedParams:(NSDictionary *)packedParams faceData:(NSData *)faceData resultCode:(int)resultCode completion:(void (^)(NSDictionary *_Nullable jsonObj, BytedCertError *_Nullable bytedCertError))completion;

- (void)faceViewController:(FaceLiveViewController *)faceViewController retryDesicionWithCompletion:(void (^)(NSDictionary *_Nullable jsonObj, BytedCertError *_Nullable bytedCertError))completion;

@end


@interface FaceLiveViewController : BDCTBaseCameraViewController

@property (nonatomic, weak) id<BDCTFaceLiveViewControllerDelegate> delegate;

@property (nonatomic, strong, readonly) LivenessTC *livenessTC;
@property (nonatomic, assign, readonly) int beautyIntensity;
@property (nonatomic, copy, readonly) NSDictionary *liveDetectAlgoParams;

@property (nonatomic, copy, nullable) void (^completionBlock)(NSDictionary *_Nullable result, BytedCertError *_Nullable error);

- (instancetype)initWithFlow:(BDCTFlow *)flow liveDetectAlgoParams:(NSDictionary *)liveDetectAlgoParams;

- (void)updateLivenessMaskRadiusRatio;

- (void)liveDetectFailWithErrorTitle:(NSString *_Nullable)title message:(NSString *_Nullable)message actionCompletion:(nullable void (^)(NSString *action))actionCompletion;
- (void)liveDetectSuccessWithPackedParams:(NSDictionary *)dict faceData:(NSData *)faceData resultCode:(int)code;

- (void)didTapNavBackButton;

- (void)callbackWithResult:(NSDictionary *_Nullable)result error:(BytedCertError *_Nullable)error;

@end

NS_ASSUME_NONNULL_END
