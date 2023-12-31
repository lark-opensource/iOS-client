//
//  DeleteFailViewController.swift
//  SpaceKit
//
//  Created by Ryan on 2019/2/15.

import UIKit
import SKUIKit
import SnapKit
import SKResource
import RxSwift
import SKCommon
import EENavigator
import LarkUIKit
import UniverseDesignColor
import UniverseDesignIcon
import SKInfra
import LarkContainer


class IpadDeleteFailViewController: BaseViewController {
    private lazy var descLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = UDColor.textTitle
        label.numberOfLines = 0
        label.text = BundleI18n.SKResource.CreationMobile_ECM_Delete_Failed_NoPermissions_description
        return label
    }()

    private lazy var failListView: DeleteFailView = {
        let view = DeleteFailView(items: dataSource)
        return view
    }()

    lazy var doneButton: UIButton = {
        let button = UIButton()
        button.setTitle(BundleI18n.SKResource.Doc_List_Filter_Done, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.backgroundColor = UDColor.primaryContentDefault
        button.layer.cornerRadius = 6
        button.addTarget(self, action: #selector(backBarButtonItemAction), for: .touchUpInside)
        button.docs.addStandardLift()
        return button
    }()

    private let dataSource: [DeleteFailListItem]

    let userResolver: UserResolver
    
    init(userResolver: UserResolver, items: [DeleteFailListItem] = []) {
        self.userResolver = userResolver
        dataSource = items
        super.init(nibName: nil, bundle: nil)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        dismiss(animated: false, completion: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupDefaultValue()
        setupView()
    }

    func setupDefaultValue() {
        view.backgroundColor = UDColor.bgBody
        navigationBar.title = BundleI18n.SKResource.CreationMobile_ECM_Delete_Failed_NoPermissions_title
        let image = UDIcon.closeSmallOutlined
        let item = SKBarButtonItem(image: image,
                                   style: .plain,
                                   target: self,
                                   action: #selector(backBarButtonItemAction))
        item.id = .back
        navigationBar.leadingBarButtonItem = item
    }
    func setupView() {
        view.addSubview(descLabel)
        descLabel.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(16)
        }
        view.addSubview(doneButton)
        doneButton.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-12)
            make.height.equalTo(48)
        }
        view.addSubview(failListView)
        failListView.snp.makeConstraints { (make) in
            make.top.equalTo(descLabel.snp.bottom).offset(12)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(doneButton.snp.top).offset(-20)
        }
    }

    override public var canShowBackItem: Bool {
        return false
    }

    override public func backBarButtonItemAction() {
        self.dismiss(animated: true, completion: nil)
    }
}

class DeleteFailViewController: SKPanelController {
    private let dataSource: [DeleteFailListItem]
    private lazy var headerView: SKPanelHeaderView = {
        let view = SKPanelHeaderView()
        view.setTitle(BundleI18n.SKResource.CreationMobile_ECM_Delete_Failed_NoPermissions_title)
        view.setCloseButtonAction(#selector(didClickMask), target: self)
        view.backgroundColor = .clear
        return view
    }()

    private lazy var descLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = UDColor.textTitle
        label.numberOfLines = 0
        label.text = BundleI18n.SKResource.CreationMobile_ECM_Delete_Failed_NoPermissions_description
        return label
    }()

    private lazy var failListView: DeleteFailView = {
        let view = DeleteFailView(items: dataSource)
        view.delegate = self
        return view
    }()

