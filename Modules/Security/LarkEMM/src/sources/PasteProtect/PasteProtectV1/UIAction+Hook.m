//
//  UIAction+Hook.m
//  LarkEMM
//
//  Created by ByteDance on 2022/10/24.
//

#import "UIAction+Hook.h"
#import <ByteDanceKit/NSObject+BTDAdditions.h>
#import <LKLoadable/Loadable.h>
#import "LarkEMM-Swift.h"

@protocol _UIActionPasteboardProtocol <NSObject>

- (void)handleIdentifier:(nonnull NSString *)identifier;

@end

@implementation UIAction (HOOK)

+ (instancetype)custom_actionWithTitle:(NSString *)title
                                 image:(nullable UIImage *)image
                            identifier:(nullable UIActionIdentifier)identifier
                               handler:(UIActionHandler)handler
{
    return [self custom_actionWithTitle:title image:image identifier:identifier handler:^(__kindof UIAction * _Nonnull action) {
        handler(action);
        //Swift UIAction extension中实现handleIdentifier方法
        id<_UIActionPasteboardProtocol> otherAction = action;
        if ([otherAction respondsToSelector:@selector(handleIdentifier:)] && action.identifier) {
            [otherAction handleIdentifier:action.identifier];
        }
    }];
}

+ (void)replaceUIActionImp {
    [[self class] btd_swizzleClassMethod:@selector(actionWithTitle:image:identifier:handler:) with:@selector(custom_actionWithTitle:image:identifier:handler:)];
}

+ (void)startConfig {
    SEL originSEL = NSSelectorFromString(@"startReplaceConfigImp");
    SEL targetSEL = @selector(replaceUIActionImp);
    [UIAction btd_swizzleClassMethod:originSEL with:targetSEL];
}

@end

@implementation UIView (PDFView)

- (BOOL)replaceCanPerformAction:(SEL)action withSender:(id)sender {
    SCResponderActionType canPerformAction = [self customCanPerformAction:action withSender:sender];
    switch (canPerformAction) {
        case SCResponderActionTypePerformOriginActionAllow:
            return [self replaceCanPerformAction:action withSender:sender];
            break;
        case SCResponderActionTypePerformActionAllow:
            return YES;
        case SCResponderActionTypePerformActionForbid:
            return NO;
        default:
            return [self replaceCanPerformAction:action withSender:sender];
            break;
    }
    return [self replaceCanPerformAction:action withSender:sender];
}

+ (void)startConfig {
    SEL originSEL = @selector(canPerformAction:withSender:);
    SEL targetSEL = @selector(replaceCanPerformAction:withSender:);
    Class cls = NSClassFromString(@"PDFDocumentView");
    [cls btd_swizzleInstanceMethod:originSEL with:targetSEL];
}

@end

LoadableDidFinishLaunchFuncBegin(pasteBoard)
if (@available(iOS 13.0, *)) {
    [UIAction startConfig];
}
if (@available(iOS 11.0, *)) {
    [UIView startConfig];
}
LoadableDidFinishLaunchFuncEnd(pasteBoard)


