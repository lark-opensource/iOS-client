//
//  BDPChooseVideoModel.h
//  Timor
//
//  Created by zhysan on 2020/11/8.
//

#import <UIKit/UIKit.h>

/**
 * 视频来源
 */
typedef NS_OPTIONS(NSInteger, BDPVideoSourceType) {
    BDPVideoSourceTypeUnknow    = 0,      /// 默认
    BDPVideoSourceTypeAlbum     = 1 << 0, /// 相册
    BDPVideoSourceTypeCamera    = 1 << 1, /// 拍摄
};

typedef NS_ENUM(NSInteger, BDPChooseVideoResultCode) {
    BDPChooseVideoResultCodeSuccess,            /// 成功
    BDPChooseVideoResultCodeCancel,             /// 用户取消
    BDPChooseVideoResultCodeSystemError,        /// 系统异常
    BDPChooseVideoResultCodeInvalidParam,       /// 选择参数错误
    BDPChooseVideoResultCodePermissionDeny,     /// 无权限
    BDPChooseVideoResultCodeTimeLimitExceed,    /// 选择视频超过最大时长限制
};

NS_ASSUME_NONNULL_BEGIN

@interface BDPChooseVideoParam : NSObject

/// 允许选择视频的最大时长(单位：s)
@property (nonatomic, assign, readonly) NSTimeInterval maxDuration;

/// 允许选择视频的模式（拍摄、相册）
@property (nonatomic, assign, readonly) BDPVideoSourceType sourceType;

/// 弹出视频选择界面的 VC
@property (nonatomic, strong, readonly) UIViewController *fromController;

/// 是否对选择的视频进行压缩
@property (nonatomic, assign, readonly) BOOL compressed;

/// 选择视频后的无拓展名导出路径（拓展名由视频的原拓展名决定）
@property (nonatomic, strong, readonly) NSString *outputFilePathWithoutExtention;

- (nullable instancetype)initWithMaxDuration:(NSTimeInterval)maxDuration
                                  sourceType:(BDPVideoSourceType)sourceType
                              fromController:(UIViewController *)fromController
                                  compressed:(BOOL)compressed
              outputFilePathWithoutExtention:(NSString *)outputFilePathWithoutExtention NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

@interface BDPChooseVideoResult : NSObject

/// 标识选择结果的 code
@property (nonatomic, assign) BDPChooseVideoResultCode code;

/// 导出视频的完整文件路径
@property (nonatomic, strong, nullable) NSString *filePath;

/// 导出视频的时长(单位：s)
@property (nonatomic, assign) NSTimeInterval duration;

/// 导出视频的文件大小（单位：Bytes）
@property (nonatomic, assign) CGFloat size;

/// 导出视频的分辨率高度
@property (nonatomic, assign) CGFloat height;

/// 导出视频的分辨率宽度
@property (nonatomic, assign) CGFloat width;

/// 通过 code 快速创建一个 result
+ (instancetype)resultWithCode:(BDPChooseVideoResultCode)code;

@end


NS_ASSUME_NONNULL_END
