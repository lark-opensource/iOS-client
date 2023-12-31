//
//  MedalView.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2021/9/2.
//

import Foundation
import UIKit
import EENavigator
import ServerPB
import ByteWebImage
import UniverseDesignEmpty
import LarkContainer

public protocol MedalCollectionViewDelegate: AnyObject {
    func changeMedalStatusBy(_ medal: LarkMedalItem)
    func showDetailMedalBy(_ medal: LarkMedalItem)
}

public final class MedalCollectionViewController: UIViewController, UserResolverWrapper {
    public var userResolver: LarkContainer.UserResolver
    
    private var userID: String

    public var contentViewDidScroll: ((UIScrollView) -> Void)?

    public weak var delegate: MedalCollectionViewDelegate?

    private var isShow: Bool = false

    private var medals: [LarkMedalItem] = []

    private var empty: UDEmpty = {
        let description = UDEmptyConfig.Description(descriptionText: BundleI18n.LarkProfile.Lark_Profile_YourBadgeAppearHere)
        let empty = UDEmpty(config: UDEmptyConfig(description: description,
                                                  type: .imNeutralProfileNoMedal))
        empty.isHidden = true
        return empty
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 14

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.ud.bgBody
        collectionView.isScrollEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()
    init(resolver: LarkContainer.UserResolver, userID: String) {
        self.userID = userID
        self.userResolver = resolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.ud.bgBody

        self.view.addSubview(collectionView)
        self.view.addSubview(empty)
        collectionView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview().offset(-16)
            make.leading.equalToSuperview().offset(14)
            make.trailing.equalToSuperview().offset(-14)
        }

        empty.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(104)
            make.left.right.equalToSuperview()
        }

        let cellName = String(describing: MedalCollectionCell.self)
        collectionView.register(MedalCollectionCell.self, forCellWithReuseIdentifier: cellName)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "emptyCell")
        collectionView.clipsToBounds = false
    }

    public func reloadData() {
        self.collectionView.reloadData()
    }

    public func setMedals(_ medals: [LarkMedalItem], isViewFirstLoad: Bool = false) {
        self.medals = medals
        self.empty.isHidden = !medals.isEmpty
        self.collectionView.isScrollEnabled = !medals.isEmpty
        self.collectionView.reloadData()

        if isViewFirstLoad {
            LarkProfileTracker.trackerAvatarMedalWallShow(medals,
                                                          extra: ["to_user_id": self.userID])
        }
    }

    public func showButton(_ isShow: Bool) {
        guard self.isShow != isShow else {
            return
        }

        self.isShow = isShow

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        self.collectionView.setCollectionViewLayout(layout, animated: false)
        self.collectionView.setNeedsLayout()
        self.collectionView.layoutIfNeeded()

        self.reloadData()
    }
}

extension MedalCollectionViewController: SegmentedTableViewContentable {
    public func listView() -> UIView {
        return self.view
    }

    public var segmentTitle: String {
        return ""
    }

    public var scrollableView: UIScrollView {
        return self.collectionView
    }
}

extension MedalCollectionViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.medals.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let name = String(describing: MedalCollectionCell.self)
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: name, for: indexPath)
            as? MedalCollectionCell {
            cell.showButton(self.isShow)
            cell.setMedal(medals[indexPath.row])
            cell.tapButtonCallback = { [weak self] (medal) in
                self?.delegate?.changeMedalStatusBy(medal)
            }

            cell.tapMedalCallback = { [weak self] (medal) in

                self?.delegate?.showDetailMedalBy(medal)
            }
            return cell
        } else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: "emptyCell", for: indexPath)
        }
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.contentViewDidScroll?(self.collectionView)
    }
}

extension MedalCollectionViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = isShow ? Cons.itemSize.height : Cons.itemSize.height - 40
        return CGSize(width: Cons.itemSize.width, height: height)
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 14
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 14
    }
}

extension MedalCollectionViewController {
    enum Cons {
        static var itemAspectRatio: CGFloat { 1.084 }
        static var itemSize: CGSize {
            let width = min((UIScreen.main.bounds.width - 14 * 3) / 2, 166)
            return CGSize(width: width, height: width * itemAspectRatio)
        }
    }
}

final class MedalCollectionCell: UICollectionViewCell {

    var tapButtonCallback: ((LarkMedalItem) -> Void)?
    var tapMedalCallback: ((LarkMedalItem) -> Void)?

    var medal: LarkMedalItem?

    var isShow: Bool = false

    lazy var wearLabel: UILabel = {
        let wearLabel = UILabel()
        wearLabel.textAlignment = .center
        wearLabel.text = BundleI18n.LarkProfile.Lark_Profile_On
        wearLabel.font = UIFont.systemFont(ofSize: 12)
        wearLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        wearLabel.backgroundColor = UIColor.ud.green
        return wearLabel
    }()

