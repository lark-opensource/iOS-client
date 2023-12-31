//
//  HMDFrameRecoverExceptionData.h
//  FrameRecover
//
//  Created by sunrunwang on 2022/1/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HMDFrameRecoverExceptionData : NSObject

@property(nonatomic, readonly, nonnull) NSException *exception;
@property(nonatomic, readonly) uintptr_t pc;

@end

typedef void (^HMDFCExceptionCallback)(HMDFrameRecoverExceptionData * _Nonnull data);

NS_ASSUME_NONNULL_END
