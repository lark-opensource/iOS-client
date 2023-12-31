//
//  TSPKCommonRequest.h
//  TSPrivacyKit
//
//  Created by admin on 2022/9/2.
//

#import <Foundation/Foundation.h>

@protocol TSPKCommonRequestProtocol

@property (copy, nullable) NSURL *tspk_util_url;
@property (copy, readonly, nullable) NSDictionary<NSString *, NSString *> *tspk_util_headers;
@property (copy, readonly, nullable) NSData *tspk_util_HTTPBody;
@property (copy, readonly, nullable) NSInputStream *tspk_util_HTTPBodyStream;
@property (copy, readonly, nullable) NSString *tspk_util_HTTPMethod;
@property (copy, readonly, nullable) NSString *tspk_util_eventType;
@property (copy, readonly, nullable) NSString *tspk_util_eventSource;
@property (nonatomic, readonly) BOOL tspk_util_isRedirect;

- (void)tspk_util_setValue:(NSString *_Nullable)value forHTTPHeaderField:(NSString *_Nullable)field;
- (NSString *_Nullable)tspk_util_valueForHTTPHeaderField:(NSString *_Nullable)field;
- (void)tspk_util_doDrop:(NSDictionary *_Nullable)actions;

@end
