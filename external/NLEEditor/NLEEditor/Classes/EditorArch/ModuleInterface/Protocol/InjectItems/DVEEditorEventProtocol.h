//
//  DVEEditorEventProtocol.h
//  NLEEditor
//
//  Created by bytedance on 2021/7/15.
//

#import <Foundation/Foundation.h>
#import <TTVideoEditor/VEEditorSession.h>
#import <NLEEditor/DVEBarComponentProtocol.h>
#import "DVEReportUtils.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DVEEditorEventProtocol <NSObject>

@optional


/// 是否强制使用全局特效，会隐藏“作用对象”，并且添加的特效都是全局的
- (BOOL)onlyUseGlobalEffect;

/// effect 路径搜索
- (effectPathBlock _Nullable)effectPathSearchBlock;

///数据上报事件转换
- (NSString *)convert:(DVEBarActionType) type;

///剪辑页关闭按钮
- (void)editorDidDismissView:(UIViewController*)viewController
                      cancel:(BOOL)cancel
                      status:(BOOL)draftStored
                     draftID:(NSString * _Nullable)draftID;

///导出视频
- (void)editorDidExportedVideo:(UIViewController*)viewController
                        result:(BOOL)success
                      videoURL:(NSURL * _Nullable)url
                       draftID:(NSString *)draftID;
@end

NS_ASSUME_NONNULL_END
