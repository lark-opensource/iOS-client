//
//  BDXLynxSvgView.m
//  BDXElement
//
//  Created by pacebill on 2020/3/19.
//

#import "BDXLynxSvgView.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxPropsProcessor.h>
#import <TTSVGView/Svg.h>
#import <BDWebImage/BDWebImage.h>
#import <Lynx/LynxView.h>
#import <Lynx/LynxRootUI.h>
#import "BDXElementResourceManager.h"
#import <Lynx/LynxUI+Internal.h>

@interface BDXLynxViewSvg()
@property (nonatomic, strong) UIImage* image;
@property (nonatomic, weak) BDXLynxSvgView* ui;
@property (nonatomic, assign)BOOL recreateLayerContents;
@property (nonatomic, assign)BOOL invalidated;
@end

@implementation BDXLynxViewSvg

// Mark view dirty, and need to refresh the svg content.
- (void)invalidate {
  self.invalidated = YES;
  [self.layer setNeedsDisplay];
}

- (instancetype)initWithFrame:(CGRect)frame andUi:(BDXLynxSvgView*)ui {
  if (self = [self initWithFrame:frame]) {
    self.ui = ui;
    self.recreateLayerContents = NO;
    self.invalidated = NO;
  }
  return self;
}

- (void)displayLayer:(CALayer *)layer {
  
  // Not invalidated. Apply the current Image to contents.
  if (!self.invalidated) {
    self.layer.contents = (__bridge id)self.image.CGImage;
    return;
  }
  
  // Invalidate during recreating new layer contents, do nothing.
  // New contents will be created after finishing current rendering task.
  if (self.recreateLayerContents && self.invalidated){
    self.layer.contents = (__bridge id)self.image.CGImage;
    return;
  }
  
  // Clear invalidated flag and use a temp flag recreateLayerContents to
  // enable invalidate during rendering.
  if (!self.recreateLayerContents && self.invalidated) {
    self.recreateLayerContents = YES;
    self.invalidated = NO;
    [self.ui updateLayoutIfNeed];
  }
}


- (void)setImage:(UIImage *)image {
  // Call on UI thread.
  if (![NSThread isMainThread]) {
    return;
  }
  _image = image;
  self.recreateLayerContents = NO;
  self.layer.contents = (__bridge id)image.CGImage;
  if (self.invalidated) {
    [self.layer setNeedsDisplay];
  }
}

@end


@interface BDXLynxSvgView()
@property NSMutableDictionary *bdImageHolder;
@end

@implementation BDXLynxSvgView

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("svg")
#else
LYNX_REGISTER_UI("svg")
#endif

- (BDXLynxViewSvg*)createView {
  BDXLynxViewSvg* view = [[BDXLynxViewSvg alloc] initWithFrame:CGRectZero andUi: self];
    view.clipsToBounds = YES;
    // Disable AutoLayout
    [view setTranslatesAutoresizingMaskIntoConstraints:YES];
    
    return view;
}

LYNX_PROP_SETTER("src", setSrc, NSString*) {
    if ([value isKindOfClass:[NSString class]]) {
        if(value.length != 0 || _src != nil) {
         //src is not empty or src is changed to empty
            _src = value;
            [self.view invalidate];
        }
    }
}

LYNX_PROP_SETTER("content", setContent, NSString*) {
    if ([value isKindOfClass:[NSString class]]) {
        if(value.length != 0 || _content != nil) {
         //Content is not empty or content is changed to empty
            _content = value;
            [self.view invalidate];
        }
    }
}


// Call on main thread;
- (void)applyImage:(UIImage*)image {
  if (image == nil || ![NSThread isMainThread]) {
    return;
  }
  
  [self.view setImage:image];
  static NSString* LynxImageEventLoad = @"load";
  if([self.eventSet valueForKey:LynxImageEventLoad]){
    NSDictionary* detail = @{
      @"height" : [NSNumber numberWithFloat:image.size.height],
      @"width" : [NSNumber numberWithFloat:image.size.width]
    };
    [self.context.eventEmitter
        dispatchCustomEvent:[[LynxDetailEvent alloc] initWithName:LynxImageEventLoad
                                                       targetSign:self.sign
                                                           detail:detail]];
  }
}

