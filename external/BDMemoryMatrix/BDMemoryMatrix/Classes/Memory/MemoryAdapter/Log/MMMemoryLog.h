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

#ifndef MMMemoryLog_h
#define MMMemoryLog_h

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C"{
#endif
void matrix_log(NSString* type, NSString* content);
#ifdef __cplusplus
}
#endif

#define MatrixError(format, ...) MatrixErrorWithModule(format, ##__VA_ARGS__)
#define MatrixWarning(format, ...) MatrixWarningWithModule(format, ##__VA_ARGS__)
#define MatrixInfo(format, ...) MatrixInfoWithModule(format, ##__VA_ARGS__)

#ifndef __FILE_NAME__
#define __FILE_NAME__ (strrchr(__FILE__, '/') + 1)
#endif

#if __has_feature(objc_arc)
#define Matrix_release(x)
#else
#define Matrix_release(x) [x release]
#endif

#define MatrixLogInternal(TYPE, FORMAT, ...)                                                        \
    @autoreleasepool {                                                                              \
        NSString *__log_message = [NSString stringWithFormat:FORMAT, ##__VA_ARGS__, nil];           \
        matrix_log(TYPE, __log_message)                                                             \
        Matrix_release(__log_message);                                                              \
    }                                                                                               \

#define MatrixErrorWithModule(FORMAT, ...) MatrixLogInternal(@"error", FORMAT, ##__VA_ARGS__)

#define MatrixWarningWithModule(FORMAT, ...) MatrixLogInternal(@"warn", FORMAT, ##__VA_ARGS__)

#define MatrixInfoWithModule(FORMAT, ...) MatrixLogInternal(@"info", FORMAT, ##__VA_ARGS__)

#endif /* MMMemoryLog_h */
