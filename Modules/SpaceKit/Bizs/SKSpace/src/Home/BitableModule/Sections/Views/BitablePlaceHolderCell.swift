//
//  BitablePlaceHolderCell.swift
//  SKSpace
//
//  Created by ByteDance on 2023/10/29.
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
import SpaceInterface
import SKInfra


enum BitablePlaceHolderCellStyle {
    case loading
    case normalEmpty
    case hasCreateButonEmpty
    case error
}

protocol BitablePlaceHolderCellDelegate: AnyObject {
    func shouldForbibbdenPlaceHolderCellSnapShot() -> Bool
}
class BitablePlaceHolderCell: UICollectionViewCell {
    //MARK: 共有属性
    // 是否是全屏模式
    var isShowInFullScreen: Bool = false
    weak var snapDelegate: BitablePlaceHolderCellDelegate?
    
    
    //MARK: 私有属性
    private lazy var loadingView: BitableListLoadingView = {
        let loadingView = BitableListLoadingView()
        return loadingView
    }()

    private lazy var emptyView: BitableMultiListEmptyView = {
        let emptyView = BitableMultiListEmptyView.init()
        return emptyView
    }()
    
    private lazy var errorView: BitableMultiListErrorView = {
        let errorView = BitableMultiListErrorView.init()
        return errorView
    }()
    
    private var reuseBag = DisposeBag()

    //MARK: lifeCycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        reuseBag = DisposeBag()
    }
    
    override func snapshotView(afterScreenUpdates afterUpdates: Bool) -> UIView? {
        guard let delegate = self.snapDelegate, delegate.shouldForbibbdenPlaceHolderCellSnapShot() else {
            let shotView = super.snapshotView(afterScreenUpdates: afterUpdates)
            return shotView
        }
        return nil
    }

    //MARK: UI
    private func setupUI() {
        contentView.backgroundColor = UDColor.rgb("#FCFCFD") & UDColor.rgb("#202020")
        contentView.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.addSubview(emptyView)
        contentView.addSubview(errorView)
    }

    func update(type: SpaceListSubSectionPlaceHolderType, module: PageModule? = nil) {
        switch type {
        case .loading:
            emptyView.isHidden = true
            errorView.isHidden = true
            loadingView.isHidden = false
            loadingView.startLoading()
        case .networkUnavailable:
            emptyView.isHidden = true
            errorView.isHidden = false
            loadingView.stopLoading()
            loadingView.isHidden = true
            errorView.update(title: BundleI18n.SKResource.Doc_Facade_OfflineDocListInvisitable, clickCompletion: nil)
            updateErrorViewConstraints()
        case let .emptyList(description, _, createEnable, createTitle, createHandler):
            emptyView.isHidden = false
            errorView.isHidden = true
            loadingView.stopLoading()
            loadingView.isHidden = true
            createEnable.subscribe(onNext: { [weak self] (isShown) in
                guard let self = self else { return }
                if isShown {
                    self.emptyView.update(style: .hasCreateButton, title: description, createTitle: createTitle, createCompletion: createHandler)
                } else {
                    self.emptyView.update(style: .normal, title: description, createTitle: nil, createCompletion: nil)
                }
            }).disposed(by: reuseBag)
             updateEmptyViewConstraints()
        case let .failure(description, clickHandler):
            emptyView.isHidden = true
            errorView.isHidden = false
            loadingView.stopLoading()
            loadingView.isHidden = true
            errorView.update(title: description, clickCompletion: clickHandler)
            updateErrorViewConstraints()
        }
    }
    
    func updateEmptyViewConstraints() {
        if isShowInFullScreen {
            self.emptyView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(148)
                make.left.right.equalToSuperview()
            }
        } else {
            emptyView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(44)
                make.left.right.equalToSuperview()
            }
        }
    }
    
    func updateErrorViewConstraints() {
        if isShowInFullScreen {
            errorView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(148)
                make.left.right.equalToSuperview()
            }
        } else {
            errorView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(44)
                make.left.right.equalToSuperview()
            }
        }
    }
    
    func stopLoading() {
        if !loadingView.isHidden {
            loadingView.stopLoading()
            loadingView.isHidden = true
        }
    }
}
