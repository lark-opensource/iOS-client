//
//  BytedCertWebView+Private.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/8/22.
//

#import "BDCTWebView.h"
#import "BDCTCorePiperHandler.h"

NS_ASSUME_NONNULL_BEGIN


@interface BDCTWebView (Private)

@property (nonatomic, strong, readonly) BDCTCorePiperHandler *corePiperHandler;

@end

NS_ASSUME_NONNULL_END
