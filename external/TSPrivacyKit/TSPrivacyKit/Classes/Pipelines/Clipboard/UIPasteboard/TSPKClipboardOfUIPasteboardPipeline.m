//
//  TSPKClipboardOfUIPasteboardPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/13.
//

#import "TSPKClipboardOfUIPasteboardPipeline.h"
#import <UIKit/UIPasteboard.h>
#import "NSObject+TSAddition.h"
#import "TSPKUtils.h"
#import "TSPKCacheEnv.h"
#import "TSPKPipelineSwizzleUtil.h"

@implementation UIPasteboard (TSPrivacyKitClipboard)

+ (void)tspk_clipboard_preload:(Class)clazz {
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKClipboardOfUIPasteboardPipeline class] clazz:clazz];
}

- (NSString *)tspk_clipboard_string {
    NSString *method = NSStringFromSelector(@selector(string));
    NSString *className = [TSPKClipboardOfUIPasteboardPipeline stubbedClass];
    TSPKHandleResult *result = [TSPKClipboardOfUIPasteboardPipeline handleAPIAccess:method className:className params:[self tspk_context]];
    
    if (result.action == TSPKResultActionFuse) {
        return [result getObjectWithReturnType:@"NSString" defaultValue:nil];
    } else if (result.action == TSPKResultActionCache) {
        NSString *api = [TSPKUtils concateClassName:className method:method];
        if (!result.cacheNeedUpdate) {
            NSString *finalResult = [[TSPKCacheEnv shareEnv] get:api];
            return finalResult;
        }
        NSString *originResult = [self tspk_clipboard_string];
        [[TSPKCacheEnv shareEnv] updateCache:api newValue:originResult];
        return originResult;
    } else {
        return [self tspk_clipboard_string];
    }
}

- (NSArray<NSString *> *)tspk_clipboard_strings {
    NSString *method = NSStringFromSelector(@selector(strings));
    NSString *className = [TSPKClipboardOfUIPasteboardPipeline stubbedClass];
    
    TSPKHandleResult *result = [TSPKClipboardOfUIPasteboardPipeline handleAPIAccess:method className:className params:[self tspk_context]];
    if (result.action == TSPKResultActionFuse) {
        return [result getObjectWithReturnType:@"NSArray" defaultValue:nil];
    } else if (result.action == TSPKResultActionCache) {
        NSString *api = [TSPKUtils concateClassName:className method:method];
        if (!result.cacheNeedUpdate) {
            return [[TSPKCacheEnv shareEnv] get:api];
        }
        NSArray<NSString *> *originResult = [self tspk_clipboard_strings];
        [[TSPKCacheEnv shareEnv] updateCache:api newValue:originResult];
        return originResult;
    } else {
        return [self tspk_clipboard_strings];
    }
}

- (NSURL *)tspk_clipboard_URL {
    NSString *method = NSStringFromSelector(@selector(URL));
    NSString *className = [TSPKClipboardOfUIPasteboardPipeline stubbedClass];
    
    TSPKHandleResult *result = [TSPKClipboardOfUIPasteboardPipeline handleAPIAccess:method className:className params:[self tspk_context]];
    if (result.action == TSPKResultActionFuse) {
        return [result getObjectWithReturnType:@"NSURL" defaultValue:nil];
    } else if (result.action == TSPKResultActionCache) {
        NSString *api = [TSPKUtils concateClassName:className method:method];
        if (!result.cacheNeedUpdate) {
            return [[TSPKCacheEnv shareEnv] get:api];
        }
        NSURL *originResult = [self tspk_clipboard_URL];
        [[TSPKCacheEnv shareEnv] updateCache:api newValue:originResult];
        return originResult;
    } else {
        return [self tspk_clipboard_URL];
    }
}

