//
//  rust_http.h
//  Pods
//
//  Created by SolaWing on 2019/1/15.
//

#ifndef rust_http_h
#define rust_http_h

typedef void (*ProtobufCallbackWithTaskId2)(int64_t, bool, const uint8_t *, size_t);
typedef int32_t (*ReadBufCallbackWithTaskId)(int64_t, uint8_t *, size_t);

void fetch_async(
                 const uint8_t *input,
                 size_t length,
                 int64_t task_id,
                 ReadBufCallbackWithTaskId on_read_buf,
                 ProtobufCallbackWithTaskId2 on_response
                 );


#endif /* rust_http_h */
