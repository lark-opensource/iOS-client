//
//  BTDPingServices.h
//  STKitDemo
//
//  Created by SunJiangting on 15-3-9.
//  Copyright (c) 2015年 SunJiangting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "BTDSimplePing.h"

typedef NS_ENUM(NSInteger, BTDPingStatus) {
    BTDPingStatusDidStart,
    BTDPingStatusDidFailToSendPacket,
    BTDPingStatusDidReceivePacket,
    BTDPingStatusDidReceiveUnexpectedPacket,
    BTDPingStatusDidTimeout,
    BTDPingStatusError,
    BTDPingStatusFinished,
};

@interface BTDPingItem : NSObject

@property(nonatomic) NSString *originalAddress;
@property(nonatomic, copy) NSString *IPAddress;

@property(nonatomic) NSUInteger dateBytesLength;
@property(nonatomic) double     timeMilliseconds;
@property(nonatomic) NSInteger  timeToLive;
@property(nonatomic) NSInteger  ICMPSequence;

@property(nonatomic) BTDPingStatus status;

+ (NSString *)statisticsWithPingItems:(NSArray *)pingItems;

@end

@interface BTDPingServices : NSObject

/// 超时时间, default 500ms
@property(nonatomic) double timeoutMilliseconds;

+ (BTDPingServices *)startPingAddress:(NSString *)address
                      callbackHandler:(void(^)(BTDPingItem *pingItem, NSArray *pingItems))handler;

+ (BTDPingServices *)startPingAddress:(NSString *)address
                    maximumPingTimes:(NSInteger)maximumPingTimes
                     callbackHandler:(void(^)(BTDPingItem *pingItem, NSArray *pingItems))handler;

+ (BTDPingServices *)startPingAddress:(NSString *)address
                    maximumPingTimes:(NSInteger)maximumPingTimes
                     callbackHandler:(void(^)(BTDPingItem *pingItem, NSArray *pingItems))handler
                       finishHandler:(void(^)(NSArray *pingItems))finishHandler;

- (void)cancel;

@end