- (NSArray<NSURL *> *)tspk_clipboard_URLs {
    NSString *method = NSStringFromSelector(@selector(URLs));
    NSString *className = [TSPKClipboardOfUIPasteboardPipeline stubbedClass];
    
    TSPKHandleResult *result = [TSPKClipboardOfUIPasteboardPipeline handleAPIAccess:method className:className params:[self tspk_context]];
    if (result.action == TSPKResultActionFuse) {
        return [result getObjectWithReturnType:@"NSArray" defaultValue:nil];
    } else if (result.action == TSPKResultActionCache) {
        NSString *api = [TSPKUtils concateClassName:className method:method];
        if (!result.cacheNeedUpdate) {
            return [[TSPKCacheEnv shareEnv] get:api];
        }
        NSArray<NSURL *> *originResult = [self tspk_clipboard_URLs];
        [[TSPKCacheEnv shareEnv] updateCache:api newValue:originResult];
        return originResult;
    } else {
        return [self tspk_clipboard_URLs];
    }
}

- (UIImage *)tspk_clipboard_image {
    NSString *method = NSStringFromSelector(@selector(image));
    NSString *className = [TSPKClipboardOfUIPasteboardPipeline stubbedClass];
    
    TSPKHandleResult *result = [TSPKClipboardOfUIPasteboardPipeline handleAPIAccess:method className:className params:[self tspk_context]];
    if (result.action == TSPKResultActionFuse) {
        return [result getObjectWithReturnType:@"UIImage" defaultValue:nil];
    } else if (result.action == TSPKResultActionCache) {
        NSString *api = [TSPKUtils concateClassName:className method:method];
        if (!result.cacheNeedUpdate) {
            return [[TSPKCacheEnv shareEnv] get:api];
        }
        UIImage *originResult = [self tspk_clipboard_image];
        [[TSPKCacheEnv shareEnv] updateCache:api newValue:originResult];
        return originResult;
    } else {
        return [self tspk_clipboard_image];
    }
}

- (NSArray<UIImage *> *)tspk_clipboard_images {
    NSString *method = NSStringFromSelector(@selector(images));
    NSString *className = [TSPKClipboardOfUIPasteboardPipeline stubbedClass];
    
    TSPKHandleResult *result = [TSPKClipboardOfUIPasteboardPipeline handleAPIAccess:method className:className params:[self tspk_context]];
    if (result.action == TSPKResultActionFuse) {
        return [result getObjectWithReturnType:@"NSArray" defaultValue:nil];
    } else if (result.action == TSPKResultActionCache) {
        NSString *api = [TSPKUtils concateClassName:className method:method];
        if (!result.cacheNeedUpdate) {
            return [[TSPKCacheEnv shareEnv] get:api];
        }
        NSArray<UIImage *> *originResult = [self tspk_clipboard_images];
        [[TSPKCacheEnv shareEnv] updateCache:api newValue:originResult];
        return originResult;
    } else {
        return [self tspk_clipboard_images];
    }
}

- (UIColor *)tspk_clipboard_color {
    NSString *method = NSStringFromSelector(@selector(color));
    NSString *className = [TSPKClipboardOfUIPasteboardPipeline stubbedClass];
    
    TSPKHandleResult *result = [TSPKClipboardOfUIPasteboardPipeline handleAPIAccess:method className:className params:[self tspk_context]];
    if (result.action == TSPKResultActionFuse) {
        return [result getObjectWithReturnType:@"UIColor" defaultValue:nil];
    } else if (result.action == TSPKResultActionCache) {
        NSString *api = [TSPKUtils concateClassName:className method:method];
        if (!result.cacheNeedUpdate) {
            return [[TSPKCacheEnv shareEnv] get:api];
        }
        UIColor *originResult = [self tspk_clipboard_color];
        [[TSPKCacheEnv shareEnv] updateCache:api newValue:originResult];
        return originResult;
    } else {
        return [self tspk_clipboard_color];
    }
}

