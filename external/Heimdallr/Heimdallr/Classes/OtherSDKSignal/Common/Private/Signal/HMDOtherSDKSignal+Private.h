//
//  HMDOtherSDKSignal+Private.h
//  CaptainAllred
//
//  Created by somebody on somday
//

#ifndef HMDOtherSDKSignal_Private_h
#define HMDOtherSDKSignal_Private_h

#include <signal.h>
#include "HMDPublicMacro.h"
#include "HMDOtherSDKSignal.h"

HMD_EXTERN_SCOPE_BEGIN

int hmd_real_sigaction(int code,
                       const struct sigaction * __restrict _Nullable newAction,
                       struct sigaction * __restrict _Nullable oldAction);

bool hmd_other_SDK_signal_live_keeper(void);

HMD_EXTERN_SCOPE_END

#endif /* HMDOtherSDKSignal_Private_h */
