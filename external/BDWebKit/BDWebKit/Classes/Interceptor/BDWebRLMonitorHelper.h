//
//  BDWebRLMonitorHelper.h
//  Pods
//
//  Created by bytedance on 4/18/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^bdwRLMonitorBlock)(NSString* eventType, NSDictionary *eventInfo);

extern void bdwResourceLoaderMonitorDic (NSDictionary *dic, bdwRLMonitorBlock callback);

NS_ASSUME_NONNULL_END
