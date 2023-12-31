//
//  CGSize+LV.h
//  CameraClient
//
//  Created by xulei on 2020/6/1.
//

#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

CGSize mv_limitMinSize(CGSize size ,CGSize minSize);

CGSize mv_limitMaxSize(CGSize size ,CGSize maxSize);

CGSize mv_CGSizeSafeValue(CGSize size);

NS_ASSUME_NONNULL_END
