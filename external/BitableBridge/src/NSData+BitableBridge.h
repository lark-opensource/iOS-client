//
//  NSData+Extension.h
//  BitableBridge
//
//  Created by maxiao on 2018/9/17.
//

#import <Foundation/Foundation.h>

@interface NSData (BitableBridge)

- (NSString *)toBinaryString;

+ (NSData *)dataFromBinaryString:(NSString *)binaryString;

@end
