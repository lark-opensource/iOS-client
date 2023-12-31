//
//  DocsCoverService.swift
//  SpaceKit
//
//  Created by lizechuang on 2020/2/4.
//

import Foundation
import SKCommon
import SKFoundation
import SKUIKit
import RxSwift
import LarkUIKit

class DocsCoverService: BaseJSService {

    private lazy var viewModel: CoverSelectPanelViewModel? = {
        guard let docsInfo = hostDocsInfo else {
            return nil
        }
        let provider = OfficialCoverPhotosProvider()
        return CoverSelectPanelViewModel(netWorkAPI: provider,
                                         sourceDocumentInfo: (docsInfo.objToken, docsInfo.type.rawValue),
                                         selectCoverInfo: nil,
                                         model: self.model)
    }()

    var bag: DisposeBag?

    private var officialSeries: OfficialCoverPhotosSeries?
    
    override init(ui: BrowserUIConfig,
                  model: BrowserModelConfig,
                  navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
    }
}

extension DocsCoverService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.showSelectCoverPanel]
    }
    public func handle(params: [String: Any], serviceName: String) {
        if serviceName == DocsJSService.showSelectCoverPanel.rawValue {
            showSelectCoverPanel(params: params)
        }
    }

    private func showSelectCoverPanel(params: [String: Any]) {
        guard let token = params["token"] as? String, let type = params["type"] as? Int else {
            //这里随机封面会导致webview起焦点弹起键盘，resign处理
            model?.jsEngine.editorView.resignFirstResponder()
            randomSelectPublicCoverPhoto(params: params)
            return
        }
        guard let viewModel = viewModel else { return }
        viewModel.selectCoverInfo = (token, type)

        let vc = CoverSelectPanelViewController(viewModel: viewModel)
        if SKDisplay.pad,
            ui?.editorView.isMyWindowRegularSize() ?? false {
            vc.modalPresentationStyle = .formSheet
            let nav = LkNavigationController(rootViewController: vc)
            navigator?.presentViewController(nav, animated: true, completion: nil)
        } else {
            vc.modalPresentationStyle = .overFullScreen
            let nav = LkNavigationController(rootViewController: vc)
            navigator?.presentViewController(nav, animated: true, completion: nil)
        }
    }

    private func randomSelectPublicCoverPhoto(params: [String: Any]) {
        guard let viewModel = viewModel else { return }
        if let series = self.officialSeries, series.count > 0 {
            viewModel.input.autoRandomSelectOfficialCoverPhoto.onNext(series)
        } else {
            let curBag = DisposeBag()
            viewModel.output.initialDataDriver.drive(onNext: {[weak self] (series) in
                guard let self = self else { return }
                self.officialSeries = series
                self.viewModel?.input.autoRandomSelectOfficialCoverPhoto.onNext(self.officialSeries)
                // 请求完即可移除监听
                self.bag = nil
            }).disposed(by: curBag)
            self.bag = curBag
            viewModel.input.initialize.accept(())
        }
    }
}
