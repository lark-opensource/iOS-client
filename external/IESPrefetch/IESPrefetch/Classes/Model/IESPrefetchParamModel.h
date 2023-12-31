//
//  IESPrefetchParamModel.h
//  IESPrefetch
//
//  Created by Hao Wang on 2019/7/31.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, IESPrefetchParamType) {
    IESPrefetchParamTypeStatic = 0,
    IESPrefetchParamTypeQuery,
};

@interface IESPrefetchParamModel : NSObject

@property(nonatomic, assign) IESPrefetchParamType type;
@property(nonatomic, strong) NSString *value;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
