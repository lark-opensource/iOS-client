//
//  NSData+Compression.h
//  Pods
//
//  Created by 延晋 张 on 16/6/6.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSData (BDUGShareCompression)

//length单位为k，如极限大小为5M,length传5000
+ (NSData *)dataWithCompressionImage:(UIImage *)image limitedLength:(NSUInteger)length;

@end
