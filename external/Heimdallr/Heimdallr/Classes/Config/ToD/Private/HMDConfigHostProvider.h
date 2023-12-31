//
//  HMDConfigHostProvider.h
//  Heimdallr
//
//  Created by Nickyo on 2023/4/18.
//

#import "HMDConfigHostProviderProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDConfigHostProvider : NSObject <HMDConfigHostProvider>

@property (nullable, nonatomic, weak) id<HMDConfigHostProviderDataSource> dataSource;

@end

NS_ASSUME_NONNULL_END
