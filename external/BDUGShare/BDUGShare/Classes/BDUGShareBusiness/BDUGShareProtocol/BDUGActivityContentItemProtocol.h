//
//  BDUGActivityContentItemProtocal.h
//  BDUGActivityViewControllerDemo
//
//  Created by 延晋 张 on 16/6/1.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BDUGShareDataModel.h"

typedef NS_ENUM(NSInteger, BDUGShareType)
{
    BDUGShareText        =  0,
    BDUGShareImage       =  1,
    BDUGShareWebPage     =  3,
    BDUGShareVideo       =  4,
};

typedef NS_ENUM(NSInteger, BDUGSharePlatformClickMode)
{
    //有分享数据即使用，没有分享数据直接走兜底
    BDUGSharePlatformClickModeSmooth = 0,
    //如果没有分享数据，会触发请求
    BDUGSharePlatformClickModeRequestIfNeed,
    //直接使用兜底。
    BDUGSharePlatformClickModeUseDefaultStrategy,
};

typedef void(^BDUGCustomAction)(void);

NS_ASSUME_NONNULL_BEGIN

@protocol BDUGActivityContentItemProtocol<NSObject>

@required

/**
 *  content item的唯一标示字符(unique identification)
 */
@property (nonatomic, readonly) NSString *contentItemType;

@optional

/**
 *  展示在panel上的标题
 */
@property (nonatomic, copy, nullable) NSString *contentTitle;

/**
 *  展示在panel上的图片
 */
@property (nonatomic, copy, nullable) NSString *activityImageName;

/// 展示在panel上的图片，优先级 > activityImageName
@property (nonatomic, strong, nullable) UIImage *activityImage;

@end

@protocol BDUGActivityContentItemSelectedProtocol <BDUGActivityContentItemProtocol>

//考虑Button的select状态和计数
@property (nonatomic, assign) BOOL selected;

@end

@protocol BDUGActivityContentItemSelectedDigProtocol <BDUGActivityContentItemSelectedProtocol>

//考虑Button的select状态和计数
@property (nonatomic, assign) BOOL banDig;
@property (nonatomic, assign) int64_t count;

@end


@protocol BDUGActivityContentItemShareProtocol <BDUGActivityContentItemProtocol>

/**
 *  分享类型, 当服务端下发策略失败时使用该字段调起三方分享
 */
@property (nonatomic, assign) BDUGShareType defaultShareType;

/**
 *  分享的内容链接
 */
@property (nonatomic, copy, nullable) NSString *webPageUrl;

/**
 视频分享的URL
 */
@property (nonatomic, copy, nullable) NSString *videoURL;

/**
 *  口令类型：需要groupID
 */
@property (nonatomic, copy, nullable) NSString *groupID;

/**
 点击面板上的三方平台时，如果数据没有ready是否需要阻塞用户行为等待数据返回。
 */
@property (nonatomic, assign) BDUGSharePlatformClickMode clickMode;

@property (nonatomic, copy, nullable) NSString *title;

@property (nonatomic, copy, nullable) NSString *desc;

@property (nonatomic, strong, nullable) UIImage *image;

@property (nonatomic, strong, nullable) UIImage *thumbImage;

@property (nonatomic, copy, nullable) NSString *imageUrl;

/**
 资源的沙盒路径，目前支持的分享类型：BDUGShareVideo
 */
@property (nonatomic, copy, nullable) NSString *resourceSandboxPathString;

/**
 该item对应的服务器返回数据。
 */
@property (nonatomic, strong, nullable) BDUGShareDataItemModel *serverDataModel;

//渠道信息。
@property (nonatomic, copy, nullable) NSString *channelString;

@end

NS_ASSUME_NONNULL_END
