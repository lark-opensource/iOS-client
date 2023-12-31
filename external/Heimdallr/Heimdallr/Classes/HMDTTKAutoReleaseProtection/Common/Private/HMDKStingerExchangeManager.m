//
//  HMDKStingerExchangeManager.m
//  Indexer
//
//  Created by Martin Lyu on 2022/3/14.
//

#import "HMDKStingerExchangeManager.h"
#import "HMDStingerBlocker.h"
#import <objc/runtime.h>
#import <Stinger/Stinger.h>
#import "HMDALogProtocol.h"
#import "hmd_crash_safe_tool.h"

static bool HMD_isEmptyString(NSString* str) {
    return str.length == 0;
}

static BOOL parseMethodString(NSString *methodString, Class *class, SEL *selector, BOOL *isInstance) {
    if (HMD_isEmptyString(methodString)) {
        return NO;
    }
    NSString *method = [methodString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (isInstance != NULL) {
        if ([method hasPrefix:@"+"]) {
            *isInstance = NO;
        } else if ([method hasPrefix:@"-"]) {
            *isInstance = YES;
        } else {
            return NO;
        }
    }
    // remove '+' or '-'
    method = [method substringFromIndex:1];
    method = [method stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    // remove '[]'
    if (method.length > 2 && [method hasPrefix:@"["] && [method hasSuffix:@"]"]) {
        method = [method substringWithRange:NSMakeRange(1, method.length - 2)];
    }
    NSArray<NSString *> *components = [method componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (!components || components.count != 2) {
        return NO;
    }
    NSString *classString = components[0];
    NSString *selectorString = components[1];
    if (HMD_isEmptyString(classString) || HMD_isEmptyString(selectorString)) {
        return NO;
    }
    if (class != NULL) {
        *class = NSClassFromString(classString);
    }
    if (selector != NULL) {
        *selector = NSSelectorFromString(selectorString);
    }
    return YES;
}

@interface HMDKStingerExchangeManager ()

@property (nonatomic, strong) HMDStingerBlocker *blocker;
@property (nonatomic, strong) NSMutableSet<NSString *> *exchangedMethods;

@end

@implementation HMDKStingerExchangeManager

+ (instancetype)sharedInstance {
    static HMDKStingerExchangeManager *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[HMDKStingerExchangeManager alloc] init];
    });
    return _instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _exchangedMethods = [[NSMutableSet alloc] init];
        _blocker = HMDStingerBlocker.sharedInstance;
    }
    return self;
}

- (BOOL)exchangeMethod:(NSString *)methodString block:(HMDStingerExchangeBodyBlock)bodyBlock {
    if (!methodString || !bodyBlock) {
        return NO;
    }
    Class class;
    SEL selector;
    BOOL isInstance;
    if (!parseMethodString(methodString, &class, &selector, &isInstance)) {
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[HMDAutoreleaseProtection] exchange fail due to parse method string failed: %@", methodString);
        return NO;
    }
    if ([self.blocker hitBlockListForCls:class selector:selector isInstance:isInstance]) {
        HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr",  @"[HMDAutoreleaseProtection] exchange failed due to method is blocked by Stinger: %@", methodString);
        return NO;
    }
    if ([self.exchangedMethods containsObject:methodString]) {
        HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"[HMDAutoreleaseProtection] method already exchanged: %@", methodString);
        return NO;
    }
    Method targetMethod = NULL;
    if (isInstance) {
        targetMethod = class_getInstanceMethod(class, selector);
    } else {
        targetMethod = class_getClassMethod(class, selector);
    }
    if (targetMethod == NULL) {
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[HMDAutoreleaseProtection] exchange failed due to get Method failed: %@", methodString);
        return NO;
    }
    const char *signature = method_getTypeEncoding(targetMethod);
    id block = [self exchangeBlockWithSignature:signature body:bodyBlock];
    if (!block) {
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[HMDAutoreleaseProtection] exchange failed due to get protect block failed: %@ %s", methodString, signature);
        return NO;
    }
    NSError *error = nil;
    if (isInstance) {
        [class st_hookInstanceMethod:selector withOptions:STOptionInstead|STOptionWeakCheckSignature usingBlock:block error:&error];
    } else {
        [class st_hookClassMethod:selector withOptions:STOptionInstead|STOptionWeakCheckSignature usingBlock:block error:&error];
    }
    if (error) {
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[HMDAutoreleaseProtection] exchange failed due to stinger error: %@ %@", methodString, error);
        return NO;
    }
    [self.exchangedMethods addObject:methodString];
    return YES;
}

static const char *HMDDCSkipMethodEncodings(const char *_Nonnull decl);

