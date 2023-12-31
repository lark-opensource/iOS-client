//
//  ExportDocumentSelectView.swift
//  SKBrowser
//
//  Created by lizechuang on 2020/11/22.
//

import Foundation
import SKCommon
import SKUIKit
import SKFoundation
import EENavigator

protocol ExportDocumentSelectDelegate: AnyObject {
    func didSelectExportDocument(_ info: ExportDocumentItemInfo)
}

class ExportDocumentSelectView: UIView {
    fileprivate struct Const {
        static let iconWidth: CGFloat = 48
        static let iconTopOffset: CGFloat = 4
        static let labelTopOffset: CGFloat = 12
        static let labelHeight: CGFloat = 20
        static let itemHeight: CGFloat = 88
        static let contentTopBottomOffset: CGFloat = 24
        static let minimumInteritemSpacing: CGFloat = 16
        static var curViewWidth: CGFloat = 0.0
        static var itemLeftOffset: CGFloat = 4
    }

    private(set) lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = Const.itemLeftOffset
        layout.minimumLineSpacing = Const.minimumInteritemSpacing
        layout.sectionInset = UIEdgeInsets(top: 0, left: Const.itemLeftOffset, bottom: 0, right: Const.itemLeftOffset)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsVerticalScrollIndicator = false
        cv.showsHorizontalScrollIndicator = false
        cv.clipsToBounds = false
        return cv
    }()

    public var preferredHeight: CGFloat {
        var totalHeight: CGFloat = Const.contentTopBottomOffset * 2
        totalHeight += infos.countOfLine * Const.itemHeight
        totalHeight += (infos.countOfLine - 1) * Const.minimumInteritemSpacing
        return totalHeight
    }

    private var infos: [ExportDocumentItemInfo]

    private var formSheet: Bool

    private weak var delegate: ExportDocumentSelectDelegate?
    
    init(infos: [ExportDocumentItemInfo], formSheet: Bool, hostSize: CGSize, delegate: ExportDocumentSelectDelegate? = nil) {
        self.infos = infos
        self.delegate = delegate
        self.formSheet = formSheet
        super.init(frame: .zero)
        Const.curViewWidth = formSheet ? CGFloat.scaleBaseline : hostSize.width
        _setupSubViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateWidth(_ width: CGFloat) {
        Self.Const.curViewWidth = width
    }
}

extension ExportDocumentSelectView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    private func _setupSubViews() {
        backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(Const.contentTopBottomOffset)
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).inset(Const.contentTopBottomOffset)
        }
        collectionView.register(ExportDocumentItemCell.self, forCellWithReuseIdentifier: ExportDocumentItemCell.reuseIdentifier)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return infos.count
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: infos.eachOflineConfig.itemWidth, height: Const.itemHeight)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ExportDocumentItemCell.reuseIdentifier, for: indexPath)
        guard indexPath.row < infos.count else {
            return cell
        }
        let info = infos[indexPath.row]
        (cell as? ExportDocumentItemCell)?.setItemInfo(info: info)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let info = infos[indexPath.row]
        delegate?.didSelectExportDocument(info)
    }

    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? ExportDocumentItemCell else {
            return
        }
        cell.updatePatternWithIsHighlight(true)
    }

    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? ExportDocumentItemCell else {
            return
        }
        cell.updatePatternWithIsHighlight(false)
    }
}

class ExportDocumentItemCell: UICollectionViewCell {
    private lazy var iconView: UIImageView = {
        let iconView = UIImageView()
        iconView.contentMode = .center
        return iconView
    }()

    private lazy var iconMaskView: UIView = {
        let maskV = UIView()
        maskV.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.15)
        maskV.isHidden = true
        maskV.layer.cornerRadius = ExportDocumentSelectView.Const.iconWidth / 2
        return maskV
    }()

    private lazy var titleLable: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        _setupViews()
    }

    private func _setupViews() {
        contentView.addSubview(iconView)
        contentView.addSubview(titleLable)
        contentView.addSubview(iconMaskView)
        contentView.bringSubviewToFront(iconMaskView)
        iconView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.width.height.equalTo(ExportDocumentSelectView.Const.iconWidth)
            make.top.equalTo(ExportDocumentSelectView.Const.iconTopOffset)
        }
        titleLable.snp.makeConstraints { (make) in
            make.centerX.left.right.equalToSuperview()
            make.top.equalTo(iconView.snp.bottom).offset(ExportDocumentSelectView.Const.labelTopOffset)
            make.height.equalTo(ExportDocumentSelectView.Const.labelHeight)
        }
        iconMaskView.snp.makeConstraints { (make) in
            make.center.width.height.equalTo(iconView)
        }
        iconView.docs.addStandardLift()
    }

    func setItemInfo(info: ExportDocumentItemInfo) {
        iconView.image = info.markImage
        titleLable.text = info.markTitle
    }

    func updatePatternWithIsHighlight(_ isHighlight: Bool) {
        iconMaskView.isHidden = !isHighlight
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Private Extension
// 这里都是计算属性，小心使用
extension Array where Element == ExportDocumentItemInfo {
    // 暂时使用成固定一行
    var eachOflineConfig: (lineCount: CGFloat, itemWidth: CGFloat) {
        let realCount: CGFloat = CGFloat(count)
        let totalItemWidth = docsViewWidth - CGFloat((realCount + 1)) * ExportDocumentSelectView.Const.itemLeftOffset
        guard realCount != 0.0 else {
            return (0.0, 0.0)
        }
        let itemWidth = floor(totalItemWidth / realCount)
        return (realCount, itemWidth)
    }

    var docsViewWidth: CGFloat {
        return ExportDocumentSelectView.Const.curViewWidth
    }

    var countOfLine: CGFloat {
        return 1
    }

    // 暂时不使用该写法，后续会通过修改文案行数恢复该写法
//    var eachOfLineConfig: (lineCount: CGFloat, offset: CGFloat) {
//        let realCount: CGFloat = CGFloat((calculateCount > count) ? count : calculateCount)
//        let totalOffset = docsViewWidth - realCount * ExportDocumentSelectView.Const.itemHeight
//        let offset = totalOffset / (realCount + 1)
//        return (realCount, offset)
//    }

//    private var calculateCount: Int {
//        return Int(floor(docsViewWidth / ExportDocumentSelectView.Const.itemHeight))
//    }

//    var countOfLine: CGFloat {
//        guard eachOfLineConfig.lineCount != 0.0 else {
//            return 0.0
//        }
//        return ceil(CGFloat(count) / eachOfLineConfig.lineCount)
//    }
}
