//
//  HMDTTMonitorServiceProtocol.h
//  Heimdallr
//
//  Created by bytedance on 2022/10/27.
//

#import <Foundation/Foundation.h>


@protocol HMDTTMonitorServiceProtocol <NSObject>

- (void)hookTTMonitorInterfaceIfNeeded:(NSNumber *_Nullable)needHook;

- (void)hmdTrackService:(NSString *_Nullable)serviceName metric:(NSDictionary <NSString *, NSNumber *> *_Nullable)metric category:(NSDictionary *_Nullable)category extra:(NSDictionary *_Nullable)extraValue;

- (void)hmdTrackService:(NSString *_Nullable)serviceName metric:(NSDictionary <NSString *, NSNumber *> *_Nullable)metric category:(NSDictionary *_Nullable)category extra:(NSDictionary *_Nullable)extraValue syncWrite:(BOOL)syncWrite;

- (void)hmdUploadImmediatelyTrackService:(NSString *_Nullable)serviceName metric:(NSDictionary <NSString *, NSNumber *> *_Nullable)metric category:(NSDictionary *_Nullable)category extra:(NSDictionary *_Nullable)extraValue;
@end


