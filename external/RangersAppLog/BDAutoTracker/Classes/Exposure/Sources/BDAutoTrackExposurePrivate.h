//
//  BDAutoTrackExposurePrivate.h
//  RangersAppLog
//
//  Created by SoulDiver on 2022/4/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDViewExposureConfig (Private)

+ (instancetype)globalDefaultConfig;

@property (nonatomic, assign) CGFloat areaRatio;

@property (nonatomic, copy) NSNumber *visualDebug;

- (BOOL)visualDiagnosisEnabled;

- (void)apply:(BDViewExposureConfig *)global;

@end

NS_ASSUME_NONNULL_END
