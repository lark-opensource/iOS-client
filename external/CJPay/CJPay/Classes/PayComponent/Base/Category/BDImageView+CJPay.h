//
//  BDImageView+CJPay.h
//  Pods
//
//  Created by 易培淮 on 2021/5/21.
//

#import <Foundation/Foundation.h>
#import <BDWebImage/BDImageView.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDImageView(CJPay)

- (void)cj_loadGifAndOnceLoop:(NSString *)gifName
                     duration:(NSTimeInterval)duration;

- (void)cj_loadGifAndOnceLoopWithURL:(NSString *)url
                            duration:(NSTimeInterval)duration;

- (void)cj_loadGifAndInfinityLoop:(NSString *)gifName
                         duration:(NSTimeInterval)duration;

- (void)cj_loadGifAndInfinityLoopWithURL:(NSString *)url
                                duration:(NSTimeInterval)duration;

@end

NS_ASSUME_NONNULL_END
