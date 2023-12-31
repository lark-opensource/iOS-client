//
//  OfficialCoverPhotosSelectView.swift
//  SpaceKit
//
//  Created by lizechuang on 2020/2/10.
//  swiftlint:disable line_length

import SKFoundation
import SKCommon
import SKResource
import LarkLocalizations
import UniverseDesignColor

protocol OfficialCoverPhotosSelectViewDelegate: AnyObject {
    func didSelectOfficialCoverPhotoWith(_ info: OfficialCoverPhotoInfo, sourceSeries: String)
}

class OfficialCoverPhotosSelectView: UIView {
    fileprivate struct Const {
        static let iPhoneItemScale: CGFloat = 0.68
        static let iPadItemScale: CGFloat = 0.55
        static let headerHeight: CGFloat = 40
    }

    weak var delegate: OfficialCoverPhotosSelectViewDelegate?

    private var officialSeries: OfficialCoverPhotosSeries
    private let dataAPI: OfficialCoverPhotoDataAPI
    private let isIPadDisplay: Bool

    lazy var collectionView: UICollectionView = {
        return setupCollectionView()
    }()

    init(frame: CGRect, isIPadDisplay: Bool, with series: OfficialCoverPhotosSeries) {
        self.officialSeries = series
        self.isIPadDisplay = isIPadDisplay
        self.dataAPI = OfficialCoverPhotoDataProvider()
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setupSubViews()
    }

    private func setupSubViews() {
        self.backgroundColor = UDColor.bgBase
        addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.right.bottom.equalToSuperview()
        }
    }

    public func updateOfficialCoverPhotosSeries(_ series: OfficialCoverPhotosSeries) {
        self.officialSeries = series
        collectionView.reloadData()
    }

    public func refreshDisplay() {
        collectionView.reloadData()
    }

    private func setupCollectionView() -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16.0, bottom: 12.0, right: 16.0)
        layout.headerReferenceSize = CGSize(width: self.bounds.size.width, height: Const.headerHeight)
        layout.scrollDirection = .vertical
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UDColor.bgBase
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        collectionView.contentInset = UIEdgeInsets(top: 12.0, left: 0.0, bottom: 0.0, right: 0.0)
        collectionView.register(OfficialCoverPhotoCell.self, forCellWithReuseIdentifier: String(describing: OfficialCoverPhotoCell.self))
        collectionView.register(OfficialCoverPhotoHeaderView.self, forSupplementaryViewOfKind: "UICollectionElementKindSectionHeader", withReuseIdentifier: String(describing: OfficialCoverPhotoHeaderView.self))
        return collectionView
    }
}

extension OfficialCoverPhotosSelectView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return officialSeries.count
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return officialSeries[section].infos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let rawCell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: OfficialCoverPhotoCell.self), for: indexPath)
        guard let cell = rawCell as? OfficialCoverPhotoCell else {
            assertionFailure("can not find CoverPhotoCollectionCell")
            return rawCell
        }
        let photoInfo = officialSeries[indexPath.section].infos[indexPath.row]
        let itemWidth = (self.bounds.size.width - 56) / 4.0
        let itemHeight = itemWidth * (self.isIPadDisplay ? Const.iPadItemScale : Const.iPhoneItemScale)
        let coverSize = CGSize(width: itemWidth, height: itemHeight)
        cell.setupWithDataAPI(self.dataAPI, photoInfo: photoInfo, coverSize: coverSize)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == "UICollectionElementKindSectionHeader" {
            let resuableView = collectionView.dequeueReusableSupplementaryView(ofKind: "UICollectionElementKindSectionHeader", withReuseIdentifier: String(describing: OfficialCoverPhotoHeaderView.self), for: indexPath)
            guard let view = resuableView as? OfficialCoverPhotoHeaderView else {
                assertionFailure("can not find OfficialCoverPhotosHeaderView")
                return resuableView
            }
            let title = officialSeries[indexPath.section].display.displayName
            view.setHeaderTitle(title)
            return view
        } else {
            return UICollectionReusableView()
        }
    }
}

extension OfficialCoverPhotosSelectView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let info = officialSeries[indexPath.section].infos[indexPath.row]
        let sourceSeries = officialSeries[indexPath.section].display.seriesId
        delegate?.didSelectOfficialCoverPhotoWith(info, sourceSeries: sourceSeries)
    }
}

extension OfficialCoverPhotosSelectView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard self.bounds.size.width != 0 else {
            return CGSize.zero
        }
        let itemWidth = (self.bounds.size.width - 56) / 4.0
        let itemHeight = itemWidth * (self.isIPadDisplay ? Const.iPadItemScale : Const.iPhoneItemScale)
        return CGSize(width: itemWidth, height: itemHeight)
    }
}
