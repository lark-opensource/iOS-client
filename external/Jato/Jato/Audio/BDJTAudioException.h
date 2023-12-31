//
//  BDJTAudioException.h
//  Jato
//
//  Created by yuanzhangjing on 2021/12/2.
//

#import <Foundation/Foundation.h>
#import "BDJTAudioExceptionOptions.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDJTAudioException : NSObject

+ (void)fix:(BDJTAudioExceptionOptions *)options;

@end

NS_ASSUME_NONNULL_END
