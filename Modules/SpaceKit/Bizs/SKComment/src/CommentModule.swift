//
//  CommentModule.swift
//  SKComment
//
//  Created by huayufan on 2023/3/27.
//  


import SKCommon
import SpaceInterface
import LarkRustClient
import SKCommon
import SKFoundation
import SKInfra
import LarkContainer

public final class CommentModule: ModuleService {

    public init() {}
    /// 初始化时调用
    public func setup() {
        _ = CommentDraftManager.shared // 评论草稿管理单例
        registerTransient()
        registerContainer()
    }
    
    /// 为了解析业务resolve传递的参数
    private class InstanceMaker<P, R> {
        static func generateInstance(parmas: P, constructor: (P) -> R) -> R {
            return constructor(parmas)
        }
    }
    
    // 保证每次resolve出来都是不同的实例
    func registerTransient() {
        DocsContainer.shared.register(FloatCommentModuleType.self) { (resolver, params) in
            return InstanceMaker<CommentModuleParams, FloatCommentModule>.generateInstance(parmas: params) { par in
                return FloatCommentModule(dependency: par.dependency, apiAdaper: par.apiAdaper)
            }
        }.inObjectScope(.transient)
        
        DocsContainer.shared.register(AsideCommentModuleType.self) { (resolver, params) in
            return InstanceMaker<CommentModuleParams, AsideCommentModule>.generateInstance(parmas: params) { par in
                return AsideCommentModule(dependency: par.dependency, apiAdaper: par.apiAdaper)
            }
        }.inObjectScope(.transient)
        
        DocsContainer.shared.register(DriveCommentModuleType.self) { (resolver, params) in
            return InstanceMaker<CommentModuleParams, DriveCommentModule>.generateInstance(parmas: params) { par in
                return DriveCommentModule(dependency: par.dependency, apiAdaper: par.apiAdaper)
            }
        }.inObjectScope(.transient)
        
        DocsContainer.shared.register(AtInputViewType.self) { (resolver, params) in
            return InstanceMaker<AtInputViewInitParams, AtInputTextView>.generateInstance(parmas: params) { par in
                return AtInputTextView(dependency: par.dependency, font: par.font, ignoreRotation: par.ignoreRotation)
            }
        }.inObjectScope(.transient)

        DocsContainer.shared.register(CommentSendResultReporterType.self) { _ in
            let enable = SettingConfig.commentPerformanceConfig?.sendEnable ?? false
            return enable ? CommentSendResultReporter() : DummyCommentSendResultReporter()
        }.inObjectScope(.transient)
    }

    func registerContainer() {
        DocsContainer.shared.register(AddCommentToastView.self, factory: { _ in
            return AddCommentToastViewImp()
        }).inObjectScope(.container)
        
        DocsContainer.shared.register(CommentTranslationToolProtocol.self, factory: { _ in
            return CommentTranslationTools.shared
        }).inObjectScope(.container)

        DocsContainer.shared.register(CommentSubScribeCacheInterface.self, factory: { _ in
            return CommentSubScribeCacheInstance()
        }).inObjectScope(.container)
        
        DocsContainer.shared.register(CommentImageCacheInterface.self, factory: { _ in
            return CommentImageCache.shared
        }).inObjectScope(.container)
        
        DocsContainer.shared.register(AudioAPI.self) { (r) -> AudioAPI in
            let rustService = r.resolve(RustService.self)
            let imp = AudioAPIImpl(client: rustService!)
            return imp
        }
 
        DocsContainer.shared.register(CommentShowInputDecoder.self, factory: { _ in
            return CommentShowInputDecoderImp()
        }).inObjectScope(.container)
        
        DocsContainer.shared.register(CommentTrackerInterface.self, factory: { _ in
            return CommentTrackerImp()
        }).inObjectScope(.container)
        
        CommentAPIContent.logFunc = { msg in
            DocsLogger.warning(msg, component: LogComponents.comment)
        }
        
        DocsContainer.shared.register(AtInfoXMLParserInterface.self, factory: { _ in
            return AtInfoXMLParserImp()
        }).inObjectScope(.container)
        
        DocsContainer.shared.register(CommentDraftManagerInterface.self, factory: { _ in
            return CommentDraftManager.shared
        }).inObjectScope(.container)
        
        DocsContainer.shared.register(CommentTranslationToolsInterface.self, factory: { _ in
            return CommentTranslationTools.shared
        }).inObjectScope(.container)
    }
}
