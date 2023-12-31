
#import "ExperimentRichTextUI.h"

#import <WebKit/WebKit.h>
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxPropsProcessor.h>

@interface ExperimentRichTextUI ()

@property (nonatomic, strong) NSString* html;
@property (nonatomic, strong) NSString* header;
@property (nonatomic, assign) CGFloat defaultFontSize;

@end

@implementation ExperimentRichTextUI

LYNX_REGISTER_UI("experiment-x-rich-text")

- (UIView *)createView {
  WKWebViewConfiguration* conf = [WKWebViewConfiguration new];
  WKWebView* webView = [[WKWebView alloc] initWithFrame:self.frame configuration:conf];
  // disable scroll and touch
  webView.scrollView.userInteractionEnabled = NO;
  if (@available(iOS 14.0, *)) {
    webView.pageZoom = [[UIScreen mainScreen] scale];
  } else {
    // Fallback on earlier versions
    // https://stackoverflow.com/questions/45998220/the-font-looks-like-smaller-in-wkwebview-than-in-uiwebview
    self.header = @"<head><meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'";
  }
  
  return webView;
}


LYNX_PROP_SETTER("html", setSpan, NSString*) {
  if (requestReset) {
    value = @"";
  }
  
  self.html = value;
  NSString* loadedHtml = self.header != nil ? [self.header stringByAppendingString:self.html] : self.html;
  [((WKWebView*) self.view) loadHTMLString:loadedHtml baseURL:nil];

  [self.view setNeedsLayout];
  [self.view setNeedsDisplay];
}

LYNX_PROP_SETTER("font-size", setFontSize, CGFloat) {
  if (requestReset) {
    value = 0;
  }
  self.defaultFontSize = value;
  
  [self.view setNeedsDisplay];
}


@end
