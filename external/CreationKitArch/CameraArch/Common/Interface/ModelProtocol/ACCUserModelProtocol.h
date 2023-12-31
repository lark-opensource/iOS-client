//
//  ACCUserModelProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2021/1/10.
//

#ifndef ACCUserModelProtocol_h
#define ACCUserModelProtocol_h

#import "ACCURLModelProtocol.h"

@protocol ACCUserModelProtocol <NSObject>

@property (nonatomic, copy) NSString *userID;
@property (nonatomic, copy) NSString *secUserID;
@property (nonatomic, copy) NSString *customID;
@property (nonatomic, copy) NSString *shortID;
@property (nonatomic, copy, readonly) NSString *socialName; // display name
@property (nonatomic, copy) NSString *nickname; // user account name
@property (nonatomic, strong) NSNumber *followerCount;
@property (nonatomic, strong) id<ACCURLModelProtocol> avatarThumb;
@property (nonatomic, strong) id<ACCURLModelProtocol> avatarMedium;//720x720
@property (nonatomic, strong) id<ACCURLModelProtocol> avatar300;//300x300，if failed will use medium
@property (nonatomic, strong, readonly) id<ACCURLModelProtocol> _Nullable avatar168FromMedium;
@property (nonatomic, assign) BOOL isFreeFlowCardUser;  // Is the user bound to the free stream card
@property (nonatomic, assign) BOOL privateAccount;
@property (nonatomic, assign) NSInteger followStatus;
@property (nonatomic, assign) BOOL showFirstAvatarDecoration; // isFirstPost
@property (nonatomic, assign) BOOL isStar;// Star
@property (nonatomic, copy) NSDictionary *logPassback;
- (BOOL)isVerifiedEnterprise;

- (BOOL)shouldUseCommerceMusic;

- (NSString *)uniqueIDForShow;
- (NSString *)displayName;

@end

#endif /* ACCUserModelProtocol_h */
