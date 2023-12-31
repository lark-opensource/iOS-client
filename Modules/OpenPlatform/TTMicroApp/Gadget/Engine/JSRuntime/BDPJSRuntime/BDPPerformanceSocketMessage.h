//
//  BDPPerformanceSocketMessage.h
//  TTMicroApp
//
//  Created by ChenMengqi on 2022/12/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDPPerformanceSocketMessage : NSObject

///事件名： init, close, stop, sendPerformanceData
@property (nonatomic, copy) NSString *event;
@property (nonatomic, copy) NSString *code;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, strong) NSDictionary *data;

+ (instancetype)messageWithString:(NSString *)string;

- (NSString *)string;

@end

NS_ASSUME_NONNULL_END
