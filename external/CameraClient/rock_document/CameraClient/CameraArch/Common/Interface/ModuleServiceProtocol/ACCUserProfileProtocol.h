//
//  ACCUserProfileProtocol.h
//  CameraClient
//
//  Created by long.chen on 2020/3/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCUserProfileProtocol <NSObject>

- (UIViewController *)userProfileVCForUserID:(NSString *)userID;

- (void)enterUserProfileWithUserID:(NSString *)userID;

@end

NS_ASSUME_NONNULL_END
