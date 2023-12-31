//
//  BDFlutterPluginManager.m
//  BDFlutterPluginManager
//
//  Created by 林一一 on 2019/9/16.
//

#import "BDFlutterPluginManager.h"

@implementation BDFlutterPluginManager {
//    NSMutableArray *_pluginProtocolImplementations;
}

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken ;
    static BDFlutterPluginManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[BDFlutterPluginManager alloc] init] ;
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _pluginProtocolImplementations = [[NSMutableArray alloc] init];
    }
    return self;
}

+ (void)registPlugin:(Class)plugin {
    if (nil != plugin) {
        Class class = NSClassFromString(@"FlutterManager");
        if (class) {
            [class performSelector:@selector(registPlugin:) withObject:plugin];
        }
    }
}

- (void)registerProtocolImplementation: (Class)implementationClass {
    [_pluginProtocolImplementations addObject:implementationClass];
}

- (void)registerProtocolImplementation: (Class)implementationClass withPlugin: (NSString *)pluginName {
    [_pluginProtocolImplementations addObject:implementationClass];
}

- (void)registerProtocolImplementation: (Class)implementationClass withProtocol: (NSString *)protocolName plugin: (NSString *)pluginName {
    [_pluginProtocolImplementations addObject:implementationClass];
}

- (void)registerProtocolImplementations: (NSArray<Class> *)implementationClasses {
    [_pluginProtocolImplementations addObjectsFromArray:implementationClasses];
}

- (void)unregisterProtocolImplementation:(Class)implementationClass {
    [_pluginProtocolImplementations removeObject:implementationClass];
}

- (nullable Class)getProtocolImplementationClass:(NSString *)protocolName {
    Class implementationClass = NULL;
    for (Class class in _pluginProtocolImplementations) {
        if ([class conformsToProtocol:NSProtocolFromString(protocolName)]) {
            implementationClass = class;
            break;
        }
    }
    if (!implementationClass) {
        NSString *defaultImplementationClass = [NSString stringWithFormat:@"%@DefaultImplementation", protocolName];
        implementationClass = NSClassFromString(defaultImplementationClass);
        
        // try again
        if (!implementationClass) {
            NSString *defaultIMP = [NSString stringWithFormat:@"%@DefaultIMP", protocolName];
            implementationClass = NSClassFromString(defaultIMP);
        }
    }
    return implementationClass;
}

@end
