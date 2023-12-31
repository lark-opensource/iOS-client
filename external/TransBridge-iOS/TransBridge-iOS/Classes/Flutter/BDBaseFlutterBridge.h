//
//  BaseFlutterBridge.h
//  FlutterIntergation
//
//  Created by bytedance on 2020/4/2.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BDFlutterProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDBaseFlutterBridge : NSObject

@property (weak , nonatomic) id<FLTBMethodChannelCreator> flutterAdapter;

+ (NSString *)globalChannelName;

+ (void)setGlobalChannelName:(NSString *)globalChannelName;

- (instancetype)initWithFlutterAdapter:(id<FLTBMethodChannelCreator>)flutterAdapter;

- (id<FLTBMethodChannel>)createMethodChannelForMessager:(NSObject *)messenger;

- (id<FLTBMethodChannel>)createMethodChannel:(NSString *)name forView:(NSObject *)messenger;

@end

NS_ASSUME_NONNULL_END
