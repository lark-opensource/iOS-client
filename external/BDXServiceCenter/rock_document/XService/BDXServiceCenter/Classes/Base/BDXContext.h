//
//  BDXContext.h
//  AAWELaunchOptimization
//
//  Created by duanefaith on 2019/10/21.
//
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDXContext : NSObject <NSCopying>

- (void)registerWeakObj:(nullable id)obj forType:(Class)aClass;
- (void)registerStrongObj:(nullable id)obj forType:(Class)aClass;
- (void)registerCopyObj:(nullable id<NSCopying>)obj forType:(Class)aClass;
- (void)registerWeakObj:(nullable id)obj forKey:(NSString *)key;
- (void)registerStrongObj:(nullable id)obj forKey:(NSString *)key;
- (void)registerCopyObj:(nullable id<NSCopying>)obj forKey:(NSString *)key;
- (nullable id)getObjForType:(Class)aClass;
- (nullable id)getObjForKey:(NSString *)key;
- (BOOL)isWeakObjForKey:(NSString *)key;
- (void)mergeContext:(BDXContext *)context;

@end

@interface BDXContext (Property)

@property (nonatomic, strong) id extraInfo;

@end

NS_ASSUME_NONNULL_END
