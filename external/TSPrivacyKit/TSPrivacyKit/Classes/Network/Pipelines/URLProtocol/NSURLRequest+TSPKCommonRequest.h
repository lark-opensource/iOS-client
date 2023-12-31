//
//  NSURLRequest+TSPKCommonRequest.h
//  TSPrivacyKit
//
//  Created by admin on 2022/9/2.
//

#import <Foundation/Foundation.h>
#import "TSPKCommonRequestProtocol.h"

extern NSString *_Nonnull const TSPKNetworkSessionDropKey;
extern NSString *_Nonnull const TSPKNetworkSessionDropMessageKey;
extern NSString *_Nonnull const TSPKNetworkSessionDropCodeKey;
extern NSString *_Nonnull const TSPKNetworkSessionHandleKey;

@interface NSURLRequest (TSPKCommonRequest) <TSPKCommonRequestProtocol>

@end

@interface NSMutableURLRequest (TSPKCommonRequest) <TSPKCommonRequestProtocol>

@end
