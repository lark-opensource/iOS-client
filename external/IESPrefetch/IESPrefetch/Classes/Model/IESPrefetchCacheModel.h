//
//  IESPrefetchCacheModel.h
//  IESPrefetch
//
//  Created by Hao Wang on 2019/8/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESPrefetchCacheModel : NSObject

@property(nonatomic, readonly, assign) NSTimeInterval timeInterval; // 获取数据时间
@property(nonatomic, readonly, assign) NSTimeInterval expires;  // 缓存时间
@property(nonatomic, readonly, strong) id data; // 数据

+ (instancetype)modelWithData:(id)data
                 timeInterval:(NSTimeInterval)timeInterval
                      expires:(NSTimeInterval)expires;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)jsonSerializationDictionary;

- (BOOL)hasExpired;

@end

NS_ASSUME_NONNULL_END
