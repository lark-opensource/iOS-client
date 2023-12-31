//
//  CCMWikiAndFolderSearchSegmentViewModel.swift
//  CCMMod
//
//  Created by ZhangYuanping on 2023/7/11.
//  
#if MessengerMod
import LarkSearchCore
import LarkModel
import LarkContainer
import RustPB
import SKResource
import SKFoundation
import RxSwift
import RxRelay
import RxCocoa
import SpaceInterface
import SKCommon
import SKWikiV2
import SKSpace
import LarkContainer

/// 供"移快副"场景使用的 [知识空间｜文件夹｜文件] 的搜索
class CCMWikiAndFolderSearchSegmentViewModel: CCMSearchSegmentViewModelType {

    static var workspaceRecommendProviderKey: String { "workspace-recommend" }

    private let config: WorkspacePickerConfig
    private let segments: [SearchSegment]

    enum SearchSegment: CaseIterable {
        case workspace
        case folder
        case docs

        var title: String {
            switch self {
            case .workspace:
                return SKResource.BundleI18n.SKResource.Doc_Facade_Wiki
            case .folder:
                return SKResource.BundleI18n.SKResource.LarkCCM_Wiki_MoveToSpace_Title_Folder
            case .docs:
                return SKResource.BundleI18n.SKResource.Doc_List_Space
            }
        }
    }

    var segmentTitles: [String] {
        return segments.map(\.title)
    }

    weak var defaultView: PickerRecommendListView?
    var searchbarTitle: String = SKResource.BundleI18n.SKResource.Doc_Facade_Search
    
    let userResolver: UserResolver

    init(userResolver: UserResolver, config: WorkspacePickerConfig) {
        self.userResolver = userResolver
        self.config = config

        if config.entrances.contains(.wiki) && config.entrances.contains(.mySpace) {
            segments = SearchSegment.allCases
        } else if config.entrances.contains(.wiki) {
            segments = [.workspace, .docs]
        } else {
            segments = [.folder]
            searchbarTitle = SKResource.BundleI18n.SKResource.Doc_Facade_SelectFolder
        }
    }

    func segmentView(at index: Int) -> CCMSearchFilterViewType {
        let segment = segments[index]
        switch segment {
        case .workspace:
            let viewModel = CCMWikiSpaceSimpleSearchViewModel(userResolver: userResolver, config: config)
            let view = CCMSearchSegmentPlaceHolderView(viewModel: viewModel)
            return view
        case .folder:
            let viewModel = CCMFolderSearchViewModel(userResolver: userResolver, config: config)
            let view = CCMSearchSegmentPlaceHolderView(viewModel: viewModel)
            return view
        case .docs:
            let viewModel = CCMWikiNodeSimpleSearchViewModel(userResolver: userResolver, config: config)
            let view = CCMSearchSegmentPlaceHolderView(viewModel: viewModel)
            return view
        }
    }

    func didSwitch(at index: Int) {
        let segment = segments[index]
        switch segment {
        case .workspace:
            defaultView?.switchProvider(by: Self.workspaceRecommendProviderKey)
        case .folder, .docs:
            defaultView?.switchProvider()
        }
        defaultView?.reload()
    }
}

class CCMSimpleSearchBaseViewModel: CCMSearchSegmentPlaceHolderViewModelType {
    let actionInput = PublishRelay<CCMSearchAction>()
    var actionSignal: Signal<CCMSearchAction> { actionInput.asSignal() }

    let config: WorkspacePickerConfig
    let userResolver: UserResolver

    init(userResolver: UserResolver, config: WorkspacePickerConfig) {
        self.userResolver = userResolver
        self.config = config
    }

    func generateSearchConfig() -> PickerSearchConfig {
        PickerSearchConfig(entities: [])
    }

    func pickerDidFinish(pickerVc: SearchPickerControllerType, items: [PickerItem]) -> Bool {
        return false
    }
}

// 知识空间搜索
class CCMWikiSpaceSimpleSearchViewModel: CCMSimpleSearchBaseViewModel {

    override func generateSearchConfig() -> PickerSearchConfig {
        PickerSearchConfig(entities: [
            PickerConfig.WikiSpaceEntityConfig()
        ])
    }

