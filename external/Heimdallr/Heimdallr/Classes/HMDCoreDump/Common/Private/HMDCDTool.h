//
//  HMDCDTool.h
//  Pods
//
//  Created by maniackk on 2020/11/5.
//

#ifndef HMDCDTool_h
#define HMDCDTool_h

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, HMDCoredumpErrorType) {
    HMDCoredumpErrorTypeNoFile = 0,
    HMDCoredumpErrorTypeZipError,
    HMDCoredumpErrorTypeInvalidFile,
    HMDCoredumpErrorTypeUploadFail,
    HMDCoredumpErrorTypeUnknow
};

#endif /* HMDCDTool_h */
