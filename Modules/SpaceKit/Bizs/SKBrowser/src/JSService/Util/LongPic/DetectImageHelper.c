//
//  DetectImageHelper.c
//  TestLongPic
//
//  Created by 吴珂 on 2020/9/3.
//  Copyright © 2020 bytedance. All rights reserved.


#include "DetectImageHelper.h"
#include <stdlib.h>

#ifndef max
#define max(a, b) ((a) > (b)) ? (a) : (b)
#endif

#ifndef min
#define min(a, b) ((a) > (b)) ? (b) : (a)
#endif

bool bufferIsAvaliableWithMinWidth(uint8_t *buffer, int width, int height, uint32_t detectValue, int minWidth) {
    int detectWidth = min(max(0, minWidth), width);
    uint32_t *castBuffer = (uint32_t *)buffer;
    for (int i = 0; i < height; i++) {
        bool hasAWhiteLine = true;
        uint32_t *currentPointer = castBuffer + width * i;
        for(int j = 0; j < detectWidth; j++) {
            if (currentPointer[j] != detectValue) {
                hasAWhiteLine = false;
                break;
            }
        }
        if(hasAWhiteLine) {//有一行命中
            return false;
        }
    }
    
    return true;
}


bool bufferIsAvaliable(uint8_t *buffer, int width, int height, uint32_t detectValue) {
    int minWidth = 50;
    int detectWidth = min(max(0, minWidth), width);
    uint32_t *castBuffer = (uint32_t *)buffer;
    for (int i = 0; i < height; i++) {
        bool hasAWhiteLine = true;
        uint32_t *currentPointer = castBuffer + width * i;
        for(int j = 0; j < detectWidth; j++) {
            if (currentPointer[j] != detectValue) {
                hasAWhiteLine = false;
                break;
            }
        }
        if(hasAWhiteLine) {//有一行命中
            return false;
        }
    }
    
    return true;
}

uint8_t ** createBuffer(int bytesPerRow, int rows)
{
    uint8_t *wholeBuffers = (uint8_t *)malloc(bytesPerRow * rows);
    uint8_t **buffer = (uint8_t **)malloc(sizeof(int64_t) * rows);
    for (int i = 0; i < rows; i++) {
        buffer[i] = wholeBuffers + i * bytesPerRow;
    }
    return buffer;
}

void freeBuffer(uint8_t **buffer, int rows) {
    free(buffer[0]);
    free(buffer);
}
