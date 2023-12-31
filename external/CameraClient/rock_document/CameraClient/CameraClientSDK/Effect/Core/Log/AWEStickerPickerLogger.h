//
//  AWEStickerPickerLogger.h
//  CameraClient
//
//  Created by Chipengliu on 2020/10/19.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, AWEStickerPickerLogLevel) {
    AWEStickerPickerLogLevelError       = 1,
    AWEStickerPickerLogLevelWarning     = 2,
    AWEStickerPickerLogLevelInfo        = 3,
    AWEStickerPickerLogLevelDebug       = 4,
    AWEStickerPickerLogLevelVerbose     = 5,
};

@class AWEStickerPickerLogger;
@protocol AWEStickerPickerLoggerDelegate <NSObject>

@required
- (void)stickerPickerLogger:(AWEStickerPickerLogger *)logger logMessage:(NSString * _Nullable)logMessage level:(AWEStickerPickerLogLevel)level;

@end

NS_ASSUME_NONNULL_BEGIN

@interface AWEStickerPickerLogger : NSObject

@property (nonatomic, weak) id<AWEStickerPickerLoggerDelegate> delegate;

@property (nonatomic, class, readonly, strong) AWEStickerPickerLogger *sharedInstance;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (void)logLevel:(AWEStickerPickerLogLevel)level format:(NSString *)format, ...;

@end

NS_ASSUME_NONNULL_END
