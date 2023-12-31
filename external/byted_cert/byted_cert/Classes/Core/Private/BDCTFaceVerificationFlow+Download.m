//
//  BDCTFaceVerificationFlow+Download.m
//  byted_cert
//
//  Created by liuminghui.2022 on 2023/2/2.
//

#import "BDCTFaceVerificationFlow+Download.h"
#import "BytedCertWrapper.h"


@implementation BDCTFaceVerificationFlow (Download)

- (void)downloadAudioWithCompletion:(void (^)(BOOL, NSDictionary *_Nullable, NSString *_Nullable))completion {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([[BytedCertWrapper sharedInstance] respondsToSelector:@selector(geckoDownloadAudioResource:)]) {
        [[BytedCertWrapper sharedInstance] performSelector:@selector(geckoDownloadAudioResource:) withObject:completion];
    }
#pragma clang diagnostic pop
}

@end
