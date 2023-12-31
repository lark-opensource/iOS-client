//
//  HMDConfigDataProcessProtocol.h
//  Heimdallr
//
//  Created by Nickyo on 2023/4/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class HMDHeimdallrConfig;
@protocol HMDConfigDataProcess;

@protocol HMDConfigDataProcessDelegate <NSObject>

@required
- (void)dataProcessorFinishProcessResponseData:(id<HMDConfigDataProcess>)dataProcessor configs:(NSDictionary<NSString *, HMDHeimdallrConfig *> *)configs updateAppIDs:(NSArray<NSString *> *)updateAppIDs;

@end

@protocol HMDConfigDataProcessDataSource <NSObject>

@required
- (NSString *)configPathWithAppID:(NSString *)appID;
- (BOOL)needForceRefreshSettings:(NSString *)appID;

@end

@protocol HMDConfigDataProcess <NSObject>

@property (nullable, nonatomic, weak) id<HMDConfigDataProcessDelegate> delegate;
@property (nullable, nonatomic, weak) id<HMDConfigDataProcessDataSource> dataSource;

- (void)processResponseData:(NSDictionary * _Nullable)data;

@end

NS_ASSUME_NONNULL_END
