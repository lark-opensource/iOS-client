//
//  CatalogSideViewCell.swift
//  SKDoc
//
//  Created by lizechuang on 2021/3/31.
//

import SKFoundation
import LarkUIKit
import UniverseDesignColor
import LarkInteraction
import SKUIKit
import UniverseDesignFont

class CatalogSideViewCell: UICollectionViewCell {

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.N600
        label.textAlignment = .left
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var tipLabel: UDLabel = {
        let label = UDLabel()
        label.isUserInteractionEnabled = false
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        label.textColor = UDColor.N00
        label.backgroundColor = UDColor.N700
        label.numberOfLines = 0
        label.contentInset = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        label.font = UIFont.ud.body2
        return label
    }()
    
    //记录鼠标位置
    var pointerLocation: CGPoint = .zero
    
    var hoverWorkItem: DispatchWorkItem?
    
    private var needShowTip: Bool {
        titleLabel.text?.lineCount(width: titleLabel.frame.width, font: titleLabel.font) ?? 1 > 1
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(titleLabel)
        selectedBackgroundView = BaseCellSelectView()
        setRoundCorners(with: 6)
        if UserScopeNoChangeFG.LJW.catalogHoverTipEnabled {
            addHover()
        } else {
            docs.addStandardHover()
        }
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(IPadCatalogConst.lineOffsetX)
            make.right.equalToSuperview().offset(-IPadCatalogConst.lineOffsetX)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.hideHoverTip()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.hideHoverTip()
    }

    public func configure(by item: CatalogItemDetail, fontZoomable: Bool) {
        let weight: UIFont.Weight = (item.level == 1) ? .medium : .regular
        if fontZoomable {
            titleLabel.font = UIFont.ud.body0
        } else {
            titleLabel.font = UIFont.systemFont(ofSize: 14, weight: weight)
        }
        titleLabel.text = item.title
        if item.level >= 1 {
            let offSetX = CGFloat(item.level) * IPadCatalogConst.lineOffsetX
            titleLabel.snp.updateConstraints { (make) in
                make.left.equalToSuperview().offset(offSetX)
            }
        }
    }

    public func highlight(_ light: Bool, shouldSetCorner: Bool) {
        titleLabel.textColor = light ? UDColor.colorfulBlue : UDColor.N600
        self.backgroundColor = light ? UDColor.fillActive : UDColor.bgBody
    }

    private func addHover() {
        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(style: .init(effect: .hover(prefersScaledContent: false)))
            pointer.handler = { [weak self] (_, request, region) -> UIPointerRegion? in
                self?.pointerLocation = request.location
                return region
            }
            pointer.animating.addWillEnter { [weak self] _, _ in
                if self?.needShowTip == true {
                    let workItem = DispatchWorkItem { [weak self] in
                        guard let self, let window = self.window else { return }
                        self.window?.addSubview(self.tipLabel)
                        self.tipLabel.text = self.titleLabel.text
                        //先计算光标在window上的位置
                        let pointInWindow = self.convert(self.pointerLocation, to: window)
                        let minX = pointInWindow.x + 13
                        //tipLabel最大宽度取400和（minX到window右边缘距离）的最小值
                        let maxWidth = min(window.frame.width - minX - 8, 400)
                        //根据最大宽度计算tipLabel尺寸
                        let size = self.tipLabel.sizeThatFits(CGSize(width: maxWidth, height: CGFloat(MAXFLOAT)))
                        //根据光标的位置决定tipLabel的y值
                        //若光标在window上半部，则tipLabel出现在光标右下方
                        //若光标在window下半部，tipLabel出现在光标右上方
                        let offsetY = pointInWindow.y <= window.frame.height / 2 ? 16 : -16 - size.height
                        let originPoint = CGPoint(x: minX, y: pointInWindow.y + offsetY)
                        self.tipLabel.frame = CGRect(origin: originPoint, size: size)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
                    self?.hoverWorkItem = workItem
                }
            }
            pointer.animating.addWillExit { [weak self] _, _ in
                self?.hideHoverTip()
            }
            self.addLKInteraction(pointer)
        }
    }

    private func hideHoverTip() {
        self.hoverWorkItem?.cancel()
        self.hoverWorkItem = nil
        self.tipLabel.removeFromSuperview()
    }
}

private extension UIView {
    //设置部分圆角
    func setRoundCorners(with radii: CGFloat) {
        layer.cornerRadius = radii
        layer.maskedCorners = .all
    }
}
