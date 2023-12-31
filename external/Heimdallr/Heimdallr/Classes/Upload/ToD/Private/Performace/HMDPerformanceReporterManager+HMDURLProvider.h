//
//  HMDPerformanceReporterManager+HMDURLProvider.h
//  Heimdallr
//
//  Created by Nickyo on 2023/8/22.
//

#import "HMDPerformanceReporterManager.h"
#import "HMDNetworkProvider.h"
// PrivateServices
#import "HMDURLProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDPerformanceReporterManager (HMDURLProvider) <HMDURLProvider>

@end

@interface HMDPerformanceReporterURLPathProvider : NSObject <HMDURLPathProvider>

- (instancetype)initWithProvider:(id<HMDNetworkProvider> _Nullable)provider;

@end

NS_ASSUME_NONNULL_END
