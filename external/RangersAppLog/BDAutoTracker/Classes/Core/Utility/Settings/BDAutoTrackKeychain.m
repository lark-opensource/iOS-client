//
//  BDAutoTrackKeychain.m
//  Applog
//
//  Created by bob on 2019/1/20.
//

#import "BDAutoTrackKeychain.h"
#import <Security/Security.h>

static NSString *const kBDAutoTrackKeychainService = @"ttKeyChainService";

static NSMutableDictionary *bd_keychain_query(NSString *key) {
    // see http://developer.apple.com/library/ios/#DOCUMENTATION/Security/Reference/keychainservices/Reference/reference.html
    
    NSMutableDictionary *keychainQuery = [NSMutableDictionary dictionaryWithDictionary:
                                          @{(__bridge id)kSecClass            : (__bridge id)kSecClassGenericPassword,
                                            (__bridge id)kSecAttrService      : kBDAutoTrackKeychainService,
                                            (__bridge id)kSecAttrAccount      : key,
                                            }];
    
    return keychainQuery;
}

static void bd_keychain_addData(NSMutableDictionary *result,NSString *key, NSString *value) {
    [result setValue:(__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly forKey:(__bridge id)kSecAttrAccessible];
    [result setValue:(__bridge id)kCFBooleanFalse forKey:(__bridge id)kSecAttrSynchronizable];
    [result setValue:key forKey:(__bridge id)kSecAttrGeneric];
    [result setValue:[value dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];
}

#pragma mark - Public

BOOL bd_keychain_save(NSString *key, NSString *value) {
    if (!value) {
        return bd_keychain_delete(key);
    }

    NSMutableDictionary *query = bd_keychain_query(key);
    OSStatus result = SecItemCopyMatching((__bridge CFDictionaryRef)query, NULL);
    /// update
    /// errSecItemNotFound  = -25300
    /// errSecDuplicateItem = -25299,

    if (result == errSecSuccess) {
        NSMutableDictionary *attributes = [NSMutableDictionary new];
        bd_keychain_addData(attributes,key, value);
        return SecItemUpdate((__bridge CFDictionaryRef)query,(__bridge CFDictionaryRef)attributes) == errSecSuccess;
    } else {
        /// add
        bd_keychain_addData(query,key, value);
        return SecItemAdd((__bridge CFDictionaryRef)query, NULL) == errSecSuccess;
    }
}

BOOL bd_keychain_delete(NSString *key) {
    NSMutableDictionary *keychainQuery = bd_keychain_query(key);
    OSStatus result = SecItemDelete((__bridge CFDictionaryRef)keychainQuery);
    return result == errSecSuccess || result == errSecItemNotFound;
}


NSString * bd_keychain_load(NSString *key) {
    NSString *value = nil;
    NSMutableDictionary *keychainQuery = bd_keychain_query(key);
    CFDataRef keyData = NULL;
    
    [keychainQuery setValue:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [keychainQuery setValue:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    
    if (SecItemCopyMatching((__bridge CFDictionaryRef)keychainQuery, (CFTypeRef *)&keyData) == errSecSuccess) {
        value = [[NSString alloc] initWithData:(__bridge NSData *)keyData encoding:NSUTF8StringEncoding];
    }
    
    if (keyData) {
        CFRelease(keyData);
    }
    
    return value;
}
