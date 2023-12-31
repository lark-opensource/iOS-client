//
//  HMDEMMacro.h
//  Pods
//
//  Created by maniackk on 2021/6/6.
//

#ifndef HMDEMMacro_h
#define HMDEMMacro_h

#define EMSeparator "####"
#define KMaxEMZipFileSizeMB 2
#define kMapMaxCapacity 2900

typedef struct {
    time_value_t wall_ts;
    u_int64_t hash;
    char phase;
}EMFuncMeta;

#endif /* HMDEMMacro_h */
