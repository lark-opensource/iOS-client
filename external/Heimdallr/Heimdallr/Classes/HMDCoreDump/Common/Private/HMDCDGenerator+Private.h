//
//  HMDCDGenerator+Private.h
//  HMDCDGenerator
//
//  Created by somebody on 2000/20/20
//

#ifndef HMDCDGenerator_Private_h
#define HMDCDGenerator_Private_h

#include "HMDMacro.h"

HMD_EXTERN_SCOPE_BEGIN

@interface HMDCDGenerator (Private)

- (void)triggerUpload;

- (void)prepareCoreDump;

@end

void HMDCoreDump_triggerUpload(void);

HMD_EXTERN_SCOPE_END

#endif /* HMDCDGenerator_Private_h */

