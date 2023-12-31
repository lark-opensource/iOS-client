//
//  BDXLynxInlineImageShadowNode.m
//  BDXElement
//
//  Created by li keliang on 2020/6/8.
//

#import "BDXLynxInlineImageShadowNode.h"
#import "BDXElementResourceManager.h"
#import "BDXLynxInlineEventTarget.h"
#import <YYText/NSAttributedString+YYText.h>
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/LynxRootUI.h>

@interface BDXLynxInlineImageShadowNode ()

@property (nonatomic, assign) BOOL isLoadingResource;

@end

@implementation BDXLynxInlineImageShadowNode

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_SHADOW_NODE("x-inline-image")
#else
LYNX_REGISTER_SHADOW_NODE("x-inline-image")
#endif

- (BOOL)isVirtual
{
    return YES;
}

LYNX_PROP_SETTER("src", src, NSString *)
{
    if ([value isKindOfClass:NSString.class]) {
        _src = [NSURL URLWithString:value];
        self.dirty = YES;
        // clear previous attachment and attribute string
        [self.textStyle.attributeTexts removeAllObjects];
        [self setNeedsLayout];
    }
}

- (NSAttributedString *)inlineAttributeString
{
    if (!self.src) {
        return nil;
    }

    if (!self.isLoadingResource && self.textStyle.attributeTexts.count == 0) {
        self.isLoadingResource = YES;
        __weak BDXLynxInlineImageShadowNode* weakSelf = self;

        //On AsyncThread Mode, We need to get the snapshot of computedValues here and consume it on the UI thread.
        CGFloat localWidth = self.style.computedWidth;
        CGFloat localHeight = self.style.computedHeight;
        CGFloat localMarginLeft = self.style.computedMarginLeft;
        CGFloat localMarginRight = self.style.computedMarginRight;
        
        NSMutableDictionary* context = [NSMutableDictionary dictionary];
        context[BDXElementContextContainerKey] = self.uiOwner.rootUI.lynxView;
        __weak NSRunLoop* currentRunLoop = [NSRunLoop currentRunLoop];
        [[BDXElementResourceManager sharedInstance] resourceDataWithURL:self.src baseURL:nil context:[context copy] completionHandler:^(NSURL *url, NSData * _Nullable data, NSError * _Nullable error) {
            BDXLynxInlineImageShadowNode* strongSelf = weakSelf;
            if (!strongSelf || strongSelf.isDestroy) {
                return;
            }
            
            if (data) {
                UIImage *image = [UIImage imageWithData:data];
                CGFloat width = localWidth;
                CGFloat height = localHeight;
                
                if (width > 0) {
                    if (height == 0) {
                        height = width;
                    }
                    
                    NSMutableAttributedString *text = [NSMutableAttributedString yy_attachmentStringWithContent:image contentMode:UIViewContentModeScaleToFill attachmentSize:CGSizeMake(width, height) alignToFont:weakSelf.textStyle.font alignment:YYTextVerticalAlignmentCenter];
                    [strongSelf setMarginOnText:text margin:localMarginLeft index:0];
                    [strongSelf setMarginOnText:text margin:localMarginRight index:text.length];
                    [strongSelf.textStyle appendAttributeText:text];
                    
                } else {
                    
                    NSAttributedString *text = [NSAttributedString yy_attachmentStringWithEmojiImage:[UIImage imageWithData:data] fontSize:weakSelf.textStyle.font.pointSize];
                    [strongSelf.textStyle appendAttributeText:text];
                }

                if ([strongSelf.eventSet valueForKey:@"load"]) {
                  NSDictionary* detail = @{
                    @"height" : [NSNumber numberWithFloat:image.size.height],
                    @"width" : [NSNumber numberWithFloat:image.size.width]
                  };

                  [strongSelf.uiOwner.uiContext.eventEmitter
                      dispatchCustomEvent:[[LynxDetailEvent alloc] initWithName:@"load"
                                                                   targetSign:strongSelf.sign
                                                                       detail:detail]];
                }
                
                strongSelf.dirty = YES;
                if (currentRunLoop != [NSRunLoop currentRunLoop]) {
                    if (@available(iOS 10.0, *)) {
                        [currentRunLoop performBlock:^{
                            __strong __typeof(weakSelf) strong_self = weakSelf;
                            [strong_self setNeedsLayout];
                        }];
                    } else {
                        [strongSelf setNeedsLayout];
                    }
                } else {
                    [strongSelf setNeedsLayout];
                }
                
            }
            
            strongSelf.isLoadingResource = NO;
        }];
    }
    
    NSMutableAttributedString* str = self.textStyle.ultimateAttributedString;
    [str addAttributes:self.textStyle.defaultAttriutes range:NSMakeRange(0, str.length)];
    [str addAttribute:[NSString stringWithFormat:@"%@%@", BDXLynxInlineElementSignKey, @(self.sign)]
                value:[[BDXLynxTextInfo alloc] initWithShadowNode:self]
                range:NSMakeRange(0, str.length)];
    return str;
}

- (void) setMarginOnText:(NSMutableAttributedString*) text margin:(CGFloat) margin index:(NSUInteger) index {
  if (margin <= 0) {
    return;
  }
  NSMutableAttributedString* attr = [NSAttributedString yy_attachmentStringWithContent:[[UIView alloc] initWithFrame:CGRectMake(0, 0, margin, 1.0)] contentMode: UIViewContentModeScaleToFill attachmentSize:CGSizeMake(margin, 1.0) alignToFont:self.textStyle.font alignment:YYTextVerticalAlignmentCenter];
  [text insertAttributedString:attr atIndex:index];
}

- (BOOL)needsEventSet {
  return YES;
}

@end
