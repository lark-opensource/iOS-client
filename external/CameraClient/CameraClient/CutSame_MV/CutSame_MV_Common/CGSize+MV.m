//
//  CGSize+LV.m
//  CameraClient
//
//  Created by xulei on 2020/6/1.
//
#import "CGSize+MV.h"
#import "CGFloat+MV.h"

CGSize mv_limitMinSize(CGSize size ,CGSize minSize) {
    if (minSize.width <= 0 || minSize.height <= 0 || size.width <= 0 || size.height <= 0) {
        return CGSizeZero;
    }
    
    CGFloat sRatio = size.width / size.height;
    CGFloat tRatio = minSize.width / minSize.height;
    
    if (sRatio >= tRatio) {
        return CGSizeMake(minSize.height * sRatio, minSize.height);
    } else {
        return CGSizeMake(minSize.width, minSize.width / sRatio);
    }
}

CGSize mv_limitMaxSize(CGSize size ,CGSize maxSize) {
    if (maxSize.width <= 0 || maxSize.height <= 0 || size.width <= 0 || size.height <= 0) {
        return CGSizeZero;
    }
    
    CGFloat sRatio = size.width / size.height;
    CGFloat tRatio = maxSize.width / maxSize.height;
    
    if (sRatio >= tRatio) {
        return CGSizeMake(maxSize.width, maxSize.width / sRatio);
    } else {
        return CGSizeMake(maxSize.height * sRatio, maxSize.height);
    }
}

CGSize mv_CGSizeSafeValue(CGSize size) {
    return CGSizeMake(mv_CGFloatSafeValue(size.width), mv_CGFloatSafeValue(size.height));
}

