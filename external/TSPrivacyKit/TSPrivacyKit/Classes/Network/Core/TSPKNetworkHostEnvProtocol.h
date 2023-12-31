//
//  TSPKNetworkHostEnvProtocol.h
//  TSPrivacyKit
//
//  Created by admin on 2022/9/9.
//

#import <Foundation/Foundation.h>
#import "TSPKCommonRequestProtocol.h"
#import "TSPKCommonResponseProtocol.h"

@protocol TSPKNetworkHostEnvProtocol <NSObject>

@optional
+ (NSString *_Nullable)getValueFromAppContextByKey:(NSString *_Nullable)key;
+ (NSString *_Nullable)eventSourceFromRequest:(id<TSPKCommonRequestProtocol> _Nullable)request;
+ (NSDictionary *_Nullable)otherInformationFromRequest:(id<TSPKCommonRequestProtocol> _Nullable)request;
+ (NSArray<NSString *> *_Nullable)commonDropUploadInfoByKeys;
+ (NSArray<NSString *> *_Nullable)moveValue2ExtraInfoByKeys;

@end
