//
//  IESPrefetchRequestModel.h
//  IESPrefetch
//
//  Created by Hao Wang on 2019/6/28.
//

#import <Foundation/Foundation.h>
#import "IESPrefetchDefines.h"
#import "IESPrefetchParamModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESPrefetchRequestModel : NSObject

@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *method;
@property (nonatomic, copy) IESPrefetchOccasion occasion;
@property (nonatomic, assign) int64_t expires;
@property (nonatomic, copy) NSDictionary *headers;
@property (nonatomic, copy) NSDictionary<NSString *, IESPrefetchParamModel *> *params;
@property (nonatomic, copy) NSDictionary<NSString *, IESPrefetchParamModel *> *data;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end


NS_ASSUME_NONNULL_END
