//
//  IESPrefetchConfigTemplate.h
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/2.
//

#import <Foundation/Foundation.h>
#import "IESPrefetchFlatSchema.h"
#import "IESPrefetchDefines.h"

@class IESPrefetchAPIModel;

NS_ASSUME_NONNULL_BEGIN

@protocol IESPrefetchTemplateInput <NSObject>

@property (nonatomic, copy, nullable) NSDictionary<NSString *, id> *variables;
@property (nonatomic, copy, nullable) NSString *name;
@property (nonatomic, strong, nullable) IESPrefetchFlatSchema *schema;
@property (nonatomic, copy, nullable) NSString *traceId;

@end

@protocol IESPrefetchTemplateOutput <NSObject>

- (void)merge:(id<IESPrefetchTemplateOutput>)anotherOutput;
- (NSArray<IESPrefetchAPIModel *> *)requestModels;

@end

@protocol IESPrefetchConfigTemplate <NSObject>

@property (nonatomic, strong) NSArray<id<IESPrefetchConfigTemplate>> * children;

- (id<IESPrefetchTemplateOutput>)process:(id<IESPrefetchTemplateInput>)input;

- (NSDictionary<NSString *, id> *)jsonRepresentation;

@end

NS_ASSUME_NONNULL_END
