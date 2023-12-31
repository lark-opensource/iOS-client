//
//  HMDOrderFileTraceData.hpp
//  AWECloudCommand
//
//  Created by maniackk on 2021/11/16.
//

#ifndef HMDOrderFileTraceData_hpp
#define HMDOrderFileTraceData_hpp

#include <stdio.h>
extern BOOL heimdallrOrderFileEnabled;

#ifdef __cplusplus
extern "C" {
#endif

void StartEnd(void);

void __heimdallr_instrument_orderfile(u_int64_t hash);


#ifdef __cplusplus
}
#endif

#endif /* HMDOrderFileTraceData_hpp */
