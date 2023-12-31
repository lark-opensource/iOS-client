//
//  BDFixWKWebViewCrash.h
//  ByteWebView
//
//  Created by 杨牧白 on 2019/8/26.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKWebView (BDFixWKCrash)
- (void)bd_fixReLaunchWebContentProcess;
+ (void)tryFixAddupdateCrash; //fix _addUpdateVisibleContentRectPreCommitHandler crash below iOS 14
@end

@interface NSObject (BDFixWKCrash)
+ (void)tryFixOfflineCrash;
+ (void)tryFixWKReloadFrameErrorRecoveryAttempter;
@end

@interface NSObject (BDFixWKBackGroundHang)
+ (void)tryFixBackGroundHang;
@end

@interface WKWebView (BDFixWKGetURLCrash)
+ (void)tryFixGetURLCrash;
@end

@interface WKWebView (BDFixWKReleaseEarlyCrash)
+ (void)tryFixWKReleaseEarlyCrash;
- (void)setBDCF_removeTs:(long)ts;
- (long)BDCF_removeTs;
@end

@interface BDFixWKWebViewCrash : NSObject
+ (void)tryFixBlobCrash;
@end

@interface WKScriptMessage (BDFixWKCrash)
+ (void)tryFixWKScriptMessageCrash;
@end

NS_ASSUME_NONNULL_END
