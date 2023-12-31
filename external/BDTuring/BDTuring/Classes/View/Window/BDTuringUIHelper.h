//
//  BDTuringUIHelper.h
//  BDTuring
//
//  Created by bob on 2019/9/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class UIWindow;
@protocol BDTuringEventCollector;

@interface BDTuringUIHelper : NSObject

@property (nonatomic, assign) BOOL shouldCloseFromMask;
@property (nonatomic, assign) BOOL showNavigationBarWhenDisappear;
@property (nonatomic, assign) BOOL turingForbidLandscape;
@property (nonatomic, assign) BOOL supportLandscape;
@property (nonatomic, assign) BOOL disableLoadingView;
@property (nonatomic, assign) BOOL isShowAlert;
@property (atomic, copy, nullable) NSDictionary *verifyThemeDictionary;
@property (atomic, copy, nullable) NSDictionary *smsThemeDictionary;
@property (atomic, copy, nullable) NSDictionary *qaThemeDictionary;

@property (atomic, copy, nullable) NSDictionary *verifyTextDictionary;
@property (atomic, copy, nullable) NSDictionary *smsTextDictionary;
@property (atomic, copy, nullable) NSDictionary *qaTextDictionary;

@property (atomic, copy, nullable) NSDictionary *sealThemeDictionary;
@property (atomic, copy, nullable) NSDictionary *sealTextDictionary;

+ (instancetype)sharedInstance;

+ (UIWindow *)keyWindow;
+ (CGFloat)statusBarHeight;

@end

NS_ASSUME_NONNULL_END
