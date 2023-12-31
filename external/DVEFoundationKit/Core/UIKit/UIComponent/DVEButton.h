//
//  DVEButton.h
//  DVEFoundationKit
//
//  Created by bytedance on 2021/4/8.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, DVEButtonLayoutType) {
    DVEButtonLayoutTypeNone                = 0,         //默认
    DVEButtonLayoutTypeImageLeft           = 1,        //图片在左边
    DVEButtonLayoutTypeImageRight          = 2,        //图片在右边
    DVEButtonLayoutTypeImageTop            = 3,        //图片在上边
    DVEButtonLayoutTypeImageBottom         = 4         //图片在下边
};


NS_ASSUME_NONNULL_BEGIN

@interface DVEButton : UIButton

@property (assign, nonatomic) CGFloat dve_space;

@property (nonatomic, assign) DVEButtonLayoutType dve_layoutType;

- (void)dve_layoutWithType:(DVEButtonLayoutType)layoutType space:(CGFloat)space;

@end

NS_ASSUME_NONNULL_END
