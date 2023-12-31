//
//  BDPAudioModel.h
//  Timor
//
//  Created by muhuai on 2018/2/1.
//  Copyright © 2018年 muhuai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import <UIKit/UIKit.h>
#import "BDPAudioPluginModel.h"
#import <OPFoundation/BDPUniqueID.h>

@interface BDPAudioModel : BDPAudioPluginModel

//@property (nonatomic, copy) NSString *src;
@property (nonatomic, copy) NSString *relativeSrc;
//@property (nonatomic, copy) NSString *encryptToken;
@property (nonatomic, assign) BOOL isInPkg;

//@property (nonatomic, assign) CGFloat startTime;
//@property (nonatomic, assign) CGFloat currentTime;
//@property (nonatomic, assign) CGFloat duration;
//@property (nonatomic, assign) CGFloat buffered;
//@property (nonatomic, strong) NSNumber *volume;
//@property (nonatomic, assign) BOOL loop;
//@property (nonatomic, assign) BOOL obeyMuteSwitch;
//@property (nonatomic, assign) BOOL autoplay;
//@property (nonatomic, assign) BOOL paused;

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *epname;
@property (nonatomic, strong) NSString *singer;

@property (nonatomic, strong) NSString *coverImgUrl;
@property (nonatomic, strong) NSString *webUrl;
@property (nonatomic, strong) NSString *protocol;
//audioPage为新增跳转回音频播放页面的字段，backScheme为根据audioPage拼出来的scheme
@property (nonatomic, strong) NSDictionary *audioPage;
@property (nonatomic, strong, readonly) NSURL *backScheme;

- (instancetype)initWithDictionary:(NSDictionary *)dic uniqueID:(BDPUniqueID *)uniqueID error:(NSError *__autoreleasing *)error;

@end
