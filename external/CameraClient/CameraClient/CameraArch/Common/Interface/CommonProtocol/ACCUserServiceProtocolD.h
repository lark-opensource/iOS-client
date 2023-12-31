//
//  ACCUserServiceProtocolD.h
//  Aweme
//
//  Created by 李辉 on 11/16/21.
//

#import <Foundation/Foundation.h>

@protocol ACCUserModelProtocol;

@protocol ACCUserServiceProtocolD <NSObject>

/*
* User Profile
*/
- (void)getUserProfileWithID:(NSString * _Nullable)userID completion:(void(^ _Nullable)(id<ACCUserModelProtocol> user, NSError *error))completion;

@end
