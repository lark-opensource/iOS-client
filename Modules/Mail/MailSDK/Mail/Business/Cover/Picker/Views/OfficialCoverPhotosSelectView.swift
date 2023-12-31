//
//  OfficialCoverPhotosSelectView.swift
//  SpaceKit
//
//  Created by lizechuang on 2020/2/10.
//  swiftlint:disable line_length

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
        static let itemSpacing: CGFloat = Display.pad ? 12 : 8
        static let horizontalInset: CGFloat = 16
    }

    weak var delegate: OfficialCoverPhotosSelectViewDelegate?

    private var officialSeries: OfficialCoverPhotosSeries
    private let dataAPI: OfficialCoverPhotoDataAPI
    private let isIPadDisplay: Bool

    lazy var collectionView: UICollectionView = {
        return setupCollectionView()
    }()

    init(frame: CGRect, isIPadDisplay: Bool, with series: OfficialCoverPhotosSeries, provider: ConfigurationProxy?, imageService: MailImageService?) {
        self.officialSeries = series
        self.isIPadDisplay = isIPadDisplay
        self.dataAPI = OfficialCoverPhotoDataProvider(configurationProvider: provider, imageService: imageService)
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
        self.backgroundColor = UDColor.bgContentBase
        addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.right.bottom.equalToSuperview()
        }
    }

    func updateOfficialCoverPhotosSeries(_ series: OfficialCoverPhotosSeries) {
        self.officialSeries = series
        collectionView.reloadData()
    }

    func refreshDisplay() {
        collectionView.reloadData()
    }

    private func setupCollectionView() -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = Const.itemSpacing
        layout.minimumInteritemSpacing = Const.itemSpacing
        layout.sectionInset = UIEdgeInsets(top: 0, left: Const.horizontalInset, bottom: 12.0, right: Const.horizontalInset)
        layout.headerReferenceSize = CGSize(width: self.bounds.size.width, height: Const.headerHeight)
        layout.scrollDirection = .vertical
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = Display.pad ? UDColor.bgFloatBase : UDColor.bgContentBase
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
            mailAssertionFailure("can not find CoverPhotoCollectionCell")
            return rawCell
        }
        let photoInfo = officialSeries[indexPath.section].infos[indexPath.row]
        cell.setupWithDataAPI(self.dataAPI, photoInfo: photoInfo)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == "UICollectionElementKindSectionHeader" {
            let resuableView = collectionView.dequeueReusableSupplementaryView(ofKind: "UICollectionElementKindSectionHeader", withReuseIdentifier: String(describing: OfficialCoverPhotoHeaderView.self), for: indexPath)
            guard let view = resuableView as? OfficialCoverPhotoHeaderView else {
                mailAssertionFailure("can not find OfficialCoverPhotosHeaderView")
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
        guard let cell = collectionView.cellForItem(at: indexPath) as? OfficialCoverPhotoCell else { return }
        let info = officialSeries[indexPath.section].infos[indexPath.row]
//        let sourceSeries = officialSeries[indexPath.section].display.seriesId
        if !cell.reloadImage.isHidden {
            let photoInfo = officialSeries[indexPath.section].infos[indexPath.row]
            cell.setupWithDataAPI(dataAPI, photoInfo: photoInfo)
        } else if cell.coverPhotoImageView.image != nil {
            delegate?.didSelectOfficialCoverPhotoWith(info, sourceSeries: "")
        }
    }
}

extension OfficialCoverPhotosSelectView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard self.bounds.size.width != 0 else {
            return CGSize.zero
        }
        let itemWidth = floor((self.bounds.size.width - (Const.horizontalInset * 2) - (Const.itemSpacing * 3)) / 4.0)
        let itemHeight = itemWidth * (self.isIPadDisplay ? Const.iPadItemScale : Const.iPhoneItemScale)
        return CGSize(width: itemWidth, height: itemHeight)
    }
}
