//
//  BridgeModuleManager.m
//  FlutterIntergation
//
//  Created by bytedance on 2020/4/3.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import "BDBridgeModuleManager.h"
#import "BDBridgeViewMarker.h"

@interface BDBridgeModuleManager()

@property(strong , nonatomic)NSMutableDictionary<NSString *, NSMutableDictionary *> *modules;

@end


@implementation BDBridgeModuleManager

- (instancetype)init {
    if (self = [super init]) {
        _modules = [[NSMutableDictionary alloc] init];
    }
    return self;
}

+ (instancetype)sharedManager {
    static BDBridgeModuleManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[BDBridgeModuleManager alloc] init];
    });
    return manager;
}

- (void)addModule:(id<BDBridgeHost>)module key:(Class)clazz carrier:(NSObject *)carrier {
    NSString *key = NSStringFromClass(clazz);
    NSInteger tagId = [BDBridgeViewMarker generateBridgeIfNeed:carrier];
    NSMutableDictionary *map = self.modules[key];
    if (!map) {
        map = [NSMutableDictionary dictionary];
        self.modules[key] = map;
    }
    map[@(tagId)] = module;
}


- (id<BDBridgeHost>)getModule:(Class)clazz carrier:(NSObject *)carrier {
    NSInteger tagId = [BDBridgeViewMarker getBridgeId:carrier];
    NSString *key = NSStringFromClass(clazz);
    NSMutableDictionary *map = self.modules[key];
    return map[@(tagId)];
}

- (void)removeModule:(Class)clazz forCarrier:(NSObject *)carrier {
    NSInteger tagId = [BDBridgeViewMarker getBridgeId:carrier];
    NSString *key = NSStringFromClass(clazz);
    NSMutableDictionary *map = self.modules[key];
    if (map) {
        [map removeObjectForKey:@(tagId)];
    }
}

@end
