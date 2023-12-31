//
//  TSPKCommonResponseProtocol.h
//  TSPrivacyKit
//
//  Created by admin on 2022/9/2.
//

#import <Foundation/Foundation.h>

@protocol TSPKCommonResponseProtocol <NSObject>

@property (copy, readonly, nullable) NSURL *tspk_util_url;
@property (copy, readonly, nullable) NSDictionary<NSString *, NSString *> *tspk_util_headers;

- (NSString *_Nullable)tspk_util_valueForHTTPHeaderField:(NSString *_Nullable)field;

@end
