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

#import <malloc/malloc.h>
#import <mach/vm_statistics.h>

#include "memory_report_generator.h"
#include "memory_stat_err_code.h"
#include "memory_logging_event_config.h"

extern int dump_call_stacks;
extern bool memory_graph_dump;
extern bool matrix_async_stack_enable;

int enable_memory_logging(const char *log_dir);
void disable_memory_logging(void);
void heimdallr_disable_memory_logging(const char *disable_reason);

void suspend_memory_logging();
void resume_memory_logging();

bool memory_dump(void (*callback)(const char *, size_t), summary_report_param param);
void get_event_time_stamp(bool event_time);
void set_memory_dump_time_cost_callback(void(*callback)(long));
