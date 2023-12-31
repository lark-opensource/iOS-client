//
//  DocsToolBarHighlightCell.swift
//  SKBrowser
//
//  Created by lizechuang on 2020/8/10.
//

import UIKit
import SKCommon
import SKResource
import UniverseDesignColor
import UniverseDesignIcon

public protocol DocsToolBarHighlightCellDelegate: AnyObject {
    func hasChooseAction(isOpenPanel: Bool, index: IndexPath)
}

public final class DocsToolBarHighlightCell: UICollectionViewCell, HighlightColorEffectViewDelegate, DocsMainToolBarV2Delegate {
    public weak var delegate: DocsToolBarHighlightCellDelegate?
    public var index: IndexPath?
    public var needRotation: Bool = false
    private var highlightColorView: DocsToolBarHighlightColorView
    private var selectView: DocsToolBarHighlightColorSelectView
    private var bgView: UIView
    private var selectViewSelectedFlag: Bool = false
    private var _selectedFlag: Bool = false
//    private var selectedColor: UIColor = UIColor.ud.N200
    private var bgColor: UIColor = .clear
//    private var selectViewBgColor: UIColor = .clear
    private var selectedBgColor: UIColor = UDColor.N100
    private var colorViewBgColor: UIColor = .clear
    private var colorViewHighlightBgColor: UIColor = .clear
    private var selectViewBgColor: UIColor = .clear
    private var selectViewHighlightBgColor: UIColor = .clear
    private var hasSetBackgroundColor = false

    public var isEnabled: Bool = true {
        didSet {
            contentView.isUserInteractionEnabled = isEnabled
            guard !isEnabled else { return }
            highlightColorView.bgColorView.alpha = 0.5
            selectView.icon.alpha = 0.5
        }
    }
    override init(frame: CGRect) {
        highlightColorView = DocsToolBarHighlightColorView()
        selectView = DocsToolBarHighlightColorSelectView()
        bgView = UIView()
        bgView.layer.cornerRadius = 8
        super.init(frame: frame)
        setupSubViews()
    }

