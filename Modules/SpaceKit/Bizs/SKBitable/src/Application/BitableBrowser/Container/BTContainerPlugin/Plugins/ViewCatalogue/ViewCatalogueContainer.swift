//
//  ViewCatalogueContainer.swift
//  SKBitable
//
//  Created by yinyuan on 2023/8/28.
//

import UIKit
import UniverseDesignIcon
import UniverseDesignColor
import SKCommon

protocol ViewCatalogueDelegate: AnyObject {
    func viewCatalogueMoreClick(sourceView: UIView)
    func viewCatalogue(sourceView: UIView, didSelect index: Int)
}

protocol ViewCatalogueService: AnyObject {
    func callFunction(_ function: DocsJSCallBack, params: [String: Any]?, completion: ((_ info: Any?, _ error: Error?) -> Void)?)
    func shouldPopoverDisplay() -> Bool
}

class ViewCatalogueContainer: UIView {
    
    public weak var delegate: ViewCatalogueDelegate?

    private let yOffset: CGFloat

    init(yOffset: CGFloat = 0) {
        self.yOffset = yOffset
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var viewCatalogue: ViewCatalogue = {
        let catalogue = ViewCatalogue()
        catalogue.backgroundColor = .clear
        return catalogue
    }()
    
    private lazy var moreButton: UIButton = {
        let button = UIButton()
        let image = UDIcon.getIconByKey(.menuOutlined).ud.resized(to: CGSize(width: 20, height: 20))
        button.setImage(image, withColorsForStates: [(UDColor.iconN2, .normal), (UDColor.iconDisabled, .highlighted)])
        button.addTarget(self, action: #selector(moreButtonClick), for: .touchUpInside)
        return button
    }()
    
    lazy var gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.startPoint = CGPoint(x: 0.5, y: 0) // 渐变起点位于视图顶部中央
        layer.endPoint = CGPoint(x: 0.5, y: 1) // 渐变终点位于视图底部中央
        return layer
    }()
    
    private func setup() {
        viewCatalogue.selectBlock = { [weak self] index in
            guard let self = self else {
                return
            }
            self.delegate?.viewCatalogue(sourceView: self, didSelect: index)
        }
        
        layer.insertSublayer(gradientLayer, at: 0)
        updateDarkMode()
        
        addSubview(viewCatalogue)
        viewCatalogue.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.centerY.equalToSuperview().offset(yOffset)
            make.height.equalTo(40)
        }
        
        addSubview(moreButton)
        moreButton.snp.makeConstraints { make in
            make.size.equalTo(36)
            make.trailing.equalToSuperview().offset(-11)
            make.centerY.equalToSuperview().offset(yOffset)
        }
    }
    
    @objc
    private func moreButtonClick() {
        delegate?.viewCatalogueMoreClick(sourceView: moreButton)
    }
    
    private func updateGradientLayerFrame() {
        // 最小 maxWindowWidth，不然宽窄变化时渐变色跟不上动画
        gradientLayer.frame = CGRectMake(0, 0, max(self.layer.bounds.width, maxWindowWidth), self.layer.bounds.height)
    }
    
    var maxWindowWidth: CGFloat = 1366 {
        didSet {
            updateGradientLayerFrame()
        }
    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        updateGradientLayerFrame()
    }

    func setData(currentViewData: BTViewContainerModel, animated: Bool = true) {
        viewCatalogue.setData(currentViewData: currentViewData, animated: animated)
    }
    
    func updateDarkMode() {
        gradientLayer.ud.setColors([BTContainer.Constaints.viewCatalogueTopColor, BTContainer.Constaints.viewCatalogueBottomColor])
    }
}
