//
//  BTCardLayoutColumnView.swift
//  SKBitable
//
//  Created by zhysan on 2023/1/10.
//

import UIKit
import SKFoundation
import SKResource
import UniverseDesignFont
import UniverseDesignColor

private struct Const {
    static let unitW = 97.0
    
    static var unitH: CGFloat {
        if UserScopeNoChangeFG.ZJ.btCardViewCoverEnable {
            return 88.0
        } else {
            return 96.0
        }
    }
    
    static let thumbDesignW = 97.0

    static var layerRadius: CGFloat {
      if UserScopeNoChangeFG.ZJ.btCardViewCoverEnable {
            return 6
        } else {
            return 8
        }
    }
    
    static var thumbDesignH: CGFloat {
        if UserScopeNoChangeFG.ZJ.btCardViewCoverEnable {
            return 56.0
        } else {
            return 64.0
        }
    }
}

protocol BTCardLayoutColumnViewDelegate: AnyObject {
    var hasCover: Bool { get }
    func onColumnTypeChanged(_ view: BTCardLayoutColumnView, columnType: BTTableLayoutSettings.ColumnType)
}

final class BTCardLayoutColumnView: BTTableSectionCardView {
    
    // MARK: - public
    
    weak var delegate: BTCardLayoutColumnViewDelegate?
    
    private(set) var currentColumnType: BTTableLayoutSettings.ColumnType = .three {
        didSet {
            updateSelection()
        }
    }
    
    func update(_ data: BTCardLayoutSettings.ColumnSection) {
        currentColumnType = data.columnType
        updateSettingUnitView()
    }
    
    // MARK: - life cycle
    
    init(frame: CGRect = .zero, delegate: BTCardLayoutColumnViewDelegate? = nil) {
        self.delegate = delegate
        super.init(frame: frame)
        subviewsInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - private
    
    private let stackView = UIStackView().construct { it in
        it.axis = .horizontal
        it.distribution = .equalSpacing
    }
    
    private var c1UnitView = SettingUnitView(config: SettingUnitView.Config(columnType: .one,
                                                                            isNewLayout: UserScopeNoChangeFG.ZJ.btCardViewCoverEnable))
    private var c2UnitView = SettingUnitView(config: SettingUnitView.Config(columnType: .two,
                                                                            isNewLayout: UserScopeNoChangeFG.ZJ.btCardViewCoverEnable))
    private var c3UnitView = SettingUnitView(config: SettingUnitView.Config(columnType: .three,
                                                                            isNewLayout: UserScopeNoChangeFG.ZJ.btCardViewCoverEnable))
    
    @objc
    private func onUnitTapped(_ sender: SettingUnitView) {
        let previousColumnType = currentColumnType
        let selectColumnType: BTTableLayoutSettings.ColumnType?
        switch sender {
        case c1UnitView:
            selectColumnType = .one
        case c2UnitView:
            selectColumnType = .two
        case c3UnitView:
            selectColumnType = .three
        default:
            spaceAssertionFailure("unknown sender")
            selectColumnType = nil
            return
        }
        if let type = selectColumnType, type != currentColumnType {
            currentColumnType = type
            delegate?.onColumnTypeChanged(self, columnType: type)
        }
    }
    
    private func updateSettingUnitView() {
        c1UnitView.config.hasCover = delegate?.hasCover ?? false
        c2UnitView.config.hasCover = delegate?.hasCover ?? false
        c3UnitView.config.hasCover = delegate?.hasCover ?? false
    }
    
    private func updateSelection() {
        c1UnitView.isSelected = (currentColumnType == .one)
        c2UnitView.isSelected = (currentColumnType == .two)
        c3UnitView.isSelected = (currentColumnType == .three)
    }
    
    private func subviewsInit() {
        headerText = BundleI18n.SKResource.Bitable_Mobile_CardMode_CardLayout_Title
        contentView.addSubview(stackView)
        
        stackView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(16)
            make.left.right.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().inset(18)
            make.height.equalTo(Const.unitH)
        }
        
        c3UnitView.snp.makeConstraints { make in
            make.height.equalTo(Const.unitH)
            make.width.equalTo(Const.unitW)
        }
        c2UnitView.snp.makeConstraints { make in
            make.height.equalTo(Const.unitH)
            make.width.equalTo(Const.unitW)
        }
        c1UnitView.snp.makeConstraints { make in
            make.height.equalTo(Const.unitH)
            make.width.equalTo(Const.unitW)
        }
        stackView.addArrangedSubview(c3UnitView)
        stackView.addArrangedSubview(c2UnitView)
        stackView.addArrangedSubview(c1UnitView)
        
        updateSelection()
        updateSettingUnitView()
        
        c3UnitView.tapAction = { [weak self] sender in
            self?.onUnitTapped(sender)
        }
        c2UnitView.tapAction = { [weak self] sender in
            self?.onUnitTapped(sender)
        }
        c1UnitView.tapAction = { [weak self] sender in
            self?.onUnitTapped(sender)
        }
    }
}

