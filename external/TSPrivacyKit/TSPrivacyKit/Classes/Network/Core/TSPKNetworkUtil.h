//
//  TSPKNetworkUtil.h
//  T-Develop
//
//  Created by admin on 2022/10/25.
//

#import <Foundation/Foundation.h>

@interface TSPKNetworkUtil : NSObject

+ (void)updateMonitorStartTime;
+ (NSTimeInterval)monitorStartTime;

+ (NSString *_Nullable)realPathFromURL:(NSURL *_Nullable)url;
+ (NSMutableDictionary *_Nullable)cookieString2MutableDict:(NSString *_Nullable)string;
+ (NSString *_Nullable)cookieDict2String:(NSDictionary *_Nullable)dict;

+ (NSData *_Nullable)bodyStream2Data:(NSInputStream *_Nullable)bodyStream;

+ (NSURL *_Nullable)URLWithURLString:(NSString *_Nullable)str;
+ (NSString *_Nullable)URLStringWithoutQuery:(NSString *_Nullable)urlString;

+ (NSArray<NSURLQueryItem *> *_Nullable)convertQueryToArray:(NSString *_Nullable)queryString;
+ (NSString *_Nullable)convertArrayToQuery:(NSArray<NSURLQueryItem *> *_Nullable)queryItems;

@end
