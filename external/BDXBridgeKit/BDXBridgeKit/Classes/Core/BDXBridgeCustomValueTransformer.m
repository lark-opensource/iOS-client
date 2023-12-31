//
//  BDXBridgeCustomValueTransformer.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/8/6.
//

#import "BDXBridgeCustomValueTransformer.h"
#import "BDXBridgeDefinitions.h"
#import <Mantle/MTLValueTransformer.h>

@implementation BDXBridgeCustomValueTransformer

+ (MTLValueTransformer *)enumTransformerWithDictionary:(NSDictionary<NSString *, NSNumber *> *)dictionary
{
    return [MTLValueTransformer transformerUsingForwardBlock:^NSNumber *(NSString *value, BOOL *success, NSError *__autoreleasing *error) {
        __block NSNumber *result = nil;
        if ([value isKindOfClass:NSString.class]) {
            result = dictionary[value];
            
            if (result == nil) {
                [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
                    if (NSOrderedSame == [key compare:value options:NSCaseInsensitiveSearch]) {
                        result = obj;
                        *stop = YES;
                    }
                }];
            }
        }
        if (!result) {
            *success = NO;
            if (error) {
                *error = [NSError errorWithDomain:BDXBridgeErrorDomain code:-1 userInfo:@{
                    NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Failed to transform string(%@) to enum.", value],
                }];
            }
        }
        return result;
    } reverseBlock:^NSString *(NSNumber *value, BOOL *success, NSError *__autoreleasing *error) {
        // Retrieve the string(key) for the enum(value), based on the assumption that the dictionary is a 1:1 map.
        NSString *result = nil;
        if ([value isKindOfClass:NSNumber.class]) {
            NSArray<NSString *> *allKeys = [dictionary allKeysForObject:value];
            if (allKeys.count > 0) {
                result = allKeys.firstObject;
            }
        }
        if (!result) {
            *success = NO;
            if (error) {
                *error = [NSError errorWithDomain:BDXBridgeErrorDomain code:-1 userInfo:@{
                    NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Failed to transform enum(%@) to string.", value],
                }];
            }
        }
        return result;
    }];
}

+ (MTLValueTransformer *)optionsTransformerWithDictionary:(NSDictionary<NSString *, NSNumber *> *)dictionary
{
    return [MTLValueTransformer transformerUsingForwardBlock:^NSNumber *(NSArray<NSString *> *value, BOOL *success, NSError *__autoreleasing *error) {
        NSNumber *result = nil;
        if ([value isKindOfClass:NSArray.class]) {
            NSArray<NSString *> *strings = value;
            __block NSInteger options = 0;
            [strings enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (![obj isKindOfClass:NSString.class]) {
                    options = 0;
                    *stop = YES;
                    return;
                }
                NSNumber *type = dictionary[obj];
                if (type) {
                    options |= [type integerValue];
                }
            }];
            result = options == 0 ? nil : @(options);
        }
        if (!result) {
            *success = NO;
            if (error) {
                *error = [NSError errorWithDomain:BDXBridgeErrorDomain code:-1 userInfo:@{
                    NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Failed to transform strings(%@) to options.", value],
                }];
            }
        }
        return result;
    } reverseBlock:^NSArray<NSString *> *(NSNumber *value, BOOL *success, NSError *__autoreleasing *error) {
        NSArray<NSString *> *result = nil;
        if ([value isKindOfClass:NSNumber.class]) {
            // Reverse the dictionary keys and objects to retrieve the string(key) for the option(value).
            NSArray *keys = dictionary.allKeys;
            NSArray *objects = [dictionary objectsForKeys:keys notFoundMarker:@(0)];
            NSDictionary<NSNumber *, NSString *> *reversedDictionary = [NSDictionary dictionaryWithObjects:keys forKeys:objects];
            __block NSMutableArray<NSString *> *strings = [NSMutableArray array];
            [reversedDictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, NSString *obj, BOOL *stop) {
                if (value.integerValue & key.integerValue) {
                    [strings addObject:obj];
                }
            }];
            result = [strings copy];
        }
        if (!result) {
            *success = NO;
            if (error) {
                *error = [NSError errorWithDomain:BDXBridgeErrorDomain code:-1 userInfo:@{
                    NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Failed to transform options(%@) to strings.", value],
                }];
            }
        }
        return result;
    }];
}

+ (MTLValueTransformer *)colorTransformer
{
    return [MTLValueTransformer transformerUsingForwardBlock:^UIColor *(NSString *value, BOOL *success, NSError *__autoreleasing *error) {
        UIColor *result = nil;
        if ([value isKindOfClass:NSString.class] && [value hasPrefix:@"#"] && value.length == 9) {
            NSScanner *scanner = [NSScanner scannerWithString:value];
            scanner.scanLocation = 1;
            unsigned int color = 0;
            BOOL succeeded = [scanner scanHexInt:&color];
            if (succeeded) {
                NSUInteger mask = 0x000000FF;
                CGFloat red = ((color >> 24) & mask) / 255.f;
                CGFloat green = ((color >> 16) & mask) / 255.f;
                CGFloat blue = ((color >> 8) & mask) / 255.f;
                CGFloat alpha = ((color >> 0) & mask) / 255.f;
                result = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
            }
        }
        if (!result) {
            *success = NO;
            if (error) {
                *error = [NSError errorWithDomain:BDXBridgeErrorDomain code:-1 userInfo:@{
                    NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Failed to transform string(%@) to color.", value],
                }];
            }
        }
        return result;
    } reverseBlock:^NSString *(UIColor *value, BOOL *success, NSError *__autoreleasing *error) {
        NSString *result = nil;
        if (value) {
            CGFloat red, green, blue, alpha;
            BOOL succeeded = [value getRed:&red green:&green blue:&blue alpha:&alpha];
            if (succeeded) {
                unsigned long rgba = ((NSUInteger)(red * 255.f) << 24) | ((NSUInteger)(green * 255.f) << 16) | ((NSUInteger)(blue * 255.f) << 8) | ((NSUInteger)(alpha * 255.f) << 0);
                result = [NSString stringWithFormat:@"#%08lx", rgba];;
            }
        }
        if (!result) {
            *success = NO;
            if (error) {
                *error = [NSError errorWithDomain:BDXBridgeErrorDomain code:-1 userInfo:@{
                    NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Failed to transform color(%@) to string.", value],
                }];
            }
        }
        return result;
    }];
}

@end
