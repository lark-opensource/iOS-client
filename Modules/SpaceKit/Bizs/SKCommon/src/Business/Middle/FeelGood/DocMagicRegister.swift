//
//  DocMagicRegister.swift
//  SKBrowser
//
//  Created by huayufan on 2021/1/4.
//  


import LarkContainer
import SKFoundation
import LarkMagic
import SpaceInterface


public enum ScenarioType: String {
    case docContent = "ccm_doc_content"
    case sheetContent = "ccm_sheet_content"
    case mindnoteContent = "ccm_mindnote_content"
    case driveContent = "ccm_drive_content"
    case docxContent = "ccm_docx_content"
    case bitableContent = "ccm_bitable_content"
    case spaceHome = "ccm_space_home"
    case wikiHome = "ccm_wiki_home"
    case wikiContent = "ccm_wiki_content"
    case templateCenter = "ccm_template_center"
}

extension ScenarioType {
    var interceptor: SpaceFeelGoodInterceptor {
        switch self {
        case .spaceHome:
            return DocsSpaceHomeInterceptor()
        default:
            return DocsContentInterceptor()
        }
    }
}

public protocol BusinessInterceptor: AnyObject {
    var hasOtherInterceptEvent: Bool { get }
}

protocol FeelGoodInterceptor {
    var businessInterceptor: BusinessInterceptor? { get set }
    var presentController: UIViewController? { get set }
    var currentController: UIViewController? { get set }
}

typealias SpaceFeelGoodInterceptor = ScenarioInterceptor & FeelGoodInterceptor

public final class FeelGoodRegister {
    
    @InjectedLazy private var larkMagicService: LarkMagicService
    
    private let type: ScenarioType
    
    public init(type: ScenarioType,
                current: UIViewController? = nil,
                businessInterceptor: BusinessInterceptor? = nil,
                _ containerProvider: @escaping () -> UIViewController?) {
        self.type = type
        if isInLark {
            DocsLogger.info("feelgood register: \(type.rawValue)")
            var interceptor = type.interceptor
            interceptor.businessInterceptor = businessInterceptor
            interceptor.currentController = current
            interceptor.presentController = containerProvider()
            larkMagicService.register(scenarioID: type.rawValue,
                                      interceptor: interceptor,
                                      containerProvider: containerProvider)
        } else {
            DocsLogger.info("feelgood register 不在lark")
        }
    }

    var isInLark: Bool {
        return !DocsSDK.isInLarkDocsApp && !DocsSDK.isInDocsApp
    }
    
    deinit {
        if isInLark {
           larkMagicService.unregister(scenarioID: type.rawValue)
        }
    }
}

extension FeelGoodRegister {
    
    public class func conver(_ docsType: DocsType) -> ScenarioType? {
        switch docsType {
        case .doc:
            return .docContent
        case .sheet:
            return .sheetContent
        case .mindnote:
            return .mindnoteContent
        case .docX:
            return .docxContent
        case .bitable:
            return .bitableContent
        default:
            return nil
        }
    }
}
