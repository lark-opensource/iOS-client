//
//  FloatPickerView.swift
//  ByteViewUI
//
//  Created by lutingting on 2022/12/16.
//

import Foundation

public protocol FloatPickerViewDelegate: AnyObject {
    func didSelectItem(at index: Int)
}

public protocol FloatPickerViewDataSource: AnyObject {
    func numberOfItemsInSection() -> Int
    func cellForItem(at index: Int) -> UIImage?
}

class FloatPickerCell: UICollectionViewCell {
    private static let defaultSize: CGFloat = 32

    let iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleToFill
        view.accessibilityLabel = "vc.reaction.skin.cell.icon"
        return view
    }()

    var image: UIImage? {
        didSet {
            iconView.image = image
        }
    }

    override var isSelected: Bool {
        didSet {
            contentView.backgroundColor = isSelected ? .ud.primaryContentDefault : .clear
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.masksToBounds = true
        contentView.layer.cornerRadius = 6
        contentView.addSubview(iconView)

        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(Self.defaultSize)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct FlowPickerLayoutConfig {
    let sourceView: UIView
    let viewSize: CGSize

    var itemSize: CGSize = CGSize(width: 44, height: 44)
    var contentInset: UIEdgeInsets = .zero
    var itemSpacing: CGFloat = 0
    var direction: GuideDirection = .top
    var distance: CGFloat = 3
    var borderWidth: CGFloat = 0
    var borderColor: UIColor = .clear
    var contentBGColor: UIColor = .clear
    var cornerRadius: CGFloat = 0
}

class FloatPickerView: UIView {
    private static let cellId = FloatPickerCell.description()

    public weak var delegate: FloatPickerViewDelegate?
    public weak var dataSource: FloatPickerViewDataSource?

    var tapCallBack: (() -> Void)?

    private lazy var collectView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = layoutConfig.itemSize
        layout.sectionInset = layoutConfig.contentInset
        layout.minimumInteritemSpacing = layoutConfig.itemSpacing
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(FloatPickerCell.self, forCellWithReuseIdentifier: Self.cellId)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.isScrollEnabled = false
        return collectionView
    }()

    private(set) lazy var anchorView: AnchorView = {
        let anchorView = AnchorView(wrapperView: collectView)
        anchorView.direction = layoutConfig.direction
        anchorView.borderWidth = layoutConfig.borderWidth
        anchorView.borderColor = layoutConfig.borderColor
        anchorView.contentBGColor = layoutConfig.contentBGColor
        anchorView.cornerRadius = layoutConfig.cornerRadius // 8
        anchorView.size = layoutConfig.viewSize
        anchorView.distance = layoutConfig.distance
        anchorView.sourceView = layoutConfig.sourceView
        anchorView.shadowType = .s3Down
        return anchorView
    }()

    private let layoutConfig: FlowPickerLayoutConfig

    public init(layoutConfig: FlowPickerLayoutConfig) {
        self.layoutConfig = layoutConfig
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        updateLayout()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        tapCallBack?()
    }

    func setupView() {
        addSubview(anchorView)
        anchorView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func updateLayout() {
        anchorView.updateLayout()
    }

    func getSubViewFrame(on view: UIView) -> [CGRect] {
        guard let allCount = dataSource?.numberOfItemsInSection() else { return [] }
        var frames: [CGRect] = []
        for i in 0...allCount {
            if let cell = collectView.cellForItem(at: IndexPath(item: i, section: 0)) {
                let frame = cell.convert(cell.bounds, to: view)
                frames.append(frame)
            }
        }
        return frames
    }

    func selectItemAt(_ index: Int) {
        collectView.selectItem(at: IndexPath(item: index, section: 0), animated: false, scrollPosition: .centeredHorizontally)
    }
}


extension FloatPickerView: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource?.numberOfItemsInSection() ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.cellId, for: indexPath) as? FloatPickerCell else { return UICollectionViewCell() }
        cell.image = dataSource?.cellForItem(at: indexPath.item)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.didSelectItem(at: indexPath.item)
    }
}
