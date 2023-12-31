//
//  HMDTTLeaksFinderConfig.h
//  Heimdallr_Example
//
//  Created by bytedance on 2020/5/29.
//  Copyright © 2020 ghlsb@hotmail.com. All rights reserved.
//

#import <Heimdallr/HMDModuleConfig.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kTTHMDModuleLeaksFinderTracker;

@interface TTHMDLeaksFinderConfig : HMDModuleConfig

@property (nonatomic, assign) BOOL enableAssociatedObjectHook;
@property (nonatomic, assign) BOOL enableNoVcAndViewHook;
@property (nonatomic, assign) BOOL doubleSend; // NO:只上报slardar YES: 上报至slardar和lark
@property (nonatomic, assign) BOOL enableAlogOpen;
@property (nonatomic, assign) NSInteger enableDetectSystemClass;
@property (nonatomic, assign) NSInteger viewStackType;
@property (nonatomic, copy) NSArray <NSString *> *classWhitelist;
@property (nonatomic, copy) NSString *filters; // jsonString NSDictionary<NSString *, NSArray<NSString *> *>

@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSArray<NSString *> *> *filtersDic;

@end

NS_ASSUME_NONNULL_END
