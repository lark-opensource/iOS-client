//
//  CCMSearchFilterItemView.swift
//  CCMMod
//
//  Created by Weston Wu on 2023/5/17.
//

import UIKit
import SnapKit
import UniverseDesignIcon
import UniverseDesignColor
import RxSwift
import RxCocoa
import SKFoundation
import SKResource
import SKUIKit

class CCMSearchFilterItemView: UIControl {

    lazy var stackView: UIStackView = {
        let view = PassThroughStackView()
        view.axis = .horizontal
        view.distribution = .fill
        view.alignment = .center
        view.spacing = 4
        return view
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Default Title"
        label.textColor = UDColor.textTitle
        label.font = .systemFont(ofSize: 14)
        return label
    }()

    lazy var iconButton: UIButton = {
        let view = UIButton()
        view.setImage(UDIcon.closeBoldOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        view.setImage(UDIcon.expandDownFilled.withRenderingMode(.alwaysTemplate), for: .disabled)
        view.imageView?.contentMode = .scaleAspectFit
        view.imageView?.tintColor = UDColor.iconN2
        view.isUserInteractionEnabled = false
        view.isEnabled = false
        return view
    }()

    let disposeBag = DisposeBag()
    let activeRelay = BehaviorRelay<Bool>(value: false)
    var activeUpdated: Driver<Bool> { activeRelay.asDriver() }
    var isActive: Bool { activeRelay.value }

    var didClickReset: ControlEvent<Void> { iconButton.rx.tap }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    func setupUI() {
        backgroundColor = UDColor.bgFiller
        layer.cornerRadius = 4

        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(12)
        }
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(iconButton)
        iconButton.snp.makeConstraints { make in
            make.width.equalTo(12)
            make.top.bottom.equalToSuperview()
        }

        activeRelay
            .asDriver()
            .distinctUntilChanged()
            .drive(onNext: { [weak self] isActive in
                self?.update(isActive: isActive)
            })
            .disposed(by: disposeBag)
    }

    fileprivate func update(isActive: Bool) {
        if isActive {
            backgroundColor = UDColor.fillSelected
            titleLabel.textColor = UDColor.primaryPri500
            iconButton.isEnabled = true
            iconButton.isUserInteractionEnabled = true
            iconButton.imageView?.tintColor = UDColor.primaryPri500
        } else {
            backgroundColor = UDColor.bgFiller
            titleLabel.textColor = UDColor.textTitle
            iconButton.isEnabled = false
            iconButton.isUserInteractionEnabled = false
            iconButton.imageView?.tintColor = UDColor.iconN2
        }
    }

    func reset() {
        activeRelay.accept(false)
    }
}

// 归我所有
class CCMSearchOwnedFilterItemView: CCMSearchFilterItemView {
    override func setupUI() {
        super.setupUI()
        iconButton.isHidden = true
        titleLabel.text = SKResource.BundleI18n.SKResource.Doc_Search_MyContent
    }
}

class CCMSearchTypeFilterItemView: CCMSearchFilterItemView {

    let selectionsRelay = BehaviorRelay<[CCMTypeFilterOption]>(value: [])
    var selections: [CCMTypeFilterOption] {
        selectionsRelay.value
    }

    override func setupUI() {
        super.setupUI()
        selectionsRelay.asDriver()
            .map { !$0.isEmpty }
            .drive(activeRelay)
            .disposed(by: disposeBag)

        selectionsRelay.asDriver().drive { [weak self] selections in
            self?.update(selections: selections)
        }
        .disposed(by: disposeBag)
    }

    private func update(selections: [CCMTypeFilterOption]) {
        if selections.isEmpty {
            titleLabel.text = SKResource.BundleI18n.SKResource.Doc_Search_Type
        } else {
            titleLabel.text = SKResource.BundleI18n.SKResource.Doc_Search_Type + "(\(selections.count))"
        }
    }

    override func reset() {
        super.reset()
        selectionsRelay.accept([])
    }
}

