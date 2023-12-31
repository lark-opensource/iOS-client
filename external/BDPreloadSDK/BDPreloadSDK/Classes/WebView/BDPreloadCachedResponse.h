//
//  BDPreloadCachedResponse.h
//  BDPreloadSDK
//
//  Created by Nami on 2019/2/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDPreloadCachedResponse : NSObject<NSCoding>

@property (nonatomic, assign) NSInteger statusCode;
@property (nonatomic, copy) NSDictionary *allHeaderFields;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, assign) NSTimeInterval saveTime;
@property (nonatomic, assign) NSTimeInterval cacheDuration;

@end

NS_ASSUME_NONNULL_END
