//
//  IESFalconStatModel.h
//  IESWebKit-Pods-Aweme
//
//  Created by 陈煜钏 on 2019/10/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESFalconStatModel : NSObject

@property (nonatomic, copy) NSString *resourceURLString;

@property (nonatomic, copy) NSString *offlineRule;

@property (nonatomic, copy) NSString *mimeType;

@property (nonatomic, assign) NSInteger offlineStatus;

@property (nonatomic, assign) NSInteger offlineDuration;

@property (nonatomic, assign) NSInteger onlineDuration;

@property (nonatomic, copy) NSString *accessKey;

@property (nonatomic, copy) NSString *channel;

@property (nonatomic, assign) uint64_t packageVersion;

@property (nonatomic, assign) NSInteger errorCode;

@property (nonatomic, copy) NSString *errorMessage;

@property (nonatomic, assign) NSInteger falconDataLength;

@property (nonatomic, assign) CFTimeInterval readDuration;

@property (nonatomic, copy, nullable) NSArray<NSString *> *bundles;

- (NSDictionary *)statDictionary;

@end

NS_ASSUME_NONNULL_END
