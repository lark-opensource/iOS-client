//
//  DVEVCContextExternalInjectProtocol.h
//  NLEEditor
//
//  Created by bytedance on 2021/5/19.
//

#import <Foundation/Foundation.h>
#if ENABLE_SUBTITLERECOGNIZE
#import "DVESubtitleNetServiceProtocol.h"
#import "DVETextReaderServiceProtocol.h"
#endif
#import "DVEResourcePickerProtocol.h"
#import "DVEResourceLoaderProtocol.h"
#import "DVEEditorEventProtocol.h"
#if ENABLE_NET_SERVICE
#import "DVEBaseNetServiceProtocol.h"

#if ENABLE_MUSIC
#import "DVEOnlineMusicListRequestProtocol.h"
#endif

#endif

#if ENABLE_TEMPLATETOOL
#import "DVETemplateModelUploadServiceProtocol.h"
#endif

#if ENABLE_DVEALBUM
#import "DAKMaterialResourcePickerProtocol.h"
#endif

#if ENABLE_LITEEDITOR
#import "DVELiteEditorInjectionProtocol.h"
#endif

NS_ASSUME_NONNULL_BEGIN

// 实现该协议所注入的对象的生命周期与编辑页 VC 绑定
@protocol DVEVCContextExternalInjectProtocol <NSObject>

@optional

#if ENABLE_SUBTITLERECOGNIZE
/// 语音转字幕网络能力
- (id<DVESubtitleNetServiceProtocol>)provideSubtitleNetService;

/// 文本朗读能力
- (id<DVETextReaderServiceProtocol>)provideTextReaderService;
#endif

/// 资源加载能力
- (id<DVEResourceLoaderProtocol>)provideResourceLoader;
#if ENABLE_MULTITRACKEDITOR

/// 相册选择能力
- (id<DVEResourcePickerProtocol>)provideResourcePicker;

/// 事件和转换能力
- (id<DVEEditorEventProtocol>)provideEditorEvent;
#endif

#if ENABLE_NET_SERVICE
/// 通用网络能力
- (id<DVEBaseNetServiceProtocol>)provideNetService;

#if ENABLE_MUSIC
- (id<DVEOnlineMusicListRequestProtocol>)provideMusicList;
#endif

#endif

#if ENABLE_TEMPLATETOOL
/// 模板生产工具模板上传到服务端能力注入
- (id<DVETemplateModelUploadServiceProtocol>)provideUploadTemplateService;
#endif

#if ENABLE_DVEALBUM
/// 相册素材库拉取下载能力
- (id<DAKMaterialResourcePickerProtocol>)provideMaterialResourcePicker;
#endif

#if ENABLE_LITEEDITOR
/// 轻剪辑所需能力注入
- (id<DVELiteEditorInjectionProtocol>)provideLiteEditorInjection;
#endif

@end

NS_ASSUME_NONNULL_END
