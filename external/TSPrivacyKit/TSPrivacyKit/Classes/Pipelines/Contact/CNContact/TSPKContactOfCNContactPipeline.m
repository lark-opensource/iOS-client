//
//  TSPKContactOfCNContactPipeline.m
//  Musically
//
//  Created by ByteDance on 2023/1/9.
//

#import "TSPKContactOfCNContactPipeline.h"
#import "TSPKPipelineSwizzleUtil.h"
#import <Contacts/CNContact.h>

@implementation CNContact (TSPrivacyKitContact)

+ (void)tspk_contact_preload {
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKContactOfCNContactPipeline class] clazz:self];
}

- (NSArray *)tspk_contact_phoneNumbers {
    NSString *method = NSStringFromSelector(@selector(phoneNumbers));
    NSString *className = [TSPKContactOfCNContactPipeline stubbedClass];
    TSPKHandleResult *result = [TSPKContactOfCNContactPipeline handleAPIAccess:method className:className];
    if (result.action == TSPKResultActionFuse) {
        return [result getObjectWithReturnType:@"NSArray" defaultValue:nil];
    } else {
        return [self tspk_contact_phoneNumbers];
    }
}

- (NSArray *)tspk_contact_emailAddresses {
    NSString *method = NSStringFromSelector(@selector(emailAddresses));
    NSString *className = [TSPKContactOfCNContactPipeline stubbedClass];
    TSPKHandleResult *result = [TSPKContactOfCNContactPipeline handleAPIAccess:method className:className];
    if (result.action == TSPKResultActionFuse) {
        return [result getObjectWithReturnType:@"NSArray" defaultValue:nil];
    } else {
        return [self tspk_contact_emailAddresses];
    }
}

- (NSArray *)tspk_contact_postalAddresses {
    NSString *method = NSStringFromSelector(@selector(postalAddresses));
    NSString *className = [TSPKContactOfCNContactPipeline stubbedClass];
    TSPKHandleResult *result = [TSPKContactOfCNContactPipeline handleAPIAccess:method className:className];
    if (result.action == TSPKResultActionFuse) {
        return [result getObjectWithReturnType:@"NSArray" defaultValue:nil];
    } else {
        return [self tspk_contact_postalAddresses];
    }
}

- (NSString *)tspk_contact_givenName {
    NSString *method = NSStringFromSelector(@selector(givenName));
    NSString *className = [TSPKContactOfCNContactPipeline stubbedClass];
    TSPKHandleResult *result = [TSPKContactOfCNContactPipeline handleAPIAccess:method className:className];
    if (result.action == TSPKResultActionFuse) {
        return [result getObjectWithReturnType:@"NSString" defaultValue:nil];
    } else {
        return [self tspk_contact_givenName];
    }
}

- (NSString *)tspk_contact_familyName {
    NSString *method = NSStringFromSelector(@selector(familyName));
    NSString *className = [TSPKContactOfCNContactPipeline stubbedClass];
    TSPKHandleResult *result = [TSPKContactOfCNContactPipeline handleAPIAccess:method className:className];
    if (result.action == TSPKResultActionFuse) {
        return [result getObjectWithReturnType:@"NSString" defaultValue:nil];
    } else {
        return [self tspk_contact_familyName];
    }
}

- (NSString *)tspk_contact_jobTitle {
    NSString *method = NSStringFromSelector(@selector(jobTitle));
    NSString *className = [TSPKContactOfCNContactPipeline stubbedClass];
    TSPKHandleResult *result = [TSPKContactOfCNContactPipeline handleAPIAccess:method className:className];
    if (result.action == TSPKResultActionFuse) {
        return [result getObjectWithReturnType:@"NSString" defaultValue:nil];
    } else {
        return [self tspk_contact_jobTitle];
    }
}

- (NSDateComponents *)tspk_contact_birthday {
    NSString *method = NSStringFromSelector(@selector(birthday));
    NSString *className = [TSPKContactOfCNContactPipeline stubbedClass];
    TSPKHandleResult *result = [TSPKContactOfCNContactPipeline handleAPIAccess:method className:className];
    if (result.action == TSPKResultActionFuse) {
        return [result getObjectWithReturnType:@"NSDateComponents" defaultValue:nil];
    } else {
        return [self tspk_contact_birthday];
    }
}

@end

@implementation TSPKContactOfCNContactPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineContactOfCNContact;
}

+ (NSString *)dataType {
    return TSPKDataTypeContact;
}

+ (BOOL)isEntryDefaultEnable {
    return NO;
}

+ (NSString *)stubbedClass
{
  return @"CNContact";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return nil;
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    return @[
        @"phoneNumbers",
        @"emailAddresses",
        @"givenName",
        @"familyName",
        @"jobTitle",
        @"birthday",
        @"postalAddresses"
    ];
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [CNContact tspk_contact_preload];
    });
}

@end
