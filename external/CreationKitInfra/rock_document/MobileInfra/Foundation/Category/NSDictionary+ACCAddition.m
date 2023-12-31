//
//  NSDictionary+ACCAddition.m
//  Pods
//
//  Created by chengfei xiao on 2019/8/6.
//

#import "NSDictionary+ACCAddition.h"
#import <CreativeKit/NSObject+ACCAdditions.h>
#import <CreationKitInfra/ACCLogProtocol.h>

NS_INLINE BOOL ACCIsNumericString(NSString *string) {
    NSScanner *scanner = [NSScanner scannerWithString:string];
    if ([scanner scanFloat:NULL])
    {
        return [scanner isAtEnd];
    }
    return NO;
}

@implementation NSDictionary (ACCAddition)

- (id)acc_objectForKey:(NSString *)key {
    return [self acc_objectForKey:key defaultObj:nil];
}

- (id)acc_objectForKey:(id)aKey ofClass:(Class)aClass {
    return [self acc_objectForKey:aKey ofClass:aClass defaultObj:nil];
}

- (int)acc_intValueForKey:(NSString *)key {
    return [self acc_intValueForKey:key defaultValue:0];
}

- (NSInteger)acc_integerValueForKey:(NSString *)key {
    return [self acc_integerValueForKey:key defaultValue:0];
}

- (NSUInteger)acc_unsignedIntegerValueForKey:(NSString *)key {
    return [self acc_unsignedIntegerValueForKey:key defaultValue:0];
}

- (float)acc_floatValueForKey:(NSString *)key {
    return [self acc_floatValueForKey:key defaultValue:0.f];
}

- (double)acc_doubleValueForKey:(NSString *)key {
    return [self acc_doubleValueForKey:key defaultValue:0.];
}

- (long)acc_longValueForKey:(NSString *)key {
    return [self acc_longValueForKey:key defaultValue:0];
}

- (long long)acc_longlongValueForKey:(NSString *)key {
    return [self acc_longlongValueForKey:key defaultValue:0];
}

- (BOOL)acc_boolValueForKey:(NSString *)key {
    return [self acc_boolValueForKey:key defaultValue:NO];
}

- (NSString *)acc_stringValueForKey:(NSString *)key {
    return [self acc_stringValueForKey:key defaultValue:nil];
}

- (NSArray *)acc_arrayValueForKey:(NSString *)key {
    return [self acc_arrayValueForKey:key defaultValue:nil];
}

- (NSDictionary *)acc_dictionaryValueForKey:(NSString *)key {
    return [self acc_dictionaryValueForKey:key defalutValue:nil];
}

- (NSString *)acc_dictionaryToJson
{
    if (![NSJSONSerialization isValidJSONObject:self]) {
        return nil;
    }
    
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:0 error:&parseError];
    if (parseError || !jsonData) {
        AWELogToolInfo(AWELogToolTagNone, @"dictionary: %@ to string error: %@", self, parseError);
        return nil;
    }
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
}

- (id)acc_objectForKey:(NSString *)key defaultObj:(id)defaultObj {
    id obj = [self objectForKey:key];
    return obj ? obj : defaultObj;
}

- (id)acc_objectForKey:(id)aKey ofClass:(Class)aClass defaultObj:(id)defaultObj {
    id obj = [self objectForKey:aKey];
    if (obj && [obj isKindOfClass:aClass]) {
        return obj;
    }
    
    // Special case for numeric string
    if ([obj isKindOfClass:[NSString class]] &&
        [aClass isSubclassOfClass:[NSNumber class]]) {
        if (ACCIsNumericString(obj)) {
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            return [formatter numberFromString:obj];
        }
    }
    return defaultObj;
}

- (BOOL)acc_boolValueForKey:(NSString *)key defaultValue:(BOOL)defaultValue {
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value boolValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value boolValue] : defaultValue;
}

- (int)acc_intValueForKey:(NSString *)key defaultValue:(int)defaultValue {
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value intValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value intValue] : defaultValue;
}

- (NSInteger)acc_integerValueForKey:(NSString *)key defaultValue:(NSInteger)defaultValue {
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value integerValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value integerValue] : defaultValue;
}

- (NSUInteger)acc_unsignedIntegerValueForKey:(NSString *)key defaultValue:(NSUInteger)defaultValue {
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return (NSUInteger)[(NSString *)value integerValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value unsignedIntegerValue] : defaultValue;
}

- (double)acc_doubleValueForKey:(NSString *)key defaultValue:(double)defaultValue
{
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value doubleValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value doubleValue] : defaultValue;
}

- (float)acc_floatValueForKey:(NSString *)key defaultValue:(float)defaultValue {
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value floatValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value floatValue] : defaultValue;
}

- (long)acc_longValueForKey:(NSString *)key defaultValue:(long)defaultValue {
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value integerValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value longValue] : defaultValue;
}

