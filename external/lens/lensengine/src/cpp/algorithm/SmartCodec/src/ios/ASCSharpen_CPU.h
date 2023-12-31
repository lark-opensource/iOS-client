//
//  ASCSharpen_CPU.h
//  Pods
//
//  Created by bytedance on 2022/5/30.
//

#ifndef ASCSharpen_CPU_h
#define ASCSharpen_CPU_h
#import <Foundation/Foundation.h>
#include <string>
#include <vector>
#include <fstream>
//#include <iostream>
#include <map>
//struct Rect{
//    int top;
//    int left;
//    int w;
//    int h;
//};

class ASCSharpen_CPU{
public:

    ASCSharpen_CPU(int width,int height,int radius);
    ~ASCSharpen_CPU();
    void process_gray(unsigned char* inY, int strideIn, unsigned char* outY,int strideOut,Rect &rect,float enhanceRatio);
    void process_rgba(unsigned char* inBGRA, int strideIn, unsigned char* outBGRA,int strideOut,Rect &rect,float enhanceRatio);
private:
    float radius_;
    int width_;
    int height_;
    unsigned char* yTemp_;
    unsigned char* uTemp_;
    unsigned char* vTemp_;
    
    int16_t *pSumS1;
    int32_t*pSumS2;
    
    int16_t *pSumS1_Offset;
    int32_t *pSumS2_Offset;
    unsigned char*ppRowGY[8];
    
};


#endif /* ASCSharpen_CPU_h */