- (NSArray<UIColor *> *)tspk_clipboard_colors {
    NSString *method = NSStringFromSelector(@selector(colors));
    NSString *className = [TSPKClipboardOfUIPasteboardPipeline stubbedClass];
    
    TSPKHandleResult *result = [TSPKClipboardOfUIPasteboardPipeline handleAPIAccess:method className:className params:[self tspk_context]];
    if (result.action == TSPKResultActionFuse) {
        return [result getObjectWithReturnType:@"NSArray" defaultValue:nil];
    } else if (result.action == TSPKResultActionCache) {
        NSString *api = [TSPKUtils concateClassName:className method:method];
        if (!result.cacheNeedUpdate) {
            return [[TSPKCacheEnv shareEnv] get:api];
        }
        NSArray<UIColor *> *originResult = [self tspk_clipboard_colors];
        [[TSPKCacheEnv shareEnv] updateCache:api newValue:originResult];
        return originResult;
    } else {
        return [self tspk_clipboard_colors];
    }
}

- (NSArray *)tspk_clipboard_valuesForPasteboardType:(NSString *)pasteboardType inItemSet:(NSIndexSet *)itemSet {
    NSString *method = NSStringFromSelector(@selector(valuesForPasteboardType:inItemSet:));
    NSString *className = [TSPKClipboardOfUIPasteboardPipeline stubbedClass];
    
    TSPKHandleResult *result = [TSPKClipboardOfUIPasteboardPipeline handleAPIAccess:method className:className params:[self tspk_context]];
    if (result.action == TSPKResultActionFuse) {
        return [result getObjectWithReturnType:@"NSArray" defaultValue:nil];
    } else if (result.action == TSPKResultActionCache) {
        NSString *api = [TSPKUtils concateClassName:className method:method];
        if (!result.cacheNeedUpdate) {
            return [[TSPKCacheEnv shareEnv] get:api];
        }
        NSArray *originResult = [self tspk_clipboard_valuesForPasteboardType:pasteboardType inItemSet:itemSet];
        [[TSPKCacheEnv shareEnv] updateCache:api newValue:originResult];
        return originResult;
    } else {
        return [self tspk_clipboard_valuesForPasteboardType:pasteboardType inItemSet:itemSet];
    }
}

- (NSArray<NSData *> *)tspk_clipboard_dataForPasteboardType:(NSString *)pasteboardType inItemSet:(NSIndexSet *)itemSet {
    NSString *method = NSStringFromSelector(@selector(dataForPasteboardType:inItemSet:));
    NSString *className = [TSPKClipboardOfUIPasteboardPipeline stubbedClass];
    
    TSPKHandleResult *result = [TSPKClipboardOfUIPasteboardPipeline handleAPIAccess:method className:className params:[self tspk_context]];
    if (result.action == TSPKResultActionFuse) {
        return [result getObjectWithReturnType:@"NSArray" defaultValue:nil];
    } else if (result.action == TSPKResultActionCache) {
        NSString *api = [TSPKUtils concateClassName:className method:method];
        if (!result.cacheNeedUpdate) {
            return [[TSPKCacheEnv shareEnv] get:api];
        }
        NSArray<NSData *> *originResult = [self tspk_clipboard_dataForPasteboardType:pasteboardType inItemSet:itemSet];
        [[TSPKCacheEnv shareEnv] updateCache:api newValue:originResult];
        return originResult;
    } else {
        return [self tspk_clipboard_dataForPasteboardType:pasteboardType inItemSet:itemSet];
    }
}

- (NSArray<NSDictionary<NSString *,id> *> *)tspk_clipboard_items {
    NSString *method = NSStringFromSelector(@selector(items));
    NSString *className = [TSPKClipboardOfUIPasteboardPipeline stubbedClass];
    
    TSPKHandleResult *result = [TSPKClipboardOfUIPasteboardPipeline handleAPIAccess:method className:className params:[self tspk_context]];
    if (result.action == TSPKResultActionFuse) {
        return [result getObjectWithReturnType:@"NSArray" defaultValue:nil];
    } else if (result.action == TSPKResultActionCache) {
        NSString *api = [TSPKUtils concateClassName:className method:method];
        if (!result.cacheNeedUpdate) {
            return [[TSPKCacheEnv shareEnv] get:api];
        }
        NSArray<NSDictionary<NSString *,id> *> *originResult = [self tspk_clipboard_items];
        [[TSPKCacheEnv shareEnv] updateCache:api newValue:originResult];
        return originResult;
    } else {
        return [self tspk_clipboard_items];
    }
}
 
