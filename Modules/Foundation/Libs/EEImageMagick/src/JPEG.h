//
//  JPEG.h
//  EEImageMagick
//
//  Created by qihongye on 2019/12/5.
//

#ifndef JPEG_h
#define JPEG_h

#ifdef __cplusplus
extern "C" {
#endif

#include <stdio.h>

#define BOOL                uint8_t

extern BOOL is_jpeg(const unsigned char* data, const size_t length);

extern size_t jpeg_get_quality(const unsigned char* data, const size_t length);

extern size_t jpeg_get_quality_by_path(const char* path);

#ifdef __cplusplus
}
#endif

#endif /* JPEG_h */
