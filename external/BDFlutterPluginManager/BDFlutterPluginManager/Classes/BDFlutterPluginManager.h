//
//  BDFlutterPluginManager.h
//  BDFlutterPluginManager
//  Created by 林一一 on 2019/9/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDFlutterPluginManager : NSObject

@property(nonatomic, strong) NSMutableArray *pluginProtocolImplementations;

+ (instancetype)sharedManager;
+ (void)registPlugin:(Class)plugin;
- (void)registerProtocolImplementation: (Class)implementationClass;
- (void)registerProtocolImplementation: (Class)implementationClass withPlugin: (NSString *)pluginName;
- (void)registerProtocolImplementation: (Class)implementationClass withProtocol: (NSString *)protocolName plugin: (NSString *)pluginName;
- (void)registerProtocolImplementations: (NSArray<Class> *)implementationClasses;
- (void)unregisterProtocolImplementation:(Class)implementationClass;
- (nullable Class)getProtocolImplementationClass:(NSString *)protocolName;

@end

NS_ASSUME_NONNULL_END
