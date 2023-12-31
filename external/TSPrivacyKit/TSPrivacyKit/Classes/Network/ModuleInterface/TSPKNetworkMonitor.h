//
//  TSPKNetworkMonitor.h
//  TSPrivacyKit
//
//  Created by admin on 2022/8/24.
//

#import <Foundation/Foundation.h>

@interface TSPKNetworkMonitor : NSObject

+ (void)start;

+ (void)setConfig:(NSDictionary *_Nullable)config;

@end
