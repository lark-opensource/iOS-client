//
//  TTVideoEngineVideoInfo.m
//  Pods
//
//  Created by guikunzhi on 2017/6/8.
//
//

#import "TTVideoEngineVideoInfo.h"
#import "NSObject+TTVideoEngine.h"

@implementation TTVideoEngineVideoInfo
/// Please use @property.

- (BOOL)isExpired {
    NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
    if (time > self.expire) {
        return YES;
    }
    return NO;
}

- (BOOL)hasPlayURL {
    BOOL urlFound = NO;
    int type = TTVideoEngineAllResolutions().count + 2;
    NSArray *urls = nil;
    while ((!urls || urls.count == 0) && type != TTVideoEngineResolutionTypeSD) {
        type -= 1;
        urls = [self.playInfo allURLWithDefinitionType:type transformedURL:NO];
        if (urls.count != 0) {
            urlFound = YES;
            break;
        }
    }
    return urlFound;
}

- (NSString *)codecType {
    NSString *tem = kTTVideoEngineCodecByteVC2;
    if (![[self.playInfo.videoInfo codecTypes] containsObject:tem]) {
        tem= kTTVideoEngineCodecByteVC1;
    }
    if (![[self.playInfo.videoInfo codecTypes] containsObject:tem]) {
        tem= kTTVideoEngineCodecH264;
    }
    return tem;
}

- (BOOL)isString:(NSString *)aString EqualToString:(NSString *)bString {
    if (aString == nil && bString == nil ) {
        return YES;
    }
    return [aString isEqualToString:bString];
}

- (BOOL)isEqual:(id)object {
    BOOL result = [super isEqual:object];
    TTVideoEngineVideoInfo *tem = (TTVideoEngineVideoInfo *)object;
    if (![object isKindOfClass:[self class]]) {
        result = NO;
    } else {
        BOOL vid = [self isString:self.vid EqualToString:tem.vid];
        BOOL video1main = [self isString:self.playInfo.videoInfo.videoURLInfoMap.video1.mainURLStr EqualToString:tem.playInfo.videoInfo.videoURLInfoMap.video1.mainURLStr];
        BOOL video1back1 = [self isString:self.playInfo.videoInfo.videoURLInfoMap.video1.backupURL1 EqualToString:tem.playInfo.videoInfo.videoURLInfoMap.video1.backupURL1];
        BOOL video1back2 = [self isString:self.playInfo.videoInfo.videoURLInfoMap.video1.backupURL2 EqualToString:tem.playInfo.videoInfo.videoURLInfoMap.video1.backupURL2];
        BOOL video1back3 = [self isString:self.playInfo.videoInfo.videoURLInfoMap.video1.backupURL3 EqualToString:tem.playInfo.videoInfo.videoURLInfoMap.video1.backupURL3];
        
        BOOL video2main = [self isString:self.playInfo.videoInfo.videoURLInfoMap.video2.mainURLStr EqualToString:tem.playInfo.videoInfo.videoURLInfoMap.video2.mainURLStr];
        BOOL video2back1 = [self isString:self.playInfo.videoInfo.videoURLInfoMap.video2.backupURL1 EqualToString:tem.playInfo.videoInfo.videoURLInfoMap.video2.backupURL1];
        BOOL video2back2 = [self isString:self.playInfo.videoInfo.videoURLInfoMap.video2.backupURL2 EqualToString:tem.playInfo.videoInfo.videoURLInfoMap.video2.backupURL2];
        BOOL video2back3 = [self isString:self.playInfo.videoInfo.videoURLInfoMap.video2.backupURL3 EqualToString:tem.playInfo.videoInfo.videoURLInfoMap.video2.backupURL3];
        
        BOOL video3main = [self isString:self.playInfo.videoInfo.videoURLInfoMap.video3.mainURLStr EqualToString:tem.playInfo.videoInfo.videoURLInfoMap.video3.mainURLStr];
        BOOL video3back1 = [self isString:self.playInfo.videoInfo.videoURLInfoMap.video3.backupURL1 EqualToString:tem.playInfo.videoInfo.videoURLInfoMap.video3.backupURL1];
        BOOL video3back2 = [self isString:self.playInfo.videoInfo.videoURLInfoMap.video3.backupURL2 EqualToString:tem.playInfo.videoInfo.videoURLInfoMap.video3.backupURL2];
        BOOL video3back3 = [self isString:self.playInfo.videoInfo.videoURLInfoMap.video3.backupURL3 EqualToString:tem.playInfo.videoInfo.videoURLInfoMap.video3.backupURL3];
        
        BOOL video4main = [self isString:self.playInfo.videoInfo.videoURLInfoMap.video4.mainURLStr EqualToString:tem.playInfo.videoInfo.videoURLInfoMap.video4.mainURLStr];
        BOOL video4back1 = [self isString:self.playInfo.videoInfo.videoURLInfoMap.video4.backupURL1 EqualToString:tem.playInfo.videoInfo.videoURLInfoMap.video4.backupURL1];
        BOOL video4back2 = [self isString:self.playInfo.videoInfo.videoURLInfoMap.video4.backupURL2 EqualToString:tem.playInfo.videoInfo.videoURLInfoMap.video4.backupURL2];
        BOOL video4back3 = [self isString:self.playInfo.videoInfo.videoURLInfoMap.video4.backupURL3 EqualToString:tem.playInfo.videoInfo.videoURLInfoMap.video4.backupURL3];
        
        if(vid && video1main && video1back1 && video1back2 && video1back3 && video2main && video2back1 && video2back2 && video2back3 && video3main && video3back1 && video3back2 && video3back3 && video4main && video4back1 && video4back2 && video4back3){
            result = YES;
        }
    }
    return result;
}

///MARK: - NSSecureCoding

TTVIDEOENGINE_NSSECURECODING_IMPLEMENTATON

- (NSString *)description {
    return [self ttvideoengine_debugDescription];
}

@end
