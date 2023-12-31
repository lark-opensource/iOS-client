//
//  FeatureSI.h

#import <UIKit/UIKit.h>
#import "VFMetalContext.h"

@interface PreTransform : NSObject
/**
 deal with resize, color space and range
 */
-(instancetype)initWithParam:(int)width height:(int)height  need_rerange:(int)need_tv_to_full context:(VFMetalContext*) sharedcontext;
-(id<MTLTexture>)Transform: (id<MTLTexture>) buffer need_color_trans:(int) need_rgb_to_yuv;
-(void)Release;
@end


