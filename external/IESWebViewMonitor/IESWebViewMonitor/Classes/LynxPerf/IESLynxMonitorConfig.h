//
//  IESLynxMonitorConfig.h
//  IESWebViewMonitor
//
//  Created by 小阿凉 on 2020/3/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESLynxMonitorConfig : NSObject

@property (nonatomic, copy, readonly) NSString *sessionID;
@property (nonatomic, copy) NSString *pageName;
@property (nonatomic, copy) NSString *channel;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *tag;
@property (nonatomic, assign, getter=isOffline) BOOL offline;

@property (nonatomic, readonly) NSDictionary *commonParams;

+ (NSString *)lynxVersion;

@end

NS_ASSUME_NONNULL_END
