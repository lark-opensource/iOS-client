//
//  IESPrefetchOccasionTemplate.m
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/2.
//

#import "IESPrefetchOccasionTemplate.h"
#import "IESPrefetchTemplateOutput.h"
#import "IESPrefetchLogger.h"

@implementation IESPrefetchOccasionNode

@end

@interface IESPrefetchOccasionTemplate ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, IESPrefetchOccasionNode *> *occasions;

@end

@implementation IESPrefetchOccasionTemplate

@synthesize children;

- (void)addOccasionNode:(IESPrefetchOccasionNode *)node
{
    if (node.name.length == 0) {
        return;
    }
    if (self.occasions == nil) {
        self.occasions = [NSMutableDictionary new];
    }
    self.occasions[node.name] = node;
}

- (IESPrefetchOccasionNode *)nodeForName:(NSString *)name
{
    if (name.length == 0 || self.occasions.count == 0) {
        return nil;
    }
    IESPrefetchOccasionNode *node = self.occasions[name];
    return node;
}

- (NSUInteger)countOfNodes
{
    return self.occasions.count;
}

- (id<IESPrefetchTemplateOutput>)process:(id<IESPrefetchTemplateInput>)input
{
    IESPrefetchOccasion occasion = input.name;
    IESPrefetchOccasionNode *node = [self nodeForName:occasion];
    if (node == nil || node.rules.count == 0) {
        return nil;
    }
    PrefetchMatcherLogV(@"[%@]Hit occasion: %@", input.traceId, occasion);
    id<IESPrefetchTemplateOutput> output = [IESPrefetchTemplateOutput new];
    [node.rules enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        IESPrefetchTemplateInput *nextInput = [IESPrefetchTemplateInput new];
        nextInput.name = obj;
        nextInput.schema = input.schema;
        nextInput.variables = input.variables;
        nextInput.traceId = input.traceId;
        for (id<IESPrefetchConfigTemplate> child in self.children) {
            id<IESPrefetchTemplateOutput> childOutput = [child process:nextInput];
            [output merge:childOutput];
        }
    }];
    return output;
}

- (NSDictionary<NSString *,id> *)jsonRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [self.occasions enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, IESPrefetchOccasionNode * _Nonnull obj, BOOL * _Nonnull stop) {
        dict[key] = obj.rules;
    }];
    return @{@"occasion": dict.copy};
}

@end
