//
//  TextModernLoupeView.m
//  LKRichView
//
//  Created by qihongye on 2022/1/11.
//
/*
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/message.h>
#import "TextModernLoupe.h"

// CAColorMatrix
struct ColorMatrix {
    float mm[20];
};
typedef struct ColorMatrix ColorMatrix;

const char alphabet[] = {
    // 0  1     2     3     4     5     6     7     8     9     10    11    12    13    14
    0x3a, 0x41, 0x42, 0x43, 0x44, 0x46, 0x4d, 0x4e, 0x52, 0x53, 0x57, 0x61, 0x62, 0x63, 0x64,
    //15  16    17    18    19    20    21    22    23    24    25    26    27    28    29
    0x65, 0x67, 0x68, 0x69, 0x6c, 0x6d, 0x6e, 0x6f, 0x70, 0x72, 0x73, 0x74, 0x75, 0x76, 0x78
};

@implementation TextModernLoupe

+ (NSString* _Nonnull)getName: (const size_t*) bytes length: (size_t) length {
    char *str = malloc(length * sizeof(char));
    for (size_t i = 0; i < length; i++) {
        str[i] = alphabet[bytes[i]];
    }
    NSData *data = [NSData dataWithBytes:str length:length];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (id)colorFilter {
    ColorMatrix colorMatrix = {
        0, 0, 0, 0,
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, -0.23, 14.72
    };
    // @"valueWithCAColorMatrix:"
    const size_t valueWithCAColorMatrixName[] = {
        28, 11, 19, 27, 15, 10, 18, 26, 17, 3, 1, 3, 22, 19, 22, 24, 6, 11, 26, 24, 18, 29, 0
    };

    SEL valueWithCAColorMatrix = NSSelectorFromString([self getName: valueWithCAColorMatrixName length: 23]);
    NSValue* (*objc_msgSendTyped)(id self, SEL _cmd, ColorMatrix m) = (void*)objc_msgSend;
    NSValue *value = objc_msgSendTyped([NSValue class], valueWithCAColorMatrix, colorMatrix);
    // extern NSString * const kCAFilterColorMatrix API_AVAILABLE(ios(15.0))
    // @"colorMatrix"
    const size_t filterName[] = {13, 22, 19, 22, 24, 6, 11, 26, 24, 18, 29};
    // @"CAFilter"
    const size_t cafilterName[] = {3, 1, 5, 18, 19, 26, 15, 24};
    id CAFilter = NSClassFromString([self getName:cafilterName length:8]);
    id colorMatrixFilter = [CAFilter filterWithName: [self getName:filterName length:11]];
    // extern NSString * const kCAFilterInputColorMatrix API_AVAILABLE(ios(15.0));
    // @"inputColorMatrix"
    const size_t key[] = {18, 21, 23, 27, 26, 3, 22, 19, 22, 24, 6, 11, 26, 24, 18, 29};
    [colorMatrixFilter setValue:value forKey: [self getName:key length:16]];
    return colorMatrixFilter;
}

+ (id)gaussianFilter {
    // extern NSString * const kCAFilterGaussianBlur API_AVAILABLE(ios(15.0))
    // @"gaussianBlur"
    const size_t filterName[] = {16, 11, 27, 25, 25, 18, 11, 21, 2, 19, 27, 24};
    // @"CAFilter"
    const size_t cafilterName[] = {3, 1, 5, 18, 19, 26, 15, 24};
    id CAFilter = NSClassFromString([self getName:cafilterName length:8]);
    id gaussianBlurFilter = [CAFilter filterWithName: [self getName:filterName length:12]];
    // extern NSString * const kCAFilterInputRadius API_AVAILABLE(ios(15.0))
    // @"inputRadius"
    const size_t key[] = {18, 21, 23, 27, 26, 8, 11, 14, 18, 27, 25};
    // @"NSConstantDoubleNumber"
    const size_t nsConstantDoubleNumberName[] = {
        7, 9, 3, 22, 21, 25, 26, 11, 21, 26, 4,
        22, 27, 12, 19, 15, 7, 27, 20, 12, 15, 24
    };
    id NSConstantDoubleNumber = NSClassFromString([self getName:nsConstantDoubleNumberName length:22]);
    [gaussianBlurFilter setValue: [NSConstantDoubleNumber numberWithInt: 6] forKey: [self getName:key length: 11]];
    return gaussianBlurFilter;
}

@end
*/
