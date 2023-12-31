//
//  IESAlgorithmRecord.h
//  EffectPlatformSDK-Pods
//
//  Created by pengzhenhuan on 2020/9/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESAlgorithmRecord : NSObject

@property (nonatomic, copy, readonly) NSString *name; // Primary property

@property (nonatomic, copy, readonly) NSString *version;

@property (nonatomic, copy, readonly) NSString *modelMD5;

@property (nonatomic, copy, readonly) NSString *filePath;

@property (nonatomic, assign, readonly) unsigned long long size;

@property (nonatomic, assign, readonly) NSInteger sizeType;

- (instancetype)initWithName:(NSString *)name
                     version:(NSString *)version
                    modelMD5:(NSString *)modelMD5
                    filePath:(NSString *)filePath
                        size:(unsigned long long)size
                    sizeType:(NSInteger)sizeType;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
