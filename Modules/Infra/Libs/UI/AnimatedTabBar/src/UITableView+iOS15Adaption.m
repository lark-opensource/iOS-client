//
//  UITableView+iOS15Adaption.m
//  TableView
//
//  Created by Hayden Wang on 2021/9/19.
//

#import <objc/runtime.h>
#import "UITableView+iOS15Adaption.h"
//#import "TableView-Bridging-Header.h"

NS_EXTENSION_UNAVAILABLE_IOS("Not available in app extensions.")

UIKIT_EXTERN API_AVAILABLE(ios(15))

@implementation UITableView (iOS15Adaption)

+ (void)methodSwizzling:(Class)cls origin:(SEL)original replacement:(SEL)replacement {
    Method originalMethod = class_getInstanceMethod(cls, original);
    IMP originalImplementation = method_getImplementation(originalMethod);
    const char *originalArgTypes = method_getTypeEncoding(originalMethod);

    Method replacementMethod = class_getInstanceMethod(cls, replacement);
    IMP replacementImplementation = method_getImplementation(replacementMethod);
    const char *replacementArgTypes = method_getTypeEncoding(replacementMethod);

    if (class_addMethod(cls, original, replacementImplementation, replacementArgTypes)) {
        class_replaceMethod(cls, replacement, originalImplementation, originalArgTypes);
    } else {
        method_exchangeImplementations(originalMethod, replacementMethod);
    }
}

static Class SwizzlingViewClass() {
    return UITableView.class;
}

+ (void)initialize {
    if (self == [UITableView class]) {
        static dispatch_once_t swizzleOnceToken;
        dispatch_once(&swizzleOnceToken, ^{
            [self swizzleInitializersIfNeeded];
        });
    }
}

+ (void)swizzleInitializersIfNeeded {
    if (@available(iOS 15, *)) {
        [UITableView methodSwizzling:SwizzlingViewClass()
                              origin:@selector(initWithFrame:style:)
                         replacement:@selector(swizzle_initWithFrame:style:)];

    }
}

- (instancetype)swizzle_initWithFrame:(CGRect)frame
                                style:(UITableViewStyle)style  API_AVAILABLE(ios(15.0)) {
    UITableView *table = [self swizzle_initWithFrame:frame style:style];
    // Only Xcode 13+ can compile this
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 150000
    if (@available(iOS 15, *)) {
        if (style == UITableViewStylePlain) {
            [table setSectionHeaderTopPadding:0];
        }
    }
#endif
    return table;
}

@end
