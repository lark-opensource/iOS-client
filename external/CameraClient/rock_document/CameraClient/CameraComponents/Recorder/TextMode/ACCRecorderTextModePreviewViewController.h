//
//  ACCRecorderTextModePreviewViewController.h
//  CameraClient-Pods-Aweme
//
//  Created by Yangguocheng on 2020/9/20.
//

#import <UIKit/UIKit.h>
#import "ACCStickerLogger.h"
#import "ACCRecorderBackgroundManagerProtocol.h"
#import "ACCRecordLayoutGuide.h"

NS_ASSUME_NONNULL_BEGIN

@class AWEStoryTextImageModel, ACCRecordTextModeColorManager;

@interface ACCRecorderTextModePreviewViewController : UIViewController

- (instancetype)initWithTextModel:(AWEStoryTextImageModel *)textModel colorManager:(ACCRecordTextModeColorManager *)colorManager;

- (instancetype)initWithTextModel:(AWEStoryTextImageModel *)textModel backgroundManager:(NSObject<ACCRecorderBackgroundSwitcherProtocol> *)backgroundManager;

@property (nonatomic, copy, nullable) void (^goNext)(void);
@property (nonatomic, copy, nullable) void (^close)(void);
@property (nonatomic, copy, nullable) void (^textViewDidApear)(void);
@property (nonatomic, copy, nullable) void (^onChangeColor) (NSString *colorString);
@property (nonatomic, copy, nullable) void (^onBeginEdit) (NSString *enterMethod);
@property (nonatomic, strong) id<ACCStickerLogger> stickerLogger;
@property (nonatomic, strong) ACCRecordLayoutGuide *layoutGuide;
@property (nonatomic, weak) AWEVideoPublishViewModel *publishModel;

@property (nonatomic, copy, nullable) void (^textDidChangeCallback)(AWEStoryTextImageModel * _Nullable);

- (UIImage *)generateBackgroundImage;

@end

NS_ASSUME_NONNULL_END
