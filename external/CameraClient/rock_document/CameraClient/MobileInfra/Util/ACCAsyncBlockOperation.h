//
//  ACCAsyncBlockOperation.h
//  CameraClient
//
//  Created by kuangjeon on 2020/2/6.
//

#import "ACCAsyncOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCAsyncBlockOperation : ACCAsyncOperation
typedef void(^ACCAsyncOperationFinishBlock)(ACCAsyncBlockOperation *asyncOp);
/// `finishBlock` will be invoked immediately when call `finish`. And you can also use KVO to observe whether operation is finished.
@property (nonatomic, copy) ACCAsyncOperationFinishBlock finishBlock;
- (instancetype)initWithBlock:(void (^)(ACCAsyncBlockOperation *asyncOp))block;
@end

NS_ASSUME_NONNULL_END
