//
//  ACCChallengeModelProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/12/26.
//

#ifndef ACCChallengeModelProtocol_h
#define ACCChallengeModelProtocol_h

#import <Mantle/MTLJSONAdapter.h>

@protocol ACCTaskModelProtocol, ACCUserModelProtocol, ACCMusicModelProtocol;

@protocol ACCChallengeModelProtocol <NSObject, NSCopying, MTLJSONSerializing>

@property (nonatomic, copy) NSString *itemID;
@property (nonatomic, copy) NSString *challengeName;
// need to check whether can be removed
@property (nonatomic, assign) BOOL isCommerce; // Is it a commercial topic
@property (nonatomic, copy) NSArray<id<ACCMusicModelProtocol>> *connectMusics;
@property (nonatomic, strong)id<ACCTaskModelProtocol> task;// Mission of the whole people
@property (nonatomic, strong) NSString *stickerId;
@optional
//commerce dynamic recorder
@property (nonatomic, assign) BOOL isCommerceCamera;
//dynamic recoder lynx schema channel
@property (nonatomic, copy) NSString *lynxChannel;

@end

@protocol ACCTaskModelProtocol <NSObject, NSCopying>

@property (nonatomic, copy) NSString *ID;
@property (nonatomic, copy) NSArray<id<ACCChallengeModelProtocol>> *challengs; // ID & name
@property (nonatomic, copy) NSArray<id<ACCUserModelProtocol>> *usersShouldBeMentioned;
@property (nonatomic, assign) BOOL isLiveRecord;
@property (nonatomic, copy) NSString *stickerText;

@property (nonatomic, copy) NSArray<__kindof id<ACCMusicModelProtocol>> *musics;

@end

#endif /* ACCChallengeModelProtocol_h */
