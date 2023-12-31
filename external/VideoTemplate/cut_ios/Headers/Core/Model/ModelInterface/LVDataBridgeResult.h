//
//  LVDataBridgeResult.h
//  DraftComponent
//
//  Created by zenglifeng on 2019/7/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LVDataBridgeResult<__covariant T> : NSObject

@property (nonatomic, strong, nullable) T data;

@property (nonatomic, strong, nullable) NSError *error;

+ (instancetype)resultWithData:(nullable T)data error:(nullable NSError *)error;

@end

NS_ASSUME_NONNULL_END
