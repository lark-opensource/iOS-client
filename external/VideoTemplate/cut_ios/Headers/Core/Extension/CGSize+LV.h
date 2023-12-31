//
//  CGSize+LV.h
//  LVTemplate
//
//  Created by iRo on 2019/9/3.
//

#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

CGSize lv_limitMinSize(CGSize size ,CGSize minSize);

CGSize lv_limitMaxSize(CGSize size ,CGSize maxSize);

CGSize lv_CGSizeSafeValue(CGSize size);

NS_ASSUME_NONNULL_END
