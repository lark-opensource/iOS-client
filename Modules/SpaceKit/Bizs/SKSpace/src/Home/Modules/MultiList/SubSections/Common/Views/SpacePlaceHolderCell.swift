//
//  SpacePlaceHolderCell.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/11.
//

import UIKit
import SKCommon
import SnapKit
import SKUIKit
import SKResource
import UniverseDesignColor
import RxSwift
import RxRelay
import RxCocoa
import UniverseDesignEmpty
import SpaceInterface
import SKInfra

class SpacePlaceHolderCell: UICollectionViewCell {
    private lazy var loadingView: DocsLoadingViewProtocol? = {
        guard let loadingView = DocsContainer.shared.resolve(DocsLoadingViewProtocol.self) else {
            assertionFailure("space.placeholoder.cell --- failed to resolve loading view")
            return nil
        }

        return loadingView
    }()

    private lazy var emptyView: UDEmptyView = {
        let emptyView = UDEmptyView(config: .init(title: .init(titleText: ""),
                                                  description: .init(descriptionText: ""),
                                                  imageSize: 100,
                                                  type: .documentDefault))
        emptyView.useCenterConstraints = true
        return emptyView
    }()

    private lazy var clickMaskView: UIControl = {
        let control = UIControl()
        control.backgroundColor = .clear
        return control
    }()

    private var reuseBag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        contentView.backgroundColor = UDColor.bgBody
        if let loadingContentView = loadingView?.displayContent {
            loadingContentView.backgroundColor = UDColor.bgBody
            contentView.addSubview(loadingContentView)
            loadingContentView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }

        contentView.addSubview(emptyView)
        emptyView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        contentView.addSubview(clickMaskView)
        clickMaskView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        loadingView?.stopAnimation()
        reuseBag = DisposeBag()
    }
    
    func stopLoading() {
        self.loadingView?.stopAnimation()
    }

    func update(type: SpaceListSubSectionPlaceHolderType, module: PageModule? = nil) {
        var config = UDEmptyConfig(type: .documentDefault)
        switch type {
        case .loading:
            emptyView.isHidden = true
            clickMaskView.isHidden = true
            loadingView?.startAnimation()
        case .networkUnavailable:
            emptyView.isHidden = false
            config.description = .init(descriptionText: BundleI18n.SKResource.Doc_Facade_OfflineDocListInvisitable)
            config.type = .noWifi
            clickMaskView.isHidden = true
            loadingView?.displayContent.isHidden = true
        case let .emptyList(description, emptyType, createEnable, createButtonTitle, createHandler):
            emptyView.isHidden = false
            config.description = .init(descriptionText: description)
            config.type = emptyType

            createEnable.subscribe(onNext: { [weak self] (isShown) in
                guard let self = self else { return }
                config.primaryButtonConfig = isShown ? (createButtonTitle, createHandler) : nil
                self.emptyView.update(config: config)
            }).disposed(by: reuseBag)

            clickMaskView.isHidden = true
            loadingView?.displayContent.isHidden = true
        case let .failure(description, clickHandler):
            emptyView.isHidden = false
            config.description = .init(descriptionText: description)
            config.type = .loadingFailure
            loadingView?.displayContent.isHidden = true
            clickMaskView.isHidden = false
            clickMaskView.rx.controlEvent(.touchUpInside)
                .subscribe(onNext: clickHandler)
                .disposed(by: reuseBag)
        }
        emptyView.update(config: config)
        if case let .baseHomePage(context) = module {
            emptyView.snp.remakeConstraints { make in
                make.left.right.equalToSuperview()
                if context.containerEnv == .workbench {
                    make.top.equalToSuperview().inset(20)
                }else{
                    make.centerY.equalToSuperview()
                }
                
            }
        }
    }
}
