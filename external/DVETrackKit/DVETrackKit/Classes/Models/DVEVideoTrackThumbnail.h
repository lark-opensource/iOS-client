//
//  DVEVideoTrackThumbnail.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/12.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVEVideoTrackThumbnail : NSObject

@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, assign, readonly) CMTime time;

- (instancetype)initWithTime:(CMTime)time identifier:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