- (void)updateLayoutIfNeed {
    BDXLynxViewSvg *imageView = self.view;
    // Image inside could be blurry due to the screen resolution after scaling.
    CGSize devSize = imageView.frame.size;
    devSize.width *= [UIScreen mainScreen].scale;
    devSize.height *= [UIScreen mainScreen].scale;
    if (devSize.width == 0 || devSize.height == 0) {
      // Clear the dirty mark before return.
      [self.view setImage:nil];
      return;
    }
    
    __weak typeof(self) weakSelf = self;
    UIImage* (^complete)(NSData *, CGSize) = ^UIImage*(NSData *data, CGSize devSize) {
        if (data == nil || data.length == 0) {
            return nil;
        }

        UIImage *image = TTDrawSvgImage(data, devSize, ^UIImage *(NSString *href) {
            // resource loading of inner resources, to be modified
            __strong __typeof(weakSelf) self = weakSelf;
            if (self.bdImageHolder == nil) {
                self.bdImageHolder = [NSMutableDictionary new];
            }
            UIImage *img = self.bdImageHolder[href];
            if (img == nil) {
                [self.bdImageHolder setObject:[NSNull null] forKey:href];
                if ([self.context.imageFetcher respondsToSelector:@selector(loadImageWithURL:size:contextInfo:completion:)]) {
                    [self.context.imageFetcher loadImageWithURL:[NSURL URLWithString:href]
                                                           size:devSize
                                                    contextInfo:@{ LynxImageFetcherContextKeyUI : self }
                                                     completion:^(UIImage * _Nullable image, NSError * _Nullable error, NSURL * _Nullable imageURL) {
                        __strong __typeof(weakSelf) self = weakSelf;
                        [self.bdImageHolder setValue:image forKey:href];
                        [self.view invalidate];
                    }];
                }
            }
            if ((NSNull *)img != [NSNull null]) {
                return img;
            }
            return nil;
        });
      
      return image;
    };
    
    if (_src) {
        if ([_src length] == 0) {
            [imageView setImage:nil];
            return;
        }
        NSURL *fileUrl = nil;
        NSURL *baseUrl = nil;
        if([_src hasPrefix:@"./"]) {
            if ([self.context.rootView isKindOfClass:[LynxView class]]) {
                baseUrl = [NSURL URLWithString:[(LynxView *)self.context.rootView url]];
            }
            fileUrl = [NSURL URLWithString:[_src substringFromIndex:2]];
        } else {
            fileUrl = [NSURL URLWithString:_src];
        }
        NSMutableDictionary* context = [NSMutableDictionary dictionary];
        context[BDXElementContextContainerKey] = self.context.rootUI.lynxView;
        [[BDXElementResourceManager sharedInstance] resourceDataWithURL:fileUrl
                                                                baseURL:baseUrl
                                                                context:[context copy]
                                                      completionHandler:^(NSURL *url, NSData * _Nullable svgData, NSError * _Nullable error) {
            if(!svgData){
                return;
            }
            
          __strong typeof(weakSelf) strongSelf = weakSelf;
          [strongSelf displayComplexBackgroundAsynchronouslyWithDisplay:^UIImage* (){
            return complete(svgData, devSize);
          } completion:^(UIImage * _Nonnull image) {
            [strongSelf applyImage:image];
          }];
        }];
    } else if (_content) {
        if ([_content length] == 0) {
            [imageView setImage:nil];
            return;
        }
        NSData *svgData = [[_content stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""] dataUsingEncoding:NSUTF8StringEncoding];
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf displayComplexBackgroundAsynchronouslyWithDisplay:^UIImage* (){
          return complete(svgData, devSize);
        } completion:^(UIImage * _Nonnull image) {
          [strongSelf applyImage:image];
        }];
    } else {
      [self.view setImage:nil];
    }
}

- (void)layoutDidFinished
{
  [super layoutDidFinished];
  if ([NSThread isMainThread]) {
    [self.view invalidate];
  } else {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.view invalidate];
    });
  }
}

@end
