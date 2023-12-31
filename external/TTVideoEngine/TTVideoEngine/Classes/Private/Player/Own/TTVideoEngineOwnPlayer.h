//
//  TTOwnAVPlayer.h
//  Pods
//
//  Created by guikunzhi on 16/12/6.
//
//

#import <Foundation/Foundation.h>
#import "TTVideoEnginePlayerDefinePrivate.h"
#import "TTVideoEnginePlayer.h"

@interface TTVideoEngineOwnPlayer : NSObject <TTVideoEnginePlayer>

- (instancetype)initWithType:(TTVideoEnginePlayerType)type async:(BOOL)async;

- (void)setValueString:(NSString *)string forKey:(int)key;

- (void)setCacheFile:(NSString *)path mode:(int)mode;

- (int64_t)getInt64ValueForKey:(int)key;

- (int)getIntValueForKey:(int)key;

- (NSString* )getIpAddress;

- (BOOL)getMedialoaderProtocolRegistered;

- (BOOL)getHLSProxyProtocolRegistered;

@end
