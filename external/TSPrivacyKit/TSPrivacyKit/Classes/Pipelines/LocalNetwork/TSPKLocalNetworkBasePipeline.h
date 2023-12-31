//
//  TSPKLocalNetworkBasePipeline.h
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/14.
//

#import <Foundation/Foundation.h>
#import "TSPKDetectPipeline.h"

@interface TSPKLocalNetworkBasePipeline : TSPKDetectPipeline

+ (TSPKHandleResult *_Nullable)handleAPIAccess:(NSString *_Nullable)api networkAddress:(NSString *_Nullable)networkAddresses;

@end
