//
//  EMADebuggerCommand.h
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/7/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EMADebuggerCommand : NSObject

@property (nonatomic, copy, readonly) NSString *cmd;
@property (nonatomic, assign) NSUInteger mid;    // 消息id，自增
@property (nonatomic, strong) NSDictionary *payload;

- (instancetype)initWithCmd:(NSString *)cmd;

- (NSString *)jsonMessage;

@end

NS_ASSUME_NONNULL_END
