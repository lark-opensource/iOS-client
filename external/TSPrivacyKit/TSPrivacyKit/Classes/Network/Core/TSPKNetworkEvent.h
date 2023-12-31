//
//  TSPKNetworkEvent.h
//  TSPrivacyKit
//
//  Created by admin on 2022/8/24.
//

#import <Foundation/Foundation.h>
#import "TSPKEvent.h"

#import "TSPKCommonRequestProtocol.h"
#import "TSPKCommonResponseProtocol.h"

@interface TSPKNetworkEvent : TSPKEvent

@property (nonatomic, strong, nullable) id<TSPKCommonRequestProtocol> request;
@property (nonatomic, strong, nullable) id<TSPKCommonResponseProtocol> response;
@property (nonatomic, strong, nullable) NSData *responseData;

@end
