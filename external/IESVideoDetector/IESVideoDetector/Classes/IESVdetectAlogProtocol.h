//
//  IESVdetectorAlogProtocol.h
//  IESVideoDetector
//
//  Created by geekxing on 2020/6/1.
//

#import <Foundation/Foundation.h>

#define IES_VDETECT_LOG(tagString,lv,frmt, ...) [IESVdetectService.defaultService.alogService doLog:[NSString stringWithFormat:frmt, ##__VA_ARGS__] level:lv tag:tagString];

typedef NS_ENUM(NSInteger, IESVdetectLogLevel) {
    IESVdetectLogLevelError,
    IESVdetectLogLevelWarn,
    IESVdetectLogLevelInfo,
    IESVdetectLogLevelDebug,
    IESVdetectLogLevelVerbose,
};

NS_ASSUME_NONNULL_BEGIN

@protocol IESVdetectAlogProtocol <NSObject>

- (void)doLog:(NSString *)logString level:(IESVdetectLogLevel)level tag:(NSString *)tag;

@end

NS_ASSUME_NONNULL_END