    private func setupSubViews() {
        contentView.addSubview(bgView)
        bgView.addSubview(highlightColorView)
        bgView.addSubview(selectView)
        bgView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.height.equalTo(DocsToolBar.Const.bgColorWidth)
        }
        highlightColorView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.height.width.equalTo(DocsToolBar.Const.highlightColorWidth)
            make.left.equalTo(DocsToolBar.Const.highlightCellInset)
        }
        highlightColorView.docs.addStandardLift()
        highlightColorView.delegate = self
        selectView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.height.equalTo(DocsToolBar.Const.highlightColorWidth)
            make.left.equalTo(highlightColorView.snp.right)
            make.width.equalTo(DocsToolBar.Const.imageWidth)
            make.right.equalToSuperview().inset(DocsToolBar.Const.highlightCellInset)
        }
        selectView.docs.addHighlight(with: .zero, radius: 6)
        selectView.delegate = self
        setupTapGR()
    }

    private func setupTapGR() {
        let applyTapGR = UITapGestureRecognizer(target: self, action: #selector(applyHighlight))
        highlightColorView.addGestureRecognizer(applyTapGR)
        let selectTapGR = UITapGestureRecognizer(target: self, action: #selector(openHighlightSelectView))
        selectView.addGestureRecognizer(selectTapGR)
    }

    ///Block快捷菜单自定义highlightColorView和selectView的size
    public func updateFrame(highlightColorViewSize size: CGSize, selectViewWidth: CGFloat) {
        selectView.snp.updateConstraints { (make) in
            make.height.equalTo(size.height)
            make.width.equalTo(selectViewWidth)
        }

        highlightColorView.snp.updateConstraints { (make) in
            make.height.equalTo(size.height)
            make.width.equalTo(size.width)
        }

        bgView.snp.updateConstraints { (make) in
            make.height.equalTo(size.height)
        }

        highlightColorView.docs.removeAllPointer()
        selectView.docs.removeAllPointer()
        highlightColorView.docs.addStandardHover()
        selectView.docs.addStandardHover()
        highlightColorView.layer.maskedCorners = .left
        selectView.layer.maskedCorners = .right
        layoutIfNeeded()
    }

    /// 设置高亮色cell的颜色
    /// - Parameters:
    ///   - colorViewBgColor: highlightColorView常态下的背景色
    ///   - colorViewHighlightBgColor: highlightColorView选中态的背景色
    ///   - selectViewBgColor: selectView常态下的背景色
    ///   - selectViewHighlightBgColor: selectView选中态的背景色
    public func setViewBackgroundColor(colorViewBgColor: UIColor,
                                 colorViewHighlightBgColor: UIColor,
                                 selectViewBgColor: UIColor,
                                 selectViewHighlightBgColor: UIColor) {
        self.colorViewBgColor = colorViewBgColor
        self.colorViewHighlightBgColor = colorViewHighlightBgColor
        self.selectViewBgColor = selectViewBgColor
        self.selectViewHighlightBgColor = selectViewHighlightBgColor
        self.selectedBgColor = .clear
        self.hasSetBackgroundColor = true
    }
    
    public func updateHighlightIcon(_ length: CGFloat) {
        highlightColorView.updateIcon(length)
    }

    public func lightItUp(light: Bool, image: UIImage) {
        _selectedFlag = light
        self.bgView.backgroundColor = (light || selectViewSelectedFlag) ? selectedBgColor : .clear
        self.highlightColorView.icon.image = image.withRenderingMode(.alwaysTemplate).ud.withTintColor(UDColor.iconN1)

        if hasSetBackgroundColor {
            self.selectView.backgroundColor = selectViewBgColor
            self.highlightColorView.backgroundColor = colorViewBgColor
            return
        }
        if selectViewSelectedFlag {
            self.selectView.backgroundColor = selectedBgColor
            self.highlightColorView.backgroundColor = .clear
            return
        }
        self.highlightColorView.backgroundColor = light ? selectedBgColor : .clear
    }

    func lightSelectView() {
        self.bgView.backgroundColor = selectedBgColor
        self.highlightColorView.backgroundColor = .clear
        selectViewSelectedFlag = true
    }

    public func updateHighlightColor(for rawData: [String: Any]?) {
        if let backgroundData = rawData?["background"] as? [String: Any],
            let textData = rawData?["text"] as? [String: Any],
            let bgValueDict = backgroundData["value"] as? [String: CGFloat],
            let textValueDict = textData["value"] as? [String: CGFloat] {
            highlightColorView.bgColorView.backgroundColor = ColorPaletteItemV2.ColorInfo(bgValueDict).color
            _updateIconColor(color: ColorPaletteItemV2.ColorInfo(textValueDict).color)
        } else if let backgroundData = rawData?["background"] as? [String: Any],
            let valueDict = backgroundData["value"] as? [String: CGFloat] {
            highlightColorView.bgColorView.backgroundColor = ColorPaletteItemV2.ColorInfo(valueDict).color
            _updateIconColor(color: UDColor.N800)
        } else if let textData = rawData?["text"] as? [String: Any],
            let valueDict = textData["value"] as? [String: CGFloat] {
            highlightColorView.bgColorView.backgroundColor = .clear
            _updateIconColor(color: ColorPaletteItemV2.ColorInfo(valueDict).color)
        }
    }

    @objc
    func applyHighlight() {
        if let curIndex = index {
            delegate?.hasChooseAction(isOpenPanel: false, index: curIndex)
        }
    }

    @objc
    func openHighlightSelectView() {
        if let curIndex = index {
            if needRotation {
                selectView.rotationAnimate(isDismissPanel: false, completion: { [weak self] _ in
                    guard let `self` = self else { return }
                    self.delegate?.hasChooseAction(isOpenPanel: true, index: curIndex)
                })
                return
            }
            delegate?.hasChooseAction(isOpenPanel: true, index: curIndex)
        }
    }

    private func _updateIconColor(color: UIColor?) {
        if let image = highlightColorView.icon.image, let curColor = color {
            highlightColorView.icon.image = isEnabled ? image.ud.withTintColor(curColor) : image.ud.withTintColor(curColor.withAlphaComponent(0.5))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func effectViewBeingTap(effectView: HighlightColorEffectView) {
        self.bgView.backgroundColor = bgColor
        if effectView is DocsToolBarHighlightColorView {
            if hasSetBackgroundColor {
                self.highlightColorView.backgroundColor = colorViewHighlightBgColor
                return
            }
            self.selectView.backgroundColor = .clear
        } else {
            if hasSetBackgroundColor {
                self.selectView.backgroundColor = selectViewHighlightBgColor
                return
            }
            self.highlightColorView.backgroundColor = .clear
        }
    }

    func effectViewHadEndTap(effectView: HighlightColorEffectView, isCancell: Bool) {
        if hasSetBackgroundColor {
            self.highlightColorView.backgroundColor = colorViewBgColor
            self.selectView.backgroundColor = selectViewBgColor
            return
        }

        if !isCancell || effectView is DocsToolBarHighlightColorSelectView {
            self.bgView.backgroundColor = _selectedFlag ? selectedBgColor : bgColor
            self.highlightColorView.backgroundColor = _selectedFlag ? UDColor.N200 : .clear
        }
    }

    func rotationHighlightColorSelectView() {
        //下掉颜色选择面板，取消小三角的选中态
        selectView.rotationAnimate(isDismissPanel: true, completion: nil)
        selectViewSelectedFlag = false
        selectView.backgroundColor = .clear
        bgView.backgroundColor = _selectedFlag ? selectedBgColor : .clear
        highlightColorView.backgroundColor = _selectedFlag ? UDColor.N200 : .clear
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        if !DocsMainToolBarV2.hasPresentHighlightPanle {
            selectView.restIconAngle()
        } else {
            selectView.rotationAnimate(animation: false, isDismissPanel: false, completion: nil)
        }
    }
}

class DocsToolBarHighlightColorView: HighlightColorEffectView {
    lazy var icon: UIImageView = UIImageView()
    lazy var bgColorView: UIView = UIView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubViews()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubViews() {
        addSubview(bgColorView)
        addSubview(icon)
        backgroundColor = .clear
        layer.cornerRadius = 6
        bgColorView.backgroundColor = .clear
        bgColorView.layer.cornerRadius = 6
        bgColorView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.height.equalTo(DocsToolBar.Const.highlightColorWidth)
        }
        icon.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.height.equalTo(DocsToolBar.Const.imageWidth)
        }
    }
    
    func updateIcon(_ length: CGFloat) {
        icon.snp.updateConstraints { (make) in
            make.width.height.equalTo(length)
        }
    }
}

class DocsToolBarHighlightColorSelectView: HighlightColorEffectView {
    lazy var icon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.getIconByKey(.expandDownFilled, size: CGSize(width: 12, height: 12)).ud.withTintColor(UIColor.ud.iconN1)
        return imageView
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        layer.cornerRadius = 6
        addSubview(icon)
        icon.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }

        //设置小三角初始状态
        if DocsMainToolBarV2.hasPresentHighlightPanle {
            rotationAnimate(animation: false, isDismissPanel: false, completion: nil)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //小三角旋转动画
    func rotationAnimate(animation: Bool = true, isDismissPanel: Bool, completion: ((Bool) -> Void)?) {
        //图片上下翻转
        UIView.animate(withDuration: animation ? 0.3 : 0, animations: {
            let rotationAngle = isDismissPanel ? 2 * CGFloat.pi : CGFloat.pi
            let transform = CGAffineTransform(rotationAngle: rotationAngle)
            self.icon.transform = transform
        }, completion: completion)
    }

    func restIconAngle() {
        icon.transform = .identity
    }
}

protocol HighlightColorEffectViewDelegate: AnyObject {
    func effectViewBeingTap(effectView: HighlightColorEffectView)
    func effectViewHadEndTap(effectView: HighlightColorEffectView, isCancell: Bool)
}

class HighlightColorEffectView: UIView {
    weak var delegate: HighlightColorEffectViewDelegate?
    let effectView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 6.0
        view.backgroundColor = .clear
        return view
    }()

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if effectView.superview == nil {
            delegate?.effectViewBeingTap(effectView: self)
            addSubview(effectView)
            sendSubviewToBack(effectView)
            effectView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if effectView.superview != nil {
            UIView.animate(withDuration: 0.15, animations: {
                self.effectView.backgroundColor = .clear
            }, completion: { (_) in
                self.effectView.removeFromSuperview()
                self.delegate?.effectViewHadEndTap(effectView: self, isCancell: true)
            })
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if effectView.superview != nil {
            UIView.animate(withDuration: 0.15, animations: {
                self.effectView.backgroundColor = .clear
            }, completion: { (_) in
                self.effectView.removeFromSuperview()
                self.delegate?.effectViewHadEndTap(effectView: self, isCancell: false)
            })
        }
    }
}
