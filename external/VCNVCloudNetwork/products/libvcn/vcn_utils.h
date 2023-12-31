//
//  utils.h
//  network-1
//
//  Created by thq on 17/2/20.
//  Copyright © 2017年 thq. All rights reserved.
//

#ifndef vcn_utils_h
#define vcn_utils_h
#include <time.h>
#include "vcn_internal.h"
/**
 * Lock operation used by lockmgr
 */
enum VCNAVLockOp {
    VCN_AV_LOCK_CREATE,  ///< Create a mutex
    VCN_AV_LOCK_OBTAIN,  ///< Lock the mutex
    VCN_AV_LOCK_RELEASE, ///< Unlock the mutex
    VCN_AV_LOCK_DESTROY, ///< Free mutex resources
};
__attribute__((visibility ("default"))) void vcn_av_url_split(char *proto, int proto_size,
                  char *authorization, int authorization_size,
                  char *hostname, int hostname_size,
                  int *port_ptr, char *path, int path_size, const char *url);
__attribute__((visibility ("default"))) void vcn_av_url_split_hostname(char *hostname, int hostname_size, int *port_ptr, const char *url);
void vcn_parse_key_value(const char *str, ff_parse_key_val_cb callback_get_buf,
                        void *context);
char *vcn_data_to_hex(char *buf, const uint8_t *src, int size, int lowercase);
int vcn_av_find_info_tag(char *arg, int arg_size, const char *tag1, const char *info);
__attribute__((visibility ("default"))) void vcn_av_url_split_hostname(char *hostname, int hostname_size, int *port_ptr, const char *url);
__attribute__((visibility ("default"))) char *vcn_av_small_strptime(const char *p, const char *fmt, struct tm *dt);
int vcn_avpriv_lock_avformat(void);
int vcn_avpriv_unlock_avformat(void);
/**
 * Convert the decomposed UTC time in tm to a time_t value.
 */
__attribute__((visibility ("default"))) time_t vcn_av_timegm(struct tm *tm);
#endif /* vcn_utils_h */
