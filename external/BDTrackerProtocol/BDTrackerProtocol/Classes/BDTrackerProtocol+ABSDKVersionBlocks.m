//
//  BDTrackerProtocol+ABSDKVersionBlocks.m
//  BDTrackerProtocol
//
//  Created by bob on 2020/3/12.
//

#import "BDTrackerProtocol+ABSDKVersionBlocks.h"
#import "BDTrackerProtocolHelper.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation BDTrackerProtocol (ABSDKVersionBlocks)

+ (void)addABSDKVersionBlock:(ProtocolABSDKVersionBlock)block forKey:(NSString *)key {
    Class cls = [BDTrackerProtocolHelper trackerCls];
    SEL sel = @selector(addABSDKVersionBlock:forKey:);
    if (cls && sel && [cls respondsToSelector:sel]) {
        void (*action)(id, SEL, ProtocolABSDKVersionBlock, NSString *) = (void (*)(id, SEL, ProtocolABSDKVersionBlock, NSString *))objc_msgSend;
        action(cls, sel, block, key);
    }
}

+ (void)removeABSDKVersionBlockForKey:(NSString *)key {
    Class cls = [BDTrackerProtocolHelper trackerCls];
    SEL sel = @selector(removeABSDKVersionBlockForKey:);
    if (cls && sel && [cls respondsToSelector:sel]) {
        void (*action)(id, SEL, NSString *) = (void (*)(id, SEL, NSString *))objc_msgSend;
        action(cls, sel, key);
    }
}

@end
