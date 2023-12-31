//
//  BDXBridgeEvent.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/6/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeEvent : NSObject

@property (nonatomic, copy, readonly) NSString *eventName;
@property (nonatomic, copy, readonly) NSDictionary *params;

+ (instancetype)eventWithEventName:(NSString *)eventName params:(nullable NSDictionary *)params;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
