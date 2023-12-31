//
//  BDCTFaceQualityDetectFlow.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2022/5/6.
//

#import "BDCTFaceQualityDetectFlow.h"


@implementation BDCTFaceQualityDetectFlow

- (void)begin {
    self.context.finalLivenessType = BytedCertLiveTypeQuality;
    [self beginVerifyWithAlgoParams:nil];
}

- (void)faceViewController:(FaceLiveViewController *)faceViewController faceCompareWithPackedParams:(NSDictionary *)packedParams faceData:(NSData *)faceData resultCode:(int)resultCode completion:(void (^)(NSDictionary *_Nullable, BytedCertError *_Nullable))completion {
    !completion ?: completion(nil, nil);
}

@end
