//
//  ACCDraftSaveLandingProtocol.h
//  AwemeInhouse
//
//  Created by Shichen Peng on 2021/9/7.
//

#ifndef ACCDraftSaveLandingProtocol_h
#define ACCDraftSaveLandingProtocol_h

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCServiceLocator.h>

@protocol ACCDraftSaveLandingProtocol <NSObject>

- (void)transferToUserProfileWithParam:(NSDictionary * _Nullable)paramDict;

@end

FOUNDATION_STATIC_INLINE id<ACCDraftSaveLandingProtocol> ACCDraftSaveLandingService() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCDraftSaveLandingProtocol)];
}

#endif /* ACCDraftSaveLandingProtocol_h */
