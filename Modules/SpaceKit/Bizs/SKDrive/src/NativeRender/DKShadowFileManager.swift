//
//  DKShadowFileManager.swift
//  SKDrive
//
//  Created by ZhangYuanping on 2023/5/12.
//  


import SKCommon
import SKFoundation
import RxSwift
import RxCocoa
import EENavigator
import UniverseDesignToast
import SKResource
import SpaceInterface

protocol DriveShadowFileProtocol: AnyObject {
    var shadowFileVM: DriveShadowFileViewModelProtocol { get }
}

protocol DriveShadowFileViewModelProtocol: AnyObject {
    var previewAction: Observable<DKPreviewAction> { get }
    var naviBarViewModelRelay: BehaviorRelay<DKNaviBarViewModel> { get }
}

class DriveShadowFileImpl: DriveShadowFileProtocol {
    var shadowFileVM: DriveShadowFileViewModelProtocol
    weak var browserVC: BaseViewController?

    let disposeBag = DisposeBag()

    init(vc: BaseViewController, vm: DriveShadowFileViewModelProtocol) {
        self.browserVC = vc
        self.shadowFileVM = vm
        observePreviewAction()
    }

    private func observePreviewAction() {
        shadowFileVM.previewAction
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] action in
                guard let self = self else { return }
                guard let browserVC = self.browserVC else { return }
                switch action {
                case let .toast(content, type: type):
                    UDToast.docs.showMessage(content, on: browserVC.view, msgType: type)
                case .hideLoadingToast:
                    UDToast.removeToast(on: browserVC.view)
                case let .forward(handler, info):
                    handler(browserVC, info)
                case let .openDrive(token, appID):
                    let router = DKDefaultRouter()
                    router.openDrive(token: token, appID: appID, from: browserVC)
                case let .openWithOtherApp(url, sourceView, sourceRect, callback):
                    let router = DKDefaultRouter()
                    router.openWith3rdApp(filePath: url, from: browserVC,
                                          sourceView: sourceView, sourceRect: sourceRect,
                                          callback: callback)
                case let .downloadOriginFile(viewModel, isOpenWithOtherApp):
                    if CacheService.isDiskCryptoEnable() {
                        DocsLogger.driveError("[KACrypto] KA crypto enable cannot download")
                        let tip = isOpenWithOtherApp ? BundleI18n.SKResource.CreationMobile_ECM_ShareSecuritySettingKAToast
                                                     : BundleI18n.SKResource.CreationMobile_ECM_SecuritySettingKAToast
                        UDToast.showTips(with: tip, on: browserVC.view.window ?? browserVC.view)
                        return
                    }
                    let view = DKBottomBar()
                    let downloadView = DKDownloadProgressView(viewModel: viewModel)
                    view.pushItemVew(downloadView)
                    view.show(on: browserVC.view, animate: true)
                case let .importAs(convertType, actionSource, previewFrom):
                    let router = DKDefaultRouter()
                    router.pushConvertFileVC(type: convertType,
                                             actionSource: actionSource,
                                             previewFrom: previewFrom,
                                             from: browserVC)
                default:
                    break
                }
            }).disposed(by: disposeBag)
    }
}

class DriveShadowFileManger: DriveShadowFileManagerProtocol {

    static let shared = DriveShadowFileManger()
    private init() {}

    @ThreadSafe var shadowFileDict: Dictionary = [String: DriveShadowFileProtocol]()

    var fileIdParamKey: String {
        return ShadowFileURLParam.shadowFileId
    }

    func addShadowFile(id: String, shadowFile: DriveShadowFileProtocol) {
        shadowFileDict[id] = shadowFile
        DocsLogger.driveInfo("shadow file: addShadowFile id \(id), count: \(shadowFileDict.count)")
    }

    func removeShadowFile(id: String) {
        shadowFileDict.removeValue(forKey: id)
        DocsLogger.driveInfo("shadow file: remove id: \(id)")
    }

    func showMorePanel(id: String, from: UIViewController, sourceView: UIView?, sourceRect: CGRect?) {
        DocsLogger.driveInfo("shadow file: showMorePanel id \(id)")
        guard let moreItem = getMoreItem(id: id) else { return }
        guard let fromVC = from as? BaseViewController else {
            DocsLogger.driveError("shadow file: source from vc should BaseViewController")
            return
        }
        let action = moreItem.itemDidClicked()
        if case let .present(body) = action {
            if let popOverInfo = fromVC.obtainPopoverInfo(at: -1) {
                body.sourceView = popOverInfo.sourceView
                body.sourceRect = popOverInfo.sourceFrame
            }
            Navigator.shared.present(body: body, from: fromVC, animated: true, completion: nil)
        }
    }

    func getMoreItemState(id: String) -> (enabled: BehaviorRelay<Bool>, visable: BehaviorRelay<Bool>) {
        guard let moreItem = getMoreItem(id: id) else {
            return (BehaviorRelay(value: false), BehaviorRelay(value: false))
        }
        return (moreItem.itemEnabled, moreItem.itemVisable)
    }

    func getMoreItem(id: String) -> DKNaviBarItem? {
        guard let shadowFile = shadowFileDict[id] else {
            DocsLogger.driveError("shadow file: cant not find shadow drive file")
            return nil
        }
        let rightBarItems = shadowFile.shadowFileVM.naviBarViewModelRelay.value.rightBarItems
        let moreItem = rightBarItems.first { item in
            item.naviBarButtonID == .more
        }
        return moreItem
    }
}
