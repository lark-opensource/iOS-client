//
//  BDTicketGuard+TTNetAdapter.h
//  BDTicketGuard
//
//  Created by ByteDance on 2022/12/16.
//

#import "BDTGTicketManager.h"
#import <TTNetworkManager/TTNetworkManager.h>

NS_ASSUME_NONNULL_BEGIN


@interface BDTGTicketManager (AdapterInner)

+ (void)addTTNetRequestForPassportAccessTokenFilterBlock;

@end

NS_ASSUME_NONNULL_END
