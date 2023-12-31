//
//  HMDConfigProviderProtocol.h
//  Heimdallr
//
//  Created by Nickyo on 2023/4/18.
//

// PrivateServices
#import "HMDURLProvider.h"

NS_ASSUME_NONNULL_BEGIN

@class HMDHeimdallrConfig;

@protocol HMDConfigHostProviderDataSource <NSObject>

@required
- (HMDHeimdallrConfig * _Nullable)mainConfig;
- (NSString * _Nullable)standardizeHost:(NSString *)host;

@end

@protocol HMDConfigHostProvider <HMDURLProvider>

@property (nullable, nonatomic, weak) id<HMDConfigHostProviderDataSource> dataSource;

@end

NS_ASSUME_NONNULL_END
