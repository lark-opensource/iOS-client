//
//  CJPayCardOCRUtil.h
//  CJPay
//
//  Created by 尚怀军 on 2020/5/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayCardOCRUtil : NSObject

+ (void)compressWithImage:(UIImage *)image
                     size:(CGFloat)size
          completionBlock:(void(^)(NSData *imageData))completionBlock;


+ (void)compressWithImageV2:(UIImage *)image
                     size:(CGFloat)size
            completionBlock:(void(^)(NSData *imageData))completionBlock;


@end

NS_ASSUME_NONNULL_END
