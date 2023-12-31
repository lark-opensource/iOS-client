//
//  TSPKContactOfCNContactStorePipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/13.
//

#import "TSPKContactOfCNContactStorePipeline.h"
#import <Contacts/CNContactStore.h>
#import "NSObject+TSAddition.h"
#import "TSPKUtils.h"
#import "TSPKCacheEnv.h"
#import "TSPKPipelineSwizzleUtil.h"

@implementation CNContactStore (TSPrivacyKitContact)

+ (void)tspk_contact_preload {
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKContactOfCNContactStorePipeline class] clazz:self];
}

- (BOOL)tspk_contact_enumerateContactsWithFetchRequest:(CNContactFetchRequest *)fetchRequest error:(NSError **)error usingBlock:(void (^)(CNContact *contact, BOOL *stop))block
{
    NSString *method = NSStringFromSelector(@selector(enumerateContactsWithFetchRequest:error:usingBlock:));
    NSString *className = [TSPKContactOfCNContactStorePipeline stubbedClass];
    TSPKHandleResult *result = [TSPKContactOfCNContactStorePipeline handleAPIAccess:NSStringFromSelector(@selector(enumerateContactsWithFetchRequest:error:usingBlock:)) className:NSStringFromClass([CNContactStore class])];
    if (result.action == TSPKResultActionFuse) {
        return NO;
    } else if (result.action == TSPKResultActionCache) {
        NSString *api = [TSPKUtils concateClassName:className method:method];
        if (!result.cacheNeedUpdate) {
            return NO;
        }
        BOOL originResult = [self tspk_contact_enumerateContactsWithFetchRequest:fetchRequest error:error usingBlock:block];
        [[TSPKCacheEnv shareEnv] updateCache:api newValue:@(originResult)];
        return originResult;
    } else {
        return [self tspk_contact_enumerateContactsWithFetchRequest:fetchRequest error:error usingBlock:block];
    }
}

- (void)tspk_contact_requestAccessForEntityType:(CNEntityType)entityType completionHandler:(void (^)(BOOL granted, NSError *__nullable error))completionHandler
{
    TSPKHandleResult *result = [TSPKContactOfCNContactStorePipeline handleAPIAccess:NSStringFromSelector(@selector(requestAccessForEntityType:completionHandler:)) className:[TSPKContactOfCNContactStorePipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        if (completionHandler) {
            completionHandler(NO, [TSPKUtils fuseError]);
        }
    } else {
        [self tspk_contact_requestAccessForEntityType:entityType completionHandler:completionHandler];
    }
}

@end

@implementation TSPKContactOfCNContactStorePipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineContactOfCNContactStore;
}

+ (NSString *)dataType {
    return TSPKDataTypeContact;
}

+ (NSString *)stubbedClass
{
  return @"CNContactStore";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return nil;
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    return @[
        NSStringFromSelector(@selector(requestAccessForEntityType:completionHandler:)),
        NSStringFromSelector(@selector(enumerateContactsWithFetchRequest:error:usingBlock:))
    ];
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [CNContactStore tspk_contact_preload];
    });
}

@end
