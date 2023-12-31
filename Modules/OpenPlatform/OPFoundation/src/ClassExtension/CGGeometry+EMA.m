//
//  CGGeometry+EMA.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/4/10.
//

#import "CGGeometry+EMA.h"

CGRect EMARectInsetEdges(CGRect rect, UIEdgeInsets edgeInsets) {
    rect.origin.x += edgeInsets.left;
    rect.size.width -= edgeInsets.left + edgeInsets.right;

    rect.origin.y += edgeInsets.top;
    rect.size.height -= edgeInsets.top + edgeInsets.bottom;

    if (rect.size.width < 0) {
        rect.size.width = 0;
    }

    if (rect.size.height < 0) {
        rect.size.height = 0;
    }

    return rect;
}
