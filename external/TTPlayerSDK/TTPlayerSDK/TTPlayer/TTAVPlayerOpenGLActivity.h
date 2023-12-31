//
//  TTAVPlayerOpenGLActivity.h
//  bdm
//
//  Created by guikunzhi on 16/12/20.
//
//

#import <Foundation/Foundation.h>

@interface TTAVPlayerOpenGLActivity : NSObject

+ (void)start;

+ (void)stop;

+ (void)checkBroken;

+ (BOOL)isBroken;

+ (BOOL)isActive;

@end