    lazy var doneButton: UIButton = {
        let button = UIButton()
        button.setTitle(BundleI18n.SKResource.Doc_List_Filter_Done, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.backgroundColor = UDColor.primaryContentDefault
        button.layer.cornerRadius = 6
        button.addTarget(self, action: #selector(didClickMask), for: .touchUpInside)
        button.docs.addStandardLift()
        return button
    }()

    let userResolver: UserResolver
    public init(userResolver: UserResolver, items: [DeleteFailListItem] = []) {
        self.userResolver = userResolver
        self.dataSource = items
        super.init(nibName: nil, bundle: nil)
        dismissalStrategy = [.systemSizeClassChanged]
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func setupUI() {
        super.setupUI()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        containerView.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(48)
        }
        containerView.addSubview(descLabel)
        descLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(headerView.snp.bottom).offset(12)
        }
        containerView.addSubview(failListView)
        failListView.snp.makeConstraints { make in
            make.top.equalTo(descLabel.snp.bottom).offset(12)
            make.left.right.equalToSuperview()
            make.height.equalTo(DeleteFailView.CellLayout.cellHeight * CGFloat(dataSource.count))
        }

        containerView.addSubview(doneButton)
        doneButton.snp.makeConstraints { (make) in
            make.top.equalTo(failListView.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(48)
            make.bottom.equalTo(containerView.safeAreaLayoutGuide.snp.bottom).inset(12)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            guard let self = self else { return }
            self.failListView.collectionView.collectionViewLayout.invalidateLayout()
        }
    }
}

extension DeleteFailViewController: DeleteFailViewDelegate {
    var canOpenEntry: Bool {
        true
    }

    func open(entry: SKEntryBody, context: [String: Any]) {
        userResolver.navigator.docs.showDetailOrPush(body: entry, context: context, wrap: LkNavigationController.self, from: self, animated: true)
    }
}

struct DeleteFailListItem {
    typealias IconType = SpaceList.IconType
    let enable: Bool
    let title: String
    let subTitle: String?
    let isShortCut: Bool
    let listIconType: IconType
    let hasPermission: Bool
    let entry: SpaceEntry
}


protocol DeleteFailViewDelegate: AnyObject {
    var canOpenEntry: Bool { get }
    func open(entry: SKEntryBody, context: [String: Any])
}

private class DeleteFailView: UIView {
    struct CellLayout {
        static let cellHeight: CGFloat = 68
    }

    fileprivate lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .vertical
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.bounces = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(DeleteFailViewCell.self, forCellWithReuseIdentifier: DeleteFailViewCell.reuseIdentifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()

    var dataSource: [DeleteFailListItem]
    weak var delegate: DeleteFailViewDelegate?

    init(items: [DeleteFailListItem] = []) {
        self.dataSource = items
        super.init(frame: .zero)
        setupDefaultValue()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupDefaultValue() {
        addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
}

extension DeleteFailView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let tempCell = collectionView.dequeueReusableCell(withReuseIdentifier: DeleteFailViewCell.reuseIdentifier, for: indexPath)
        guard let cell = tempCell as? DeleteFailViewCell else {
            return tempCell
        }
        let item = dataSource[indexPath.row]
        cell.update(item: item)
        cell.isUserInteractionEnabled = !item.hasPermission && delegate?.canOpenEntry ?? false
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width,
                      height: CellLayout.cellHeight)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = dataSource[indexPath.row]
        guard !item.hasPermission, (delegate?.canOpenEntry ?? false) else {
            return
        }
        let entry = item.entry
        entry.fromModule = "delte_fail_list"
        FileListStatistics.curFileObjToken = entry.objToken
        FileListStatistics.curFileType = entry.type
        let body = SKEntryBody(entry)
        let context: [String: Any] = [SKEntryBody.fileEntryListKey: "delte_fail_list",
                                      SKEntryBody.fromKey: FileListStatistics.Module.sharedSpace]
        self.delegate?.open(entry: body, context: context)
    }
}

private class DeleteFailViewCell: SlideableCell {

    enum Layout {
        static let iconLeftInset = 16
        static let iconSize: CGFloat = 40
        static let cellHeight: CGFloat = 68
    }

    // 重用时清理的 bag
    private var reuseBag = DisposeBag()

    private lazy var iconView: AvatarImageView = {
        let view = AvatarImageView()
        view.backgroundColor = .clear
        view.lastingColor = .clear
        view.layer.cornerRadius = 6
        view.clipsToBounds = true
        return view
    }()

    /// shortcut
    lazy var shortCutImageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect.zero)
        imageView.contentMode = .center
        imageView.image = BundleResources.SKResource.Space.DocsType.icon_shortcut_left_bottom_tip
        return imageView
    }()
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        label.textColor = UIColor.ud.N900
        label.backgroundColor = .clear
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.ud.N500
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        contentView.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(Layout.iconSize)
            make.left.equalToSuperview().offset(Layout.iconLeftInset)
            make.centerY.equalToSuperview()
        }

        contentView.addSubview(shortCutImageView)
        shortCutImageView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 12, height: 12))
//            make.top.equalTo(container).inset(13)
            make.leading.equalTo(iconView.snp.leading)
            make.bottom.equalTo(iconView.snp.bottom)
        }

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(11)
            make.left.equalTo(iconView.snp.right).offset(12)
        }

        contentView.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-11)
            make.left.equalTo(iconView.snp.right).offset(12)
        }
    }

    private func resetLayout(by hasPermission: Bool) {
        if !hasPermission {
            titleLabel.snp.remakeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalTo(iconView.snp.right).offset(12)
            }
        } else {
            titleLabel.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(11)
                make.left.equalTo(iconView.snp.right).offset(12)
            }
        }
        subtitleLabel.isHidden = !hasPermission
    }

    func update(item: DeleteFailListItem) {
        container.alpha = item.enable ? 1 : 0.3
        titleLabel.text = item.title
        subtitleLabel.text = item.subTitle
        shortCutImageView.isHidden = !item.isShortCut
        setup(iconType: item.listIconType)
        resetLayout(by: item.hasPermission)
        shortCutImageView.isHidden = !item.isShortCut
    }
    private func setup(iconType: DeleteFailListItem.IconType) {
        switch iconType {
        case let .newIcon(data):
            iconView.set(avatarKey: data.iconKey,
                         fsUnit: data.fsUnit,
                         placeholder: data.placeHolder,
                         image: nil,
                         completion: nil)
        case let .icon(image, _):
            iconView.imageView.image = image
        case let .thumbIcon(thumbInfo):
            let processer = SpaceDefaultProcesser()
            let manager = DocsContainer.shared.resolve(SpaceThumbnailManager.self)
            let request = SpaceThumbnailManager.Request(token: thumbInfo.token,
                                                        info: thumbInfo.thumbInfo,
                                                        source: thumbInfo.source,
                                                        fileType: thumbInfo.fileType,
                                                        placeholderImage: thumbInfo.placeholder,
                                                        failureImage: thumbInfo.failedImage,
                                                        processer: processer)
            manager?.getThumbnail(request: request)
                .asDriver(onErrorJustReturn: BundleResources.SKResource.Space.FileList.Grid.grid_cell_fail)
                .drive(onNext: { [weak self] image in
                    self?.iconView.imageView.image = image
                })
                .disposed(by: reuseBag)
        }
    }
}
