//
//  BDPAudioPluginModel.h
//  Timor
//
//  Created by MacPu on 2019/5/27.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/BDPBaseJSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDPAudioPluginModel : BDPBaseJSONModel

@property (nonatomic, copy) NSString *src;
@property (nonatomic, copy) NSString *encryptToken;

@property (nonatomic, assign) CGFloat startTime;
@property (nonatomic, assign) CGFloat currentTime;
@property (nonatomic, assign) CGFloat duration;
@property (nonatomic, assign) CGFloat buffered;
@property (nonatomic, strong) NSNumber *volume;

@property (nonatomic, assign) BOOL loop;
@property (nonatomic, assign) BOOL obeyMuteSwitch;
@property (nonatomic, assign) BOOL autoplay;
@property (nonatomic, assign) BOOL paused;

@end

NS_ASSUME_NONNULL_END
