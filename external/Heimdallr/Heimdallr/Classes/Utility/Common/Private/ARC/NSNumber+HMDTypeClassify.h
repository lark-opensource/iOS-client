//
//  NSNumber+HMDTypeClassify.h
//  Heimdallr
//
//  Created by sunrunwang on 2019/4/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSNumber (HMDTypeClassify)

@property(nonatomic, readonly, getter=hmd_isIntegerType) BOOL hmdIntegerType;
@property(nonatomic, readonly, getter=hmd_isBoolType) BOOL hmdBoolType;

@end

NS_ASSUME_NONNULL_END
