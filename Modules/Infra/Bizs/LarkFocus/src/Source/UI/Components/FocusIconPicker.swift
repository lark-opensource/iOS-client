//
//  FocusIconPicker.swift
//  LarkFocus
//
//  Created by Hayden Wang on 2021/9/7.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignPopover
import UniverseDesignDatePicker
import UniverseDesignActionPanel
import LarkEmotion
import LarkContainer
import RxSwift
import LarkSDKInterface

public final class FocusIconCell: UICollectionViewCell {

    public static var identifier = "FocusIconPickerCell"

    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(32)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configure(_ image: UIImage) {
        imageView.image = image
    }

}

final class FocusIconPickerHeader: UICollectionReusableView {

    public static var identifier = "FocusIconPickerHeader"

    var title: String? {
        get { label.text }
        set { label.text = newValue }
    }

    private lazy var bgView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()

    private lazy var label: UILabel = {
        let label: UILabel = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.systemFont(ofSize: 12)
        label.sizeToFit()
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(bgView)
        bgView.addSubview(label)
        bgView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        label.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
        }
        backgroundColor = UIColor.ud.bgBody
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class FocusIconPickerController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UserResolverWrapper {

    var onSelect: ((String) -> Void)?

    @ScopedInjectedLazy var focusAPI: LarkFocusAPI?
    @ScopedInjectedLazy private var emotionService: ReactionService?
    @ScopedInjectedLazy private var focusManager: FocusManager?

    private var popoverTransition = UDPopoverTransition(sourceView: nil)

    private let disposeBag = DisposeBag()

    var selectedIconKey: String?

    private lazy var allIconKeys: [String] = {
        var reactionKeys = emotionService?.getUsedReactions() ?? []
        if reactionKeys.isEmpty {
            reactionKeys = EmotionResouce.reactions
        }
        // 筛选出未下线且存在本地图片的 emotion keys.
        return reactionKeys
            .filter({ !EmotionResouce.shared.isDeletedBy(key: $0) })
            .filter({ EmotionResouce.shared.imageBy(key: $0) != nil })
    }()

    private lazy var recommendedKeys: [String] = {
        focusManager?.dataService.recommendedIconKeys ?? emotionService?.getRecentReactions().map { $0.key } ?? []
    }()

    private var recommendedIconKeys: [String] {
        return recommendedKeys
            .filter({ !EmotionResouce.shared.isDeletedBy(key: $0) })
            .filter({ EmotionResouce.shared.imageBy(key: $0) != nil })
    }

    private lazy var flowLayout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        flowLayout.sectionHeadersPinToVisibleBounds = true
        flowLayout.minimumInteritemSpacing = 4
        flowLayout.minimumLineSpacing = 8
        flowLayout.itemSize = CGSize(width: 48, height: 48)
        return flowLayout
    }()

    private lazy var dimmingView = UIView()

    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        view.showsVerticalScrollIndicator = false
        view.backgroundColor = .clear
        view.isPagingEnabled = false
        view.scrollsToTop = false
        view.delegate = self
        view.dataSource = self
        view.register(FocusIconCell.self,
                      forCellWithReuseIdentifier: FocusIconCell.identifier)
        view.register(FocusIconPickerHeader.self,
                      forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                      withReuseIdentifier: FocusIconPickerHeader.identifier)
        view.contentInsetAdjustmentBehavior = .never
        return view
    }()

    let userResolver: UserResolver
    init(userResolver: UserResolver, sourceView: UIView) {
        self.userResolver = userResolver
        popoverTransition = UDPopoverTransition(
            sourceView: sourceView,
            permittedArrowDirections: .left
        )
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = popoverTransition
        self.preferredContentSize = CGSize(width: 375, height: 618)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        focusAPI?.getRecommendedIcons(strategy: .forceServer)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] iconKeys in
                self?.recommendedKeys = iconKeys
                self?.focusManager?.dataService.recommendedIconKeys = iconKeys
                self?.collectionView.reloadData()
            }, onError: { [weak self] error in
                debugPrint(error)
            }).disposed(by: disposeBag)
        dimmingView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapBackgroundView(_:))))
        popoverPresentationController?.backgroundColor = UIColor.ud.bgBody
    }

    private func setupSubviews() {
        view.addSubview(dimmingView)
        view.addSubview(collectionView)
        dimmingView.snp.makeConstraints { make in
            make.top.left.trailing.equalToSuperview()
            make.bottom.equalTo(collectionView.snp.top)
        }
        collectionView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.height.equalTo(618)
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide)
        }
        collectionView.backgroundColor = UIColor.ud.bgBody
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 4, bottom: 32, right: 4)
        collectionView.layer.cornerRadius = 10
        collectionView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return recommendedIconKeys.count
        } else {
            return allIconKeys.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FocusIconCell.identifier, for: indexPath) as? FocusIconCell ?? FocusIconCell()
        if indexPath.section == 0 {
            cell.imageView.image = EmotionResouce.shared.imageBy(key: recommendedIconKeys[indexPath.row]) ?? EmotionResouce.placeholder
        } else {
            cell.imageView.image = EmotionResouce.shared.imageBy(key: allIconKeys[indexPath.row]) ?? EmotionResouce.placeholder
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 42)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return .zero
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: FocusIconPickerHeader.identifier,
                for: indexPath) as? FocusIconPickerHeader ?? FocusIconPickerHeader()
            header.title = indexPath.section == 0
                ? BundleI18n.LarkFocus.Lark_Profile_RecommendUse
                : BundleI18n.LarkFocus.Lark_Profile_AllEmojis
            return header
        default:
            return UICollectionReusableView()
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            didSelectIconKey(recommendedIconKeys[indexPath.item])
        } else {
            didSelectIconKey(allIconKeys[indexPath.item])
        }
    }

    private func didSelectIconKey(_ iconKey: String) {
        onSelect?(iconKey)
        dismiss(animated: true)
    }

    @objc
    private func didTapBackgroundView(_ gesture: UITapGestureRecognizer) {
        dismiss(animated: true)
    }
}
