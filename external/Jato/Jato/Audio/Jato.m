//
//  Jato.m
//  Jato
//
//  Created by yuanzhangjing on 2021/12/2.
//

#import "Jato.h"
#import "BDJTAudioException.h"

@implementation Jato

+ (void)fixAudioException:(BDJTAudioExceptionOptions *)options {
    [BDJTAudioException fix:options];
}

@end
