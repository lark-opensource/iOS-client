//
//  HMDFrameRecoverMachData.h
//  FrameRecover
//
//  Created by sunrunwang on 2022/1/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HMDFrameRecoverMachData : NSObject

@property(nonatomic) NSString *scope;

@property(nonatomic, nullable) NSPointerArray *backtraces;

@end

typedef void (^HMDFCMachCallback)(HMDFrameRecoverMachData * _Nullable data);

NS_ASSUME_NONNULL_END
