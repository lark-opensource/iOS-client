//
//  OKSectionData.h
//  OneKit
//
//  Created by bob on 2020/10/2.
//

#import <OneKit/OKMacros.h>

NS_ASSUME_NONNULL_BEGIN

typedef struct _OKString {
    const char *key;
    const char *value;
} OKString;

#define OKStringUniqueIdentifier OKIdentifier(__OKString, __COUNTER__)

#define OK_STRINGS_EXPORT(key, value) \
OKSectionNameData(__OKString) \
static const OKString OKStringUniqueIdentifier = (OKString){key, value};

/**
 e.g
 to define values:
 OK_STRINGS_EXPORT("key1", "value1")
 OK_STRINGS_EXPORT("key1", "value2")
 OK_STRINGS_EXPORT("key2", "value1")
 
 to get values:
 NSArray *key1 = [OKSectionData exportedStringsForKey:@"key1"];
 NSArray *key2 = [OKSectionData exportedStringsForKey:@"key2"];
 */

/// lazy load
@interface OKSectionData : NSObject

+ (nullable NSArray<NSString *> *)exportedStringsForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
