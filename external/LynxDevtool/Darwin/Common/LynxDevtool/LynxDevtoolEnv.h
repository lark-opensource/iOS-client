// Copyright 2020 The Lynx Authors. All rights reserved.

#if __has_include(<Lynx/LynxConfig.h>)
#import <Lynx/LynxConfig.h>
#else
#import <LynxMacOS/LynxConfig.h>
#endif

@interface LynxDevtoolEnv : NSObject

+ (instancetype)sharedInstance;
- (void)set:(BOOL)value forKey:(NSString *)key;
- (BOOL)get:(NSString *)key withDefaultValue:(BOOL)value;

- (void)set:(NSSet *)newGroupValues forGroup:(NSString *)groupKey;
- (NSSet *)getGroup:(NSString *)groupKey;

- (void)setSwitchMask:(BOOL)value forKey:(NSString *)key;
- (BOOL)getSwitchMask:(NSString *)key;

- (BOOL)isErrorTypeIgnored:(NSInteger)errCode;

- (BOOL)getDefaultValue:(NSString *)key;

// support iOS platform now
- (void)prepareConfig:(LynxConfig *)config;

@property(nonatomic, readwrite) BOOL showDevtoolBadge
    __attribute__((deprecated("Deprecated after Lynx2.9")));
@property(nonatomic, readwrite) BOOL v8Enabled;
@property(nonatomic, readwrite) BOOL domTreeEnabled;

// swithches below only support iOS platform now
@property(nonatomic, readwrite) BOOL longPressMenuEnabled;
@property(nonatomic, readonly) BOOL previewScreenshotEnabled;
@property(nonatomic, readwrite) BOOL quickjsDebugEnabled;

@end
