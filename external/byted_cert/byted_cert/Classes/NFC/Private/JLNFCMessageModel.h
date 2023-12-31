//
//  JLNFCMessageModel.h
//  JLReader3.1.4
//
//  Created by wangyang on 2022/6/1.
//  Copyright © 2022 亮. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM(NSInteger, JLNFCLanguagesState) {
    JLNFCLanguagesStateAuto = 0,    //自动获取系统语言类型，如不包含语言类型，默认英文
    JLNFCLanguagesStateZH = 1,      //简体中文
    JLNFCLanguagesStateEN = 2,      //英文
    JLNFCLanguagesStateZH_Hant = 3, //繁体中文
};

typedef NS_ENUM(NSInteger, JLReadCertificatesState) {
    JLReadCertificatesStateCard = 0,     //身份证
    JLReadCertificatesStatePassport = 1, //旅行证件
};
NS_ASSUME_NONNULL_BEGIN


@interface JLNFCMessageModel : NSObject

/**
 *  根据语言类型和读取证件类型获取model
 *  JLNFCLanguagesState 语言类型
 *  JLReadCertificatesState 读取证件类型
 *  PS:非单例
 */
+ (JLNFCMessageModel *)getDefaultMessageModelWithLanguagesState:(JLNFCLanguagesState)state withReadCertificatesState:(JLReadCertificatesState)cState;
#pragma mark - 身份证和旅行证件通用参数
/**
 *  NFC 初始提示
 *  身份证内容 ：请将身份证放在图示位置，静置3秒
 *  旅行者内容 ：请将证件放在图示位置，静置10秒
 *  PS:秒数不能更改
 */
@property (nonatomic, copy) NSString *ExampleLocation;

#pragma mark - need move 拼接成正在读取证件的提示，提示内容为：还需X秒，请勿移动证件
/**
 *  还需
 */
@property (nonatomic, copy) NSString *need;
/**
 *  秒，请勿移动证件
 */
@property (nonatomic, copy) NSString *dontMove;
#pragma mark---- end
/**
 *  正在处理，请稍候...
 *  提示出现情况 ：
 *  1.读取身份证时间超过3秒
 *  2.读取旅行证件时间超过10秒
 */
@property (nonatomic, copy) NSString *wait;
/**
 *  网络状况不佳，请检查网络后重试
 *  提示出现情况 ：
 *  1.在读取过程中网络出现不好或断开的情况会提示
 */
@property (nonatomic, copy) NSString *networkAgain;
/**
 *  读取失败，请勿移动
 *  提示出现情况 ：
 *  1.读取证件失败，证件重读的时候会提示
 */
@property (nonatomic, copy) NSString *readFailNoMove;
/**
 *  读取成功
 *  证件读取成功
 */
@property (nonatomic, copy) NSString *readCertificatesSuccee;
/**
 *  读卡失败，请重新读卡
 */
@property (nonatomic, copy) NSString *readCertificatesFail;
/**
 *  不支持证件类型
 */
@property (nonatomic, copy) NSString *notCertificatesState;

#pragma mark - 旅行证件独有参数
/**
 *  证件认证失败
 *  提示出现情况：
 *  旅行证件认证失败
 */
@property (nonatomic, copy) NSString *authenticationError;
/**
 *  您的证件信息填写有误\r\n请修改正确后重试
 *  提示出现情况：
 *  旅行证件三要素填写有误
 */
@property (nonatomic, copy) NSString *certificatesInfoError;

@end

NS_ASSUME_NONNULL_END
