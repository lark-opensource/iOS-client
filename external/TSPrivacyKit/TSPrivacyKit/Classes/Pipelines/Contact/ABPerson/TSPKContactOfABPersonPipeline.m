//
//  TSPKContactOfABPersonPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/13.
//

#import "TSPKContactOfABPersonPipeline.h"
#include <BDFishhook/BDFishhook.h>
#import <AddressBook/ABPerson.h>
#import "TSPKFishhookUtils.h"
#import "TSPKUtils.h"
#import "TSPKCacheEnv.h"

static NSString *const copyArrayOfAllPeople = @"ABAddressBookCopyArrayOfAllPeople";
static NSString *const copyArrayOfAllPeopleInSource = @"ABAddressBookCopyArrayOfAllPeopleInSource";
static NSString *const copyArrayOfAllPeopleInSourceWithSortOrdering = @"ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering";
static NSString *const copyPeopleWithName = @"ABAddressBookCopyPeopleWithName";

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

static CFArrayRef (*old_ABAddressBookCopyArrayOfAllPeople)(ABAddressBookRef) = ABAddressBookCopyArrayOfAllPeople;

CFArrayRef new_ABAddressBookCopyArrayOfAllPeople(ABAddressBookRef addressBook)
{
    @autoreleasepool {
        TSPKHandleResult *result = [TSPKContactOfABPersonPipeline handleAPIAccess:copyArrayOfAllPeople];

        if (result.action == TSPKResultActionFuse) {
            id resultValue = [result getObjectWithReturnType:TSPKReturnTypeNSArray defaultValue:@[]];
            return (__bridge CFArrayRef)([resultValue isKindOfClass:[NSArray class]] ? resultValue : @[]);
        } else if (result.action == TSPKResultActionCache) {
            NSString *api = copyArrayOfAllPeople;
            if (![[TSPKCacheEnv shareEnv] needUpdate:api]) {
                return (__bridge CFArrayRef)[[TSPKCacheEnv shareEnv] get:api];
            }
            CFArrayRef originResult = old_ABAddressBookCopyArrayOfAllPeople(addressBook);
            [[TSPKCacheEnv shareEnv] updateCache:api newValue:(__bridge NSArray*)originResult];
            return originResult;
        } else {
            return old_ABAddressBookCopyArrayOfAllPeople(addressBook);
        }
    }
}

static CFArrayRef (*old_ABAddressBookCopyArrayOfAllPeopleInSource)(ABAddressBookRef, ABRecordRef) = ABAddressBookCopyArrayOfAllPeopleInSource;

CFArrayRef new_ABAddressBookCopyArrayOfAllPeopleInSource(ABAddressBookRef addressBook, ABRecordRef source)
{
    @autoreleasepool {
        TSPKHandleResult *result = [TSPKContactOfABPersonPipeline handleAPIAccess:copyArrayOfAllPeopleInSource];
        
        if (result.action == TSPKResultActionFuse) {
            id resultValue = [result getObjectWithReturnType:TSPKReturnTypeNSArray defaultValue:@[]];
            return (__bridge CFArrayRef)([resultValue isKindOfClass:[NSArray class]] ? resultValue : @[]);
        } else if (result.action == TSPKResultActionCache) {
            NSString *api = copyArrayOfAllPeopleInSource;
            if (![[TSPKCacheEnv shareEnv] needUpdate:api]) {
                return (__bridge CFArrayRef)[[TSPKCacheEnv shareEnv] get:api];
            }
            CFArrayRef originResult = old_ABAddressBookCopyArrayOfAllPeopleInSource(addressBook, source);
            [[TSPKCacheEnv shareEnv] updateCache:api newValue:(__bridge NSArray*)originResult];
            return originResult;
        } else {
            return old_ABAddressBookCopyArrayOfAllPeopleInSource(addressBook, source);
        }
    }
}

static CFArrayRef (*old_ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering)(ABAddressBookRef, ABRecordRef, ABPersonSortOrdering) = ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering;

CFArrayRef new_ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(ABAddressBookRef addressBook, ABRecordRef source, ABPersonSortOrdering sortOrdering)
{
    @autoreleasepool {
        TSPKHandleResult *result = [TSPKContactOfABPersonPipeline handleAPIAccess:copyArrayOfAllPeopleInSourceWithSortOrdering];
        
        if (result.action == TSPKResultActionFuse) {
            id resultValue = [result getObjectWithReturnType:TSPKReturnTypeNSArray defaultValue:@[]];
            return (__bridge CFArrayRef)([resultValue isKindOfClass:[NSArray class]] ? resultValue : @[]);
        } else if (result.action == TSPKResultActionCache) {
            NSString *api = copyArrayOfAllPeopleInSourceWithSortOrdering;
            if (![[TSPKCacheEnv shareEnv] needUpdate:api]) {
                return (__bridge CFArrayRef)[[TSPKCacheEnv shareEnv] get:api];
            }
            CFArrayRef originResult = old_ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(addressBook, source, sortOrdering);
            [[TSPKCacheEnv shareEnv] updateCache:api newValue:(__bridge NSArray*)originResult];
            return originResult;
        } else {
            return old_ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(addressBook, source, sortOrdering);
        }
    }
}

