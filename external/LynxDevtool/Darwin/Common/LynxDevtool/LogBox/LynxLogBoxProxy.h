//  Copyright 2022 The Lynx Authors. All rights reserved.

#if __has_include(<Lynx/LynxBaseLogBoxProxy.h>)
#import <Lynx/LynxBaseLogBoxProxy.h>
#import <Lynx/LynxView.h>
#else
#import <LynxMacOS/LynxBaseLogBoxProxy.h>
#import <LynxMacOS/LynxView.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface LynxLogBoxProxy : NSObject <LynxBaseLogBoxProxy>

@property(nonatomic, readwrite, nullable)
    NSMutableDictionary<NSNumber *, NSMutableArray *> *logMessages;         // level -> msg
@property(nonatomic, readwrite, nullable) NSMutableArray *consoleMessages;  // js console log
@property(nullable, copy, nonatomic, readonly) NSDictionary *allJsSource;
@property(nullable, copy, nonatomic, readonly) NSString *templateUrl;

- (instancetype)initWithLynxView:(nullable LynxView *)view;
- (void)setReloadHelper:(nullable LynxPageReloadHelper *)reloadHelper;
- (void)showLogMessage:(nullable NSString *)message
             withLevel:(LynxLogBoxLevel)level
              withCode:(NSInteger)errCode;
- (void)reloadLynxViewFromLogBox;  // click reload btn on logbox
- (void)setRuntimeId:(NSInteger)runtimeId;
- (nullable NSMutableArray *)logMessagesWithLevel:(LynxLogBoxLevel)level;
- (void)removeLogMessagesWithLevel:(LynxLogBoxLevel)level;

@end

NS_ASSUME_NONNULL_END
