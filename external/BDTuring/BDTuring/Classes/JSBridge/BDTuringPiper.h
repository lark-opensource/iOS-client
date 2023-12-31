//
//  BDTuringPiper.h
//  BDTuring
//
//  Created by bob on 2019/8/26.
//

#import <Foundation/Foundation.h>
#import "BDTuringPiperConstant.h"

NS_ASSUME_NONNULL_BEGIN
@class WKWebView;

@interface BDTuringPiper : NSObject

@property (nonatomic, weak, nullable, readonly)  WKWebView *webView;

- (instancetype)initWithWebView:(WKWebView *)webView;

- (BOOL)webOnPiper:(NSString *)name;

- (void)call:(NSString *)name
         msg:(BDTuringPiperMsg)msg
      params:(nullable NSDictionary *)params
  completion:(nullable BDTuringPiperCallCompletion)completion;

- (void)on:(NSString *)bridgeName callback:(BDTuringPiperOnHandler)callback;


@end

NS_ASSUME_NONNULL_END
