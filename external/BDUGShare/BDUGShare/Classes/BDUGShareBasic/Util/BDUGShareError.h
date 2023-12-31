//
//  BDUGShareError.h
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/6/4.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, BDUGShareErrorType) {
    BDUGShareErrorTypeAppNotInstalled = 1001, // 未安装
    BDUGShareErrorTypeAppNotSupportAPI, // 不支持的API
    BDUGShareErrorTypeAppNotSupportShareType, // 不支持的分享类型。
    
    BDUGShareErrorTypeInvalidContent, //分享类型不可用
    BDUGShareErrorTypeNoTitle, //缺少title字段。
    BDUGShareErrorTypeNoWebPageURL, //缺少url字段
    BDUGShareErrorTypeNoImage, //缺少Image字段。
    BDUGShareErrorTypeNoVideo, //缺少videoURL字段。
    
    BDUGShareErrorTypeUserCancel, //用户取消
    BDUGShareErrorTypeNoValidItemInPanel, //无可用面板
    
    BDUGShareErrorTypeExceedMaxVideoSize, //超出视频最大大小。
    BDUGShareErrorTypeExceedMaxImageSize, //超出图片最大大小。
    BDUGShareErrorTypeExceedMaxTitleSize,  //超出title最大长度
    BDUGShareErrorTypeExceedMaxDescSize,  //超出desc最大长度
    BDUGShareErrorTypeExceedMaxWebPageURLSize,  //超出url最大长度
    BDUGShareErrorTypeExceedMaxFileSize,  //超出文件最大长度
    
    BDUGShareErrorTypeSendRequestFail,  //request发送失败
    
    BDUGShareErrorTypeOther, //其他分享错误
};

@interface BDUGShareError : NSObject

+ (NSError *)errorWithDomain:(NSString *)domain
                        code:(BDUGShareErrorType)type
                    userInfo:(NSDictionary *)userInfo;

@end
