//
//  IESGurdByteSyncMessageManager+Setup.m
//  IESGeckoKit
//
//  Created by bytedance on 2021/10/27.
//

#import "IESGurdByteSyncMessageManager+Setup.h"

#import <BDUGSyncSDK/BDUGSyncManager.h>

@implementation IESGurdByteSyncMessageManager (Setup)

+ (void)setupWithType:(IESGurdByteSyncBusinessType)type
{
    [[BDUGSyncManager sharedManager] addObserverForBusinessID:[self businessIdWithType:type]
                                                   usingBlock:^(BDUGSyncClientData * _Nonnull data, NSInteger businessID) {
        NSDictionary *messageDictionary = [NSJSONSerialization JSONObjectWithData:data.data options:0 error:NULL];
        if (![messageDictionary isKindOfClass:[NSDictionary class]]) {
            return;
        }
        [self handleMessageDictionary:messageDictionary];
    }];
}

@end
