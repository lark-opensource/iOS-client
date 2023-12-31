//
//  EMANetworkRequestManager.h
//  EEMicroAppSDK
//
//  Created by houjihu on 2019/9/5.
//

#import <Foundation/Foundation.h>
#import <ECOInfra/BDPNetworkProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURLSessionTask(BDPNetwork) <BDPNetworkTaskProtocol>
@end

@interface NSURLResponse (BDPNetwork) <BDPNetworkResponseProtocol>
@end

@interface EMANetworkRequestManager : NSObject<BDPNetworkRequestProtocol>

@end

NS_ASSUME_NONNULL_END
