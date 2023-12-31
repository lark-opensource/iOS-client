//
//  IESPrefetchTemplateOutput.m
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/4.
//

#import "IESPrefetchTemplateOutput.h"

@implementation IESPrefetchTemplateInput

@synthesize variables;
@synthesize schema;
@synthesize name;
@synthesize traceId;

@end

@interface IESPrefetchTemplateOutput ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, IESPrefetchAPIModel *> *results;

@end

@implementation IESPrefetchTemplateOutput

- (void)merge:(id<IESPrefetchTemplateOutput>)anotherOutput
{
    if (self.results == nil) {
        self.results = [NSMutableDictionary new];
    }
    NSArray<IESPrefetchAPIModel *> *requests = [anotherOutput requestModels];
    [requests enumerateObjectsUsingBlock:^(IESPrefetchAPIModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.request.hashValue.length > 0) {
            self.results[obj.request.hashValue] = obj;
        }
    }];
}

- (NSArray<IESPrefetchAPIModel *> *)requestModels {
    return self.results.allValues;
}


- (void)addRequestModel:(IESPrefetchAPIModel *)model
{
    if (model == nil || model.request.hashValue.length == 0) {
        return;
    }
    if (self.results == nil) {
        self.results = [NSMutableDictionary new];
    }
    self.results[model.request.hashValue] = model;
}

@end
