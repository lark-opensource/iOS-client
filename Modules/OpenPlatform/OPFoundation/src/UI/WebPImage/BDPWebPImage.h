//
//  BDPWebPImage.h
//  Timor
//
//  Created by 王浩宇 on 2019/1/24.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDPWebPImage : NSObject

+ (UIImage *)imageWithWebPData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
