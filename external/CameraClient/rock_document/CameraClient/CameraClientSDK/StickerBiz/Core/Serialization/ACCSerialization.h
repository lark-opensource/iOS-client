//
//  ACCSerialization.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/12/17.
//

#import <Foundation/Foundation.h>
#import "ACCSerializationProtocol.h"

#define ACC_SERIALIZATION_KEY_EQUAL(CLASS1, CLASS2, PATH) \
    _Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Warc-repeated-use-of-weak\"") \
    ((NO && ((void)(((CLASS1)NSObject.new).PATH = ((CLASS2)NSObject.new).PATH), NO))) \
    _Pragma("clang diagnostic pop") \

#define ACC_SERIALIZATION_KEY_RELATION(CLASS1, PATH1, CLASS2, PATH2) \
    _Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Warc-repeated-use-of-weak\"") \
    ((NO && ((void)(((CLASS1)NSObject.new).PATH1 = ((CLASS2)NSObject.new).PATH2), NO))) \
    _Pragma("clang diagnostic pop") \

NS_ASSUME_NONNULL_BEGIN

@interface ACCSerialization : NSObject

/// Transform original object to target class object
/// @param originalObj Original object
/// @param toClass Target class
+ (__kindof NSObject<ACCSerializationProtocol> *)transformOriginalObj:(NSObject *)originalObj to:(Class)toClass;

/// Restore original object from this object
/// @param fromObj Be transformed obj
/// @param originalClass Original class
+ (__kindof NSObject *)restoreFromObj:(NSObject<ACCSerializationProtocol> *)fromObj to:(Class)originalClass;

+ (NSArray<__kindof NSObject<ACCSerializationProtocol> *> *)transformOriginalObjArray:(NSArray *)originalObjArray to:(Class)toClass;

+ (NSArray *)restoreFromObjArray:(NSArray<NSObject<ACCSerializationProtocol> *> *)fromObjArray to:(Class)originClass;

@end

NS_ASSUME_NONNULL_END
