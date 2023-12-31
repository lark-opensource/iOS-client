//
//  BTProgressColorPickerViewController.swift
//  SKBitable
//
//  Created by yinyuan on 2022/12/6.
//

import SKFoundation
import SKUIKit
import HandyJSON
import SKResource
import UniverseDesignEmpty
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignProgressView


protocol BTProgressColorPickerViewControllerDelegate: AnyObject {
    func didSelectedColor(color: BTColor, relatedView: UIView?)
}

final class BTProgressColorPickerViewController: BTDraggableViewController {
    
    weak var delegate: BTProgressColorPickerViewControllerDelegate?
    
    weak var relatedView: UIView?
    
    private let colors: [BTColor]
    
    private var selectedColor: BTColor {
        didSet {
            update()
        }
    }
    
    private func update(animation: Bool = true) {
        progressPreviewView.updateProgress(progressColor: selectedColor)
        colorNameView.text = selectedColor.name
        
        // 进入时滚动到选中项
        if let index = colors.firstIndex { color in
            color.id == selectedColor.id
        } {
            colorsView.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredHorizontally, animated: animation)
        }
    }
    
    lazy var mainView: UIView = {
        let view = UIStackView()
        
        view.addSubview(progressBackgroundView)
        view.addSubview(colorsView)
        
        progressBackgroundView.snp.makeConstraints { make in
            make.left.top.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(180)
        }
        
        colorsView.snp.makeConstraints { make in
            make.top.equalTo(progressBackgroundView.snp.bottom).offset(24)
            make.left.right.equalToSuperview()
            make.height.equalTo(60)
        }
        
        return view
    }()
    
    lazy var colorNameView: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return view
    }()
    
    lazy var progressBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgFloat
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        
        let wrapperView = UIView()
        view.addSubview(wrapperView)
        wrapperView.addSubview(progressPreviewView)
        
        view.addSubview(colorNameView)
        
        colorNameView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-10)
            make.height.equalTo(24)
            make.centerX.equalToSuperview()
        }
        wrapperView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalTo(colorNameView.snp.top)
            make.left.right.equalToSuperview()
            make.width.equalTo(180)
        }
        progressPreviewView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(180)
        }
        
        return view
    }()
    
    final class ProgressPreviewView: UIStackView {
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setup()
        }
        
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setup() {
            axis = .vertical
        }
        
        func updateProgress(progressColor: BTColor) {
            // 显示 n 个进度条
            func showProgressViews(count: Int) {
                // spacingConfig[n] 表示显示 n 个进度条时进度条之间的间距
                let spacingConfig = [0, 28, 20, 17, 14]
                self.spacing = CGFloat(spacingConfig[count - 1])
                
                // progressValueConfigs[n] 表示显示 n 个进度条时，各进度条的展示进度
                let progressValueConfigs = [
                    [144.0 / 180.0],                                                                    // 1个进度条
                    [72.0 / 180.0, 108.0 / 180.0],                                                     // 2个进度条
                    [67.5 / 180.0, 112.5 / 180.0, 180.0 / 180.0],                                     // 3个进度条
                    [0.5, 0.5, 0.5, 0.5],                               // 4个进度条
                    [30.0 / 180.0, 60.0 / 180.0, 90.0 / 180.0, 120.0 / 180.0, 150.0 / 180.0]      // 5个进度条
                ]
                for i in 0..<progressValueConfigs.count {
                    if i < count {
                        // 进度条尚未初始化则先初始化
                        if self.arrangedSubviews.count <= i {
                            let progressView = BTProgressView()
                            progressView.minValue = 0
                            progressView.maxValue = 1
                            addArrangedSubview(progressView)
                            progressView.snp.makeConstraints { make in
                                make.width.equalToSuperview()
                                make.height.equalTo(10)
                            }
                        }
                        guard let progressView = self.arrangedSubviews[i] as? BTProgressView else {
                            continue
                        }
                        progressView.isHidden = false
                        progressView.progressColor = progressColor
                        if count - 1 < progressValueConfigs.count {
                            let progressValueConfig = progressValueConfigs[count - 1]
                            if i < progressValueConfig.count {
                                progressView.value = progressValueConfig[i]
                            } else {
                                progressView.value = 0.5
                            }
                        } else {
                            progressView.value = 0.5
                        }
                    } else {
                        // 暂时用不上的进度条隐藏掉
                        if self.arrangedSubviews.count > i {
                            self.arrangedSubviews[i].isHidden = true
                        }
                    }
                }
            }
            
            switch progressColor.type {
            case .multi:
                // 多段色有几个颜色就显示几个进度条
                showProgressViews(count: progressColor.color?.count ?? 0)
            case .gradient:
                // 渐变色显示 3 个进度条
                showProgressViews(count: 3)
            case .none:
                showProgressViews(count: progressColor.color?.count ?? 0)
            }
        }
    }
    
    
    lazy var progressPreviewView: ProgressPreviewView = {
        let view = ProgressPreviewView()
        return view
    }()
    
    final class BTProgressColorCell: UICollectionViewCell {
        
        lazy var selectedView: UIImageView = {
            let view = UIImageView()
            view.tintColor = UIColor.ud.primaryOnPrimaryFill
            view.image = UDIcon.listCheckOutlined.withRenderingMode(.alwaysTemplate)
            return view
        }()
        
        lazy var colorView: BTColorView = {
            let view = BTColorView()
            return view
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setup()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            layer.cornerRadius = self.frame.width / 2
            layer.masksToBounds = true
        }
        
        private func setup() {
            contentView.addSubview(colorView)
            contentView.addSubview(selectedView)
            colorView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
                make.width.equalTo(60)
                make.height.equalTo(60)
            }
            selectedView.snp.makeConstraints { make in
                make.width.height.equalTo(32)
                make.center.equalToSuperview()
            }
        }
    }
    
    lazy var colorsView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sectionInset = .init(top: 0, left: 16, bottom: 0, right: 16)
        layout.itemSize = .init(width: 60, height: 60)
        layout.minimumInteritemSpacing = 6
        
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.showsHorizontalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
        view.register(BTProgressColorCell.self, forCellWithReuseIdentifier: BTProgressColorCell.reuseIdentifier)
        
        return view
    }()
    
    
    init(colors: [BTColor], selectedColor: BTColor, relatedView: UIView? = nil) {
        self.colors = colors
        self.selectedColor = selectedColor
        self.relatedView = relatedView
        super.init(title: BundleI18n.SKResource.Bitable_Progress_ProgressBarColor_Title,
                   shouldShowDragBar: false,
                   shouldShowDoneButton: false)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var maxViewHeight: CGFloat {
        SKDisplay.windowBounds(self.view).height
    }
    
    override func setupUI() {
        super.setupUI()
        initViewHeight = 348.0 + 48
        
        contentView.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.top.left.right.bottom.equalToSuperview()
        }
        
        colorsView.reloadData()
        colorsView.layoutIfNeeded()
        update(animation: false)
    }
    
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        guard self.navigationController?.modalPresentationStyle == .overFullScreen,
              !self.hasBackPage else { return }
        
        let contenViewHeight = min(initViewHeight + view.safeAreaInsets.bottom, maxViewHeight)
        containerView.snp.remakeConstraints { make in
            make.height.equalTo(contenViewHeight)
            make.left.right.bottom.equalToSuperview()
        }
    }
    
}

extension BTProgressColorPickerViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colors.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BTProgressColorCell.reuseIdentifier, for: indexPath)
        if let cell = cell as? BTProgressColorCell {
            let color = colors[indexPath.row]
            cell.colorView.progressColor = color
            cell.selectedView.isHidden = (color != selectedColor)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        selectedColor = colors[indexPath.row]
        delegate?.didSelectedColor(color: selectedColor, relatedView: relatedView)
        collectionView.performBatchUpdates {
            collectionView.reloadSections(.init(integer: 0))
        } completion: { _ in
            CATransaction.commit()
        }
    }
}
