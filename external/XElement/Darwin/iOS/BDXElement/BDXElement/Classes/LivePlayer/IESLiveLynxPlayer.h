//
//  IESLiveLynxPlayer.h
//  BDXElement
//
//  Created by chenweiwei.luna on 2020/10/13.
//

#import <Lynx/LynxUI.h>
#import "IESLiveLynxPlayerView.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESLiveLynxPlayer : LynxUI <IESLiveLynxPlayerView *>

@property (nonatomic, assign) BOOL mute;

@property (nonatomic, strong) NSNumber *volume;

@property (nonatomic, copy) NSString *streamData;

@property (nonatomic, copy) NSString *posterURL;

@property (nonatomic, copy) NSString *fitMode;

@property (nonatomic, assign) BOOL autoPlay;

@property (nonatomic, assign) BOOL bgPlay;

@property (nonatomic, copy) NSString *qualities;

@end

NS_ASSUME_NONNULL_END