- (void)tspk_clipboard_setString:(NSString *)string {
    TSPKHandleResult *result = [TSPKClipboardOfUIPasteboardPipeline handleAPIAccess:NSStringFromSelector(@selector(setString:)) className:[TSPKClipboardOfUIPasteboardPipeline stubbedClass] params:[self tspk_context]];
    if (result.action == TSPKResultActionFuse) {
    } else {
        return [self tspk_clipboard_setString:string];
    }
}

- (void)tspk_clipboard_setStrings:(NSArray<NSString *> *)strings {
    TSPKHandleResult *result = [TSPKClipboardOfUIPasteboardPipeline handleAPIAccess:NSStringFromSelector(@selector(setStrings:)) className:[TSPKClipboardOfUIPasteboardPipeline stubbedClass] params:[self tspk_context]];
    if (result.action == TSPKResultActionFuse) {
    } else {
        return [self tspk_clipboard_setStrings:strings];
    }
}

- (void)tspk_clipboard_setURL:(NSURL *)URL {
    TSPKHandleResult *result = [TSPKClipboardOfUIPasteboardPipeline handleAPIAccess:NSStringFromSelector(@selector(setURL:)) className:[TSPKClipboardOfUIPasteboardPipeline stubbedClass] params:[self tspk_context]];
    if (result.action == TSPKResultActionFuse) {
    } else {
        return [self tspk_clipboard_setURL:URL];
    }
}

- (void)tspk_clipboard_setURLs:(NSArray<NSURL *> *)URLs {
    TSPKHandleResult *result = [TSPKClipboardOfUIPasteboardPipeline handleAPIAccess:NSStringFromSelector(@selector(setURLs:)) className:[TSPKClipboardOfUIPasteboardPipeline stubbedClass] params:[self tspk_context]];
    if (result.action == TSPKResultActionFuse) {
    } else {
        return [self tspk_clipboard_setURLs:URLs];
    }
}

- (void)tspk_clipboard_setImage:(UIImage *)image {
    TSPKHandleResult *result = [TSPKClipboardOfUIPasteboardPipeline handleAPIAccess:NSStringFromSelector(@selector(setImage:)) className:[TSPKClipboardOfUIPasteboardPipeline stubbedClass] params:[self tspk_context]];
    if (result.action == TSPKResultActionFuse) {
    } else {
        return [self tspk_clipboard_setImage:image];
    }
}

- (void)tspk_clipboard_setImages:(NSArray<UIImage *> *)images {
    TSPKHandleResult *result = [TSPKClipboardOfUIPasteboardPipeline handleAPIAccess:NSStringFromSelector(@selector(setImages:)) className:[TSPKClipboardOfUIPasteboardPipeline stubbedClass] params:[self tspk_context]];
    if (result.action == TSPKResultActionFuse) {
    } else {
        return [self tspk_clipboard_setImages:images];
    }
}

- (void)tspk_clipboard_setColor:(UIColor *)color {
    TSPKHandleResult *result = [TSPKClipboardOfUIPasteboardPipeline handleAPIAccess:NSStringFromSelector(@selector(setColor:)) className:[TSPKClipboardOfUIPasteboardPipeline stubbedClass] params:[self tspk_context]];
    if (result.action == TSPKResultActionFuse) {
    } else {
        return [self tspk_clipboard_setColor:color];
    }
}

- (void)tspk_clipboard_setColors:(NSArray<UIColor *> *)colors {
    TSPKHandleResult *result = [TSPKClipboardOfUIPasteboardPipeline handleAPIAccess:NSStringFromSelector(@selector(setColors:)) className:[TSPKClipboardOfUIPasteboardPipeline stubbedClass] params:[self tspk_context]];
    if (result.action == TSPKResultActionFuse) {
    } else {
        return [self tspk_clipboard_setColors:colors];
    }
}

