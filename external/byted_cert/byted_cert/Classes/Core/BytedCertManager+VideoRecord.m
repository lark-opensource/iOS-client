//
//  BytedCertManager+VideoRecord.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/12/5.
//

#import "BytedCertManager+VideoRecord.h"
#import "BDCTVideoRecordViewController.h"
#import "BDCTFlow.h"
#import "BDCTFlowContext.h"
#import "BDCTAdditions.h"
#import "BytedCertError.h"
#import <ByteDanceKit/BTDResponder.h>
#import <BDAssert/BDAssert.h>


@implementation BytedCertManager (VideoRecord)

+ (void)recordVideoWithParameter:(BytedCertVideoRecordParameter *)parameter fromViewController:(UIViewController *)fromViewController completion:(nonnull void (^)(BytedCertError *))completion {
    BDAssert(parameter.skipFaceDetect || parameter.faceEnvBase64.length, @"faceEnvBase64 must not be nil.");
    BDCTFlowContext *context = [BDCTFlowContext contextWithParameter:parameter];
    BDCTFlow *flow = [[BDCTFlow alloc] initWithContext:context];
    BDCTVideoRecordViewController *viewController = [BDCTVideoRecordViewController new];
    viewController.completionBlock = completion;
    viewController.bdct_flow = flow;
    [(fromViewController ?: BTDResponder.topViewController) bdct_showViewController:viewController];
}

@end
