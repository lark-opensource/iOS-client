//
//  HMDOrderFileCollectData.hpp
//  AWECloudCommand
//
//  Created by maniackk on 2021/11/16.
//

#ifndef HMDOrderFileCollectData_hpp
#define HMDOrderFileCollectData_hpp

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif
void writeOrderFileDataToDisk(void *dataMap);

BOOL setupOFCollectData(void);

void finishWriteFile(void);

#ifdef __cplusplus
}
#endif


#endif /* HMDOrderFileCollectData_hpp */
