//
//  ACCRepoChallengeModel+Track.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2021/6/15.
//

#import "ACCRepoChallengeModel+Track.h"
#import <IESInject/IESInject.h>
#import <CreativeKit/ACCServiceLocator.h>
#import "ACCCommerceServiceProtocol.h"

@implementation ACCRepoChallengeModel (Track)

#pragma mark - ACCRepositoryTrackContextProtocol

- (NSDictionary *)acc_errorLogParams {
    return @{
        @"challenge_id":self.challenge.itemID?:@"",
    };
}

- (NSDictionary *)acc_referExtraParams
{
    NSMutableDictionary *extrasDict = @{}.mutableCopy;
    extrasDict[@"tag_id"] = self.challenge.itemID;
    if ([IESAutoInline(ACCBaseServiceProvider(), ACCCommerceServiceProtocol) shouldUseCommerceMusic] || self.challenge.isCommerce) {
        extrasDict[@"is_commercial"] = @1;
    }
    return extrasDict.copy;
}

@end
