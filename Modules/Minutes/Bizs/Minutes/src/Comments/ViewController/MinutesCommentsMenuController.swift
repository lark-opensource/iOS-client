//
//  MinutesCommentsMenuController.swift
//  Minutes
//
//  Created by yangyao on 2021/2/7.
//

import UIKit
import UniverseDesignColor

struct MinutesCommentsMenuLayout {
    static let itemWidth: CGFloat = 60
    static let itemHeight: CGFloat = 82
    static let itemInset: CGFloat = 8

    static let leftOffset: CGFloat = 16
    static let maxHeight: CGFloat = 200
    static let arrowHeight: CGFloat = 10
}

struct MinutesCommentsMenuItem {
    var title: String
    var icon: UIImage
    var action: ((Any?) -> Void)?
}

class MinutesCommentsMenuItemCell: UICollectionViewCell {
    lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    lazy var label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(iconImageView)
        contentView.addSubview(label)

        iconImageView.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().offset(18)
            maker.centerX.equalToSuperview()
            maker.size.equalTo(24)
        }

        label.snp.makeConstraints { (maker) in
            maker.centerX.equalTo(iconImageView)
            maker.top.equalTo(iconImageView.snp.bottom).offset(2)
            maker.height.equalTo(20)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ item: MinutesCommentsMenuItem) {
        iconImageView.image = item.icon
        label.text = item.title
    }
}

class MinutesCommentsMenuController: UIViewController {
    private var collectionLayout: UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: MinutesCommentsMenuLayout.itemWidth, height: MinutesCommentsMenuLayout.itemHeight)
        layout.minimumLineSpacing = 0.0
        layout.minimumInteritemSpacing = 0.0
        return layout
    }

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionLayout)
        collectionView.backgroundColor = .clear
        collectionView.register(MinutesCommentsMenuItemCell.self, forCellWithReuseIdentifier: MinutesCommentsMenuItemCell.description())
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.bounces = false
        collectionView.isScrollEnabled = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }()

    var collectionWidth: CGFloat = 0.0
    var collectionHeight: CGFloat = 0.0
    var arrowViewHidden: Bool = true

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        modalPresentationStyle = .overFullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var containerWidth: CGFloat = 0.0
    var dataSource: [MinutesCommentsMenuItem] = [] {
        didSet {
            let totalCount: Int = dataSource.count
            let maxWidth = containerWidth - MinutesCommentsMenuLayout.leftOffset * 2
            let maxHeight: CGFloat = MinutesCommentsMenuLayout.maxHeight
            let width = CGFloat(totalCount) * MinutesCommentsMenuLayout.itemWidth + MinutesCommentsMenuLayout.itemInset * 2
            if width < maxWidth {
                collectionWidth = width
                collectionHeight = MinutesCommentsMenuLayout.itemHeight
            } else {
                collectionWidth = maxWidth
                let eachLineCount: Int = Int(maxWidth / MinutesCommentsMenuLayout.itemWidth)
                let line: Int = Int(ceil(CGFloat(totalCount) / CGFloat(eachLineCount)))
                let height = MinutesCommentsMenuLayout.itemHeight * CGFloat(line)
                collectionHeight = height < maxHeight ? height : maxHeight
            }
        }
    }
    var textFirstLineInWindow: CGPoint = .zero
    var cardTopInWindow: CGPoint = .zero
    enum ArrowDirection {
        case up
        case down
    }

    var arrowDirection: ArrowDirection = .down

    override func viewDidLoad() {
        super.viewDidLoad()

        let bgView = UIView()

        view.addSubview(bgView)
        view.addSubview(arrowView)
        view.addSubview(collectionView)

        bgView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }

        if textFirstLineInWindow.y > cardTopInWindow.y {
            arrowDirection = .down

            let pointInSelf = view.convert(textFirstLineInWindow, from: nil)
            collectionView.snp.makeConstraints { (maker) in
                maker.bottom.equalToSuperview().inset(view.bounds.height - pointInSelf.y + MinutesCommentsMenuLayout.arrowHeight)
                maker.height.equalTo(collectionHeight)
                maker.width.equalTo(collectionWidth)
                maker.centerX.equalToSuperview()
            }
        } else {
            arrowDirection = .up

            let pointInSelf = view.convert(cardTopInWindow, from: nil)
            collectionView.snp.makeConstraints { (maker) in
                maker.top.equalToSuperview().offset(pointInSelf.y + 10)
                maker.height.equalTo(collectionHeight)
                maker.width.equalTo(collectionWidth)
                maker.centerX.equalToSuperview()
            }
        }

        arrowView.snp.makeConstraints { (maker) in
            maker.edges.equalTo(collectionView)
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissSelf))
        bgView.addGestureRecognizer(tapGesture)
    }

    var maskPath: UIBezierPath?
    private lazy var arrowView: UIView = {
        return UIView()
    }()

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if maskPath == nil {
            let maskPath = UIBezierPath(roundedRect: arrowView.bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: 10, height: 10))
            self.maskPath = maskPath
            if !arrowViewHidden {
                if arrowDirection == .down {
                    maskPath.move(to: CGPoint(x: 28, y: arrowView.bounds.maxY))
                    maskPath.addLine(to: CGPoint(x: 38, y: arrowView.bounds.maxY + MinutesCommentsMenuLayout.arrowHeight))
                    maskPath.addLine(to: CGPoint(x: 48, y: arrowView.bounds.maxY))
                } else {
                    maskPath.move(to: CGPoint(x: 28, y: arrowView.bounds.minY))
                    maskPath.addLine(to: CGPoint(x: 38, y: arrowView.bounds.minY - MinutesCommentsMenuLayout.arrowHeight))
                    maskPath.addLine(to: CGPoint(x: 48, y: arrowView.bounds.minY))
                }
                maskPath.close()
            }

            let maskLayer = CAShapeLayer()
            maskLayer.shadowOffset = CGSize(width: 0, height: 1)
            maskLayer.shadowOpacity = 0.1
            maskLayer.borderWidth = 1.0

            maskLayer.path = maskPath.cgPath
            arrowView.layer.addSublayer(maskLayer)
            maskLayer.ud.setBorderColor(UIColor.ud.lineBorderCard)
            maskLayer.ud.setShadowColor(UIColor.ud.staticBlack)
            maskLayer.ud.setStrokeColor(UIColor.ud.lineBorderCard)
            maskLayer.ud.setFillColor(UIColor.ud.bgFloatOverlay)
        }
    }

    @objc func dismissSelf() {
        dismiss(animated: false, completion: nil)
    }
}

extension MinutesCommentsMenuController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = dataSource[indexPath.item]
        item.action?(nil)
    }
}

extension MinutesCommentsMenuController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MinutesCommentsMenuItemCell.description(), for: indexPath) as? MinutesCommentsMenuItemCell else {
            return UICollectionViewCell()
        }
        cell.configure(dataSource[indexPath.item])
        return cell
    }
}

extension MinutesCommentsMenuController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: MinutesCommentsMenuLayout.itemInset, bottom: 0, right: MinutesCommentsMenuLayout.itemInset)
    }
}