private extension BTTableLayoutSettings.ColumnType {
    var title: String {
        switch self {
        case .one:
            return "  \(BundleI18n.SKResource.Bitable_Mobile_CardMode_CardLayout_1Row1Column)  "
        case .two:
            return "  \(BundleI18n.SKResource.Bitable_Mobile_CardMode_CardLayout_1Row2Column)  "
        case .three:
            return "  \(BundleI18n.SKResource.Bitable_Mobile_CardMode_CardLayout_1Row3Column)  "
        }
    }
}

private final class SettingUnitView: UIView {
    
    // MARK: - public
    struct Config {
        var columnType: BTTableLayoutSettings.ColumnType
        var hasCover: Bool
        var isNewLayout: Bool
        
        init(columnType: BTTableLayoutSettings.ColumnType, isNewLayout: Bool, hasCover: Bool = false) {
            self.columnType = columnType
            self.isNewLayout = isNewLayout
            self.hasCover = hasCover
        }
    }
    
    var config: Config {
        didSet {
            diagramView.config = config
        }
    }
    
    var isSelected: Bool = false {
        didSet {
            updateSelection()
        }
    }
    
    var tapAction: ((SettingUnitView) -> Void)?
    
    // MARK: - life cycle
    init(frame: CGRect = .zero, config: Config) {
        self.config = config
        super.init(frame: frame)
        
        subviewsInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - private
    private lazy var diagramView = LayoutDiagramView(config: config)
    
    private lazy var titleButton = UIButton(type: .custom)
    
    private let startAnimationKey = "SettingUnitView.startAnimationKey"
    private let endAnimationKey = "SettingUnitView.endAnimationKey"
    
    private func updateSelection() {
        diagramView.isHighlighted = isSelected
        titleButton.isSelected = isSelected
        if isSelected {
            titleButton.backgroundColor = UDColor.primaryContentDefault
        } else {
            titleButton.backgroundColor = UIColor.clear
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.layer.removeAllAnimations()
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.toValue = 0.9
        animation.fromValue = 1.0
        animation.duration = 0.1
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        self.layer.add(animation, forKey: startAnimationKey)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.toValue = 1.0
        animation.fromValue = 0.9
        animation.duration = 0.1
        self.layer.add(animation, forKey: startAnimationKey)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.toValue = 1.0
        animation.fromValue = 0.9
        animation.duration = 0.1
        self.layer.add(animation, forKey: startAnimationKey)
    }
    
    @objc
    private func onUnitTapped(_ sender: UITapGestureRecognizer) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            [weak self] in
            guard let self = self else { return }
            self.tapAction?(self)
        }
    }
    
    private func subviewsInit() {
        addSubview(diagramView)
        addSubview(titleButton)
        
        diagramView.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(Const.thumbDesignH)
        }
        titleButton.snp.makeConstraints { make in
            make.bottom.centerX.equalToSuperview()
            make.height.equalTo(24)
            make.left.greaterThanOrEqualToSuperview().offset(8)
        }
        
