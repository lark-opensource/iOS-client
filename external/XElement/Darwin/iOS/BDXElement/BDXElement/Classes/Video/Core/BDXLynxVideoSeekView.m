//
//  BDXLynxVideoCtrlView.m
//  BDLynx
//
//  Created by suixudong on 2021/4/6.
//

#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxPropsProcessor.h>
#import "BDXLynxVideoSeekView.h"
#import "BDXVideoDefines.h"


@interface BDXLynxVideoSeekView ()
@property (nonatomic, assign) CGFloat customScale;
@property (nonatomic, strong) UIColor *customColor;
@property (nonatomic, assign) BOOL needRedrawThumb;
@end

@implementation BDXLynxVideoSeekView

#pragma mark - Lynx props

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-video-seek")
#else
LYNX_REGISTER_UI("x-video-seek")
#endif

- (UIColor *)parseColor:(NSString *)colorStr {
  colorStr = [colorStr stringByReplacingOccurrencesOfString:@" " withString:@""];
  if ([colorStr hasPrefix:@"rgb"]) {
    NSUInteger begin = [colorStr rangeOfString:@"("].location;
    NSUInteger end = [colorStr rangeOfString:@")"].location;
    if (begin != NSNotFound && end != NSNotFound && end > begin) {
      begin = begin + 1;
      end = end - 1;
      colorStr = [colorStr substringWithRange:NSMakeRange(begin, end - begin + 1)];
      NSArray<NSString *> *rgba = [colorStr componentsSeparatedByString:@","];
      
      if (rgba.count == 3) {
        return [UIColor colorWithRed:[rgba[0] floatValue] / 255.0f green:[rgba[1] floatValue] / 255.0f blue:[rgba[2] floatValue] / 255.0f alpha:1.0f];
      } else if (rgba.count == 4) {
        return [UIColor colorWithRed:[rgba[0] floatValue] / 255.0f green:[rgba[1] floatValue] / 255.0f blue:[rgba[2] floatValue] / 255.0f alpha:[rgba[3] floatValue]];
      } else {
        return nil;
      }
    }
    
  }
  return nil;
}

- (UIImage *)makeCircleWithSize:(CGSize)size color:(UIColor *)color {
  UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSetFillColorWithColor(context, color.CGColor);
  CGContextSetStrokeColorWithColor(context, color.CGColor);
  CGContextAddEllipseInRect(context, CGRectMake(0, 0, size.width, size.height));
  CGContextDrawPath(context, kCGPathFill);
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
}

- (UIView *)createView
{
    UISlider *seek = [UISlider new];
    seek.minimumTrackTintColor = [UIColor whiteColor];
    seek.maximumTrackTintColor = [UIColor colorWithWhite:1 alpha:0.34];
    seek.thumbTintColor = [UIColor whiteColor];
    seek.userInteractionEnabled = NO;
    [seek addTarget:self action:@selector(didSeekValueChanged:forEvent:) forControlEvents:UIControlEventValueChanged];
    _seek = seek;
    return seek;
}

LYNX_PROP_SETTER("unstable-ios-custom-color", setCustomColor, NSString *) {
  self.customColor = [self parseColor:value];
  self.needRedrawThumb = YES;
}

LYNX_PROP_SETTER("unstable-ios-custom-scale", setCustomScale, NSNumber *) {
  self.customScale = [value floatValue];
  self.needRedrawThumb = YES;
}


LYNX_PROP_SETTER("currentDuration", currentDuration, NSNumber *)
{
    NSInteger currentDuration = [value integerValue];
    if (currentDuration < 0) return;
    _seek.value = currentDuration;
}

LYNX_PROP_SETTER("current-duration", current_duration, NSNumber *)
{
    [self currentDuration:value requestReset:requestReset];
}

LYNX_PROP_SETTER("duration", duration, NSNumber *)
{
    NSInteger duration = [value integerValue];
    if (duration < 0) return;
    _seek.maximumValue = duration;
    _seek.userInteractionEnabled = YES;
}

- (void)layoutDidFinished {
  [super layoutDidFinished];
  self.needRedrawThumb = YES;
}

- (void)onNodeReady {
  [super onNodeReady];
  if (_needRedrawThumb && _customColor) {
    _needRedrawThumb = NO;
    CGFloat size = self.frame.size.height * self.customScale;
    UIImage *image = [self makeCircleWithSize:CGSizeMake(size, size) color:_customColor];
    [_seek setThumbImage:image forState:UIControlStateNormal];
    [_seek setThumbImage:image forState:UIControlStateHighlighted];
  }
  
}


- (IBAction)didSeekValueChanged:(UISlider *)sender forEvent:(UIEvent*)event
{
    UITouch *touchEvent = [[event allTouches] anyObject];
    LynxCustomEvent *customEvent = nil;
    switch (touchEvent.phase) {
        case UITouchPhaseBegan:
            customEvent = [[LynxDetailEvent alloc] initWithName:BDXVideoSeekBeginEvent targetSign:[self sign] detail:@{@"currentDuration" : @(sender.value)}];
            break;
        case UITouchPhaseMoved:
            customEvent = [[LynxDetailEvent alloc] initWithName:BDXVideoSeekChangeEvent targetSign:[self sign] detail:@{@"currentDuration" : @(sender.value)}];
            break;
        case UITouchPhaseEnded:
            customEvent = [[LynxDetailEvent alloc] initWithName:BDXVideoSeekEndEvent targetSign:[self sign] detail:@{@"currentDuration" : @(sender.value)}];
            break;
        default:
            break;
    }
    [self.context.eventEmitter sendCustomEvent:customEvent];
}

@end
