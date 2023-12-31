//
//  ACCExternalBussinessTemplate.m
//  CreativeKit-Pods-Aweme
//
//  Created by xiangpeng on 2021/7/19.
//

#import "ACCExternalBussinessTemplate.h"

#ifndef ACCAutoInjectClass
#define ACCAutoInjectClass(provider, property, cls) -(cls *)property  { \
if (!_##property) {\
_##property = [provider resolveObject:NSClassFromString(@#cls)]; \
}\
return _##property;\
}
#endif

@interface ACCExternalBussinessTemplate ()

@property (nonatomic, weak) id<IESServiceProvider> context;

@end

@implementation ACCExternalBussinessTemplate

@synthesize repository = _repository;

ACCAutoInjectClass(self.context, repository, AWEVideoPublishViewModel)

- (instancetype)initWithContext:(id<IESServiceProvider>)context
{
    if (self = [super init]) {
        _context = context;
    }
    return self;
}

-(NSArray<ACCFeatureComponentClass> *)componentClasses
{
    return @[];
}

@end
