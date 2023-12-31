//
//  IESGurdSettingsResponseExtra.m
//  Pods

#import "IESGurdSettingsResponseExtra.h"

#import "IESGeckoDefines+Private.h"
#import "NSDictionary+IESGurdKit.h"

@implementation IESGurdSettingsResponseExtra

+ (instancetype)extraWithDictionary:(NSDictionary *)dictionary
{
    if (!GURD_CHECK_DICTIONARY(dictionary)) {
        return nil;
    }
    IESGurdSettingsResponseExtra *extra = [[self alloc] init];
    extra.noLocalAk = [dictionary iesgurdkit_safeArrayWithKey:@"no_local_ak" itemClass:[NSString class]];
    return extra;
}

@end
