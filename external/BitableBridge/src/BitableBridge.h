//
//  BitableBridge.h
//  BitableBridge
//
//  Created by zenghao on 2018/9/12.
//

#import <Foundation/Foundation.h>

extern NSString *const kBitableBridgeErrorDomain;

typedef NS_ENUM(NSUInteger, BridgeLoadingError) {
    BridgeLoadingErrorJSBundleNotExisted = 1, // js bundle文件不存在
    BridgeLoadingErrorPackerServerNotRunning, // 在线调试服务器没有启动
    BridgeLoadingErrorJSBundleParseFailed, // js bundle 解析失败
    
};

// 主线程发送的delegate消息
@protocol BitableBridgeDelegate<NSObject>

// 需要Bridge完成初始化才能发送reqeust
- (void)readyToUse;

// JS Bundle加载过程中出错，e.g: 解析JS文件
- (void)loadJSBundleFailedWithError:(NSError *)error;

// 收到JS端发送的base64编码后的数据
- (void)didReceivedResponse:(NSString *)dataString;

// 收到docs JS端发送的json的数据
- (void)didReceivedDocsResponse:(NSString *)jsonString;

@end

@interface BitableBridge : NSObject

@property (nonatomic, weak) id<BitableBridgeDelegate> delegate;


/**
 初始化BriableBridge对象，支持创建多个实例，相互之间的JS运行环境是隔离开的

 @return BriableBridge对象，需要外部持有
 */
- (instancetype)init;

+ (NSURL *)jsBundleURL;

- (void)reloadWithOfflineMode:(BOOL)offlineMode
           WithJSBundleFolder:(NSURL *)jsBundleFolder
                     filename:(NSString *)filename
                    extension:(NSString *)extension
                     remoteIP:(NSString *)remoteIP;

/**
 加载业务包到RN实例
 
 @param sourceCode 业务包数据
 @param sync 是否同步执行
 */
- (void)executeSourceCode:(NSData *)sourceCode sync:(BOOL)sync;

/**
 发送请求到JS端，只有Bridge完成初始化工作收到`readyToUse`后才能发送，否则触发Assert

 @param string 经过base64编码后的字符串
 */
- (void)request:(NSString *)string;

/**
 发送请求到docs JS端，只有Bridge完成初始化工作收到`readyToUse`后才能发送，否则触发Assert
 
 @param string json字符串
 */
- (void)docsRequest:(NSString *)string;

@end
