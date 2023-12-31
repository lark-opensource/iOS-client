//
//  BDCTAudioPlayer.h
//  byted_cert
//
//  Created by liuminghui.2022 on 2023/2/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BDCTAudioPlayerState) {
    BDCTAudioPlayerStateStop = 0,
    BDCTAudioPlayerStatePlaying = 1,
};


@interface BDCTAudioPlayer : NSObject

- (void)playAudioWithFilePath:(NSString *)path;


@end

NS_ASSUME_NONNULL_END
