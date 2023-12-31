//
//  BDLynxGurdModule.h
//  BDLynx
//
//  Created by bill on 2020/2/4.
//

#define BDGurdLynxEnable 1

#import <Foundation/Foundation.h>
#import "BDLGurdModuleProtocol.h"

FOUNDATION_EXTERN NSString* const BDGurdLynxBusinessModuleDidSyncResources;
FOUNDATION_EXTERN NSString* const BDGurdLynxBusinessModuleDidSyncHighPriorityResources;

@interface BDLynxGurdModule : NSObject <BDLGurdModuleProtocol>

+ (instancetype)sharedInstance;

@end
