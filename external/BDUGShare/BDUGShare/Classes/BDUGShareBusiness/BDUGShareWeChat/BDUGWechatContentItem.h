//
//  BDUGWechatContentItem.h
//  Pods
//
//  Created by 延晋 张 on 16/6/6.
//
//

#import <Foundation/Foundation.h>
#import "BDUGActivityContentItemProtocol.h"
#import "BDUGShareBaseContentItem.h"

typedef NS_ENUM(NSInteger, BDUGWechatShareType)
{
    BDUGWechatShareTypeSDK = 0,
    BDUGWechatShareTypeMiniProgram       =  1,
    BDUGWechatShareTypeFile       =  2,
};

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGActivityContentItemTypeWechat;

@interface BDUGWechatContentItem : BDUGShareBaseContentItem

/**
 微信独立的分享类型，优先级 > defaultShareType
 */
@property (nonatomic, assign) BDUGWechatShareType wechatShareType;

/**
 BDUGWechatShareTypeMiniProgram下为required属性。 小程序原始ID，需要跟应用在同一个微信开发者账号后台。
 */
@property (nonatomic, copy, nullable) NSString *miniProgramUserName;

/**
 小程序路径path，@optionnal
 */
@property (nonatomic, copy, nullable) NSString *miniProgramPath;

/// 是否直接调起小程序，默认为NO。 这里如果设为yes，如果小程序不能跳转回应用则拿不到回调。
@property (nonatomic, assign) BOOL launchMiniProgram;

/**
 BDUGWechatShareTypeFile下为required属性。 要分享的文件URL，可以是本地文件路径fileURL，也可以是下载链接。
 */
@property (nonatomic, strong, nullable) NSURL *fileURL;

/**
 BDUGWechatShareTypeFile下为required属性。 要分享的文件名，且必须有后缀名(例如：pdf)
 */
@property (nonatomic, copy, nullable) NSString *fileName;

@property (nonatomic, copy, nullable) NSDictionary *callbackUserInfo;

- (instancetype)initWithTitle:(NSString * _Nullable)title
                         desc:(NSString * _Nullable)desc
                   webPageUrl:(NSString * _Nullable)webPageUrl
                   thumbImage:(UIImage * _Nullable)thumbImage
                    defaultShareType:(BDUGShareType)defaultShareType;

@end

NS_ASSUME_NONNULL_END
