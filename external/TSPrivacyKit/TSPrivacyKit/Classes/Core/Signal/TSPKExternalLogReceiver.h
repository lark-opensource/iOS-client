//
//  TSPKExternalLogReceiver.h
//  Musically
//
//  Created by ByteDance on 2022/12/19.
//

#import <Foundation/Foundation.h>

@interface TSPKExternalLogReceiver : NSObject

+ (BOOL)enableReceiveExternalLog;

+ (void)externalLogWithTag:(nullable NSString *)tag content:(nullable NSString *)content;

@end

