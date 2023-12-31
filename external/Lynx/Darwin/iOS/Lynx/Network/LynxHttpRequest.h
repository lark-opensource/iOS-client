//  Copyright 2022 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LynxHttpRequest : NSObject

@property(nullable, copy) NSString *HTTPMethod;

@property(nullable, copy) NSURL *URL;

@property(nullable, copy) NSData *HTTPBody;

@property(nullable, copy) NSDictionary<NSString *, NSString *> *allHTTPHeaderFields;

@property BOOL addCommonParams;

@property(nullable, copy) NSDictionary<NSString *, NSObject *> *params;

@end

@interface LynxHttpResponse : NSObject

@property NSInteger statusCode;

@property NSInteger clientCode;

@property(nullable, copy) NSDictionary *allHeaderFields;

@property(nullable, copy) NSURL *URL;

@property(nullable, copy) NSString *MIMEType;

@property(nullable) id body;

@property(nullable) NSError *error;

@end

NS_ASSUME_NONNULL_END
