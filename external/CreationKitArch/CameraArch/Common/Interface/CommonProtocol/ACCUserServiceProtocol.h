//
//  ACCUserServiceProtocol.h
//  Pods
//
//  Created by chengfei xiao on 2019/7/28.
// User information related protocols

#import <Foundation/Foundation.h>
#import "ACCUserModelProtocol.h"
#import "ACCAwemeModelProtocol.h"
#import "ACCLoginUserContext.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCUserServiceMessage

@optional
- (void)didFinishLogin;
- (void)didFinishLogout;

@end

@protocol ACCUserServiceProtocol <NSObject>
@property (nonatomic, assign) BOOL isUserLogin;

/*
 * Logged in or not
 */
- (BOOL)isLogin;

/*
 * Child mode or not
 */
- (BOOL)isChildMode;

/*
 * New user or not
 */
- (BOOL)isNewUser;

/**
 * An operation requires a login to complete, use this method
 */
- (void)requireLogin:(void (^)(BOOL success))completion;

- (void)requireLogin:(void (^)(BOOL success))completion withTrackerInformation:(NSDictionary *)trackerInformation;

/**
 *  Is the userID the currently logged in user
 */
- (BOOL)isCurrentLoginUserWithID:(NSString *)userID;

/*
 * Current log-in account
 */
- (id<ACCUserModelProtocol>)currentLoginUserModel;

/*
* User Profile
*/
- (void)getUserProfileWithID:(NSString *)userID secUserID:(NSString *)secUserID completion:(void(^)(id<ACCUserModelProtocol> user, NSError *error))completion;

@optional

- (NSArray<NSString *> *)recentLoginedUserIdListWithCountLimit:(NSNumber *)limit;

// Synchronize current user login information
- (void)syncUser:(void(^)(id<ACCUserModelProtocol> user, NSError *error))synccompletion;

// Clear current user cache
- (void)cleanUserCache;

// Switch users
- (void)switchUserWithCompletion:(void (^)(BOOL))completion;

- (void)requireLoginWithContext:(ACCLoginUserContext *)context
                     completion:(void (^)(BOOL success))completion;

- (UIWindow*)loginWindow;

@end

NS_ASSUME_NONNULL_END
