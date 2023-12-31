//
//  ACCSerializationProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/12/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCSerializationProtocol <NSObject>

@optional
+ (id _Nullable)accs_covertRelations:(Class)originalClass;

+ (id)accs_includeKeys:(BOOL)isTransform;

+ (id)accs_excludeKeys:(BOOL)isTransform;

+ (NSSet<Class> *)accs_acceptClasses:(BOOL)isTransform;

- (BOOL)accs_customCheckAcceptClass:(Class)checkClass isTransform:(BOOL)isTransform;

+ (__kindof NSObject<ACCSerializationProtocol> *)accs_customSaveByOriginObj:(NSObject *)originObj;

- (__kindof NSObject *_Nullable)accs_customRestoreOriginObj:(Class)originalClass;

- (void)accs_extraFinishTransform:(NSObject *)originalObj;

- (void)accs_extraFinishRestore:(NSObject *)originalObj;

@end

NS_ASSUME_NONNULL_END