- (long long)acc_longlongValueForKey:(NSString *)key defaultValue:(long long)defaultValue {
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value longLongValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value longLongValue] : defaultValue;
}

- (NSString *)acc_stringValueForKey:(NSString *)key defaultValue:(NSString *)defaultValue {
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return value;
    }else if(value && [value isKindOfClass:[NSNumber class]]){
        return [value stringValue];
    }else{
        return defaultValue;
    }
}

- (NSArray *)acc_arrayValueForKey:(NSString *)key defaultValue:(NSArray *)defaultValue {
    id value = [self objectForKey:key];
    return (value && [value isKindOfClass:[NSArray class]]) ? value : defaultValue;
}

- (NSDictionary *)acc_dictionaryValueForKey:(NSString *)key defalutValue:(NSDictionary *)defaultValue {
    id value = [self objectForKey:key];
    return (value && [value isKindOfClass:[NSDictionary class]]) ? value : defaultValue;
}

- (NSString *)acc_dictionaryToContentJson
{
    NSString *jsonString = [self acc_dictionaryToJson];
    NSString *jsonEncodedString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:@[jsonString] options:0 error:nil] encoding:NSUTF8StringEncoding];
    NSInteger startLocation = [jsonEncodedString rangeOfString:@"{"].location;
    NSInteger endLocation = [jsonEncodedString rangeOfString:@"}" options:NSBackwardsSearch].location;
    if (startLocation == NSNotFound) {
        startLocation = 0;
    }
    if (endLocation == NSNotFound) {
        endLocation = jsonEncodedString.length - 1;
    }
    return [jsonEncodedString substringWithRange:NSMakeRange(startLocation, endLocation - startLocation + 1)];
}

- (NSString *)acc_jsonStringEncoded
{
    NSError *error = nil;
    return [self acc_jsonStringEncoded:&error];
}

- (nullable NSString *)acc_jsonStringEncoded:(NSError *__autoreleasing *)error
{
    if ([NSJSONSerialization isValidJSONObject:self]) {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:error];
        if (*error != nil || !jsonData) {
            return nil;
        }
        NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return json;
    }
    return nil;
}

- (nullable NSString *)acc_safeJsonStringEncoded
{
    id object = [self acc_safeJsonObject];
    if ([object isKindOfClass:[NSDictionary class]]) {
        return [object acc_jsonStringEncoded];
    }
    return nil;
}

- (id)acc_safeJsonObject
{
    NSMutableDictionary *safeEncodingDict = [NSMutableDictionary dictionary];
    for (NSString *key in [(NSDictionary *)self allKeys]) {
        id object = [self valueForKey:key];
        safeEncodingDict[key] = [object acc_safeJsonObject];
    }
    return safeEncodingDict.copy;
}

#pragma mark - write

- (BOOL)acc_writeToURL:(NSURL *)url error:(NSError **)error API_AVAILABLE(ios(11.0))
{
    if (@available(iOS 11.0, *)) {
        NSError *innerError;
        BOOL writeSuccess = [self writeToURL:url error:&innerError];
        if (!writeSuccess && innerError) {
            AWELogToolError2(@"write", AWELogToolTagNone, @"dic write to file failed, error:%@", innerError);
            if ([innerError.domain isEqual:NSCocoaErrorDomain] && innerError.code == NSFileWriteUnknownError) {
                writeSuccess = [self acc_writeToURL:url atomically:YES];
                if (writeSuccess) {
                    innerError = nil;
                }
                if (error) {
                    *error = innerError;
                }
                AWELogToolError2(@"write", AWELogToolTagNone, @"dic retry write to file success:%@, error:%@", @(writeSuccess), innerError);
            }
        }
        return writeSuccess;
    } else {
        return [self acc_writeToURL:url atomically:YES];
    }
}

- (BOOL)acc_writeToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile
{
    BOOL writeSuccess = [self writeToFile:path atomically:useAuxiliaryFile];
    if (!writeSuccess && useAuxiliaryFile) {
        writeSuccess = [self writeToFile:path atomically:NO];
        AWELogToolError2(@"write", AWELogToolTagNone, @"dic write to file failed, retry success:%@", @(writeSuccess));
    }
    return writeSuccess;
}

- (BOOL)acc_writeToURL:(NSURL *)url atomically:(BOOL)atomically
{
  BOOL writeSuccess = [self writeToURL:url atomically:atomically];
    if (!writeSuccess && atomically) {
        writeSuccess = [self writeToURL:url atomically:NO];
        AWELogToolError2(@"write", AWELogToolTagNone, @"dic write to file failed, retry success:%@", @(writeSuccess));
    }
    return writeSuccess;
}

@end

@implementation NSMutableDictionary (ACCAddition)

- (void)acc_setObject:(id)anObject forKey:(id<NSCopying>)key {
    NSAssert(key != nil, @"set nil key");
    if (key != nil && anObject != nil) {
        [self setObject:anObject forKey:key];
    }
}

@end
