//
//  TSPKNetworkReporter.h
//  Musically
//
//  Created by admin on 2022/10/18.
//

#import <Foundation/Foundation.h>
@class TSPKNetworkEvent;

@interface TSPKNetworkReporter : NSObject

+ (void)reportWithCommonInfo:(NSDictionary *_Nullable)dict networkEvent:(TSPKNetworkEvent *_Nullable)networkEvent;
+ (void)perfWithName:(NSString *_Nullable)name calledTime:(NSTimeInterval)calledTime;
+ (void)perfWithName:(NSString *_Nullable)name calledTime:(NSTimeInterval)calledTime networkEvent:(TSPKNetworkEvent *_Nullable)networkEvent;

@end
