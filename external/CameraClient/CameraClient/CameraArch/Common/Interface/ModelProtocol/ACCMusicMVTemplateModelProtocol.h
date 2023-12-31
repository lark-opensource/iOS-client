//
//  ACCMusicMVTemplateModelProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2021/1/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCMusicMVEditInfoProtocol <NSObject>

@property (nonatomic, assign) int64_t templateID;
@property (nonatomic, assign) int64_t startTime;
@property (nonatomic, assign) int64_t duration;
@property (nonatomic, assign) CGFloat speed;

@end

@protocol ACCMusicMVVideoSegInfoProtocol <NSObject>

@property (nonatomic, assign) CGFloat startTime;
@property (nonatomic, assign) CGFloat endTime;
@property (nonatomic, copy) NSString *fragmentID;
@property (nonatomic, assign) CGFloat cropRatio;
@property (nonatomic, copy) NSString *materialType;
@property (nonatomic, assign) CGFloat sourceDuration;
@property (nonatomic, assign) NSInteger groupID;

@end

@protocol ACCMusicMVTemplateInfoProtocol <NSObject>

@property (nonatomic, assign) int64_t templateID;
@property (nonatomic, copy) NSString *tag;
@property (nonatomic, copy) NSString *style;
@property (nonatomic, copy) NSString *expr;
@property (nonatomic, assign) NSInteger numSegs;
@property (nonatomic, assign) BOOL isCommon;
@property (nonatomic, assign) NSInteger source;
@property (nonatomic, copy) NSString *zipURL;
@property (nonatomic, copy) NSArray<id<ACCMusicMVVideoSegInfoProtocol>> *videoSegs;

@end

@protocol ACCMusicMVTemplateModelProtocol <NSObject>

@property (nonatomic, copy) NSArray<id<ACCMusicMVTemplateInfoProtocol>> *templatesInfo;
@property (nonatomic, copy) NSArray<id<ACCMusicMVEditInfoProtocol>> *musicEditsInfo;

@end

NS_ASSUME_NONNULL_END
