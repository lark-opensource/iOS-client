//
//  TTVideoEngineLogView.h
//  TTVideoEngine
//
//  Created by 黄清 on 2019/1/28.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, TTVideoEngineViewLogType) {
    TTVideoEngineViewLogTypeInfo        = 0,
    TTVideoEngineViewLogTypeError       = 1,
    TTVideoEngineViewLogTypeSucceed     = 2,
};

NS_ASSUME_NONNULL_BEGIN

@interface UIView (_TTVideoEngine)
@property (nonatomic) CGFloat ttvideoengine_left;        ///< Shortcut for frame.origin.x.
@property (nonatomic) CGFloat ttvideoengine_top;         ///< Shortcut for frame.origin.y
@property (nonatomic) CGFloat ttvideoengine_right;       ///< Shortcut for frame.origin.x + frame.size.width
@property (nonatomic) CGFloat ttvideoengine_bottom;      ///< Shortcut for frame.origin.y + frame.size.height
@property (nonatomic) CGFloat ttvideoengine_width;       ///< Shortcut for frame.size.width.
@property (nonatomic) CGFloat ttvideoengine_height;      ///< Shortcut for frame.size.height.
@property (nonatomic) CGFloat ttvideoengine_centerX;     ///< Shortcut for center.x
@property (nonatomic) CGFloat ttvideoengine_centerY;     ///< Shortcut for center.y
@property (nonatomic) CGPoint ttvideoengine_origin;      ///< Shortcut for frame.origin.
@property (nonatomic) CGSize  ttvideoengine_size;        ///< Shortcut for frame.size.
@end

@interface TTVideoEngineLogView : UIView

/// Add a log
- (void)addLogInfo:(NSString *)log type:(TTVideoEngineViewLogType)logType;

/// Clear logs
- (void)clearLogs;

@end

NS_ASSUME_NONNULL_END
