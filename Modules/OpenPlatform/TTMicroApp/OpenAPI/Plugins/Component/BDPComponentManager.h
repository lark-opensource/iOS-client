//
//  BDPComponentManager.h
//  Timor
//
//  Created by 王浩宇 on 2018/11/17.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

/* ------------- 🌇组件视图协议 ------------- */
@protocol BDPComponentViewProtocol <NSObject>

@property (nonatomic, assign) NSInteger componentID;

@end

/* ------------- 🌇组件管理单例 ------------- */
@interface BDPComponentManager : NSObject

+ (instancetype)sharedManager;

- (NSInteger)generateComponentID;
- (BOOL)insertComponentView:(UIView<BDPComponentViewProtocol> *)view toView:(UIView *)container;
- (BOOL)removeComponentViewByID:(NSInteger)componentID;
- (UIView<BDPComponentViewProtocol> *)findComponentViewByID:(NSInteger)componentID;

- (BOOL)insertComponentView:(UIView<BDPComponentViewProtocol> *)view toView:(UIView *)container stringID:(NSString *)stringID;
- (BOOL)removeComponentViewByStringID:(NSString *)stringID;
- (UIView *)findComponentViewByStringID:(NSString *)stringID;

@end
