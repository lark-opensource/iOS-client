//
//  ACCChallengeServiceProtocol.h
//  CameraClient
//
//  Created by wishes on 2019/12/9.
//

#ifndef ACCChallengeServiceProtocol_h
#define ACCChallengeServiceProtocol_h

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCAwemeModelProtocol.h>
#import <CreationKitArch/ACCChallengeModelProtocol.h>

@protocol ACCChallengeNetServiceProtocol <NSObject>

/*
* 获取挑战model
*/
- (void)requestChallengeItemWithID:(NSString * _Nonnull)itemID
                        completion:(void(^ _Nullable)(id<ACCChallengeModelProtocol> _Nullable model, NSError * _Nullable error))block;

@end


#endif /* ACCChallengeServiceProtocol_h */
