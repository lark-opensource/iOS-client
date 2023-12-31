//
//  ACCEventContext.h
//  Pods
//
//  Created by chengfei xiao on 2019/8/1.
//

#import <Foundation/Foundation.h>
#import "ACCAttributeBuilder.h"
#import "ACCAttributeBuilder+Attribute.h"

@interface ACCEventContext : NSObject

@property (nonatomic, strong, readonly) NSDictionary *attributes;
@property (nonatomic, strong, readonly) ACCEventContext *baseContext;

+ (instancetype)contextWithContext:(ACCEventContext *)context;
+ (instancetype)contextWithBaseContext:(ACCEventContext *)baseContext;

- (instancetype)makeAttributes:(void(^)(ACCAttributeBuilder *builder))block;
- (instancetype)updateAttributes:(void(^)(ACCAttributeBuilder *builder))block;
@end

