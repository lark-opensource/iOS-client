//
// Created by wangyinhui on 2021/6/7.
//

#import <Foundation/Foundation.h>


@interface HMDUIViewHierarchy : NSObject
+ (instancetype)shared;
+ (NSString *)getDescriptionForUI:(UIResponder *)responder;

@property (nonatomic, assign) NSUInteger maxFileCount;
@property (nonatomic, assign) NSUInteger clearFileCount;

- (void)updateConfigWithMaxFileCount:(NSUInteger)max clearFileCount:(NSUInteger)clear;

- (void)recordViewHierarchy:(NSDictionary *)vh;

- (void)uploadViewHierarchyIfNeedWithTitle:(NSString *)title subTitle:(NSString *)subTitle;

//需要在主线程下获取，对应复杂页面，耗时较高，withDetail为NO可以降低耗时
- (NSDictionary *)getViewHierarchy:(UIView *)view superView:(UIView *)superView superVC:(UIViewController *)superVC
                        withDetail:(BOOL)need targetView:(UIView *)targetView;
@end
