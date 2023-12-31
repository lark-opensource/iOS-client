//
//  BDWebViewUtil.h
//  ByteWebView
//
//  Created by Lin Yong on 2019/5/5.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import <BDWebKit/BDWebKitUtil.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDWebKitUtil (BlankDetect)
+ (BOOL)checkWebContentBlank:(UIImage *)image withBlankColor:(UIColor *)color;
@end

NS_ASSUME_NONNULL_END
