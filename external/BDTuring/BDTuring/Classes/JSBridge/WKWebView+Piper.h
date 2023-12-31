//
//  WKWebView+Piper.h
//  BDTuring
//
//  Created by bob on 2019/8/25.
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@class BDTuringPiper;

@interface WKWebView (BDTuringPiper)

@property (nonatomic, strong, nullable) BDTuringPiper *turing_piper;

- (void)turing_installPiper;
- (void)onNetworkPiperName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
