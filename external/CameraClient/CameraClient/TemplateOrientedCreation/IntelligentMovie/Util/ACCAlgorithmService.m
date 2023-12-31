//
//  ACCAlgorithmService.m
//  CameraClient-Pods-Aweme
//
//  Created by Lemonior on 2020/12/3.
//

#import "ACCAlgorithmService.h"
#import <EffectPlatformSDK/EffectPlatform.h>
#import <CreationKitInfra/ACCLogProtocol.h>

@implementation ACCAlgorithmService

#pragma mark - BIM

- (BOOL)isBIMModelReady
{
    NSAssert(self.bimAlgorithm, @"invalid bim algorithm");
    return [EffectPlatform isRequirementsDownloaded:self.bimAlgorithm];
}

- (void)updateBIMModelWithCompletion:(void (^)(BOOL success))completion
{
    NSAssert(self.bimAlgorithm, @"invalid bim algorithm");
    [EffectPlatform downloadRequirements:self.bimAlgorithm
                              completion:^(BOOL success, NSError * _Nonnull error) {
        if (error) {
            AWELogToolError(AWELogToolTagMoment, @"algorithmService: download requirements: %@", error);
        }
        if (completion) {
            BOOL updateSuccess = (error == nil && success);
            completion(updateSuccess);
        }
    }];
}

@end
