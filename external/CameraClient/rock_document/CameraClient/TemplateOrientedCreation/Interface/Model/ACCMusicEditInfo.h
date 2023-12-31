//
//  ACCMusicEditInfo.h
//  CameraClient-Pods-Aweme
//
//  Created by Lemonior on 2020/11/20.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

@interface ACCMusicInfo : MTLModel <MTLJSONSerializing, NSCopying>

@property (nonatomic, copy) NSString *musicID;
@property (nonatomic, copy) NSString *musicUrl;

- (NSDictionary *)acc_musicInfoDict;

@end

@interface ACCMusicEditInfo : MTLModel <MTLJSONSerializing, NSCopying>

@property (nonatomic, strong) ACCMusicInfo *musicInfo;
@property (nonatomic, assign) NSInteger startTime;
@property (nonatomic, assign) NSInteger duration;
@property (nonatomic, assign) CGFloat speed;

@end
