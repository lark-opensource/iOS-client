//
//  BytedCertFlowRecord.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2020/10/29.
//

#import "BDCTFlow.h"
#import "FaceLiveViewController.h"

@class BytedCertError, BDCTImageManager;

NS_ASSUME_NONNULL_BEGIN


@interface BDCTFaceVerificationFlow : BDCTFlow <BDCTFaceLiveViewControllerDelegate>

@property (nonatomic, copy) BOOL (^shouldPresentHandler)(void);
@property (nonatomic, copy) void (^completionBlock)(NSDictionary *_Nullable result, BytedCertError *_Nullable error);

- (void)begin;
- (void)beginVerifyWithAlgoParams:(NSDictionary *_Nullable)algoParams;
- (void)finishWithResult:(NSDictionary *_Nullable)result error:(BytedCertError *_Nullable)error;

@end

NS_ASSUME_NONNULL_END
