//
//  HMDABTestVids.h
//  Heimdallr
//
//  Created by ByteDance on 2023/7/20.
//

#ifndef HMDABTestVids_h
#define HMDABTestVids_h

#include <stdio.h>
#include "HMDPublicMacro.h"

#define HMD_MAX_VID_COUNT  3000

//vid "7777777",
#define HMD_VID_LENGTH 10

#define HMD_MAX_VID_LIST_LENGTH  (HMD_MAX_VID_COUNT * HMD_VID_LENGTH)

#define HMD_AB_TEST_SUCCESS             0

#define HMD_AB_TEST_NULL_VID            1

#define HMD_AB_TEST_INVALID_VID         2

#define HMD_AB_TEST_INIT_ERR            3

#define HMD_AB_TEST_LIMIT               4


typedef int hmd_ab_test_return_t;

typedef struct hmd_ab_test_vids {
    char vids[HMD_MAX_VID_LIST_LENGTH]; //"vid1","vid2","vid3"
    size_t vid_count; //the count of vids
    size_t offset; //The end position of the current vids, the writing position of the next vid
} hmd_ab_test_vids_t;

HMD_EXTERN_SCOPE_BEGIN
hmd_ab_test_vids_t * _Nullable hmd_init_ab_test_vids(void);

hmd_ab_test_return_t hmd_add_hit_vid(const char * _Nonnull vid);

hmd_ab_test_vids_t * _Nullable hmd_get_vid_info(void);

HMD_EXTERN_SCOPE_END

#endif /* HMDABTestVids_h */
