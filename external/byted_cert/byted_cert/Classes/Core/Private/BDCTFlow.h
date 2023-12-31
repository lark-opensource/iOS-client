//
//  BDCTFlow.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/8/23.
//

#import <Foundation/Foundation.h>

@class BDCTEventTracker, BDCTFlow, BDCTFlowContext, BDCTAPIService;

NS_ASSUME_NONNULL_BEGIN


@interface UIViewController (BDCTFlowAdditions)

@property (nonatomic, strong) BDCTFlow *bdct_flow;

@end

@protocol BDCTFlowPerformanceProtocol <NSObject>

@optional
- (void)flowStart;
- (void)webviewStartLoad;
- (void)webviewDidLoad;

- (void)faceDetectOpen;
- (void)faceSmashPreLoad;
- (void)faceSmashPreSetup;
- (void)faceSmashLoaded;
- (void)faceSmashDidSetup;
- (void)faceCameraSetup;
- (void)facePageNotify;
- (void)faceLivenessEnd;
- (void)faceVideoRecordUpload;
- (void)faceCompareStart;
- (void)faceCompareEnd;
- (void)faceQueryResult;
- (void)flowEnd;
- (void)nfcConnected;
- (void)nfcEnd;

@end


@interface BDCTFlowPerformance : NSObject <BDCTFlowPerformanceProtocol>

@property (nonatomic, weak) BDCTFlow *flow;
@property (nonatomic, readonly) NSMutableDictionary *timeStampParams;

@end


@interface BDCTFlow : NSObject

@property (nonatomic, weak) BDCTFlow *superFlow;

@property (nonatomic, strong, readonly) BDCTFlowContext *context;
@property (nonatomic, strong, readonly) BDCTAPIService *apiService;
@property (nonatomic, strong, readonly) BDCTEventTracker *eventTracker;
@property (nonatomic, strong, readonly) BDCTFlowPerformance *performance;

@property (nonatomic, assign) BOOL forcePresent;
@property (nonatomic, assign) BOOL disableInteractivePopGesture;
@property (nonatomic, weak) UIViewController *fromViewController;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)flowWithContext:(BDCTFlowContext *)context;

- (instancetype)initWithContext:(BDCTFlowContext *)context;

- (void)showViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
