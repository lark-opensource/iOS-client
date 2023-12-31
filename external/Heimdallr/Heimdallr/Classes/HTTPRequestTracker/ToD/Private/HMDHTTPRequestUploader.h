//
//  HMDHTTPRequestUploader.h
//  Heimdallr
//
//  Created by fengyadong on 2018/11/19.
//

#import <Foundation/Foundation.h>

@protocol HMDRecordStoreObject;

NS_ASSUME_NONNULL_BEGIN

@interface HMDHTTPRequestUploader : NSObject

- (instancetype)initWithlogType:(NSString *)logType
                 recordClass:(Class<HMDRecordStoreObject>)recordClass;

- (instancetype)initWithlogType:(NSString *)logType
                 recordClass:(Class<HMDRecordStoreObject>)recordClass
                         sdkAid:(NSString *)sdkAid
             sdkStartUploadTime:(NSTimeInterval)startTime;

@end

NS_ASSUME_NONNULL_END
