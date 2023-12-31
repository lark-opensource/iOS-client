//
//  BDUGSystemShare.h
//  BDUGShare
//
//  Created by zhxsheng on 2018/7/20.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGSystemShareErrorDomain;

@interface BDUGSystemShare : NSObject

+ (void)setPopoverRect:(CGRect)popoverRect;
+ (void)setApplicationActivities:(NSArray <__kindof UIActivity *> * _Nullable)applicationActivities;
+ (void)setExcludedActivityTypes:(NSArray <UIActivityType> * _Nullable)excludedActivityTypes;

+ (void)shareImage:(UIImage *)image completion:(UIActivityViewControllerCompletionWithItemsHandler _Nullable)completion;

+ (void)shareFileWithSandboxPath:(NSString *)sandboxPath completion:(UIActivityViewControllerCompletionWithItemsHandler _Nullable)completion;

+ (void)shareWithTitle:(NSString * _Nullable)title image:(UIImage * _Nullable)image url:(NSURL * _Nullable)url completion:(UIActivityViewControllerCompletionWithItemsHandler _Nullable)completion;

+ (void)shareWithActivityItems:(NSArray *)activityItems
                    completion:(UIActivityViewControllerCompletionWithItemsHandler _Nullable)completion;

@end

NS_ASSUME_NONNULL_END