static CFArrayRef (*old_ABAddressBookCopyPeopleWithName)(ABAddressBookRef, CFStringRef) = ABAddressBookCopyPeopleWithName;

CFArrayRef new_ABAddressBookCopyPeopleWithName(ABAddressBookRef addressBook, CFStringRef name)
{
    @autoreleasepool {
        TSPKHandleResult *result = [TSPKContactOfABPersonPipeline handleAPIAccess:copyPeopleWithName];
        
        if (result.action == TSPKResultActionFuse) {
            return (__bridge CFArrayRef)@[];
        } else if (result.action == TSPKResultActionCache) {
            NSString *api = copyPeopleWithName;
            if (![[TSPKCacheEnv shareEnv] needUpdate:api]) {
                return (__bridge CFArrayRef)[[TSPKCacheEnv shareEnv] get:api];
            }
            CFArrayRef originResult = old_ABAddressBookCopyPeopleWithName(addressBook, name);
            [[TSPKCacheEnv shareEnv] updateCache:api newValue:(__bridge NSArray*)originResult];
            return originResult;
        } else {
            return old_ABAddressBookCopyPeopleWithName(addressBook, name);
        }
    }

}

@implementation TSPKContactOfABPersonPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineContactOfAddressBook;
}

+ (NSString *)dataType {
    return TSPKDataTypeContact;
}

+ (NSArray<NSString *> * _Nullable)stubbedCAPIs
{
    return @[copyArrayOfAllPeople, copyArrayOfAllPeopleInSource, copyArrayOfAllPeopleInSourceWithSortOrdering, copyPeopleWithName];
}

+ (NSString *)stubbedClass
{
    return nil;
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        struct bd_rebinding copyArrayOfAllPeopleRebinding;
        copyArrayOfAllPeopleRebinding.name = [copyArrayOfAllPeople UTF8String];
        copyArrayOfAllPeopleRebinding.replacement = new_ABAddressBookCopyArrayOfAllPeople;
        copyArrayOfAllPeopleRebinding.replaced = (void *)&old_ABAddressBookCopyArrayOfAllPeople;
        
        struct bd_rebinding copyArrayOfAllPeopleInSourceRebinding;
        copyArrayOfAllPeopleInSourceRebinding.name = [copyArrayOfAllPeopleInSource UTF8String];
        copyArrayOfAllPeopleInSourceRebinding.replacement = new_ABAddressBookCopyArrayOfAllPeopleInSource;
        copyArrayOfAllPeopleInSourceRebinding.replaced = (void *)&old_ABAddressBookCopyArrayOfAllPeopleInSource;

        struct bd_rebinding copyArrayOfAllPeopleInSourceWithSortOrderingRebinding;
        copyArrayOfAllPeopleInSourceWithSortOrderingRebinding.name = [copyArrayOfAllPeopleInSourceWithSortOrdering UTF8String];
        copyArrayOfAllPeopleInSourceWithSortOrderingRebinding.replacement = new_ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering;
        copyArrayOfAllPeopleInSourceWithSortOrderingRebinding.replaced = (void *)&old_ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering;
        
        struct bd_rebinding copyPeopleWithNameRebinding;
        copyPeopleWithNameRebinding.name = [copyPeopleWithName UTF8String];
        copyPeopleWithNameRebinding.replacement = new_ABAddressBookCopyPeopleWithName;
        copyPeopleWithNameRebinding.replaced = (void *)&old_ABAddressBookCopyPeopleWithName;

        struct bd_rebinding rebs[] = {copyArrayOfAllPeopleRebinding, copyArrayOfAllPeopleInSourceRebinding, copyArrayOfAllPeopleInSourceWithSortOrderingRebinding, copyPeopleWithNameRebinding};
        tspk_rebind_symbols(rebs, 4);
    });
}

- (BOOL)deferPreload
{
    return YES;
}

+ (BOOL)isEntryDefaultEnable
{
    return NO;
}

+ (BOOL)entryEnable {
    if (@available(iOS 13.0, *)) {
        return [super entryEnable];
    } else {
        return NO;
    }
}

@end
