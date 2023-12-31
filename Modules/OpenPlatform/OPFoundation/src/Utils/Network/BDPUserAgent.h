//
//  BDPUserAgent.h
//  Timor
//
//  Created by zhoushijie on 2019/1/4.
//

#import <Foundation/Foundation.h>

@class OPAppUniqueID;

@interface BDPUserAgent : NSObject

+ (NSString *)getOriginUserAgentString;
+ (NSString *)getAppNameAndVersionString;
+ (NSString *)getUserAgentString;
+ (NSString *)getUserAgentStringWithUniqueID:(OPAppUniqueID *)uniqueID;
+ (NSString *)getUserAgentStringWithUniqueID:(OPAppUniqueID *)uniqueID webviewID:(NSString *)webviewID ;

@end