    lazy var medalView: UIImageView = {
        let medalView = UIImageView()
        medalView.contentMode = .scaleAspectFill
        medalView.isUserInteractionEnabled = true
        medalView.clipsToBounds = true
        return medalView
    }()

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.numberOfLines = 1
        return titleLabel
    }()

    lazy var medalButton: UIButton = {
        let medalButton = UIButton()
        medalButton.backgroundColor = UIColor.ud.primaryContentDefault
        medalButton.layer.cornerRadius = 4
        medalButton.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        medalButton.layer.borderWidth = 1
        medalButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        return medalButton
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layoutView()

        self.backgroundColor = UIColor.clear
        self.layer.shadowRadius = 5
        self.ud.setLayerShadowColor(UIColor.ud.rgb(0x1F2329))
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.layer.shadowOpacity = 0.1
        self.clipsToBounds = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard let medal = medal else {
            return
        }

        switch medal.status {
        case .invalid:
            medalButton.layer.borderColor = UIColor.ud.textDisabled.cgColor
        case .taking:
            medalButton.layer.borderColor = UIColor.ud.primaryContentDefault.cgColor
        case .valid:
            medalButton.layer.borderColor = UIColor.clear.cgColor
        @unknown default:
            break
        }
    }

    func setMedal(_ medal: LarkMedalItem) {
        self.medal = medal
        self.titleLabel.text = medal.name.getString()

        var passThrough = ImagePassThrough()
        passThrough.key = medal.medalImage.key
        passThrough.fsUnit = medal.medalImage.fsUnit

        self.medalView.bt.setLarkImage(with: .default(key: medal.medalImage.key),
                                       placeholder: BundleResources.LarkProfile.default_bg_image,
                                       passThrough: passThrough)

        medalButton.isUserInteractionEnabled = medal.status != .invalid
        wearLabel.isHidden = medal.status != .taking
        titleLabel.textColor = medal.status != .invalid ? UIColor.ud.textTitle : UIColor.ud.textDisabled
        switch medal.status {
        case .invalid:
            medalButton.backgroundColor = UIColor.clear
            medalButton.setTitleColor(UIColor.ud.textDisabled, for: .normal)
            medalButton.setTitle(BundleI18n.LarkProfile.Lark_Profile_Expired, for: .normal)
        case .taking:
            medalButton.backgroundColor = UIColor.clear
            medalButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
            medalButton.setTitle(BundleI18n.LarkProfile.Lark_Profile_TakeOff, for: .normal)
        case .valid:
            medalButton.backgroundColor = UIColor.ud.primaryContentDefault
            medalButton.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
            medalButton.setTitle(BundleI18n.LarkProfile.Lark_Profile_Wear, for: .normal)
        @unknown default:
            break
        }
    }

    private func layoutView() {
        let wrapperView = UIView()
        self.contentView.clipsToBounds = true
        self.contentView.addSubview(wrapperView)
        self.contentView.addSubview(wearLabel)

        wearLabel.frame = CGRect(x: -18, y: 13, width: 80, height: 18)
        wearLabel.center = CGPoint(x: 22, y: 22)
        wearLabel.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 4).inverted()

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapMedal))
        medalView.addGestureRecognizer(tap)

        wrapperView.isUserInteractionEnabled = true
        wrapperView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        wrapperView.backgroundColor = UIColor.ud.bgFloat
        wrapperView.layer.cornerRadius = 10

        wrapperView.addSubview(medalView)
        wrapperView.addSubview(titleLabel)
        wrapperView.addSubview(medalButton)

        medalButton.addTarget(self, action: #selector(tapButton), for: .touchUpInside)
        setConstraints()
    }

    func setConstraints() {
        medalView.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.height.width.equalTo(64)
            make.centerX.equalToSuperview()
        }

        titleLabel.snp.remakeConstraints { make in
            make.top.equalTo(medalView.snp.bottom).offset(10)
            make.left.equalToSuperview().offset(21)
            make.right.equalToSuperview().offset(-21)
            if medalButton.isHidden {
                make.bottom.equalToSuperview().offset(-20)
            }
        }

        if !medalButton.isHidden {
            medalButton.snp.remakeConstraints { make in
                make.left.right.equalTo(titleLabel)
                make.top.equalTo(titleLabel.snp.bottom).offset(20)
                make.bottom.equalToSuperview().offset(-20)
            }
        }
    }

    func showButton(_ isShow: Bool) {
        self.isShow = isShow
        self.medalButton.isHidden = !isShow
        self.setConstraints()
    }

    @objc
    private func tapButton() {
        guard let medal = self.medal else { return }
        self.tapButtonCallback?(medal)
    }

    @objc
    private func tapMedal() {
        guard let medal = self.medal else { return }
        self.tapMedalCallback?(medal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
