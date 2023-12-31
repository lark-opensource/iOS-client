//
//  NLEExportSession_Private.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/4/27.
//

#import "NLEExportSession.h"

@class HTSVideoData, VEEditorSession;

@interface NLEExportSession ()

- (instancetype)initWithVideoData:(HTSVideoData *)videoData
                           editor:(VEEditorSession *)veEditor;
- (instancetype)init NS_UNAVAILABLE;

- (void)updateVEEditor:(VEEditorSession *)veEditor;

// hook 外部先 commit
@property (nonatomic, copy) void(^commitBlock)(NLEExportBaseBlock completion);

@end
