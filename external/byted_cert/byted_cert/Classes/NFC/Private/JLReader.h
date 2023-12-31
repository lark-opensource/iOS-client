//
//  JLReader.h
//  BleReader2.2.4
//
//  Created by zczx on 2021/8/2.
//  Copyright © 2021 亮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JLNFCMessageModel.h"

typedef NS_ENUM(NSInteger, JLConnectTagState) {
    JLConnectTagConnected = 0, //已连接到卡片
};
typedef NS_ENUM(NSInteger, JLReaderConfigState) {
    JLReaderConfigCard = 0,     //读身份证
    JLReaderConfigPassport = 1, //读旅行证件
};

typedef void (^JLRPData)(NSString *_Nullable reqID, NSInteger errCode, NSString *_Nullable errMsg, NSString *_Nullable biz_id, NSString *infoData);
typedef void (^ReadCardBlock)(NSInteger errCode, NSString *_Nullable reqID, NSString *_Nullable errMsg, NSString *_Nullable infoData, NSString *_Nullable biz_id);
typedef void (^ConnectTagResult)(JLConnectTagState connectState);

NS_ASSUME_NONNULL_BEGIN


@interface JLReader : NSObject
/**
 * 重读次数，默认为5次，可设置1-10。
 */
@property (nonatomic, assign) NSInteger reTryTimes;
/**
 * NFC等待读卡超时时间，单位为秒。默认为20秒，可设置5-59秒。
 */
@property (nonatomic, assign) NSInteger timeouts;
/**
 *  NFC界面提示内容是否显示进度
 *  NO 不显示  YES 显示 默认 NO 不显示
 *  PS:
 *  1.只有旅行证件支持进度显示
 *  2.只iOS 15以上，iOS 15以下不支持
 */
@property (nonatomic, assign) BOOL isProgress;
/**
 *  卡片连接回调
 */
@property (nonatomic, copy) ConnectTagResult connectBlock;
/**
 * 单例实例化
 */
+ (JLReader *)sharedInstance;
/**
 *  设置读卡全局参数
 *  @param appid 我司分配的appid
 *  @param mod 可选0，1。默认为1
 *  @param ip 环境ip
 *  @param port 环境端口号
 *  @param cardType 证件类型，0：身份证
 *  @param envCode 环境识别码
 *  @param isImg 是否返回身份证头像照片 YES 返回 NO 不返回
 *  @param model 可自定义NFC界面提示内容
 *       1.使用自定义内容可使用 model init 创建  初始值全部为空(model 内所有属性值均为必填)
 *       2.非自定义内容可使用  getDefaultMessageModelWithLanguagesState 传入语言类型和证件类型获取model
 *       3.model 可传入 nil,语言类型为 JLNFCLanguagesStateAuto(自动获取语言类型)
 *       4.语言类型支持中文简体，中文繁体，英文,未支持语言类型默认使用英文
 *  @param state 参数配置类型
 *       1.设置 JLReaderConfigCard 是配置读取身份证的参数
 *       2.设置 JLReaderConfigPassport 是配置读取旅行证件的参数
 */
- (void)setReaderConfigWithAppid:(NSString *)appid withMod:(NSInteger)mod withIp:(NSString *)ip withPort:(NSInteger)port withCardType:(NSInteger)cardType withEnvCode:(NSInteger)envCode withIsImg:(BOOL)isImg withModel:(JLNFCMessageModel *)model withConfigState:(JLReaderConfigState)state;
#pragma mark NFC读身份证
/**
 *@param result 数据返回
 */
- (void)startReadIDCardWithResult:(ReadCardBlock)result;
#pragma mark NFC读旅行证件

/**
 *
 *@param passportNumber 旅行证件编号
 *@param dateOfBirth 出生日期 6位数字
 *@param expiryDate 截止日期 6位数字
 *@param jlData 返回reqID和错误码
 */
- (void)readPassportWithPassportNumber:(NSString *)passportNumber birth:(NSString *)dateOfBirth date:(NSString *)expiryDate result:(JLRPData)jlData;
/**
 *  自用方法,请勿使用
 */
- (double)updateNetDelayStateWithIp:(NSString *)ip withPort:(NSInteger)port withEnvCode:(NSInteger)envCode;


@end

NS_ASSUME_NONNULL_END