- (id)exchangeBlockWithSignature:(const char *)signature body:(HMDStingerExchangeBodyBlock)body {
    if (signature == NULL || !body) {
        return nil;
    }
    
    signature = HMDDCSkipMethodEncodings(signature);

    // generate block
    id block = nil;
    switch (signature[0]) {
        case _C_ID:
        {
            block = ^id(id<StingerParams> params) {
                void *rst = NULL;
                body(params, &rst);
                return (__bridge id)rst;
            };
            break;
        }
        case _C_VOID:
        {
            block = ^void(id<StingerParams> params) {
                body(params, nil);
            };
            break;
        }
        case _C_CLASS:
        {
            block = ^Class(id<StingerParams> params) {
                Class rst = nil;
                body(params, &rst);
                return rst;
            };
            break;
        }
        case _C_SEL:
        {
            block = ^SEL(id<StingerParams> params) {
                SEL rst = nil;
                body(params, &rst);
                return rst;
            };
            break;
        }
        case _C_PTR:
        {
            block = ^void *(id<StingerParams> params) {
                void *rst = nil;
                body(params, &rst);
                return rst;
            };
            break;
        }
        case _C_CHARPTR:
        {
            block = ^char *(id<StingerParams> params) {
                char *rst = nil;
                body(params, &rst);
                return rst;
            };
            break;
        }
        case _C_CHR:
        {
            block = ^char(id<StingerParams> params) {
                char rst = 0;
                body(params, &rst);
                return rst;
            };
            break;
        }
        case _C_UCHR:
        {
            block = ^unsigned char(id<StingerParams> params) {
                unsigned char rst = 0;
                body(params, &rst);
                return rst;
            };
            break;
        }
        case _C_SHT:
        {
            block = ^short(id<StingerParams> params) {
                short rst = 0;
                body(params, &rst);
                return rst;
            };
            break;
        }
        case _C_USHT:
        {
            block = ^unsigned short(id<StingerParams> params) {
                unsigned short rst = 0;
                body(params, &rst);
                return rst;
            };
            break;
        }
        case _C_INT:
        {
            block = ^int(id<StingerParams> params) {
                int rst = 0;
                body(params, &rst);
                return rst;
            };
            break;
        }
        case _C_UINT:
        {
            block = ^unsigned int(id<StingerParams> params) {
                unsigned int rst = 0;
                body(params, &rst);
                return rst;
            };
            break;
        }
        case _C_LNG:
        {
            block = ^long(id<StingerParams> params) {
                long rst = 0;
                body(params, &rst);
                return rst;
            };
            break;
        }
        case _C_ULNG:
        {
            block = ^unsigned long(id<StingerParams> params) {
                unsigned long rst = 0;
                body(params, &rst);
                return rst;
            };
            break;
        }
        case _C_LNG_LNG:
        {
            block = ^long long(id<StingerParams> params) {
                long long rst = 0;
                body(params, &rst);
                return rst;
            };
            break;
        }
        case _C_ULNG_LNG:
        {
            block = ^unsigned long long(id<StingerParams> params) {
                unsigned long long rst = 0;
                body(params, &rst);
                return rst;
            };
            break;
        }
        case _C_FLT:
        {
            block = ^float(id<StingerParams> params) {
                float rst = 0;
                body(params, &rst);
                return rst;
            };
            break;
        }
        case _C_DBL:
        {
            block = ^double(id<StingerParams> params) {
                double rst = 0;
                body(params, &rst);
                return rst;
            };
            break;
        }
        case _C_BOOL:
        {
            block = ^BOOL(id<StingerParams> params) {
                BOOL rst = NO;
                body(params, &rst);
                return rst;
            };
            break;
        }
        case _C_STRUCT_B:
        {
            if (hmd_reliable_has_prefix(signature, @encode(CGPoint))) {
                block = ^CGPoint(id<StingerParams> params) {
                    CGPoint rst = CGPointZero;
                    body(params, &rst);
                    return rst;
                };
            } else if (hmd_reliable_has_prefix(signature, @encode(CGSize))) {
                block = ^CGSize(id<StingerParams> params) {
                    CGSize rst = CGSizeZero;
                    body(params, &rst);
                    return rst;
                };
            } else if (hmd_reliable_has_prefix(signature, @encode(CGRect))) {
                block = ^CGRect(id<StingerParams> params) {
                    CGRect rst = CGRectZero;
                    body(params, &rst);
                    return rst;
                };
            } else if (hmd_reliable_has_prefix(signature, @encode(NSRange))) {
                block = ^NSRange(id<StingerParams> params) {
                    NSRange rst = NSMakeRange(NSNotFound, 0);
                    body(params, &rst);
                    return rst;
                };
            } else {
                HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[HMDAutoreleaseProtection] get exchange block fail due to unknown _C_STRUCT_B: %s", signature);
            }
            break;
        }
        default:
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[HMDAutoreleaseProtection] get exchange block fail due to unknown signature: %s", signature);
            break;
    }

    return block;
}

@end

static const char *HMDDCSkipMethodEncodings(const char *_Nonnull decl) {
    static const char *qualifiersAndComments = "nNoOrRV\"";
    while (*decl != '\0' && strchr(qualifiersAndComments, *decl)) {
        if (*decl == '"') {
            decl++;
            while (*decl++ != '"');
        }
        else decl++;
    }
    return decl;
}
