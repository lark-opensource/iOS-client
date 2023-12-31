//
//  CJPayProtocolManager.m
//  CJPay
//
//  Created by 王新华 on 3/4/20.
//

#import "CJPayProtocolManager.h"
#import "CJPaySDKMacro.h"

@interface CJPayProtocolManager()

@property (nonatomic, strong) NSMutableDictionary *protocolToObjectMap;
@property (nonatomic, strong) NSMutableDictionary *protocolToClassMap;
@property (nonatomic, strong) NSMutableDictionary *sharedSelectorNameToClassMap;
@property (nonatomic, strong) dispatch_queue_t rwQueue;

@end

@implementation CJPayProtocolManager

+ (CJPayProtocolManager *)sharedInstance {
    static CJPayProtocolManager *protocolManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        protocolManager = [CJPayProtocolManager new];
        protocolManager.protocolToObjectMap = [NSMutableDictionary new];
        protocolManager.protocolToClassMap = [NSMutableDictionary new];
        protocolManager.sharedSelectorNameToClassMap = [NSMutableDictionary new];
        protocolManager.rwQueue = dispatch_queue_create("cjpay.protocolmanager.queue", DISPATCH_QUEUE_SERIAL);
    });
    return protocolManager;
}

+ (void)bindObject:(id)object toProtocol:(Protocol *)protocol {
    if (object == nil || protocol == nil || ![object conformsToProtocol:protocol]) {
        CJPayLogAssert(NO, @"%@ should conforms to %@, %s", object, NSStringFromProtocol(protocol), __func__);
        return;
    }
    NSString *protocolName = NSStringFromProtocol(protocol);
    
    dispatch_sync([self sharedInstance].rwQueue, ^{
        if ([[self sharedInstance].protocolToObjectMap objectForKey:protocolName] == nil) {
            [[self sharedInstance].protocolToObjectMap setObject:object forKey:protocolName];
        } else {
            CJPayLogAssert(NO, @"%@ and %@ are duplicated bindings, %s", object, NSStringFromProtocol(protocol), __func__);
        }
    });
}

+ (void)bindClass:(Class)cls toProtocol:(Protocol *)protocol {
    [self bindClass:cls withSharedSelector:nil toProtocol:protocol];
}

+ (void)bindClass:(Class)cls withSharedSelector:(nullable SEL)sharedSelector toProtocol:(Protocol *)protocol {
    if (cls == nil || protocol == nil || ![cls conformsToProtocol:protocol]) {
        [CJMonitor trackService:@"wallet_rd_serviceframework_protocol_not_conform" metric:@{} category:@{@"cls": CJString(NSStringFromClass(cls)), @"protocol": CJString(NSStringFromProtocol(protocol))} extra:@{}];
        CJPayLogAssert(NO, @"%@ should conforms to %@, %s", CJString(NSStringFromClass(cls)), CJString(NSStringFromProtocol(protocol)), __func__);
        return;
    }
    dispatch_sync([self sharedInstance].rwQueue, ^{
        NSString *protocolName = NSStringFromProtocol(protocol);
        if ([[self sharedInstance].protocolToClassMap objectForKey:protocolName] == nil) {
            [[self sharedInstance].protocolToClassMap setObject:cls forKey:protocolName];
            if (NSStringFromSelector(sharedSelector) && NSStringFromClass(cls)) {
               [[self sharedInstance].sharedSelectorNameToClassMap setObject:NSStringFromSelector(sharedSelector) forKey:NSStringFromClass(cls)];
            }
        } else {
            [CJMonitor trackService:@"wallet_rd_serviceframework_duplicate_bind_protocol" category:@{@"new_object": CJString(NSStringFromClass(cls)),@"old_object": CJString(NSStringFromClass([[self sharedInstance].protocolToClassMap objectForKey:protocolName])), @"protocol": CJString(NSStringFromProtocol(protocol))} extra:@{}];
           CJPayLogAssert(NO, @"%@ and %@ are duplicated bindings, %s", NSStringFromClass(cls), NSStringFromProtocol(protocol), __func__);
        }
    });
}

+ (nullable id)getObjectWithProtocol:(Protocol *)protocol {
    if (protocol == nil) {
        return nil;
    }
    
    __block id object;
    dispatch_sync([self sharedInstance].rwQueue, ^{
        NSString *protocolName = NSStringFromProtocol(protocol);
        object = [[self sharedInstance].protocolToObjectMap objectForKey:protocolName];
        if (object == nil) {
            Class cls = [[self sharedInstance].protocolToClassMap btd_objectForKey:protocolName default:nil];
            if (cls != nil) {
                NSString *sharedSelectorName = [[self sharedInstance].sharedSelectorNameToClassMap objectForKey:NSStringFromClass(cls)];
                SEL sharedSelector = NSSelectorFromString(sharedSelectorName);
                if (sharedSelector && [cls respondsToSelector:sharedSelector]) {
                    object = [cls performSelector:sharedSelector];
                } else {
                    object = [[cls alloc] init];
                }
                [[self sharedInstance].protocolToObjectMap setObject:object forKey:protocolName];
            } else {
                NSArray *blackList = @[@"CJPayClosePayDeskAlertProtocol",@"CJPayLocalizedPlugin"];
                if (protocolName.length > 0 && ![blackList containsObject:protocolName]) {
                    [CJMonitor trackService:@"wallet_rd_serviceframework_getservice_failed" metric:@{} category:@{@"protocol": CJString(protocolName)} extra:@{}];
                }
            }
        }
    });
    return object;
}

+ (nullable Class)getClassWithProtocol:(Protocol *)protocol {
    if (protocol == nil) {
        return nil;
    }
    NSString *protocolName = NSStringFromProtocol(protocol);
    Class cls = [[self sharedInstance].protocolToClassMap objectForKey:protocolName];
    return cls;
}

+ (void)unbindProtocol:(Protocol *)protocol
{
    NSString *protocolName = NSStringFromProtocol(protocol);
    dispatch_sync([self sharedInstance].rwQueue, ^{
        if ([[self sharedInstance].protocolToClassMap objectForKey:protocolName]) {
            [[self sharedInstance].protocolToClassMap removeObjectForKey:protocolName];
            // 不处理class 到 单例方法的映射
        }
        if ([[self sharedInstance].protocolToObjectMap objectForKey:protocolName]) {
            [[self sharedInstance].protocolToObjectMap removeObjectForKey:protocolName];
        }
    });
}

@end
