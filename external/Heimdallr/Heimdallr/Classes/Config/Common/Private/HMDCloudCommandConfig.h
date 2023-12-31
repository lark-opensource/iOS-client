//
//  HMDCloudCommandConfig.h
//  Pods
//
//  Created by liuhan on 2022/12/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HMDCloudCommandConfig : NSObject

@property (nonatomic, copy, readonly, nullable) NSArray<NSString *> *complianceRelativePaths; // 磁盘回捞需要脱敏的路径

- (instancetype)initWithParams:(NSDictionary *)params;
@end

NS_ASSUME_NONNULL_END
