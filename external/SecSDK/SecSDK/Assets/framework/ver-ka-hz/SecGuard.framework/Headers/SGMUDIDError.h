//
// Created by bytedance on 2022/2/7.
//

#import <Foundation/Foundation.h>


@interface SGMUDIDError : NSObject

@property NSMutableArray *buffer;

+ (instancetype)shareInstance;

- (void)clear;

- (void)emit:(NSString *)msg;

- (NSString *)dump;
@end