//
//  TSPKNetworkManager.h
//  Indexer
//
//  Created by bytedance on 2022/4/6.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, TSPKNetworkStatus);

@interface TSPKNetworkManager : NSObject

+ (nonnull instancetype)shared;

- (void)initializeNetworkInfo;

- (BOOL)checkIfIPAddressInSameSubnet:(nullable NSString *)networkAddress;

- (TSPKNetworkStatus)currentNetworkStatus;

@end