class CCMSearchEntityFilterItemView<T>: CCMSearchFilterItemView {
    fileprivate lazy var entityIconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        return view
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.primaryPri500
        label.font = .systemFont(ofSize: 14)
        return label
    }()

    let selectionsRelay = BehaviorRelay<[T]>(value: [])
    var selections: [T] {
        selectionsRelay.value
    }

    override func setupUI() {
        super.setupUI()

        // 插入到 iconView 前
        let index = max(stackView.arrangedSubviews.count - 1, 0)
        stackView.insertArrangedSubview(entityIconView, at: index)
        entityIconView.snp.makeConstraints { make in
            make.width.height.equalTo(16)
        }
        stackView.insertArrangedSubview(subtitleLabel, at: index + 1)

        selectionsRelay.asDriver()
            .map { !$0.isEmpty }
            .drive(activeRelay)
            .disposed(by: disposeBag)

        selectionsRelay.asDriver().drive { [weak self] selections in
            self?.update(selections: selections)
        }
        .disposed(by: disposeBag)
    }

    private func update(selections: [T]) {
        titleLabel.text = getTitle(for: selections)
        if let first = selections.first {
            entityIconView.isHidden = false
            updateEntityIcon(for: first)
            if selections.count > 1 {
                subtitleLabel.isHidden = false
                subtitleLabel.text = SKResource.BundleI18n.SKResource.LarkCCM_CM_Search_FileAndNum_Placeholder("", selections.count - 1)
            } else {
                subtitleLabel.isHidden = true
            }
        } else {
            entityIconView.isHidden = true
            subtitleLabel.isHidden = true
        }
    }

    func getTitle(for selections: [T]) -> String? {
        return nil
    }

    func updateEntityIcon(for entity: T) {
    }

    override func reset() {
        super.reset()
        selectionsRelay.accept([])
    }
}

struct CCMSearchFolderInfo {
    let token: String
    let name: String
    let isShareFolder: Bool
}

class CCMSearchFolderFilterItemView: CCMSearchEntityFilterItemView<CCMSearchFolderInfo> {

    typealias FolderInfo = CCMSearchFolderInfo

    override func getTitle(for selections: [FolderInfo]) -> String? {
        guard let first = selections.first else {
            return SKResource.BundleI18n.SKResource.LarkCCM_CM_Search_InFolder_Option
        }
        return first.name
    }

    override func updateEntityIcon(for entity: CCMSearchFolderInfo) {
        if entity.isShareFolder {
            entityIconView.image = UDIcon.fileRoundSharefolderColorful
        } else {
            entityIconView.image = UDIcon.fileRoundFolderColorful
        }
    }
}

struct CCMSearchOwnerInfo {
    let entityID: String
    let avatarKey: String?
}

class CCMSearchOwnerFilterItemView: CCMSearchEntityFilterItemView<CCMSearchOwnerInfo> {
    typealias OwnerInfo = CCMSearchOwnerInfo

    override func setupUI() {
        super.setupUI()
        entityIconView.layer.cornerRadius = 8
    }

    override func getTitle(for selections: [OwnerInfo]) -> String? {
        return SKResource.BundleI18n.SKResource.Doc_List_SortByOwner
    }

    override func updateEntityIcon(for entity: OwnerInfo) {
        guard let avatarKey = entity.avatarKey else {
            // 没给 key，降级到兜底 icon
            entityIconView.image = SKResource.BundleResources.SKResource.Common.Collaborator.avatar_placeholder
            return
        }
        entityIconView.bt.setLarkImage(with: .avatar(key: avatarKey, entityID: entity.entityID),
                                       placeholder: SKResource.BundleResources.SKResource.Common.Collaborator.avatar_placeholder)
    }
}

class CCMSearchChatFilterItemView: CCMSearchEntityFilterItemView<CCMSearchOwnerInfo> {
    typealias ChatInfo = CCMSearchOwnerInfo

    override func setupUI() {
        super.setupUI()
        entityIconView.layer.cornerRadius = 8
    }

    override func getTitle(for selections: [ChatInfo]) -> String? {
        // 固定文案
        return SKResource.BundleI18n.SKResource.Doc_Search_SharedInChat
    }

    override func updateEntityIcon(for entity: ChatInfo) {
        guard let avatarKey = entity.avatarKey else {
            // 没给 key，降级到兜底 icon
            entityIconView.image = SKResource.BundleResources.SKResource.Common.Collaborator.avatar_placeholder
            return
        }
        entityIconView.bt.setLarkImage(with: .avatar(key: avatarKey, entityID: entity.entityID),
                                       placeholder: SKResource.BundleResources.SKResource.Common.Collaborator.avatar_placeholder)
    }
}

struct CCMSearchWikiSpaceInfo {
    let spaceID: String
    let name: String
}

class CCMSearchWikiSpaceFilterItemView: CCMSearchEntityFilterItemView<CCMSearchWikiSpaceInfo> {

    typealias WikiSpaceInfo = CCMSearchWikiSpaceInfo

    override func setupUI() {
        super.setupUI()
        entityIconView.image = UDIcon.wikibookCircleColorful
    }

    override func getTitle(for selections: [WikiSpaceInfo]) -> String? {
        guard let first = selections.first else {
            return SKResource.BundleI18n.SKResource.LarkCCM_CM_Search_InWorkspace_Placeholder
        }
        return first.name
    }
}
