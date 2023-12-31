//
//  BDQBDelegate.h
//  BDDynamically
//
//  Created by zuopengliu on 10/10/2018.
//

#import <Foundation/Foundation.h>



NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BDDYCDeployArea) {
    kBDDYCDeployAreaCN = 0,  // 中国
    kBDDYCDeployAreaSG,      // 新加坡
    kBDDYCDeployAreaVA,      // 美东
};

@protocol BDQBDelegate <NSObject>
@optional
// 拉取整个补丁列表接口回调
- (void)didFailFetchListWithError:(NSError * _Nullable)error;

// 拉取某个补丁回调
- (void)moduleData:(id _Nullable)aModule didFetchWithError:(NSError *_Nullable)error;

// 加载某个补丁回调
- (void)moduleData:(id _Nullable)aModule didLoadWithError:(NSError *_Nullable)error;

// 将要加载某个补丁
- (void)moduleData:(id _Nullable)aModule willLoadWithError:(NSError *_Nullable)error;

// 引擎初始化回调
- (void)engineDidInitWithError:(NSError *_Nullable)error type:(NSInteger)type;

// 引擎内部运行CRASH回调
- (void)engineDidRunWithError:(NSError *_Nullable)error type:(NSInteger)type;

@end

NS_ASSUME_NONNULL_END
