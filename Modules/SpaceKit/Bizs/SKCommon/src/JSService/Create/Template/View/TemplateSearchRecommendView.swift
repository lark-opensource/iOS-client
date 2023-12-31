//
//  TemplateSearchRecommendView.swift
//  SKCommon
//
//  Created by bytedance on 2021/1/7.
//

import SKUIKit
import SKFoundation
import SKResource
import UniverseDesignColor
protocol TemplateSearchRecommendViewDelegate: AnyObject {
    func didSelectRecommendCell(_ recommand: TemplateSearchRecommend)
}
final class TemplateSearchRecommendView: UIView {
    
    private var dataSource = [TemplateSearchRecommend]()
    
    weak var delegate: TemplateSearchRecommendViewDelegate?
    let leftPadding: CGFloat = SKDisplay.pad ? 56 : 16
    var rightPadding: CGFloat = 16
    var hostViewWidth: CGFloat

    //layout
    lazy var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = rightPadding
        layout.minimumInteritemSpacing = rightPadding

        var currentRightPadding = rightPadding
        if SKDisplay.pad, hostViewWidth > 415 {
            currentRightPadding = max(currentRightPadding, hostViewWidth - leftPadding - 343)
        }

        layout.sectionInset = UIEdgeInsets(top: 0, left: leftPadding, bottom: 20, right: currentRightPadding)
        return layout
    }()

    // view
    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UDColor.bgBody
        
        collectionView.register(SearchRecommandCell.self, forCellWithReuseIdentifier: SearchRecommandCell.reuseIdentifier)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "UICollectionViewCell") // 以防万一
        collectionView.register(TemplateNameHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: TemplateNameHeaderView.reuseIdentifier)

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)

        return collectionView
    }()
    
    init(hostViewWidth: CGFloat) {
        self.hostViewWidth = hostViewWidth
        super.init(frame: .zero)
        addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateDataSource(_ recommends: [TemplateSearchRecommend]) {
        dataSource = recommends
        collectionView.reloadData()
    }

    //iPad拖动分屏时刷新布局
//    func freshLayout(frame: CGRect) {
//        self.hostViewWidth = frame.size.width
//        var currentRightPadding = rightPadding
//        if SKDisplay.pad, hostViewWidth > 415 {
//            currentRightPadding = max(currentRightPadding, hostViewWidth - leftPadding - 343)
//        }
//        layout.sectionInset.right = currentRightPadding
//        collectionView.collectionViewLayout.invalidateLayout()
//    }
}


extension TemplateSearchRecommendView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let recommand = self.dataSource[indexPath.item]
        let cellReuse = collectionView.dequeueReusableCell(withReuseIdentifier: SearchRecommandCell.reuseIdentifier, for: indexPath)
        guard let cell = cellReuse as? SearchRecommandCell else {
            return cellReuse
        }
        
        cell.updateBy(recommand, index: indexPath.item)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var currentViewWidth = hostViewWidth
        if SKDisplay.pad, currentViewWidth > 415 {
            currentViewWidth = 415
        }
        return CGSize(width: (currentViewWidth - 2 * rightPadding - leftPadding) / 2, height: 20)
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                                           withReuseIdentifier: TemplateNameHeaderView.reuseIdentifier,
                                                                           for: indexPath) as? TemplateNameHeaderView else {
            return UICollectionReusableView()
        }
        if SKDisplay.pad {
            header.updateLabelLeftOffest(offest: 56)
        }
        header.tipLabel.text = BundleI18n.SKResource.Doc_List_TemplateSearchRecommendation
//        header.backgroundColor = 
        return header
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: hostViewWidth, height: 44)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard self.dataSource.count > indexPath.item else {
                spaceAssertionFailure("did click template out of range \(indexPath)")
                return
        }
        let recommend = self.dataSource[indexPath.item]
        delegate?.didSelectRecommendCell(recommend)
    }
}

private final class SearchRecommandCell: UICollectionViewCell {
    let noLabel = UILabel()
    let titleLabel = UILabel()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(noLabel)
        contentView.addSubview(titleLabel)
        
        noLabel.snp.makeConstraints { (make) in
            make.left.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }
        
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(noLabel.snp.right).offset(6)
            make.centerY.equalTo(noLabel)
            make.right.equalToSuperview()
            make.height.equalTo(noLabel)
        }
        
        noLabel.layer.cornerRadius = 2
        noLabel.layer.masksToBounds = true
        noLabel.textAlignment = .center
        noLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        
        titleLabel.font = UIFont.systemFont(ofSize: 14)
    }
    
    func updateBy(_ recommend: TemplateSearchRecommend, index: Int) {
        let no = index + 1
        noLabel.text = "\(no)"
        titleLabel.text = recommend.name
        // https://www.figma.com/file/JlNdCX48LqbxIZq0tAHijs/🌚🌚🌚-CCM-Dark-Mode?node-id=83%3A31952
        var noColor: UIColor = UDColor.textCaption
        var bgColor: UIColor = UDColor.bgFiller
        switch no {
        case 1:
            noColor = UDColor.R400
            bgColor = UDColor.colorfulRed.withAlphaComponent(0.2)
        case 2:
            noColor = UDColor.O500
            bgColor = UDColor.colorfulOrange.withAlphaComponent(0.3)
        case 3:
            noColor = UDColor.Y500
            bgColor = UDColor.colorfulYellow.withAlphaComponent(0.5)
        default:
            break
        }
        
        noLabel.textColor = noColor
        noLabel.backgroundColor = bgColor
    }
}
