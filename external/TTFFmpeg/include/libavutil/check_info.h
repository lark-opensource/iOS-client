/*
 * Copyright 2022 Bytedance Inc.
 * SPDX license identifier: LGPL-2.1-or-later
 */

#ifndef AVUTIL_CHECK_INFO_H
#define AVUTIL_CHECK_INFO_H

enum AVCheckMethod {
    CHECK_METHOD_VID,
    CHECK_METHOD_MEDIA_TYPE,
};

typedef struct AVCheckInfoItem {
    int check_method;
    char *check_info;
} AVCheckInfoItem;

typedef struct AVCheckInfo {
    int nb_items;
    AVCheckInfoItem **items;
} AVCheckInfo;

AVCheckInfoItem *av_check_info_item_alloc(void);

AVCheckInfoItem *av_check_info_item_init(const char *info_str);

void av_check_info_item_free(AVCheckInfoItem *item);

AVCheckInfo *av_check_info_alloc(void);

void av_check_info_add_item(AVCheckInfo *info, AVCheckInfoItem *item);

AVCheckInfo *av_check_info_init(const char *info_str);

void av_check_info_free(AVCheckInfo *info);

#endif /* AVUTIL_CHECK_INFO_H */
