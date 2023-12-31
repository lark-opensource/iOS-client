//
//  HMDFileTool.h
//  Pods
//
//  Created by maniackk on 2021/7/29.
//

#ifndef HMDFileTool_h
#define HMDFileTool_h

#import <Foundation/Foundation.h>
#include "HMDPublicMacro.h"

HMD_EXTERN BOOL hmdCheckAndCreateDirectory(NSString * _Nullable directory);

HMD_EXTERN bool HMDFileAllocate(int fd, size_t length, int * _Nullable error);

#endif /* HMDFileTool_h */
