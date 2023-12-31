//
//  HMDCustomAlog.h
//  Pods
//
//  Created by YSurfer on 2023/5/18.
//

#ifndef HMDCustomAlog_h
#define HMDCustomAlog_h
#import <BDAlogProtocol/BDAlogProtocol.h>

extern const char *KALOGMemoryInstance;

#ifdef __cplusplus
extern "C" {
#endif
#define ALOG_Matrix_INSTANCE(instance_name, format, ...) ALOG_PROTOCOL_INFO_TAG_INSTANCE(instance_name, "matrixLynx", format, ##__VA_ARGS__)
#define MEMORY_ALOG_INSTANCE(format, ...) ALOG_Matrix_INSTANCE(KALOGMemoryInstance, format, ## __VA_ARGS__)
#ifdef __cplusplus
}
#endif

#endif /* HMDCustomAlog_h */
