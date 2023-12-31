#ifndef TTSVGVIEW_SVG_h
#define TTSVGVIEW_SVG_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef UIImage * _Nullable (^SvgImageCallback)(NSString * _Nonnull href);

UIImage * _Nullable TTDrawSvgImage(NSData * _Nonnull data, CGSize size, SvgImageCallback _Nullable imageCb);


typedef enum TTSvgContentMode : NSUInteger {
    TTSvgContentModelScaleToFill = 0,
    TTSvgContentModelScaleToAspectFit,
    TTSvgContentModelScaleToAspectFill,
} TTSvgContentMode;

typedef struct TTDrawSvgOptions {
    TTSvgContentMode contentMode;
    SvgImageCallback _Nullable imageCb;
    UIColor * _Nullable color;
} TTDrawSvgOptions;

UIImage * _Nullable TTDrawSvgImageWithOptions(NSData * _Nonnull data, CGSize size, TTDrawSvgOptions * _Nullable options);


#if defined(__cplusplus)
extern "C" {
#endif

    void svg_set_enable_console_log(bool enable);

#if defined(__cplusplus)
}
#endif

#endif /* TTSVGVIEW_SVG_h */
