//
//  HMDInfo+AppInfo.h
//  Heimdallr
//
//  Created by 谢俊逸 on 8/4/2018.
//

#import "HMDInfo.h"

#ifdef Heimdallr_POD_VERSION
static NSString *const kHeimdallrPodVersion = Heimdallr_POD_VERSION;
#else
static NSString *const kHeimdallrPodVersion = @"0.8.2";
#endif

@interface HMDInfo (AppInfo)

@property (nonatomic, strong, readonly) NSString *appDisplayName;
@property (nonatomic, strong, readonly) NSString *shortVersion;
@property (nonatomic, strong, readonly) NSString *bundleIdentifier;
@property (nonatomic, strong, readonly) NSString *buildVersion;
@property (nonatomic, strong, readonly) NSString *version;
@property (nonatomic, strong, readonly) NSString *commitID;
@property (nonatomic, strong, readonly) NSString *emUUID;
@property (nonatomic, strong, readonly) NSString *sdkVersion;
@property (nonatomic, assign, readonly) NSInteger sdkVersionCode;

@end