    override func pickerDidFinish(pickerVc: SearchPickerControllerType, items: [PickerItem]) -> Bool {
        guard let item = items.first else {
            DocsLogger.error("wiki space picker did finish without item")
            return false
        }
        guard case let .wikiSpace(meta) = item.meta,
              let wikiSpaceMeta = meta.meta else {
            DocsLogger.error("un-expected item meta type found: \(item.meta.type)")
            return false
        }
        
        guard let provider = try? userResolver.resolve(assert: WikiPickerProvider.self) else {
            DocsLogger.error("can not get provider")
            return false
        }

        let vc = provider.createTreePicker(wikiToken: nil,
                                           spaceID: wikiSpaceMeta.spaceID,
                                           spaceName: wikiSpaceMeta.spaceName,
                                           config: config)
        actionInput.accept(.push(controller: vc))
        return false
    }
}

// 文件夹搜索
class CCMFolderSearchViewModel: CCMSimpleSearchBaseViewModel {

    override func generateSearchConfig() -> PickerSearchConfig {
        PickerSearchConfig(entities: [
            PickerConfig.DocEntityConfig(types: [.folder],
                                         searchContentTypes: [.onlyTitle])
        ])
    }

    override func pickerDidFinish(pickerVc: SearchPickerControllerType, items: [PickerItem]) -> Bool {
        guard let item = items.first else {
            DocsLogger.error("folder picker did finish without item")
            return false
        }
        guard case let .doc(docMeta) = item.meta, let meta = docMeta.meta else {
            DocsLogger.error("un-expect type: \(item.meta.type) found in folder filter picker delegate")
            return false
        }
        guard case .folder = meta.type else {
            DocsLogger.error("un-expect doc type: \(meta.type) found in folder filter picker delegate")
            return false
        }

        let folderType = FolderType(ownerType: singleContainerOwnerTypeValue, shareVersion: nil, isShared: meta.isShareFolder)
        let folderEntry = FolderEntry(type: .folder, nodeToken: meta.id, objToken: meta.id)
        folderEntry.updateName(docMeta.title)
        folderEntry.updateFolderType(folderType)

        let completion = config.completion
        let callback: DirectoryUtilCallback = { location, picker in
            completion(.folder(location: location.folderPickerLocation), picker)
        }
        let context = DirectoryUtilContext(action: .callback(completion: callback),
                                           desFile: folderEntry,
                                           desType: .subFolder(folderType: folderEntry.folderType),
                                           ownerTypeChecker: config.ownerTypeChecker,
                                           pickerConfig: config,
                                           targetModule: .space)
        context.actionName = config.actionName

        let vc = DirectoryUtilController(context: context)
        vc.navigationBar.title = folderEntry.name

        actionInput.accept(.push(controller: vc))

        return false
    }
}

// Wiki节点搜索(不含过滤组件)
class CCMWikiNodeSimpleSearchViewModel: CCMSimpleSearchBaseViewModel {

    override func generateSearchConfig() -> PickerSearchConfig {
        PickerSearchConfig(entities: [
            PickerConfig.WikiEntityConfig(belongUser: .all,
                                          belongChat: .all,
                                          types: Basic_V1_Doc.TypeEnum.allCases,
                                          spaceIds: [])
        ])
    }

    override func pickerDidFinish(pickerVc: SearchPickerControllerType, items: [PickerItem]) -> Bool {
        guard let item = items.first else {
            DocsLogger.error("wiki space picker did finish without item")
            return false
        }
        guard case let .wiki(meta) = item.meta,
              let wikiMeta = meta.meta else {
            DocsLogger.error("un-expected item meta type found: \(item.meta.type)")
            return false
        }
        
        guard let provider = try? userResolver.resolve(assert: WikiPickerProvider.self) else {
            DocsLogger.error("can not get provider")
            return false
        }

        let vc = provider.createTreePicker(wikiToken: wikiMeta.token,
                                          spaceID: String(wikiMeta.spaceID),
                                          spaceName: wikiMeta.spaceName,
                                          config: config)
        actionInput.accept(.push(controller: vc))
        return false
    }
}

#endif
