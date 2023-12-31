//
//  BDISocketServer.h
//  BDiOSpy
//
//  Created by byte dance on 2021/7/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDISocketServer : NSObject

+ (int)getPort;
+ (BOOL)pushMessage:(id)message;
+ (void)registerAPIHandlers:(NSArray *)apiHandlerClasses;
+ (void)start:(BOOL)needRunloop;

- (void)startServer:(BOOL)needRunloop;

@end

NS_ASSUME_NONNULL_END
