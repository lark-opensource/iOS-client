//
//  HMDGWPAsanPublicDefine.h
//  HMDGWPASan
//
//  Created by bytedance on 2023/10/17.
//

#ifndef HMDGWPAsanPublicDefine_h
#define HMDGWPAsanPublicDefine_h

#include <malloc/malloc.h>

typedef void (*HMDGWPAsanReplaceZoneFunc)(malloc_zone_t * _Nonnull);

#endif /* HMDGWPAsanPublicDefine_h */
