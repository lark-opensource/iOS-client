//
//  HMDExtensionCrashTracker.h
//  HeimdallrForExtension
//
//  Created by xuminghao.eric on 2020/8/14.
//

#import <Foundation/Foundation.h>
#import "HMDInjectedInfo.h"


@interface HMDExtensionCrashTracker : NSObject

+ (instancetype)sharedTracker;
- (void)startWithGroupID:(NSString * _Nullable)groupID;

@end

