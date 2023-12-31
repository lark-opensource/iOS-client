//
//  BTDkeyChainStorage.m
//  Article
//
//  Created by Dianwei on 13-5-9.
//
//

#import "BTDkeyChainStorage.h"
#import "BTDMacros.h"
#import "NSString+BTDAdditions.h"
#import "NSDictionary+BTDAdditions.h"
#import "NSArray+BTDAdditions.h"

#define kKeyChainServiceName        @"BTD_KeyChainService"
#define kKeyChainStorageException   @"BTD_KeyChainStorageException"

@implementation BTDkeyChainStorage

+ (id)objectForKey:(NSString*)key
{
    if(BTD_isEmptyString(key))
    {
        @throw [NSException exceptionWithName:kKeyChainStorageException reason:@"key cannot be nil" userInfo:nil];
    }
    
    NSMutableDictionary *query = [NSMutableDictionary dictionaryWithCapacity:6];
    [query setObject:(id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [query setObject:key forKey:(__bridge id)kSecAttrAccount];
    [query setObject:kKeyChainServiceName forKey:(__bridge id)kSecAttrService];
    [query setObject:key forKey:(__bridge id)kSecAttrGeneric];
    [query setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [query setObject:(id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    CFTypeRef result = nil;
    OSStatus status = SecItemCopyMatching((CFDictionaryRef)query, &result);
    
    
    if(status != errSecSuccess)
    {
        if (result) {
            CFRelease(result);
        }
        return nil;
    }
    
    NSData *data = [NSData dataWithData:(__bridge NSData * _Nonnull)(result)];
    if (result) {
        CFRelease(result);
    }
    NSString *stringResult = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if(!BTD_isEmptyString(stringResult))
    {
        return [stringResult btd_jsonValueDecoded];
    }
    else
    {
        return nil;
    }
}

+ (BOOL)setObject:(id)value key:(NSString*)key
{
    if(![value respondsToSelector:@selector(btd_jsonStringEncoded)])
    {
        @throw [NSException exceptionWithName:kKeyChainStorageException reason:@"value must be JSON respresentable" userInfo:[NSDictionary dictionaryWithObject:value forKey:@"value"]];
    }
    
    NSString *stringValue = [value btd_jsonStringEncoded];
    return [self setData:[stringValue dataUsingEncoding:NSUTF8StringEncoding] key:key];
}

+ (BOOL)setData:(NSData*)data key:(NSString*)key
{
    if(BTD_isEmptyString(key))
    {
        @throw [NSException exceptionWithName:kKeyChainStorageException reason:@"key cannot be nil" userInfo:nil];
    }
    
    BOOL result = NO;
    
    NSMutableDictionary *query = [NSMutableDictionary dictionaryWithCapacity:4];
    [query setObject:(id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [query setObject:(id)kKeyChainServiceName forKey:(__bridge id)kSecAttrService];
    [query setObject:key forKey:(__bridge id)kSecAttrAccount];
    [query setObject:key forKey:(__bridge id)kSecAttrGeneric];
    
    OSStatus status = SecItemCopyMatching((CFDictionaryRef)query, NULL);
    if(status == errSecSuccess)
    {
        if(data)
        {
            NSMutableDictionary *updateDict = [NSMutableDictionary dictionaryWithCapacity:2];
            [updateDict setObject:data forKey:(__bridge id)kSecValueData];
            status = SecItemUpdate((CFDictionaryRef)query, (CFDictionaryRef)updateDict);
            if(status == errSecSuccess)
            {
                result = YES;
            }
        }
        else
        {
            result = [self removeValueForKey:key];
        }
    }
    else if(status == errSecItemNotFound)
    {
        NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithCapacity:5];
        [attrs setObject:(id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
        [attrs setObject:kKeyChainServiceName forKey:(__bridge id)kSecAttrService];
        [attrs setObject:key forKey:(__bridge id)kSecAttrAccount];
        [attrs setObject:key forKey:(__bridge id)kSecAttrGeneric];
        [attrs setObject:data forKey:(__bridge id)kSecValueData];
        status = SecItemAdd((CFDictionaryRef)attrs, NULL);
        result = (status == errSecSuccess);
    }
    
    return result;
}

+ (BOOL)removeValueForKey:(NSString*)key
{
    if(BTD_isEmptyString(key))
    {
        @throw [NSException exceptionWithName:kKeyChainStorageException reason:@"key cannot be nil" userInfo:nil];
    }
    
    NSMutableDictionary *itemToDelete = [NSMutableDictionary dictionaryWithCapacity:6];
    [itemToDelete setObject:(id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [itemToDelete setObject:kKeyChainServiceName forKey:(__bridge id)kSecAttrService];
    [itemToDelete setObject:key forKey:(__bridge id)kSecAttrAccount];
    [itemToDelete setObject:key forKey:(__bridge id)kSecAttrGeneric];
    OSStatus status = SecItemDelete((CFDictionaryRef)itemToDelete);
    BOOL result = (status == errSecSuccess || status == errSecItemNotFound);
    return result;
}

@end
