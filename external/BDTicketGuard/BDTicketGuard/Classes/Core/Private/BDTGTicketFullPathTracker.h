//
//  BDTGTicketFullPathTracker.h
//  Aweme
//
//  Created by ByteDance on 2023/9/10.
//

#import <Foundation/Foundation.h>
#import "BDTicketGuard+Private.h"

NS_ASSUME_NONNULL_BEGIN


@interface BDTGTicketFullPathTracker : NSObject

+ (instancetype)sharedInstance;

+ (NSDictionary *)snapshotForRequest:(id<BDTGHttpRequest>)request response:(id<BDTGHttpResponse>)response;

- (void)serverDataDidUpdateWithRequset:(id<BDTGHttpRequest>)request response:(id<BDTGHttpResponse>)response;

- (void)ticketDidUpdateWithRequset:(id<BDTGHttpRequest>)requst response:(id<BDTGHttpResponse>)response ticketName:(NSString *)ticketName ticket:(NSString *)ticket tsSign:(NSString *)tsSign;

- (void)signVerifyErrorUpdateWithRequest:(id<BDTGHttpRequest>)request response:(id<BDTGHttpResponse>)response;

@end

NS_ASSUME_NONNULL_END
