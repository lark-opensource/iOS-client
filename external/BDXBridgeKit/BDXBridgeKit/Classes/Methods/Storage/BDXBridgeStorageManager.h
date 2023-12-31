//
//  BDXBridgeStorageManager.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/7/20.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeStorageManager : BDXBridgeMethod

@property (class, nonatomic, strong, readonly) BDXBridgeStorageManager *sharedManager;

- (void)setObject:(nullable id)object forKey:(NSString *)key;
- (nullable id)objectForKey:(NSString *)key;
- (void)removeObjectForKey:(NSString *)key;
- (NSArray<NSString *> *)allKeys;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
