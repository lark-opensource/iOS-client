#if ALPHA
#import <objc/runtime.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DebugOverlay: NSObject

@end

@implementation DebugOverlay

+ (NSString *)beautify:(NSString *)string withKey:(NSString *)key
{
    // Create data object from the string
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];

    // Get pointer to data to obfuscate
    char *dataPtr = (char *) [data bytes];

    // Get pointer to key data
    char *keyData = (char *) [[key dataUsingEncoding:NSUTF8StringEncoding] bytes];

    // Points to each char in sequence in the key
    char *keyPtr = keyData;
    int keyIndex = 0;

    // For each character in data, xor with current value in key
    for (int x = 0; x < [data length]; x++)
    {
        // Replace current character in data with
        // current character xor'd with current key value.
        // Bump each pointer to the next character
        *dataPtr = *dataPtr ^ *keyPtr;
        dataPtr++;
        keyPtr++;

        // If at end of key data, reset count and
        // set key pointer back to start of key value
        if (++keyIndex == [key length]) {
            keyIndex = 0;
            keyPtr = keyData;
        }
    }

    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (void)addToMLksFndWhiteList {
    NSString *salt = @"123";
    SEL selector = NSSelectorFromString([self beautify:@"PVWr^RBA}P_VBf\\fZZEW_XAG\v" withKey:salt]);
    if ([NSObject respondsToSelector:selector]) {
        NSArray *whiteList = @[
            [self beautify:@"d{wTPFVUZ_Uz_T\\C_RE[\\_zZT@RCQ[HdZTEp^\\GC]_]WA" withKey:salt],
            [self beautify:@"d{wTPFVUZ_Uz_T\\C_RE[\\_dpy[VCSARZJg[VFq\\_FA^^_T@" withKey:salt],
            [self beautify:@"d{wTPFVUZ_Ui^]^g[VFq\\_FA^^_T@" withKey:salt],
            [self beautify:@"d{wTPFVUZ_UzGSAg[VFq\\_FA^^_T@" withKey:salt],
            [self beautify:@"d{wTPFVUZ_U`AWPg[VFq\\_FA^^_T@" withKey:salt],
            [self beautify:@"ngza@\\E]GHBZ_U~T\\Fg[VFq\\_FA^^_T@" withKey:salt],
            [self beautify:@"d{wTPFVUZ_Uz_T\\C_RE[\\_{]BBVRF\\CvVESZ]dZTEp^\\GC]_]WA" withKey:salt]
        ];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [NSObject performSelector:selector withObject:whiteList];
#pragma clang diagnostic pop
    }
}

// via https://gist.github.com/IMcD23/1fda47126429df43cc989d02c1c5e4a0
+ (void)toggleOverlay {
    NSString *salt = @"123";

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

#define __UIDebuggingInformationOverlay__ @"d{wTPFVUZ_Uz_T\\C_RE[\\_}ET@_PK"
#define __UIDebuggingInformationOverlayInvokeGestureHandler__ @"d{wTPFVUZ_Uz_T\\C_RE[\\_}ET@_PKz_D\\ZWtTAGD@VyS]U^VC"
#define __overlay__ @"^DVC^RH"
#define __mainHandler__ @"\\SZ_zR_V_T@"
#define ___handleActivationGesture__ @"nZR_V_TsPE[EPFZ^\\tTAGD@V\v"
#define __toggleVisibility__ @"E]TV^Vg[@XPZ][GH"

    id debugInfoClass = NSClassFromString([self beautify:__UIDebuggingInformationOverlay__ withKey:salt]);

    // In iOS 11, Apple added additional checks to disable this overlay unless the
    // device is an internal device. To get around this, we swizzle out the
    // -[UIDebuggingInformationOverlay init] method (which returns nil now if
    // the device is non-internal), and we call:
    // [[UIDebuggingInformationOverlayInvokeGestureHandler mainHandler] _handleActivationGesture:(UIGestureRecognizer *)]
    // to show the window, since that now adds the debugging view controllers, and calls
    // [overlay toggleVisibility] for us.
    if (@available(iOS 11.0, *)) {
        id handlerClass = NSClassFromString([self beautify:__UIDebuggingInformationOverlayInvokeGestureHandler__ withKey:salt]);

        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            // Swizzle init of debugInfo class to just call [UIWindow init]
            Method initMethod = class_getInstanceMethod(debugInfoClass, @selector(init));
            IMP newInit = method_getImplementation(class_getInstanceMethod([UIWindow class], @selector(init)));
            method_setImplementation(initMethod, newInit);
            [self addToMLksFndWhiteList];
        });

        id debugOverlayInstance = [debugInfoClass performSelector:NSSelectorFromString([self beautify:__overlay__ withKey:salt])];
        [debugOverlayInstance setFrame:[[UIScreen mainScreen] bounds]];

        UIGestureRecognizer *dummyGestureRecognizer = [[UIGestureRecognizer alloc] init];
        dummyGestureRecognizer.state = UIGestureRecognizerStateEnded;

        id handler = [handlerClass performSelector:NSSelectorFromString([self beautify:__mainHandler__ withKey:salt])];
        [handler performSelector:NSSelectorFromString([self beautify:___handleActivationGesture__ withKey:salt]) withObject:dummyGestureRecognizer];
    } else {
        id debugOverlayInstance = [debugInfoClass performSelector:NSSelectorFromString([self beautify:__overlay__ withKey:salt])];
        [debugOverlayInstance performSelector:NSSelectorFromString([self beautify:__toggleVisibility__ withKey:salt])];
    }
#pragma clang diagnostic pop
}

@end
#endif
