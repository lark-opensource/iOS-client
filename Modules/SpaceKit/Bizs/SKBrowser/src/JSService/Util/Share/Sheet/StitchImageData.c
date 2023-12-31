//
//  StitchImageData.c
//  TestCombineImageDatas
//
//  Created by 吴珂 on 2020/11/2.
//  

#include <stdio.h>
#include <stdlib.h>
#include "StitchImageData.h"
#include <string.h>

void stitchImage(uint8_t *destination, uint8_t *source, int sourceWidth, int sourceHeight, int colOffset, int desWidth) {
    int writeOffset = 0;
    uint8_t *writePtr = 0;
    uint8_t *sourcePtr = 0;
    for(int i = 0; i < sourceHeight; i++) {
        writeOffset = i * desWidth + colOffset;
        writePtr = writeOffset + destination;
        sourcePtr = source + i * sourceWidth;
        memcpy(writePtr, sourcePtr, sourceWidth);
    }
}
