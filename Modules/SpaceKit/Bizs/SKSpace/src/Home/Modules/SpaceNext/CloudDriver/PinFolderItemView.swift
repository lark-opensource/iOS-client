//
//  PinFolderItemView.swift
//  SKSpace
//
//  Created by majie.7 on 2023/12/11.
//

import Foundation
import UniverseDesignColor
import UniverseDesignIcon
import SKCommon
import LarkDocsIcon
import LarkContainer
import SKResource
import RxSwift
import SKUIKit
import SnapKit

class PinFolderItemView: UIControl {
    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = UDColor.textTitle
        label.textAlignment = .left
        label.numberOfLines = 1
        return label
    }()
    
    private lazy var moreButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.moreOutlined, for: .normal)
        button.isHidden = !isShowInDetail
        button.docs.addStandardHighlight()
        return button
    }()
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                backgroundColor = UDColor.fillPressed
            } else {
                backgroundColor = .clear
            }
        }
    }

    private var hoverGesture: UIGestureRecognizer?
    private let bag = DisposeBag()
    
    var clickHandler: (() -> Void)?
    var moreHandler: ((UIView) -> Void)?
    private var titleLabelConstraints: Constraint?
    
    let isShowInDetail: Bool
    
    init(isShowInDetail: Bool) {
        self.isShowInDetail = isShowInDetail
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(moreButton)
        
        iconView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(12)
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualToSuperview().inset(16)
            titleLabelConstraints = make.right.lessThanOrEqualTo(moreButton.snp.left).offset(-4).priority(.required).constraint
            titleLabelConstraints?.deactivate()
        }
        
        moreButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(16)
            make.width.height.equalTo(16)
        }
        
        if isShowInDetail {
            titleLabelConstraints?.activate()
        } else {
            titleLabelConstraints?.deactivate()
        }
        
        self.layer.cornerRadius = 8
        self.layer.borderWidth = 1
        self.layer.ud.setBorderColor(UDColor.lineBorderCard)
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didClick)))
        
        if #available(iOS 13.0, *) {
            setupHoverInteraction()
        }
        bindMoreButtonAction()
    }
    
    // nolint: duplicated_code
    private func setupIcon(item: SpaceListItem) {
        switch item.listIconType {
        case let .thumbIcon(thumbInfo):
            iconView.layer.cornerRadius = 6
            iconView.di.setCustomDocsIcon(model: thumbInfo,
                                          container: ContainerInfo(isShortCut: item.isShortCut),
                                          errorImage: BundleResources.SKResource.Space.FileList.Grid.grid_cell_fail)
        case .icon:
            iconView.di.setDocsImage(iconInfo: item.entry.iconInfo ?? "",
                                     token: item.entry.realToken,
                                     type: item.entry.realType,
                                     shape: .SQUARE,
                                     container: ContainerInfo(isShortCut: item.isShortCut,
                                                                   isShareFolder: item.entry.isShareFolder),
                                     userResolver: Container.shared.getCurrentUserResolver())
        default:
            iconView.di.setDocsImage(iconInfo: item.entry.iconInfo ?? "",
                                     token: item.entry.realToken,
                                     type: item.entry.realType,
                                     container: ContainerInfo(isShortCut: item.isShortCut,
                                                              isShareFolder: item.entry.isShareFolder),
                                     userResolver: Container.shared.getCurrentUserResolver())
        }
    }
    
    func update(item: SpaceListItem) {
        alpha = item.enable ? 1 : 0.3
        titleLabel.text = item.title
        setupIcon(item: item)
    }
    
    @objc
    private func didClick() {
        self.clickHandler?()
    }
    
    // nolint: duplicated_code
    @available(iOS 13.0, *)
    private func setupHoverInteraction() {
        guard SKDisplay.pad else { return }
        let gesture = UIHoverGestureRecognizer()
        gesture.rx.event.subscribe(onNext: { [weak self] gesture in
            guard let self else { return }
            switch gesture.state {
            case .began, .changed:
                if !self.isHighlighted {
                    self.backgroundColor = UDColor.fillHover
                }
            case .ended, .cancelled:
                if !self.isHighlighted {
                    self.backgroundColor = .clear
                }
            default:
                break
            }
        })
        .disposed(by: bag)
        hoverGesture = gesture
        addGestureRecognizer(gesture)
    }
    
    private func bindMoreButtonAction() {
        moreButton.rx.tap.subscribe(onNext: { [weak self, weak moreButton] _ in
            guard let moreButton else { return }
            self?.moreHandler?(moreButton)
        })
        .disposed(by: bag)
    }
}


class PinFolderGridView: UIView {
    
    private lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.distribution = .fillEqually
        view.alignment = .fill
        view.spacing = 12
        return view
    }()
    
    var clickHandler: ((Int) -> Void)?
    var moreHandler: ((SpaceListItem, UIView) -> Void)?
    
    private let isShowInDetail: Bool
    
    private var maxCount: Int {
        let ipadMaxCount = 3
        let phoneMaxCount = 2
        return isShowInDetail ? ipadMaxCount : phoneMaxCount
    }
    
    private var stackViewHeight: CGFloat {
        let ipadHeight: CGFloat = 64
        let phoneHeight: CGFloat = 48
        return isShowInDetail ? ipadHeight : phoneHeight
    }
    
    init(isShowInDetail: Bool = false) {
        self.isShowInDetail = isShowInDetail
        
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(stackViewHeight)
        }
    }
    
    private func removeAllSubViewFromStackView() {
        stackView.arrangedSubviews.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }
    
    func update(items: [SpaceListItem]) {
        removeAllSubViewFromStackView()
        
        for (index, item) in items.enumerated() {
            let itemview = PinFolderItemView(isShowInDetail: isShowInDetail)
            itemview.update(item: item)
            
            itemview.clickHandler = { [weak self] in
                self?.clickHandler?(index)
            }
            itemview.moreHandler = { [weak self] view in
                self?.moreHandler?(item, view)
            }
            stackView.addArrangedSubview(itemview)
        }
        
        if items.count < maxCount {
            let needChargeCount = maxCount - items.count
            for _ in 0..<needChargeCount {
                let emptyView = UIView()
                stackView.addArrangedSubview(emptyView)
            }
        }
    }
}
