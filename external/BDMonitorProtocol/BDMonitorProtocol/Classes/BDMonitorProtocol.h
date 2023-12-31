//
//  BDMonitorProtocol.h
//  BDAlogProtocol
//
//  Created by 李琢鹏 on 2019/3/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDMonitorProtocol : NSObject

+ (void)hmdTrackService:(NSString *)serviceName metric:(NSDictionary <NSString *, NSNumber *> *)metric category:(NSDictionary *)category extra:(NSDictionary *)extraValue;


+ (void)hmdTrackData:(NSDictionary *)data logType:(NSString *)logType;

@end

NS_ASSUME_NONNULL_END
