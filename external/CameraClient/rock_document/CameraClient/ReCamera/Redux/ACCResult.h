//
//  ACCResult.h
//  CameraClient
//
//  Created by liuqing on 2020/1/14.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ACCResult_OneOfCase) {
    ACCResult_OneOfCase_Success = 0,
    ACCResult_OneOfCase_Failure = 1
};

NS_ASSUME_NONNULL_BEGIN

@interface ACCResult<ValueType> : NSObject

@property (nonatomic, assign, readonly) ACCResult_OneOfCase resultOneOfCase;
@property (nonatomic, strong, readonly) ValueType _Nullable value;
@property (nonatomic, strong, readonly) NSError * _Nullable error;

+ (ACCResult<ValueType> *)success:(ValueType _Nullable)value;
+ (ACCResult *)failure:(NSError * _Nullable)error;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (ACCResult *)map:(id _Nullable (^)(ValueType _Nullable value))transform;
- (ACCResult *)flatMap:(ACCResult * (^)(ValueType _Nullable value))transform;

@end

NS_ASSUME_NONNULL_END
