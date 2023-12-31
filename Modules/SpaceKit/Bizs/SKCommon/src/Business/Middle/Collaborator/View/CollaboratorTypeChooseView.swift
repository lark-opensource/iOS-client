//
//  CollaboratorTypeChooseView.swift
//  SpaceKit
//
//

import Foundation
import SKUIKit
import UniverseDesignColor

protocol CollaboratorTypeChooseViewDelegate: AnyObject {
    func collaboratorTypeChooseView(_ collaboratorTypeChooseView: CollaboratorTypeChooseView, didClickTypeAt index: Int)
}

/// 一级分类选择
class CollaboratorTypeChooseView: UIView {
    weak var delegate: CollaboratorTypeChooseViewDelegate?
    private let blueLineView: UIView = {
        let line = UIView()
        line.layer.cornerRadius = 2
        line.backgroundColor = UIColor.ud.colorfulBlue
        return line
    }()
    private let bottomLineView: UIView = {
        let line = UIView()
        line.backgroundColor = UDColor.lineDividerDefault
        return line
    }()
    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.alignment = .fill
        sv.distribution = .fillEqually
        sv.spacing = 0.0
        return sv
    }()
    private let typeNames: [String]
    private var itemViews: [ItemView] = []
    private var blueLineWidths: [CGFloat] = []
    private let isBlueLineAlignToText: Bool
    
    init(names: [String], isBlueLineAlignToText: Bool = false) {
        typeNames = names
        self.isBlueLineAlignToText = isBlueLineAlignToText
        super.init(frame: .zero)
        setupSubviews()
        calculateBlueLineWidths()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        calculateBlueLineWidths()
        if let index = itemViews.firstIndex(where: { $0.selected }) {
            stackView.layoutIfNeeded()
            blueLineView.frame = frameOfBlueLine(at: index)
        }
    }

    func select(at index: Int, animated: Bool) {
        select(at: index, animated: animated, needNotifyDelegate: false)
    }
    
    func currentSelectIndex() -> Int? {
        return itemViews.firstIndex(where: { $0.selected })
    }
    
    private func setupSubviews() {
        addSubview(stackView)
        addSubview(bottomLineView)
        addSubview(blueLineView)
        for index in 0..<typeNames.count {
            let typeName = typeNames[index]
            let itemView = createItemView()
            itemView.label.text = typeName
            itemView.tag = index
            stackView.addArrangedSubview(itemView)
            itemViews.append(itemView)
            itemView.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
            }
        }
        setupSubviewsConstraints()
    }
    private func setupSubviewsConstraints() {
        stackView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(10)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(bottomLineView.snp.top).offset(-8)
        }
        bottomLineView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.height.equalTo(1)
            make.bottom.equalToSuperview()
        }
    }
    
    private func select(at index: Int, animated: Bool, needNotifyDelegate: Bool) {
        guard index >= 0 && index < typeNames.count else {
            return
        }
        if let curSelectItemView = itemViews.first(where: { $0.selected }) {
            if curSelectItemView.tag == index {
                return
            }
            curSelectItemView.selected = false
        }
        itemViews[index].selected = true
        let blueLineFrame = frameOfBlueLine(at: index)
        if animated {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.64, initialSpringVelocity: 0, options: [.curveEaseOut], animations: {() -> Void in
                self.blueLineView.frame = blueLineFrame
            }, completion: nil)
        } else {
            self.blueLineView.frame = blueLineFrame
        }
        if needNotifyDelegate {
            delegate?.collaboratorTypeChooseView(self, didClickTypeAt: index)
        }
    }
    
    @objc
    private func didClickTypaNameLabel(tap: UITapGestureRecognizer) {
        guard let itemView = tap.view as? ItemView else {
            return
        }
        select(at: itemView.tag, animated: true, needNotifyDelegate: true)
        SKCreateTracker.reportClickTemplatePrimaryTab(type: itemView.label.text ?? "")
    }
    
    private func frameOfBlueLine(at index: Int) -> CGRect {
        guard index >= 0 && index < itemViews.count && index < blueLineWidths.count else {
            return .zero
        }
        let center = itemViews[index].center
        let width = blueLineWidths[index]
        let height: CGFloat = 2.0
        let blueLineFrame = CGRect(x: center.x - width / 2.0,
                                   y: self.frame.height - height,
                                   width: width,
                                   height: height)
        return blueLineFrame
    }

    private func calculateBlueLineWidths() {
        guard typeNames.count > 0 else {
            blueLineWidths = []
            return
        }
        var widths: [CGFloat] = []
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)
        ]
        let itemViewWidth: CGFloat = self.frame.width / CGFloat(typeNames.count)
        typeNames.forEach { text in
            var width: CGFloat = itemViewWidth
            if isBlueLineAlignToText {
                let attributedStr = NSAttributedString(string: text,
                                                       attributes: attributes)
                let maxWidth = itemViewWidth - 2 * ItemView.margin
                width = min(attributedStr.estimatedSingleLineUILabelWidth, maxWidth)
            }
            widths.append(width)
        }
        blueLineWidths = widths
    }
    
    private func createItemView() -> ItemView {
        let itemView = ItemView()
        let tap = UITapGestureRecognizer(target: self, action: #selector(didClickTypaNameLabel(tap:)))
        itemView.addGestureRecognizer(tap)
        return itemView
    }
    
    private class ItemView: UIView {
        static let margin: CGFloat = 4.0
        let label: UILabel = {
            let lb = UILabel()
            lb.textAlignment = .center
            lb.font = UIFont.systemFont(ofSize: 16)
            lb.textColor = UDColor.textCaption
            lb.docs.addStandardHighlight()
            lb.numberOfLines = 0
            return lb
        }()
        
        var selected: Bool = false {
            didSet {
                label.textColor = selected ? UIColor.ud.colorfulBlue : UDColor.textCaption
            }
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            addSubview(label)
            label.snp.makeConstraints { make in
                make.left.right.top.bottom.equalToSuperview()
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
