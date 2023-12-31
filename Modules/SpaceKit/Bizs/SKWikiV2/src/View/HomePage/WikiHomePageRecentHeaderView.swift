//
//  WikiHomePageRecentHeaderView.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/9/27.
//  

import UIKit
import SnapKit
import SKCommon
import SKResource
import UniverseDesignColor
import UniverseDesignIcon
import RxSwift
import RxRelay
import RxCocoa

// 全量后删除
class WikiHomePageRecentHeaderView: UIView {

    private lazy var recentLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.SKResource.Doc_Wiki_Home_RecentTitle
        label.font = UIFont.ct.systemMedium(ofSize: 16)
        label.textColor = UDColor.textTitle
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UDColor.bgBody
        addSubview(recentLabel)
        recentLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
    }
}


class WikiHomePageAllSpaceHeaderView: UICollectionReusableView {

    struct Config {
        let titleLeftInset: CGFloat
        let iconSize: CGFloat
        let iconRightInset: CGFloat

        static var compact: Config {
            Config(titleLeftInset: 16, iconSize: 18, iconRightInset: 20)
        }

        static var regular: Config {
            Config(titleLeftInset: 24, iconSize: 24, iconRightInset: 20)
        }
    }

    private var bag = DisposeBag()
    
    var clickHandler: (() -> Void)?

    private(set) lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.SKResource.LarkCCM_NewCM_Sidebar_Mobile_AllWorkspaces_Title
        label.font = UIFont.ct.systemMedium(ofSize: 16)
        label.textColor = UDColor.textTitle
        return label
    }()
    
    lazy var filterView: SpaceListFilterStateView = {
        let view = SpaceListFilterStateView()
        view.isHidden = true
        view.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -10, bottom: -8, right: -10)
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UDColor.bgBody
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(24)
            make.centerY.equalToSuperview()
        }
        
        addSubview(filterView)
        filterView.snp.makeConstraints { make in
            make.width.height.equalTo(18)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(20)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        bag = DisposeBag()
        titleLabel.text = BundleI18n.SKResource.LarkCCM_NewCM_Sidebar_Mobile_AllWorkspaces_Title
        filterView.isHidden = true
        clickHandler = nil
    }
    
    func setupFilterView(stateRelay: BehaviorRelay<SpaceListFilterState>,
                         clickEnable: Driver<Bool>,
                         showEnable: Driver<Bool>) {
        stateRelay.asDriver()
            .drive(onNext: { [weak self] newState in
                guard let self else { return }
                self.filterView.update(isActive: newState.isActive)
            })
            .disposed(by: bag)
        
        clickEnable
            .drive(filterView.rx.isEnabled)
            .disposed(by: bag)
        
        showEnable
            .map { !$0 }
            .drive(filterView.rx.isHidden)
            .disposed(by: bag)
        
        filterView.rx.controlEvent(.touchUpInside)
            .subscribe { [weak self] _ in
                // 筛选页面
                self?.clickHandler?()
            }
            .disposed(by: bag)
    }

    func update(config: Config) {
        titleLabel.snp.updateConstraints { make in
            make.left.equalToSuperview().inset(config.titleLeftInset)
            make.centerY.equalToSuperview()
        }

        addSubview(filterView)
        filterView.snp.updateConstraints { make in
            make.width.height.equalTo(config.iconSize)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(config.iconRightInset)
        }
    }
}