- (void)tspk_clipboard_setItems:(NSArray<NSDictionary<NSString *,id> *> *)items options:(NSDictionary<UIPasteboardOption,id> *)options {
    TSPKHandleResult *result = [TSPKClipboardOfUIPasteboardPipeline handleAPIAccess:NSStringFromSelector(@selector(setItems:options:)) className:[TSPKClipboardOfUIPasteboardPipeline stubbedClass] params:[self tspk_context]];
    if (result.action == TSPKResultActionFuse) {
    } else {
        return [self tspk_clipboard_setItems:items options:options];
    }
}

- (void)tspk_clipboard_setItems:(NSArray<NSDictionary<NSString *,id> *> *)items {
    TSPKHandleResult *result = [TSPKClipboardOfUIPasteboardPipeline handleAPIAccess:NSStringFromSelector(@selector(setItems:)) className:[TSPKClipboardOfUIPasteboardPipeline stubbedClass] params:[self tspk_context]];
    if (result.action == TSPKResultActionFuse) {
    } else {
        return [self tspk_clipboard_setItems:items];
    }
}

- (NSDictionary *)tspk_context
{
    return @{
        @"pasteboard_name": [self name] ?: @""
    };
}
@end

@implementation TSPKClipboardOfUIPasteboardPipeline

+ (Class)pasteboardClass {
    if (@available(iOS 10.0, *)) {
        NSString *className = [TSPKUtils decodeBase64String:@"X1VJQ29uY3JldGVQYXN0ZWJvYXJk"]; //_UIConcretePasteboard
        Class realClass = NSClassFromString(className);
        if (realClass == nil) {
            NSString *alternativeClassName = [TSPKUtils decodeBase64String:@"X1VJQ29uY3JldGVQYXN0ZWJvYXJkQ0Y="]; //_UIConcretePasteboardCF
            Class alternativeRealClass = NSClassFromString(alternativeClassName);
            if (alternativeRealClass == nil) {
                NSAssert(false, @"%@ and %@ class are not exist", className, alternativeRealClass);
            }
            return alternativeRealClass;
        }
        return realClass;
    }
    return nil;
}

+ (NSString *)dataType {
    return TSPKDataTypeClipboard;
}

+ (NSString *)pipelineType {
    return TSPKPipelineClipboardOfUIPasteboard;
}

+ (NSString *)stubbedClass
{
  return @"UIPasteboard";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return nil;
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    return @[
        NSStringFromSelector(@selector(string)),
        NSStringFromSelector(@selector(strings)),
        NSStringFromSelector(@selector(URL)),
        NSStringFromSelector(@selector(URLs)),
        NSStringFromSelector(@selector(image)),
        NSStringFromSelector(@selector(images)),
        NSStringFromSelector(@selector(color)),
        NSStringFromSelector(@selector(colors)),
        NSStringFromSelector(@selector(valuesForPasteboardType:inItemSet:)),
        NSStringFromSelector(@selector(dataForPasteboardType:inItemSet:)),
        NSStringFromSelector(@selector(items)),
        NSStringFromSelector(@selector(setString:)),
        NSStringFromSelector(@selector(setStrings:)),
        NSStringFromSelector(@selector(setURL:)),
        NSStringFromSelector(@selector(setURLs:)),
        NSStringFromSelector(@selector(setImage:)),
        NSStringFromSelector(@selector(setImages:)),
        NSStringFromSelector(@selector(setColor:)),
        NSStringFromSelector(@selector(setColors:)),
        NSStringFromSelector(@selector(setItems:options:)),
        NSStringFromSelector(@selector(setItems:))
    ];
}

+ (void)preload {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [UIPasteboard tspk_clipboard_preload:[self pasteboardClass]];
    });
}

@end
