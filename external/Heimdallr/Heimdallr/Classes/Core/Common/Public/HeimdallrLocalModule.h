//
//  HeimdallrLocalModule.h
//  Heimdallr
//
//  Created by fengyadong on 2019/1/2.
//

#import <Foundation/Foundation.h>

@protocol HeimdallrLocalModule <NSObject>

@required

+ (id<HeimdallrLocalModule> _Nullable)getInstance;

- (NSString * _Nullable)moduleName;
- (void)start;
- (void)stop;
- (BOOL)isRunning;

@end

