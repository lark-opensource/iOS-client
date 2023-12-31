//
//  Jato.h
//  Jato
//
//  Created by yuanzhangjing on 2021/12/2.
//

#import <Foundation/Foundation.h>
#import <Jato/BDJTAudioExceptionOptions.h>

NS_ASSUME_NONNULL_BEGIN

@interface Jato : NSObject

+ (void)fixAudioException:(BDJTAudioExceptionOptions *_Nullable)options;

@end

NS_ASSUME_NONNULL_END
