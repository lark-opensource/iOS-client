//
//  IESGurdMonitorManager.h
//  IESGeckoKit-ByteSync-Config_CN-Core-Downloader-Example
//
//  Created by 陈煜钏 on 2021/5/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdMonitorManager : NSObject

@property (nonatomic, assign) NSInteger flushCount;

+ (instancetype)sharedManager;

- (void)monitorEvent:(NSString *)event
            category:(NSDictionary * _Nullable)category
              metric:(NSDictionary * _Nullable)metric
               extra:(NSDictionary * _Nullable)extra;

@end

NS_ASSUME_NONNULL_END
