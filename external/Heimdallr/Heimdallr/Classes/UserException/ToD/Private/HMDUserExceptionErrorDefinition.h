//
//  HMDUserExceptionErrorDefinition.h
//  Heimdallr
//
//  Created by Nickyo on 2023/8/30.
//

#import "HMDUserExceptionTracker.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HMDStaticUserExceptionFailType) {
    HMDStaticUserExceptionFailTypeNotWorking      = HMDUserExceptionFailTypeNotWorking,
    HMDStaticUserExceptionFailTypeMissingType     = HMDUserExceptionFailTypeMissingType,
    HMDStaticUserExceptionFailTypeExceedsLimiting = HMDUserExceptionFailTypeExceedsLimiting,
    HMDStaticUserExceptionFailTypeInsertFail      = HMDUserExceptionFailTypeInsertFail,
    HMDStaticUserExceptionFailTypeParamsMissing   = HMDUserExceptionFailTypeParamsMissing,
    HMDStaticUserExceptionFailTypeBlockList       = HMDUserExceptionFailTypeBlockList,
    HMDStaticUserExceptionFailTypeLog             = HMDUserExceptionFailTypeLog,
    HMDStaticUserExceptionFailTypeDropData        = HMDUserExceptionFailTypeDropData,
};

NS_ASSUME_NONNULL_END
