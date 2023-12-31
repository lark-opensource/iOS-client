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

#ifndef allocation_event_h
#define allocation_event_h

#include <mach/mach.h>

/*
 alloca_type is 32 bit ,but we only need a little bits in matrix.
 allocation_event must be 16 bytes aligned,we should not add more bytes.
 vc_name_index is only 1 byte,0xff is enough for vc count.
 */
#define alloca_type_mask (0xFF00FFFF)
#define vc_name_index_mask (0xFF << 16)

struct allocation_event {
    uint32_t stack_identifier;
    uint32_t size;
    uint32_t object_type; // object type, such as NSObject, NSData, CFString, etc...
    uint32_t alloca_type; // allocation type, such as memory_logging_type_alloc or memory_logging_type_vm_allocate
    uint64_t time_stamp;

    allocation_event(uint32_t _at = 0, uint32_t _ot = 0, uint32_t _si = 0, uint32_t _sz = 0, uint32_t _tz = 0) {
        alloca_type = _at;
        object_type = _ot;
        stack_identifier = _si;
        size = _sz;
        time_stamp = _tz;
    }
};

#endif /* allocation_event_h */
