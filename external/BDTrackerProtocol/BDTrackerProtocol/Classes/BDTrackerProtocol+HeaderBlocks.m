//
//  BDTrackerProtocol+HeaderBlocks.m
//  BDTrackerProtocol
//
//  Created by bob on 2020/11/22.
//

#import "BDTrackerProtocol+HeaderBlocks.h"
#import "BDTrackerProtocolHelper.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation BDTrackerProtocol (HeaderBlocks)

+ (void)addHTTPHeaderBlock:(BDTrackerHeaderBlock)block forKey:(NSString *)key {
    Class cls = [BDTrackerProtocolHelper trackerCls];
    SEL sel = @selector(addHTTPHeaderBlock:forKey:);
    if (cls && sel && [cls respondsToSelector:sel]) {
        void (*action)(id, SEL, BDTrackerHeaderBlock, NSString *) = (void (*)(id, SEL, BDTrackerHeaderBlock, NSString *))objc_msgSend;
        action(cls, sel, block, key);
    }
}

+ (void)removeHTTPHeaderBlockForKey:(NSString *)key {
    Class cls = [BDTrackerProtocolHelper trackerCls];
    SEL sel = @selector(removeHTTPHeaderBlockForKey:);
    if (cls && sel && [cls respondsToSelector:sel]) {
        void (*action)(id, SEL, NSString *) = (void (*)(id, SEL, NSString *))objc_msgSend;
        action(cls, sel, key);
    }
}

@end
