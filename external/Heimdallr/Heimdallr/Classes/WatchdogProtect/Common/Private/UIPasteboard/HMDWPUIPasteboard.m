//
//  HMDWPUIPasteboard.m
//  AWECloudCommand
//
//  Created by 白昆仑 on 2020/4/9.
//

#import "HMDWPUIPasteboard.h"
#import "HMDSwizzle.h"
#import "HMDWatchdogProtectManager.h"
#import "pthread_extended.h"
#import "NSString+HDMUtility.h"
#import "HMDWPUtility.h"
#import <UIKit/UIKit.h>
#import "HMDMacro.h"

#if HMD_APPSTORE_REVIEW_FIXUP

void hmd_wp_toggle_pasteboard_protection(HMDWPExceptionCallback _Nullable callback) {
    
}

#else /* HMD_APPSTORE_REVIEW_FIXUP */

//static pthread_rwlock_t lock = PTHREAD_RWLOCK_INITIALIZER;
//static HMDWPExceptionCallback exceptionCallback;
//
//static void hmd_wp_pasteboard_capture(HMDWPCapture * capture);
//
//@interface HMDWPUIPasteboard : NSObject
//@end @implementation HMDWPUIPasteboard
//
//+(id)HMDWPPasteboardNamed:(id)arg1 createIfNotFound:(BOOL)arg2 {
//    if ([NSThread isMainThread] && exceptionCallback) {
//        __block id rst = nil;
//        static atomic_flag waitFlag = ATOMIC_FLAG_INIT;
//        [HMDWPUtility protectClass:self
//                           slector:_cmd
//                      skippedDepth:1
//                          waitFlag:&waitFlag
//                      syncWaitTime:[HMDWatchdogProtectManager sharedInstance].timeoutInterval
//                  exceptionTimeout:HMDWPExceptionMaxWaitTime
//                 exceptionCallback:^(HMDWPCapture *capture) {
//            hmd_wp_pasteboard_capture(capture);
//        }
//                      protectBlock:^{
//            rst = [self HMDWPPasteboardNamed:arg1 createIfNotFound:arg2];
//        }];
//
//        return rst;
//    }
//
//    return [self HMDWPPasteboardNamed:arg1 createIfNotFound:arg2];
//}
//
//@end
//
//void hmd_wp_toggle_pasteboard_protection(HMDWPExceptionCallback _Nullable callback) {
//    int lock_rst = pthread_rwlock_wrlock(&lock);
//    exceptionCallback = callback;
//    if (lock_rst == 0) {
//        pthread_rwlock_unlock(&lock);
//    }
//
//    if (callback) {
//        static atomic_flag onceToken = ATOMIC_FLAG_INIT;
//        if(!atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) {
//            /*@"_UIConcretePasteboard"*/
//            Class class = NSClassFromString([@"X1VJQ29uY3JldGVQYXN0ZWJvYXJk" base64Decode]);
//            /*@"_pasteboardNamed:createIfNotFound:"*/
//            SEL selector = NSSelectorFromString([@"X3Bhc3RlYm9hcmROYW1lZDpjcmVhdGVJZk5vdEZvdW5kOg==" base64Decode]);
//            if (class && selector) {
//                hmd_insert_and_swizzle_class_method(class, selector, [HMDWPUIPasteboard class], @selector(HMDWPPasteboardNamed:createIfNotFound:));
//            }
//
//    //        if (@available(iOS 13.0, *)) {
//    //            /*@"UIKeyboardImpl"*/
//    //            class = NSClassFromString([@"VUlLZXlib2FyZEltcGw==" base64Decode]);
//    //            /*@"delegateSupportsImagePaste"*/
//    //            selector = NSSelectorFromString([@"ZGVsZWdhdGVTdXBwb3J0c0ltYWdlUGFzdGU=" base64Decode]);
//    //            if (class && selector) {
//    //                hmd_insert_and_swizzle_instance_method(class, selector, [HMDWPUIPasteboard class], @selector(HMDWPDelegateSupportsImagePaste));
//    //            }
//    //        }
//        }
//    }
//}
//
//static void hmd_wp_pasteboard_capture(HMDWPCapture * capture) {
//    if (!capture) {
//        return;
//    }
//
//    int lock_rst = pthread_rwlock_rdlock(&lock);
//    HMDWPExceptionCallback callback = exceptionCallback;
//    if (lock_rst == 0) {
//        pthread_rwlock_unlock(&lock);
//    }
//
//    if (callback) {
//        callback(capture);
//    }
//}
#endif /* HMD_APPSTORE_REVIEW_FIXUP */
