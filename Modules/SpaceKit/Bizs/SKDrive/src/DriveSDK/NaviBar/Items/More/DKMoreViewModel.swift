//
//  DKMoreViewModel.swift
//  SpaceKit
//
//  Created by Weston Wu on 2020/6/16.
//

import Foundation
import EENavigator
import RxSwift
import RxRelay
import SpaceInterface
import SKUIKit
import SKCommon
import UniverseDesignBadge
import UniverseDesignIcon
import LarkDocsIcon

enum DKNaviBarBodyType {
    case unknown
    case more
}

class DKNaviBarBody: PlainBody {

    var sourceView: UIView?
    var sourceRect: CGRect?

    var bodyType: DKNaviBarBodyType {
        .unknown
    }

    static let pattern: String = "client://spacekit/drivesdk/navibar"
}

class DKNaviBarMoreBody: DKNaviBarBody {

    override var bodyType: DKNaviBarBodyType {
        .more
    }

    let items: [DKMoreItem]
    let saveState: DKSaveToSpaceState

    init(items: [DKMoreItem], saveState: DKSaveToSpaceState) {
        self.items = items
        self.saveState = saveState
    }
}

enum DriveSDKMoreType: Equatable {
    case openWithOtherApp
    case saveToSpace
    case loopupInChat
    case forward
    case forwardToChat // 邮箱附件使用的转发到聊天消息
    case saveToFile // 保存带file
    case saveToAlbum
    case importAsOnlineFile(fileType: DriveFileType)
    case saveToLocal // 保存到本地
    case cancel
    case customUserDefine//用户自定义操作
}

enum DKMoreItemState {
    case normal // 正常状态
    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    case deny // admin管控不能使用的能力
    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    case fileDeny // 条件访问控制不能使用的能力
    /// 适配新的 PermissionSDK 架构改造场景
    case forbidden
}

struct DKMoreItem {
    let type: DriveSDKMoreType
    let itemState: DKMoreItemState
    let handler: (UIView?, CGRect?) -> Void
    let text: String
    let textColor: UIColor?
    init(type: DriveSDKMoreType,
         itemState: DKMoreItemState = .normal,
         text: String = "",
         textColor: UIColor? = nil,
         handler: @escaping (UIView?, CGRect?) -> Void) {
        self.type = type
        self.itemState = itemState
        self.text = text
        self.handler = handler
        self.textColor = textColor
    }
}

protocol DKMoreViewModelDependency {
    var moreVisable: Observable<Bool> { get }
    var moreEnable: Observable<Bool> { get }
    var isReachable: Observable<Bool> { get }
    var saveToSpaceState: Observable<DKSaveToSpaceState> { get }
}

class DKMoreViewModel {
    typealias Dependency = DKMoreViewModelDependency
    var badgeStyle: UDBadgeConfig?
    // DKNaviBarItem 被点击时触发(目前仅用于埋点上报)
    var itemDidClickAction: (() -> Void)?
    
    private let saveStateRelay = BehaviorRelay<DKSaveToSpaceState>(value: .unsave)
    var currentSaveState: DKSaveToSpaceState { saveStateRelay.value }

    let moreEnableRelay = BehaviorRelay<Bool>(value: false)
    let moreVisableRelay: BehaviorRelay<Bool>
    let moreType: DKMoreItemType

    private let disposeBag = DisposeBag()

    init(dependency: Dependency, moreType: DKMoreItemType) {
        self.moreType = moreType
        switch moreType {
        case let .attach(moreItems):
            moreVisableRelay = BehaviorRelay<Bool>(value: !moreItems.isEmpty)
            dependency.saveToSpaceState.bind(to: saveStateRelay).disposed(by: disposeBag)
            // 仅当 moreItems 不为空的时候，才需要判断网络、外部的控制
            if !moreItems.isEmpty {
                dependency.moreVisable.bind(to: moreVisableRelay).disposed(by: disposeBag)
                Observable<Bool>.combineLatest(dependency.moreEnable, dependency.isReachable) { $0 && $1 }
                    .bind(to: moreEnableRelay)
                    .disposed(by: disposeBag)
            }
        case .space:
            moreVisableRelay = BehaviorRelay<Bool>(value: true)
            dependency.moreVisable.bind(to: moreVisableRelay).disposed(by: disposeBag)
            Observable<Bool>.combineLatest(dependency.moreEnable, dependency.isReachable) { $0 && $1 }
                .bind(to: moreEnableRelay)
                .disposed(by: disposeBag)
        }
    }
}

extension DKMoreViewModel: DKNaviBarItem {
    
    var naviBarButtonID: SKNavigationBar.ButtonIdentifier {
        .more
    }

    var itemIcon: UIImage {
        UDIcon.moreOutlined
    }

    var itemVisable: BehaviorRelay<Bool> {
        moreVisableRelay
    }

    var itemEnabled: BehaviorRelay<Bool> {
        moreEnableRelay
    }

    var isHighLighted: Bool {
        false
    }
    
    func itemDidClicked() -> Action {
        itemDidClickAction?()
        switch moreType {
        case let .attach(moreItems):
            let body = DKNaviBarMoreBody(items: moreItems, saveState: currentSaveState)
            return .present(body: body)
        case .space:
            return .presentSpaceMoreVC
        }
    }
}
