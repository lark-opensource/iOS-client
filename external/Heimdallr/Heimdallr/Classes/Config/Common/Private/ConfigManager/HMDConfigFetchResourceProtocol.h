//
//  HMDConfigFetchResourceProtocol.h
//  Heimdallr
//
//  Created by Nickyo on 2023/5/30.
//

#import <Foundation/Foundation.h>
#import "HMDConfigFetcher.h"

NS_ASSUME_NONNULL_BEGIN

@class HMDConfigStore;
@protocol HMDConfigDataProcess;
@protocol HMDConfigHostProvider;

@protocol HMDConfigFetchResource <HMDConfigFetchDelegate, HMDConfigFetchDataSource>

- (instancetype)initWithStore:(HMDConfigStore *)store dataProcessor:(id<HMDConfigDataProcess>)dataProcessor hostProvider:(id<HMDConfigHostProvider>)hostProvider;

@end

NS_ASSUME_NONNULL_END
