//
//  IESPrefetchProjectTemplate.m
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/2.
//

#import "IESPrefetchProjectTemplate.h"
#import "IESPrefetchLogger.h"
#import "IESPrefetchTemplateOutput.h"

@interface IESPrefetchProjectTemplate ()

@end

@implementation IESPrefetchProjectTemplate

@synthesize children;

- (id<IESPrefetchTemplateOutput>)process:(id<IESPrefetchTemplateInput>)input
{
    id<IESPrefetchTemplateOutput> output = [IESPrefetchTemplateOutput new];
    [self.children enumerateObjectsUsingBlock:^(id<IESPrefetchConfigTemplate>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        id<IESPrefetchTemplateOutput> childOutput = [obj process:input];
        [output merge:childOutput];
    }];
    return output;
}

- (NSDictionary<NSString *,id> *)jsonRepresentation
{
    NSMutableDictionary<NSString *, id> *dict = [NSMutableDictionary new];
    dict[@"project"] = self.project;
    dict[@"version"] = self.version;
    
    [self.children enumerateObjectsUsingBlock:^(id<IESPrefetchConfigTemplate>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [dict addEntriesFromDictionary:[obj jsonRepresentation]];
    }];
    
    return dict.copy;
}

@end
