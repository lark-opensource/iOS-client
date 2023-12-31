//
//  EventEditAttendeeView.swift
//  Calendar
//
//  Created by 张威 on 2020/2/18.
//

import UniverseDesignIcon
import UniverseDesignColor
import UIKit
import SnapKit
import CalendarFoundation
import RxSwift
import RxCocoa
import LarkBizAvatar
import LarkActivityIndicatorView

protocol EventEditAttendeeViewDataType {
    var avatars: [Avatar] { get }
    var countStr: String { get }
    var isVisible: Bool { get }
    var enableAdd: Bool { get }
    var isLoading: Bool { get }
    var shouldShowAIStyle: Bool { get }
}

final class EventEditAttendeeView: EventEditCellLikeView, ViewDataConvertible {

    var viewData: EventEditAttendeeViewDataType? {
        didSet {
            let avatars = viewData?.avatars ?? []
            let enableAdd = viewData?.enableAdd ?? false
            let isLoading = viewData?.isLoading ?? false

            if avatars.isEmpty {
                content = .customView(emptyAttendeeContentView)
                accessory = .none
                emptyAttendeeContentView.isLoading = isLoading
            } else {
                if let shouldShowAIStyle = viewData?.shouldShowAIStyle, shouldShowAIStyle {
                    addFooterButton.isHidden = true
                } else {
                    addFooterButton.isHidden = !(viewData?.enableAdd ?? false)
                }
                content = .customView(attendeesContentView)
                accessory = enableAdd ? .type(.next()) : .none
                attendeesContentView.isLoading = isLoading

                attendeesContentView.countStr = viewData?.countStr
                attendeesContentView.collectionView.reloadData()
            }
            icon = .customImageWithoutN3(enableAdd ? iconImage : iconImageDisabled)
            isHidden = !(viewData?.isVisible ?? false)
            
            if let shouldShowAIStyle = viewData?.shouldShowAIStyle {
                layoutAIBackGround(shouldShowAIBg: shouldShowAIStyle, customRight: 7)
            }
        }
    }

    var addHandler: (() -> Void)?
    var clickHandler: (() -> Void)?

    private lazy var emptyAttendeeContentView: EmptyAttendeeContentView = {
        let contentView = EmptyAttendeeContentView()
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleAddAttendee))
        contentView.addGestureRecognizer(tap)
        return contentView
    }()

    private lazy var attendeesContentView: AttendeesContentView = {
        let contentView = AttendeesContentView()
        contentView.collectionView.register(
            AttendeeCell.self,
            forCellWithReuseIdentifier: String(describing: Self.self)
        )
        contentView.collectionView.register(
            UICollectionReusableView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: String(describing: Self.self)
        )
        contentView.collectionView.dataSource = self
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapCollectionView))
        contentView.addGestureRecognizer(tap)
        return contentView
    }()

    private lazy var counterLabel: UILabel = {
        let label = UILabel()
        label.textColor = EventEditUIStyle.Color.normalGrayText
        label.font = EventEditUIStyle.Font.smallText
        label.isHidden = true
        return label
    }()

    private lazy var addFooterButton: UIButton = {
        let button = UIButton()
        let imageView = UIImageView(image: UDIcon.getIconByKeyNoLimitSize(.addOutlined).renderColor(with: .n2))
        button.addSubview(imageView)
        imageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(16)
        }
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.ud.iconN2.cgColor
        button.addTarget(self, action: #selector(handleAddAttendee), for: .touchUpInside)
        button.snp.makeConstraints {
            $0.width.height.equalTo(32)
        }
        return button
    }()
    private lazy var iconImage = UDIcon.getIconByKeyNoLimitSize(.groupOutlined).renderColor(with: .n3)
    private lazy var iconImageDisabled = UDIcon.getIconByKeyNoLimitSize(.groupOutlined).renderColor(with: .n4)

    override init(frame: CGRect) {
        super.init(frame: frame)
        icon = .customImage(iconImage)
        iconSize = EventEditUIStyle.Layout.cellLeftIconSize
        backgroundColor = UIColor.ud.bgFloat
        backgroundColors = EventEditUIStyle.Color.cellBackgrounds
        onClick = { [weak self] in
            if let avatars = self?.viewData?.avatars, !avatars.isEmpty {
                self?.clickHandler?()
            } else {
                self?.addHandler?()
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: Self.noIntrinsicMetric, height: EventEditUIStyle.Layout.singleLineCellHeight)
    }

    override var frame: CGRect {
        didSet {
            if abs(oldValue.width - frame.width) > 0.00001 {
                /// 屏幕宽度变化时要重新刷新参与人头像，不然很有可能被截断
                attendeesContentView.collectionView.reloadData()
            }
        }
    }

    override var bounds: CGRect {
        didSet {
            if abs(oldValue.width - bounds.width) > 0.00001 {
                /// 屏幕宽度变化时要重新刷新参与人头像，不然很有可能被截断
                attendeesContentView.collectionView.reloadData()
            }
        }
    }

    @objc
    private func handleAddAttendee() {
        addHandler?()
    }

    @objc
    private func tapCollectionView() {
        clickHandler?()
    }

}

