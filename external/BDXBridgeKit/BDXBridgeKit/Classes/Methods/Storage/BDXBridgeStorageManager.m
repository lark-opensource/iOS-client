//
//  BDXBridgeStorageManager.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/7/20.
//

#import "BDXBridgeStorageManager.h"

static NSString * const kUserDefaultsDomain = @"BDXBridgeStorage";

@interface BDXBridgeStorageManager ()

@property (nonatomic, strong, readonly) NSUserDefaults *userDefaults;

@end

@implementation BDXBridgeStorageManager

+ (instancetype)sharedManager
{
    static BDXBridgeStorageManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[BDXBridgeStorageManager alloc] initWithDomain:kUserDefaultsDomain];
    });
    return manager;
}

- (instancetype)initWithDomain:(NSString *)domain
{
    self = [super init];
    if (self) {
        _userDefaults = [[NSUserDefaults alloc] initWithSuiteName:domain];
    }
    return self;
}

- (void)setObject:(id)object forKey:(NSString *)key
{
    [self.userDefaults setObject:object forKey:key];
}

- (id)objectForKey:(NSString *)key
{
    return [self.userDefaults objectForKey:key];
}

- (void)removeObjectForKey:(NSString *)key
{
    [self.userDefaults removeObjectForKey:key];
}

- (NSArray<NSString *> *)allKeys
{
    return [[self.userDefaults persistentDomainForName:kUserDefaultsDomain] allKeys];
}

@end
