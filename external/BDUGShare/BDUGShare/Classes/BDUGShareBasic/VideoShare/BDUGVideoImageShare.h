//
//  BDUGVideoImageShare.h
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/5/16.
//

#import <Foundation/Foundation.h>
#import "BDUGActivityProtocol.h"
#import "BDUGVideoImageShareDialogManager.h"
#import "BDUGVideoImageShareModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^BDUGVideoShareCompletionHandler)(BDUGVideoShareStatusCode statusCode, NSString * _Nullable desc, BDUGVideoImageShareContentModel * _Nullable resultModel);

typedef NS_ENUM(NSInteger, BDUGVideoImageShareStrategy) {
    BDUGVideoImageShareStrategyOpenThirdApp = 0,//视频分享中直接打开三方App，适用：微信、QQ被打压的情况。
    BDUGVideoImageShareStrategyResponseSaveSandbox,//视频存储后回调，使用：抖音视频分享。
    BDUGVideoImageShareStrategyResponseSaveAlbum,//视频存储后回调，使用：抖音视频分享。
    BDUGVideoImageShareStrategyResponseMemory, //在内存中以变量形式返回，适用image。
};

typedef NS_ENUM(NSInteger, BDUGVideoImageShareType) {
    BDUGVideoImageShareTypeVideo = 0,//保存视频，分享。
    BDUGVideoImageShareTypeImage,//保存图片，分享
};

@interface BDUGVideoImageShareInfo: NSObject

/**
 视频或图片URL
 */
@property (nonatomic, copy, nullable) NSString *resourceURLString;

/**
 分享图片
 */
@property (nonatomic, strong, nullable) UIImage *shareImage;

/**
 沙盒路径
 */
@property (nonatomic, copy, nullable) NSString *sandboxPath;

/**
 面板ID
 */
@property (nonatomic, copy, nullable) NSString *panelID;
@property (nonatomic, copy, nullable) NSString *panelType;
@property (nonatomic, copy, nullable) NSString *resourceID;

@property (nonatomic, copy, nullable) NSString *platformString;

@property (nonatomic, copy, nullable) NSString *channelStringForEvent;

@property (nonatomic, assign) BDUGVideoImageShareStrategy shareStrategy;
@property (nonatomic, assign) BDUGVideoImageShareType shareType;

@property (nonatomic, assign) BOOL needPreviewDialog;

@property (nonatomic, copy, nullable) BDUGShareOpenThirPlatform openThirdPlatformBlock;
@property (nonatomic, copy, nullable) BDUGVideoShareCompletionHandler completeBlock;
@property (nonatomic, copy, nullable) BDUGActivityTokenDialogDidShow dialogDidShowBlock;

@property (nonatomic, strong, nullable) NSDictionary *clientExtraData;

@end

@interface BDUGVideoImageShare : NSObject

/**
 视频分享功能入口

 @param info 视频分享所需数据
 */
+ (void)shareVideoWithInfo:(BDUGVideoImageShareInfo *)info;

+ (void)cancelShareProcess;

@end

NS_ASSUME_NONNULL_END
