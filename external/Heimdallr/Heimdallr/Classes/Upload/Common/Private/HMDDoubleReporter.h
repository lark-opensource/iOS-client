//
//  HMDDoubleReporter.h
//  Heimdallr
//
//  Created by bytedance on 2022/3/7.
//

#import <Foundation/Foundation.h>

@class HMDHeimdallrConfig;

NS_ASSUME_NONNULL_BEGIN

@protocol HMDDoubleReporterDelegate <NSObject>

- (void)doubleUploadNetworkRecordArray:(NSArray *)records toURLString:(NSString *)urlstring;

@end

@interface HMDDoubleReporter : NSObject

@property(nonatomic, weak)id<HMDDoubleReporterDelegate> delegate;

@property (nonatomic, assign)BOOL isRunning;

@property (nonatomic, copy)NSSet *allowPathSet;

+ (nonnull instancetype)sharedReporter;

- (void)update:(HMDHeimdallrConfig *)config;

- (void)doubleUploadRecordArray:(NSArray *)records;

@end

NS_ASSUME_NONNULL_END