extension EventEditAttendeeView: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        /// 获取真实参与人头像个数
        guard let currentCount = viewData?.avatars.count else { return 0 }
        /// 获取当前屏幕能显示的最大头像数量，减去加号 icon 的占位长度, icon 32pt, 间距 12pt
        let avatarContainerWidth = EventEditUIStyle.Layout.avatarContainerSize.width
        let maximumSupportedCount = Int((collectionView.frame.width - avatarContainerWidth) / avatarContainerWidth)
        /// 参与者头像最多显示4位，否则按照实际情况显示
        return min(currentCount, maximumSupportedCount, 4)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: String(describing: Self.self),
            for: indexPath
        )
        if let attendeeCell = cell as? AttendeeCell,
            let avatars = viewData?.avatars {
            let avatar = avatars[indexPath.row]
            attendeeCell.avatarView.setAvatar(avatar, with: EventEditUIStyle.Layout.avatarSize.width)
        }
        cell.isUserInteractionEnabled = false
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionFooter else {
            return UICollectionReusableView(frame: .zero)
        }
        let footerView = collectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: String(describing: Self.self),
            for: indexPath
        )
        addFooterButton.removeFromSuperview()
        if let showAddEntry = viewData?.enableAdd, showAddEntry {
            footerView.isHidden = false
            footerView.addSubview(addFooterButton)
            addFooterButton.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
            }
        } else {
            footerView.isHidden = true
        }
        return footerView
    }

}

extension EventEditAttendeeView {

    // 无参与人的 ContentView
    private final class EmptyAttendeeContentView: UIView {

        fileprivate var isLoading: Bool = false {
            didSet {
                if isLoading {
                    activityView.isHidden = false
                    activityView.startAnimating()
                } else {
                    activityView.isHidden = true
                    activityView.stopAnimating()
                }
            }
        }

        private var titleLabel: UILabel = {
            let label = UILabel()
            label.text = BundleI18n.Calendar.Calendar_Edit_AddGuest
            label.textColor = EventEditUIStyle.Color.dynamicGrayText
            label.font = UIFont.cd.regularFont(ofSize: 16)
            return label
        }()

        private var activityView = ActivityIndicatorView(color: UIColor.ud.primaryContentDefault)

        override init(frame: CGRect) {
            super.init(frame: frame)

            addSubview(titleLabel)
            titleLabel.snp.makeConstraints {
                $0.left.centerY.equalToSuperview()
            }

            addSubview(activityView)
            activityView.snp.makeConstraints {
                $0.width.height.equalTo(14)
                $0.centerY.right.equalToSuperview()
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    // 有参与人的 ContentView
    private final class AttendeesContentView: UIView {

        fileprivate var countStr: String? {
            didSet {
                countLabel.text = countStr
            }
        }

        fileprivate var isLoading: Bool = false {
            didSet {
                activityView.snp.remakeConstraints {
                    $0.width.height.equalTo(isLoading ? 14 : 0)
                    $0.centerY.equalToSuperview()
                    $0.right.equalTo(countLabel.snp.left).offset(isLoading ? -8 : 0)
                }

                if isLoading {
                    activityView.isHidden = false
                    activityView.startAnimating()
                } else {
                    activityView.isHidden = true
                    activityView.stopAnimating()
                }
            }
        }

        fileprivate lazy var collectionView: UICollectionView = {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .horizontal
            let itemSize = EventEditUIStyle.Layout.avatarSize
            layout.itemSize = itemSize
            layout.minimumLineSpacing = EventEditUIStyle.Layout.avatarSpaing
            layout.footerReferenceSize = EventEditUIStyle.Layout.avatarContainerSize
            layout.sectionInset.right = EventEditUIStyle.Layout.avatarSpaing

            let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
            collectionView.isScrollEnabled = false
            collectionView.showsHorizontalScrollIndicator = false
            collectionView.showsVerticalScrollIndicator = false
            collectionView.backgroundColor = .clear
            return collectionView
        }()

        private lazy var activityView = ActivityIndicatorView(color: UIColor.ud.primaryContentDefault)

        private lazy var countLabel: UILabel = {
            let label = UILabel()
            label.textColor = EventEditUIStyle.Color.normalGrayText
            label.font = EventEditUIStyle.Font.smallText
            return label
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)

            addSubview(countLabel)
            countLabel.snp.makeConstraints {
                $0.right.centerY.equalToSuperview()
            }

            addSubview(activityView)
            activityView.snp.makeConstraints {
                $0.width.height.equalTo(isLoading ? 14 : 0)
                $0.centerY.equalToSuperview()
                $0.right.equalTo(countLabel.snp.left).offset(isLoading ? -8 : 0)
            }

            addSubview(collectionView)
            collectionView.snp.makeConstraints {
                $0.left.top.height.equalToSuperview()
                $0.right.equalTo(countLabel.snp.left).offset(-24)
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func updateAIBgAndLayout(needAIStyle: Bool) {
            self.backgroundColor = needAIStyle ? UDColor.AIPrimaryFillTransparent01(ofSize: self.bounds.size) : .clear
            self.layer.cornerRadius = 8
            
            collectionView.snp.updateConstraints {
                $0.left.equalToSuperview().offset(needAIStyle ? 4: 0)
            }
            
            countLabel.snp.updateConstraints {
                $0.right.equalToSuperview().inset(needAIStyle ? 4: 0)
            }
        }
    }

    private final class AttendeeCell: UICollectionViewCell {
        let avatarView = AvatarView()
        override init(frame: CGRect) {
            super.init(frame: frame)
            contentView.addSubview(avatarView)
            avatarView.snp.makeConstraints {
                $0.left.centerY.equalToSuperview()
                $0.size.equalTo(EventEditUIStyle.Layout.avatarSize)
            }
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

}
