//
//  UIViewController+PDFHostController.m
//  LarkEMM
//
//  Created by ByteDance on 2023/10/24.
//

#import "UIViewController+PDFHostController.h"
#import <ByteDanceKit/NSObject+BTDAdditions.h>
#import <LKLoadable/Loadable.h>
#import "LarkEMM-Swift.h"

@implementation UIViewController (PDFHostController)

+ (NSDictionary *)replaceMethods {
    return @{
        @"didCopyString:": @"swizzleDidCopyString:",
        @"didCopyData:": @"swizzleDidCopyData:"
    };
}

+ (void)replacePasteProtectMethods {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self logPdfMessage:@"SCPasteboard start replace PDFHostViewController"];
        Class cls = NSClassFromString(@"PDFHostViewController");
        [[self replaceMethods] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            SEL target = NSSelectorFromString(key);
            SEL swizzled = NSSelectorFromString(obj);
            BOOL result = [cls btd_swizzleInstanceMethod:target with:swizzled];
            [self logPdfMessage: [NSString stringWithFormat:@"SCPasteboard: replace %@ with %@, result：%@", key, obj, @(result)]];
        }];
    });
}

+ (void)logPdfMessage:(NSString *)message {
    [SCPasteboardWrapper info:message file:[[NSString stringWithUTF8String:__FILE__] lastPathComponent]];
}

- (void)swizzleDidCopyString:(id)sender {
    [self swizzleDidCopyString:sender];
    [SCPasteboardWrapper updatePasteboardForPdfCopyContent];
}

- (void)swizzleDidCopyData:(id)sender {
    [self swizzleDidCopyData:sender];
    [SCPasteboardWrapper updatePasteboardForPdfCopyContent];
}

@end
