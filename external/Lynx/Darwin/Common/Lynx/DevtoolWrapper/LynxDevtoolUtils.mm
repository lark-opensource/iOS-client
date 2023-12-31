//  Copyright 2023 The Lynx Authors. All rights reserved.

#import "LynxDevtoolUtils.h"
#import <objc/message.h>
#import "LynxLog.h"

@implementation LynxDevtoolUtils

+ (id)getDevtoolEnvInstance {
  static id instance = nil;
  if (instance == nil) {
    Class devtoolEnv = NSClassFromString(@"LynxDevtoolEnv");
    SEL sharedInstanceSel = NSSelectorFromString(@"sharedInstance");
    if (devtoolEnv && [devtoolEnv respondsToSelector:sharedInstanceSel]) {
      id (*sharedInstance)(Class, SEL) = (id(*)(Class, SEL))objc_msgSend;
      instance = sharedInstance(devtoolEnv, sharedInstanceSel);
      NSAssert([instance respondsToSelector:NSSelectorFromString(@"set:forKey:")],
               @"No selector 'set:forKey:' in LynxDevtoolEnv!");
      NSAssert([instance respondsToSelector:NSSelectorFromString(@"set:forGroup:")],
               @"No selector 'set:forGroup:' in LynxDevtoolEnv!");
      NSAssert([instance respondsToSelector:NSSelectorFromString(@"get:withDefaultValue:")],
               @"No selector 'get:withDefaultValue:' in LynxDevtoolEnv!");
      NSAssert([instance respondsToSelector:NSSelectorFromString(@"getGroup:")],
               @"No selector 'getGroup:' in LynxDevtoolEnv!");
    } else {
      LLogError(@"Get instance of LynxDevtoolEnv failed!");
    }
  }
  return instance;
}

+ (void)setDevtoolEnv:(BOOL)value forKey:(NSString *)key {
  id instance = [self getDevtoolEnvInstance];
  if (instance) {
    void (*setEnv)(id, SEL, BOOL, NSString *) = (void (*)(id, SEL, BOOL, NSString *))objc_msgSend;
    setEnv(instance, NSSelectorFromString(@"set:forKey:"), value, key);
  } else {
    LLogError(@"setDevtoolEnv failed! key:%@ value:%d", key, value);
  }
}

+ (BOOL)getDevtoolEnv:(NSString *)key withDefaultValue:(BOOL)value {
  id instance = [self getDevtoolEnvInstance];
  if (instance) {
    BOOL (*getEnv)(id, SEL, NSString *, BOOL) = (BOOL(*)(id, SEL, NSString *, BOOL))objc_msgSend;
    return getEnv(instance, NSSelectorFromString(@"get:withDefaultValue:"), key, value);
  } else {
    LLogError(@"getDevtoolEnv failed! key:%@ default value:%d", key, value);
    return value;
  }
}

+ (void)setDevtoolEnv:(NSSet *)newGroupValues forGroup:(NSString *)groupKey {
  id instance = [self getDevtoolEnvInstance];
  if (instance) {
    void (*setEnvForGroup)(id, SEL, NSSet *, NSString *) =
        (void (*)(id, SEL, NSSet *, NSString *))objc_msgSend;
    setEnvForGroup(instance, NSSelectorFromString(@"set:forGroup:"), newGroupValues, groupKey);
  } else {
    LLogError(@"setDevtoolEnv:forGroup: failed! groupKey:%@", groupKey);
  }
}

+ (NSSet *)getDevtoolEnvWithGroupName:(NSString *)groupKey {
  id instance = [self getDevtoolEnvInstance];
  if (instance) {
    id (*getEnvForGroup)(id, SEL, NSString *) = (id(*)(id, SEL, NSString *))objc_msgSend;
    return getEnvForGroup(instance, NSSelectorFromString(@"getGroup:"), groupKey);
  } else {
    LLogError(@"getDevtoolEnvWithGroupName failed! groupKey:%@", groupKey);
    return nil;
  }
}

@end
