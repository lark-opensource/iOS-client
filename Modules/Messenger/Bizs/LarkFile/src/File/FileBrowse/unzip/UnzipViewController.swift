//
//  UnzipViewController.swift
//  LarkFile
//
//  Created by bytedance on 2021/11/10.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import RustPB
import LarkMessengerInterface
import LarkCore
import LarkSDKInterface

final class UnzipViewController: BaseFolderBrowserViewController {
    private var isAppear = false
    let viewModel: UnzipViewModel
    private let disposeBag = DisposeBag()
    private let userGeneralSettings: UserGeneralSettings
    private lazy var loadingView: CoreLoadingView = {
        let loadingView = CoreLoadingView()
        return loadingView
    }()

    private lazy var unzipingView: UnzipingView = {
        let view = UnzipingView(userGeneralSettings: userGeneralSettings)
        view.setEmptyViewConfig(description: getDescription(baseText: BundleI18n.LarkFile.Lark_IMPreviewCompress_Decompressing_Toast,
                                                            size: viewModel.file.fileSize))
        return view
    }()

    private lazy var canNotUnzipView: CanNotUnzipView = {
        let view = CanNotUnzipView()
        return view
    }()

    private let canOpenWithOtherApp: Bool

    private lazy var unzipOverTimeView: UnzipOverTimeView = {
        let view = UnzipOverTimeView()
        view.setConfig(description: getDescription(baseText: BundleI18n.LarkFile.Lark_IMPreviewCompress_DecompressTimeOutTryAgain_Toast, size: viewModel.file.fileSize)) { [weak self] _ in
            FileTrackUtil.DecompressFail.timeOutClick()
            self?.retry()
        }
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        contentContainer.addSubview(loadingView)
        loadingView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
        }
        configViewModel()
    }

    init(viewModel: UnzipViewModel,
         displayTopContainer: Bool = false,
         canOpenWithOtherApp: Bool,
         userGeneralSettings: UserGeneralSettings) {
        self.viewModel = viewModel
        self.canOpenWithOtherApp = canOpenWithOtherApp
        self.userGeneralSettings = userGeneralSettings
        super.init(displayTopContainer: displayTopContainer)
        self.title = viewModel.file.fileName
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configViewModel() {
        loadingView.show()
        viewModel.extractPackageObservable?.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] push in
                guard let self = self else {
                    return
                }
                switch push.status {
                case .inProgress(let progress):
                    if self.viewModel.status == .loading {
                        self.viewModel.status = .inProgress
                        self.setupUnzipingView()
                    }
                    self.updateProgress(progress)
                case .success(let result):
                    self.viewModel.status = .success
                    self.successUnzip(result: result)
                case .failed(let error):
                    self.viewModel.status = .failed
                    switch error.code {
                    //解压失败（文件问题）
                    case 5657, 5658, 5659, 5660, 5661, 5662, 311_125, 311_123, 311_121:
                        self.setupCanNotUnzipView(errorMessage: error.displayMessage)
                    //解压超时
                    case 10_009:
                        self.setupUnzipOverTimeView()
                    //其他错误（也按照超时来处理）
                    default:
                        self.setupUnzipOverTimeView()
                    }
                }
            }).disposed(by: disposeBag)
        viewModel.statusChangeNotice.drive(onNext: { [weak self] _ in
            guard let self = self else {
                return
            }
            self.router?.onVCStatusChanged(self)
        }).disposed(by: disposeBag)
        viewModel.extractPackageFailCallBack = { [weak self] in
            self?.setupUnzipOverTimeView()
        }
        viewModel.extractPackange()
    }

    override func getCanOpenWithOtherApp() -> Bool {
        return canOpenWithOtherApp
    }

    override func getStyleButtonisHidden() -> Bool {
        return viewModel.status != .success
    }

    private func setupUnzipingView() {
        if unzipingView.superview == nil {
            contentContainer.addSubview(unzipingView)
            unzipingView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        unzipingView.isHidden = false
        loadingView.hide()
    }

    private func updateProgress(_ progress: Float) {
        unzipingView.setProgress(progress)
    }

    private func successUnzip(result: Media_V1_BrowseFolderResponse) {
        guard let vc = router?.buildFolderBrowserViewController(key: viewModel.file.fileKey,
                                                                name: viewModel.file.fileName,
                                                                size: viewModel.file.fileSize,
                                                                firstScreenData: result) else { return }
        addChild(vc)
        contentContainer.addSubview(vc.view)
        vc.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        unzipingView.isHidden = true
        loadingView.hide()
    }

    private func setupCanNotUnzipView(errorMessage: String) {
        FileTrackUtil.DecompressFail.notSupportView()
        if canNotUnzipView.superview == nil {
            self.contentContainer.addSubview(canNotUnzipView)
            canNotUnzipView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        canNotUnzipView.setConfig(description: getDescription(baseText: errorMessage, size: viewModel.file.fileSize)) { [weak self] _ in
            FileTrackUtil.DecompressFail.notSupportClick()
            self?.openWithOtherApp()
        }
        canNotUnzipView.isHidden = false
        unzipingView.isHidden = true
        loadingView.hide()
    }

    func openWithOtherApp() {
        if canOpenWithOtherApp {
            router?.openWithOtherApp()
        }
    }

    private func setupUnzipOverTimeView() {
        FileTrackUtil.DecompressFail.timeOutView()
        if unzipOverTimeView.superview == nil {
            self.contentContainer.addSubview(unzipOverTimeView)
            unzipOverTimeView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        unzipOverTimeView.isHidden = false
        unzipingView.isHidden = true
        loadingView.hide()
    }
    private func retry() {
        unzipOverTimeView.isHidden = true
        loadingView.show()
        viewModel.extractPackange()
    }

    private func getDescription(baseText: String, size: Int64) -> String {
        return "\(baseText)\n\(FileDisplayInfoUtil.sizeStringFromSize(size))"
    }
}

extension UnzipViewController: HierarchyFolderInfoProtocol {
    var copyType: ForwardCopyFromFolderMessageBody.CopyType {
        return .file
    }

    var key: String {
        return self.viewModel.file.fileKey
    }

    var name: String {
        return self.viewModel.file.fileName
    }

    var size: Int64 {
        return self.viewModel.file.fileSize
    }
}
