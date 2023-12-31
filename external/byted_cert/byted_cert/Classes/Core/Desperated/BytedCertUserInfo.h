//
//  BytedCertUserInfo.h
//  Pods
//
//  Created by LiuChundian on 2019/6/2.
//

#ifndef BytedCertUserInfo_h
#define BytedCertUserInfo_h


@interface BytedCertUserInfo : NSObject

@property (nonatomic, copy, readonly, nullable) NSString *ticket;

+ (instancetype _Nonnull)sharedInstance;

@end

#endif /* BytedCertUserInfo_h */
