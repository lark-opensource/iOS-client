//
//  LVDraftSpeedPayload.h
//  LVTemplate
//
//  Created by luochaojing on 2020/2/26.
//

#import <Foundation/Foundation.h>
#import "LVMediaDraft.h"

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSUInteger, LVDraftSpeedMode) {
    LVDraftSpeedModeNormal = 0, //常规变速
    LVDraftSpeedModeCurve = 1,  //曲线变速
};


/*
 曲线变速点
 */
@interface LVPoint(Interface)

- (instancetype)initX:(CGFloat)x WithY:(CGFloat)y;

- (CGPoint)point;

@end

@interface LVDraftCurveSpeedModel (Inteface)

//曲线变速的平均速度
@property (nonatomic, assign) CGFloat avgRatioSpeed;

@end

/**
 速度素材
 */
@interface LVDraftSpeedPayload (Interface)

/**
 变速类型
 */
@property (nonatomic, assign) LVDraftSpeedMode mode;

/**
 获得一个默认值
 */
+ (LVDraftSpeedPayload*)defaultPayload;

@end

NS_ASSUME_NONNULL_END
