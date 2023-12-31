//
//  DetectImageHelper.h
//  TestLongPic
//
//  Created by 吴珂 on 2020/9/3.
//  Copyright © 2020 bytedance. All rights reserved.


#ifndef DetectImageHelper_h
#define DetectImageHelper_h

#include <stdio.h>
#include <stdbool.h>

bool bufferIsAvaliable(uint8_t *buffer, int width, int height, uint32_t detectValue);
bool bufferIsAvaliableWithMinWidth(uint8_t *buffer, int width, int height, uint32_t detectValue, int minWidth);
uint8_t ** createBuffer(int bytesPerRow, int rows);
void freeBuffer(uint8_t **buffer, int rows);

#endif /* DetectImageHelper_h */
