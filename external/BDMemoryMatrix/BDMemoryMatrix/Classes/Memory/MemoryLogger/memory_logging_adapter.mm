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

#import "memory_logging_adapter.h"
#import "MMMemoryLog.h"
#import "MMMemoryAdapter+Private.h"

static thread_id ignore_thread_id = 0;

void set_memory_logging_invalid(void) {
    [[MMMemoryAdapter shared] setCurrentRecordInvalid];
}

void log_internal(const char *file, int line, const char *funcname, char *msg) {
    if (ignore_thread_id == current_thread_id()) {
        return;
    }
    set_curr_thread_ignore_logging(true);
    MatrixInfo(@"MemStat %s", msg);
    set_curr_thread_ignore_logging(false);
}

void log_internal_without_this_thread(thread_id t_id) {
    ignore_thread_id = t_id;
}

void report_error(int error) {
    [[MMMemoryAdapter shared] reportError:error];
}

void report_reason(const char *reason) {
    NSString *reasonString = [[NSString alloc] initWithUTF8String:reason];
    [[MMMemoryAdapter shared] reportReason:reasonString];
}

void delete_current_record(void) {
    [[MMMemoryAdapter shared] stop];
}
