//
//  HMDInfo+CustomInfo.h
//  Heimdallr
//
//  Created by joy on 2018/4/27.
//

#import "HMDInfo.h"

@interface HMDInfo (CustomInfo)

@property (nonatomic, assign, readonly) BOOL isInHouseApp;
@property (nonatomic, strong, readonly) NSString *ssAppMID;
@property (nonatomic, strong, readonly) NSString *ssAppScheme;
@property (nonatomic, strong, readonly) NSString *appOwnURL;
@property (nonatomic, assign, readonly) BOOL isUpgradeUser;

@end