        diagramView.isUserInteractionEnabled = false
        titleButton.isUserInteractionEnabled = false
        
        titleButton.clipsToBounds = true
        titleButton.layer.cornerRadius = 12
        titleButton.titleLabel?.font = UDFont.body2
        titleButton.setTitle(config.columnType.title, for: .normal)
        titleButton.setTitleColor(UDColor.textCaption, for: .normal)
        titleButton.setTitleColor(UDColor.primaryOnPrimaryFill, for: .selected)
        
        updateSelection()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onUnitTapped(_:)))
        tap.cancelsTouchesInView = false
        addGestureRecognizer(tap)
    }
}

private final class LayoutDiagramView: UIView {
    // MARK: - public
    
    var isHighlighted: Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var config: SettingUnitView.Config {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // MARK: - life cycle
    
    init(frame: CGRect = .zero, config: SettingUnitView.Config) {
        self.config = config
        super.init(frame: frame)
        if config.isNewLayout {
            layer.cornerRadius = Const.layerRadius
            backgroundColor = UDColor.bgBody
            clipsToBounds = true
        } else {
            backgroundColor = .clear
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        drawInsideBorder(rect)
        
        if config.isNewLayout {
            if config.hasCover {
                drawCoverRect(rect)
            }
            drawNewLine1(rect, hasCover: config.hasCover)
            drawNewLine34(rect, hasCover: config.hasCover)
        } else {
            drawLine1(rect)
            drawLine2(rect)
            drawLine34(rect)
        }
    }
    
    // MARK: - private
    
    private var line34FillColor: UIColor {
        isHighlighted ? UDColor.primaryContentDefault : UDColor.N500
    }
    
    private var newLine34FillColor: UIColor {
        isHighlighted ? UDColor.B200 : UDColor.N300
    }
    
    private func transformToDesign(_ rect: CGRect) -> CGAffineTransform {
        let sx = rect.width / Const.thumbDesignW
        let sy = rect.height / Const.thumbDesignH
        return CGAffineTransformMakeScale(sx, sy)
    }
    
    private func drawInsideBorder(_ rect: CGRect) {
        let lineWidth = isHighlighted ? 2.0 : 1.0
        let frame = rect.insetBy(dx: lineWidth * 0.5, dy: lineWidth * 0.5)
        let path = UIBezierPath(roundedRect: frame, cornerRadius: Const.layerRadius)
        path.lineWidth = lineWidth
        path.close()
        if isHighlighted {
            UDColor.primaryContentDefault.setStroke()
        } else {
            UDColor.lineBorderCard.setStroke()
        }
        path.stroke()
    }
    
    private func drawCoverRect(_ rect: CGRect) {
        let frame = CGRect(x: 8, y: 16.5, width: 18, height: 18).applying(transformToDesign(rect))
        let path = UIBezierPath(roundedRect: frame, cornerRadius: 4)
        path.close()
        if isHighlighted {
            UDColor.B200.setFill()
        } else {
            UDColor.N300.setFill()
        }
        path.fill()
    }
    
    private func drawNewLine1(_ rect: CGRect, hasCover: Bool = false) {
        let width: CGFloat = 36
        let height: CGFloat = 4
        
        let originX: CGFloat = hasCover ? 32 : 12
        let originY = hasCover ? 17.5 : 17
        
        drawRoundedRect_NxN(
            fillColor: isHighlighted ? UDColor.B400 : UDColor.N400,
            rect: rect,
            origin: CGPoint(x: originX, y: originY),
            lineSize: CGSize(width: width, height: height),
            row: 1,
            column: 1,
            spaceH: 0,
            spaceV: 0
        )
    }
    
    private func drawNewLine34(_ rect: CGRect, hasCover: Bool = false) {
        switch config.columnType {
        case .one:
            drawNewLine34_2x1(rect, hasCover)
        case .two:
            drawNewLine34_2x2(rect, hasCover)
        case .three:
            drawNewLine34_2x3(rect, hasCover)
        }
    }
    
    private func drawRoundedRect_NxN(
        fillColor: UIColor,
        rect: CGRect,
        origin: CGPoint,
        lineSize: CGSize,
        row: Int,
        column: Int,
        spaceH: CGFloat,
        spaceV: CGFloat
    ) {
        for r in 0..<row {
            for c in 0..<column {
                let x = origin.x + CGFloat(c) * (lineSize.width + spaceH)
                let y = origin.y + CGFloat(r) * (lineSize.height + spaceV)
                let w = lineSize.width
                let h = lineSize.height
                
                let frame = CGRect(x: x, y: y, width: w, height: h).applying(transformToDesign(rect))
                let path = UIBezierPath(roundedRect: frame, cornerRadius: frame.height * 0.5)
                path.close()
                fillColor.setFill()
                path.fill()
            }
        }
    }
    
    private func drawNewLine34_2x3(_ rect: CGRect, _ hasCover: Bool) {
        let width: CGFloat = hasCover ? 16 : 20
        let height: CGFloat = 4
        
        let spaceH: CGFloat = hasCover ? 4 : 6
        let spaceV: CGFloat = 4
        
        let originX: CGFloat = hasCover ? 32 : 12
        let originY = hasCover ? 27.5 : 27
        
        drawRoundedRect_NxN(
            fillColor: newLine34FillColor,
            rect: rect,
            origin: CGPoint(x: originX, y: originY),
            lineSize: CGSize(width: width, height: height),
            row: 2,
            column: 3,
            spaceH: spaceH,
            spaceV: spaceV
        )
    }
    
    private func drawNewLine34_2x2(_ rect: CGRect, _ hasCover: Bool) {
        let width: CGFloat = hasCover ? 26 : 33
        let height: CGFloat = 4
        
        let spaceH: CGFloat = hasCover ? 4 : 6
        let spaceV: CGFloat = 4
        
        let originX: CGFloat = hasCover ? 32 : 12
        let originY = hasCover ? 27.5 : 27
        
        drawRoundedRect_NxN(
            fillColor: newLine34FillColor,
            rect: rect,
            origin: CGPoint(x: originX, y: originY),
            lineSize: CGSize(width: width, height: height),
            row: 2,
            column: 2,
            spaceH: spaceH,
            spaceV: spaceV
        )
    }
    
    private func drawNewLine34_2x1(_ rect: CGRect, _ hasCover: Bool) {
        let width: CGFloat = hasCover ? 56 : 72
        let height: CGFloat = 4
        
        let spaceV: CGFloat = 4
        
        let originX: CGFloat = hasCover ? 32 : 12
        let originY = hasCover ? 27.5 : 27
        
        drawRoundedRect_NxN(
            fillColor: newLine34FillColor,
            rect: rect,
            origin: CGPoint(x: originX, y: originY),
            lineSize: CGSize(width: width, height: height),
            row: 2,
            column: 1,
            spaceH: 0,
            spaceV: spaceV
        )
    }
    
    private func drawLine1(_ rect: CGRect) {
        let frame = CGRect(x: 10, y: 11, width: 32, height: 8).applying(transformToDesign(rect))
        let path = UIBezierPath(roundedRect: frame, cornerRadius: frame.height * 0.5)
        path.close()
        if isHighlighted {
            UDColor.primaryContentLoading.setFill()
        } else {
            UDColor.N350.setFill()
        }
        path.fill()
    }
    
    private func drawLine2(_ rect: CGRect) {
        let frame = CGRect(x: 10, y: 24, width: 44, height: 4).applying(transformToDesign(rect))
        let path = UIBezierPath(roundedRect: frame, cornerRadius: frame.height * 0.5)
        path.close()
        if isHighlighted {
            UDColor.primaryFillSolid03.setFill()
        } else {
            UDColor.N300.setFill()
        }
        path.fill()
    }
    
    private func drawLine34(_ rect: CGRect) {
        switch config.columnType {
        case .one:
            drawLine34_2x1(rect)
        case .two:
            drawLine34_2x2(rect)
        case .three:
            drawLine34_2x3(rect)
        }
    }
    
    private func drawLine34_2x3(_ rect: CGRect) {
        let f1 = CGRect(x: 10, y: 36, width: 19, height: 6).applying(transformToDesign(rect))
        let p1 = UIBezierPath(roundedRect: f1, cornerRadius: f1.height * 0.5)
        p1.close()
        line34FillColor.setFill()
        p1.fill()
        
        let f2 = CGRect(x: 39, y: 36, width: 19, height: 6).applying(transformToDesign(rect))
        let p2 = UIBezierPath(roundedRect: f2, cornerRadius: f2.height * 0.5)
        p2.close()
        line34FillColor.setFill()
        p2.fill()
        
        let f3 = CGRect(x: 68, y: 36, width: 19, height: 6).applying(transformToDesign(rect))
        let p3 = UIBezierPath(roundedRect: f3, cornerRadius: f3.height * 0.5)
        p3.close()
        line34FillColor.setFill()
        p3.fill()
        
        let f4 = CGRect(x: 10, y: 47, width: 19, height: 6).applying(transformToDesign(rect))
        let p4 = UIBezierPath(roundedRect: f4, cornerRadius: f4.height * 0.5)
        p4.close()
        line34FillColor.setFill()
        p4.fill()
        
        let f5 = CGRect(x: 39, y: 47, width: 19, height: 6).applying(transformToDesign(rect))
        let p5 = UIBezierPath(roundedRect: f5, cornerRadius: f5.height * 0.5)
        p5.close()
        line34FillColor.setFill()
        p5.fill()
        
        let f6 = CGRect(x: 68, y: 47, width: 19, height: 6).applying(transformToDesign(rect))
        let p6 = UIBezierPath(roundedRect: f6, cornerRadius: f6.height * 0.5)
        p6.close()
        line34FillColor.setFill()
        p6.fill()
    }
    
    private func drawLine34_2x2(_ rect: CGRect) {
        let f1 = CGRect(x: 10, y: 36, width: 34, height: 6).applying(transformToDesign(rect))
        let p1 = UIBezierPath(roundedRect: f1, cornerRadius: f1.height * 0.5)
        p1.close()
        line34FillColor.setFill()
        p1.fill()
        
        let f2 = CGRect(x: 53, y: 36, width: 34, height: 6).applying(transformToDesign(rect))
        let p2 = UIBezierPath(roundedRect: f2, cornerRadius: f2.height * 0.5)
        p2.close()
        line34FillColor.setFill()
        p2.fill()
        
        let f3 = CGRect(x: 10, y: 47, width: 34, height: 6).applying(transformToDesign(rect))
        let p3 = UIBezierPath(roundedRect: f3, cornerRadius: f3.height * 0.5)
        p3.close()
        line34FillColor.setFill()
        p3.fill()
        
        let f4 = CGRect(x: 53, y: 47, width: 34, height: 6).applying(transformToDesign(rect))
        let p4 = UIBezierPath(roundedRect: f4, cornerRadius: f4.height * 0.5)
        p4.close()
        line34FillColor.setFill()
        p4.fill()
    }
    
    private func drawLine34_2x1(_ rect: CGRect) {
        let f1 = CGRect(x: 10, y: 36, width: 77, height: 6).applying(transformToDesign(rect))
        let p1 = UIBezierPath(roundedRect: f1, cornerRadius: f1.height * 0.5)
        p1.close()
        line34FillColor.setFill()
        p1.fill()
        
        let f2 = CGRect(x: 10, y: 47, width: 77, height: 6).applying(transformToDesign(rect))
        let p2 = UIBezierPath(roundedRect: f2, cornerRadius: f2.height * 0.5)
        p2.close()
        line34FillColor.setFill()
        p2.fill()
    }
}
