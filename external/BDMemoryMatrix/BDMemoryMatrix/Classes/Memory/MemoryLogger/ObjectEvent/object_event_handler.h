/*
 * Tencent is pleased to support the open source community by making wechat-matrix available.
 * Copyright (C) 2019 THL A29 Limited, a Tencent company. All rights reserved.
 * Licensed under the BSD 3-Clause License (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://opensource.org/licenses/BSD-3-Clause
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef object_event_handler_h
#define object_event_handler_h

#include <stdio.h>
#include <mach/mach.h>

struct object_type_db;
struct vc_name_db;

object_type_db *prepare_object_event_logger(const char *log_dir);
void disable_object_event_logger();
void nsobject_set_last_allocation_event_name(void *ptr, const char *classname);

object_type_db *object_type_db_open_or_create(const char *event_dir);
void object_type_db_close(object_type_db *db_context);

const char *object_type_db_get_object_name(object_type_db *db_context, uint32_t type);
bool object_type_db_is_nsobject(object_type_db *db_context, uint32_t type);

vc_name_db *prepare_vc_name_logger(const char *log_dir);
vc_name_db *vc_name_db_open_or_create(const char *event_dir);
uint8_t vc_name_db_set_name(const char *vc_name);
void vc_name_db_close(vc_name_db *db_context);
uint8_t get_current_vc_name_index();
void set_current_vc_name(const char * vc_name);
const char *vc_name_db_get_name(vc_name_db *db_context, uint8_t index);
uint8_t vc_name_db_get_count(vc_name_db *db_context);

#endif /* object_event_handler_h */
