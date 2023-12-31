//
//  CGFloat+LV.m
//  CameraClient
//
//  Created by xulei on 2020/6/1.
//

#import "CGFloat+MV.h"

CGFloat mv_CGFloatInRange(CGFloat value, CGFloat minValue, CGFloat maxValue) {
    value = MIN(maxValue, value);
    value = MAX(minValue, value);
    return value;
}

CGFloat mv_CGFloatSafeValue(CGFloat value) {
    if (isnan(value) || isinf(value)) {
        return 0.0;
    }
    return value;
}

