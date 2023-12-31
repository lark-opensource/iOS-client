//
//  BDPFPSMonitor.m
//  Timor
//
//  Created by MacPu on 2018/10/18.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "BDPFPSMonitor.h"

@interface BDPFPSMonitor()

@property (nonatomic, strong) CADisplayLink *link;
@property (nonatomic, strong) NSLock* lock;
@property (nonatomic, assign) NSUInteger count;
@property (nonatomic, assign) NSTimeInterval lastTime;

@end

@implementation BDPFPSMonitor

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static BDPFPSMonitor *monitor;
    dispatch_once(&onceToken, ^{
        monitor = [[BDPFPSMonitor alloc] _init];
    });
    return monitor;
}

+ (void)start
{
    [[BDPFPSMonitor sharedInstance].lock lock];
    if ([BDPFPSMonitor sharedInstance].link) {
        [BDPFPSMonitor stop];
    }
    [BDPFPSMonitor sharedInstance].link = [CADisplayLink displayLinkWithTarget:[BDPFPSMonitor sharedInstance] selector:@selector(tick:)];
    [[BDPFPSMonitor sharedInstance].link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    [BDPFPSMonitor sharedInstance].lastTime = 0;
    [BDPFPSMonitor sharedInstance].count = 0;
    [[BDPFPSMonitor sharedInstance].lock unlock];
}

+ (void)stop
{
    [[BDPFPSMonitor sharedInstance].lock lock];
    [[BDPFPSMonitor sharedInstance].link removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    [[BDPFPSMonitor sharedInstance].link invalidate];
    [BDPFPSMonitor sharedInstance].link = nil;
    [[BDPFPSMonitor sharedInstance].lock unlock];
}

+ (CGFloat)fps
{
    [[BDPFPSMonitor sharedInstance].lock lock];
    CGFloat fps = 0;
    NSTimeInterval delta = [BDPFPSMonitor sharedInstance].link.timestamp - [BDPFPSMonitor sharedInstance].lastTime;
    if (delta >= 1) {
        fps = [BDPFPSMonitor sharedInstance].count / delta;
    }
    [BDPFPSMonitor sharedInstance].lastTime = 0;
    [BDPFPSMonitor sharedInstance].count = 0;
    [[BDPFPSMonitor sharedInstance].lock unlock];
    return fps;
}

- (instancetype)_init {
    self = [super init];
    if ( self ) {
        self.lock = [[NSLock alloc] init];
    }
    return self;
}

- (void)dealloc {
    [_link removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    [_link invalidate];
    _link = nil;
}

- (void)tick:(CADisplayLink *)link {
    if (_lastTime == 0) {
        _lastTime = link.timestamp;
        return;
    }
    _count++;
}
@end
