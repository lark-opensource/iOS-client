//
//  WikiHomePageSpaceView.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/9/27.
//  

import UIKit
import SnapKit
import SKCommon
import SKResource
import SKFoundation
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignNotice

class WikiHomePageSpaceView: UIView {
    typealias R = BundleI18n.SKResource
    private(set) lazy var spaceCollectionView: UICollectionView = {
        let config = WikiSpaceCoverConfig.layoutConfig
        let layout = WikiHorizontalPagingLayout(config: config)
        let view = UICollectionView(frame: self.frame, collectionViewLayout: layout)
        view.register(WikiSpaceCoverConfig.cellClass, forCellWithReuseIdentifier: cellIdentifier)
        view.register(WikiSpacePlaceHolderCollectionCell.self, forCellWithReuseIdentifier: placeHolderCellIdentifier)
        view.backgroundColor = UDColor.bgBody
        view.showsHorizontalScrollIndicator = false
        view.decelerationRate = .fast
        view.clipsToBounds = false
        return view
    }()

    private lazy var spaceTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.ct.systemMedium(ofSize: 16)
        label.textColor = UDColor.textTitle
        label.text = R.LarkCCM_NewCM_Sidebar_Mobile_PinWorkspaceToTop_Title
        return label
    }()

    private lazy var allSpaceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.ct.systemRegular(ofSize: 14)
        label.textColor = UDColor.primaryContentDefault
        label.text = R.Doc_Wiki_Home_SeeAll
        return label
    }()

    private lazy var allSpaceImageView: UIImageView = {
        let view = UIImageView(image: UDIcon.rightOutlined.ud.withTintColor(UDColor.primaryContentDefault))
        view.contentMode = .scaleAspectFit
        return view
    }()

    private lazy var allSpaceButton: UIButton = {
        let button = UIButton(type: .custom)
        return button
    }()

    private lazy var emptySpaceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.ct.systemRegular(ofSize: 14)
        label.textColor = UDColor.textCaption
        label.numberOfLines = 2
        label.text = R.Doc_Wiki_Home_WorkspaceEmptyText
        return label
    }()

    private lazy var bottomSepeartorView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgBase
        return view
    }()

    var spaceCollectionViewDataSource: UICollectionViewDataSource? {
        get { return spaceCollectionView.dataSource }
        set { spaceCollectionView.dataSource = newValue }
    }

    var spaceCollectionViewDelegate: UICollectionViewDelegate? {
        get { return spaceCollectionView.delegate }
        set { spaceCollectionView.delegate = newValue }
    }

    var shouldShowAllSpaceEntrance: Bool = false {
        didSet {
            let isHidden = isV2 ? true : !shouldShowAllSpaceEntrance
            allSpaceLabel.isHidden = isHidden
            allSpaceImageView.isHidden = isHidden
            allSpaceButton.isHidden = isHidden
        }
    }
    private let cellIdentifier: String
    private let placeHolderCellIdentifier: String
    var onClickAllSpace: (() -> Void)?
    private let isV2: Bool

    init(frame: CGRect, cellIdentifier: String, placeHolderCellIdentifier: String, isV2: Bool) {
        self.cellIdentifier = cellIdentifier
        self.placeHolderCellIdentifier = placeHolderCellIdentifier
        self.isV2 = isV2
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UDColor.bgBody
        clipsToBounds = true

        addSubview(bottomSepeartorView)
        bottomSepeartorView.snp.makeConstraints { make in
            make.bottom.left.right.equalToSuperview()
            make.height.equalTo(8)
        }
        addSubview(allSpaceImageView)
        allSpaceImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-15)
            make.width.height.equalTo(16)
        }
        addSubview(allSpaceLabel)
        allSpaceLabel.snp.makeConstraints { make in
            make.centerY.equalTo(allSpaceImageView.snp.centerY)
            make.right.equalTo(allSpaceImageView.snp.left).offset(-4)
        }
        addSubview(allSpaceButton)
        allSpaceButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(8)
            make.top.equalTo(allSpaceImageView.snp.top).offset(-8)
            make.bottom.equalTo(allSpaceImageView.snp.bottom).offset(8)
            make.left.equalTo(allSpaceLabel.snp.left).offset(-8)
        }
        allSpaceButton.docs.addHighlight(with: .zero, radius: 8)
        allSpaceButton.addTarget(self, action: #selector(clickAllSpaceButton), for: .touchUpInside)
        addSubview(spaceTitleLabel)
        spaceTitleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(allSpaceImageView.snp.centerY)
            make.left.equalToSuperview().offset(16)
        }
        addSubview(bottomSepeartorView)
        bottomSepeartorView.snp.makeConstraints { make in
            make.height.equalTo(8)
            make.left.right.bottom.equalToSuperview()
        }
        addSubview(emptySpaceLabel)
        emptySpaceLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalTo(bottomSepeartorView.snp.top).offset(-10)
            make.top.equalTo(spaceTitleLabel.snp.bottom).offset(10)
        }

        let itemCount = getItemCount(isLoading: true)
        let collectionViewHeight = getCollectionViewHeight(itemCount: itemCount)
        addSubview(spaceCollectionView)
        spaceCollectionView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(bottomSepeartorView.snp.top).offset(-16)
            make.height.equalTo(collectionViewHeight)
        }

        frame.size.height = getPreferHeight(itemCount: itemCount)
    }

    func getItemCount(isLoading: Bool) -> Int {
        if isLoading {
            return WikiSpaceCoverConfig.placeHolderCount
        } else {
            guard let layout = spaceCollectionView.collectionViewLayout as? WikiHorizontalPagingLayout else {
                assertionFailure("wiki.space.collectionView --- parse layout failed")
                return 0
            }
            return layout.itemCount
        }
    }

    func getPreferHeight(itemCount: Int) -> CGFloat {
        if itemCount == 0 {
            return 110
        } else {
            let collectionViewHeight = getCollectionViewHeight(itemCount: itemCount)
            return 48 + collectionViewHeight + 24
        }
    }

    private func getCollectionViewHeight(itemCount: Int) -> CGFloat {
        guard let layout = spaceCollectionView.collectionViewLayout as? WikiHorizontalPagingLayout else {
            assertionFailure("wiki.space.collectionView --- parse layout failed")
            return 110
        }
        return layout.preferHeight(itemCount: itemCount)
    }

    func reloadSpaceData(count: Int, isLoading: Bool) {

        let itemCount = isLoading ? getItemCount(isLoading: true) : count
        let collectionViewHeight = getCollectionViewHeight(itemCount: itemCount)
        spaceCollectionView.snp.updateConstraints { make in
            make.height.equalTo(collectionViewHeight)
        }
        frame.size.height = getPreferHeight(itemCount: itemCount)

        spaceCollectionView.isUserInteractionEnabled = !isLoading
        if isLoading {
            shouldShowAllSpaceEntrance = false
            emptySpaceLabel.isHidden = true
        } else {
            shouldShowAllSpaceEntrance = count > WikiSpaceCoverConfig.allSpacesThreadhold
            emptySpaceLabel.isHidden = count != 0
        }
        spaceCollectionView.reloadData()
    }

    func setupClickHandler(onClickAllSpace: (() -> Void)?) {
        self.onClickAllSpace = onClickAllSpace
    }

    @objc
    func clickAllSpaceButton() {
        onClickAllSpace?()
    }
}
