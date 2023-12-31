//
//  TranslatedView.swift
//  ByteView
//
//  Created by helijian on 2021/11/9.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignIcon
import ByteViewUI

protocol TranslatedViewDelegate: AnyObject {
    func lanuageItemDidTap()
}

enum TranslatedViewConfigure {
    case leftMargin(CGFloat)
    case rightMargin(CGFloat)
    case minimumWidth(CGFloat)
    case maximumWidth(CGFloat)
    case minimumResultHeight(CGFloat)
    case maximumResultHeight(CGFloat)
}

class TranslateViewCell: UITableViewCell {
    private lazy var translationLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .left
        label.numberOfLines = 0
        label.backgroundColor = UIColor.clear
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.clear
        self.isUserInteractionEnabled = true
        self.addSubview(translationLabel)
        translationLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configCell(attributeText: NSMutableAttributedString) {
        translationLabel.attributedText = attributeText
    }
}

class TranslateView: UIView {
    weak var delegate: TranslatedViewDelegate?
    private weak var topVC: UIViewController?

    // 可配置参数
    private var leftMargin: CGFloat = 22 // view的左边最小边距
    private var rightMargin: CGFloat = 23 // view的右边最小边距
    private var minimumWidth: CGFloat = 240 // view的最小宽度
    private var maximumWidth: CGFloat = 330 // view的最大宽度
    private var minimumResultHeight: CGFloat = 48 // 显示结果的最小高度
    private var maximumResultHeight: CGFloat = 184 // 显示结果的最大高度

    // 内部参数
    private let marginToLabel: CGFloat = 11 // 箭头离指向的距离
    private let arrowViewHeight: CGFloat = 6 // 箭头高度
    private let arrowViewWidth: CGFloat = 16 // 箭头宽度
    private let labelLeftAndRightMargin: CGFloat = 16 // label左右边距
    private let fontSize: CGFloat = 17 // 字体大小
    private let lineHeight: CGFloat = 24 // 行高
    private let bottomHeight: CGFloat = 36 // 底部栏高度
    private let preferredMaxLayoutWidth: CGFloat = 298 // 换行宽度

    private let selectRect: CGRect // 用于确定布局的rect
    private var numsOfLines: Int = 0 // 文本总行数
    private var arrowUp: Bool = true // 箭头是否朝上
    private var textWidth: CGFloat = 0 // 文本宽度
    private var allAttributedText: [NSMutableAttributedString] = []// 显示的文本，数组到tableView的映射
    private let cellIdentifier: String = "translateCell"
    private var language: String
    private var arrowOffset: CGFloat = 0

    // 用于处理dismiss后的事物，当前用于清空label的选中状态
    var dismissClosure: (() -> Void)?

    private lazy var arrowView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: arrowViewWidth, height: arrowViewHeight + 1))
        view.backgroundColor = UIColor.clear
        let trianglePath = UIBezierPath()
        trianglePath.lineWidth = 1
        var point = CGPoint(x: 0, y: arrowViewHeight + 1)
        trianglePath.move(to: point)
        point = CGPoint(x: arrowViewWidth / 2, y: 0)
        trianglePath.addLine(to: point)
        point = CGPoint(x: arrowViewWidth, y: arrowViewHeight + 1)
        trianglePath.addLine(to: point)
        let triangleLayer = CAShapeLayer()
        triangleLayer.path = trianglePath.cgPath
        view.layer.addSublayer(triangleLayer)
        triangleLayer.ud.setStrokeColor(UIColor.ud.lineBorderCard)
        if arrowUp {
            triangleLayer.ud.setFillColor(UIColor.ud.N00)
        } else {
            triangleLayer.ud.setFillColor(UIColor.ud.N100)
        }
        return view
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = UIColor.clear
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.delegate = self
        tableView.showsVerticalScrollIndicator = false
        tableView.dataSource = self
        tableView.register(TranslateViewCell.self, forCellReuseIdentifier: self.cellIdentifier)
        return tableView
    }()

    private lazy var bottomView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N100
        return view
    }()

    private lazy var topView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N00
        return view
    }()

    private lazy var wrapperView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N00
        view.layer.cornerRadius = 4
        view.layer.shadowOpacity = 1.0
        view.layer.masksToBounds = true
        view.layer.shadowOffset = CGSize(width: 0, height: 5)
        view.layer.shadowRadius = 2
        view.layer.borderWidth = 1
        view.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        view.layer.ud.setShadow(type: .s4Down)
        return view
    }()

    private lazy var totalView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }()

    private lazy var languageLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textLinkNormal
        label.text = self.language
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()

    private lazy var languageAndExpandView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        let tapGesutre = UITapGestureRecognizer(target: self, action: #selector(changeLanguage))
        view.addGestureRecognizer(tapGesutre)
        view.isUserInteractionEnabled = true
        return view
    }()

    init(delegate: TranslatedViewDelegate, text: [String], language: String, selectRect: CGRect, topVC: UIViewController, configures: [TranslatedViewConfigure] = []) {
        self.selectRect = selectRect
        self.topVC = topVC
        self.delegate = delegate
        self.language = language
        super.init(frame: topVC.view.bounds)
        self.clipsToBounds = true
        self.layer.cornerRadius = 4
        configures.forEach { (config) in
            switch config {
            case let .leftMargin(value):
                self.leftMargin = value
            case let .rightMargin(value):
                self.rightMargin = value
            case let .minimumWidth(value):
                self.minimumWidth = value
            case let .maximumWidth(value):
                self.maximumWidth = value
            case let .minimumResultHeight(value):
                self.minimumResultHeight = value
            case let .maximumResultHeight(value):
                self.maximumResultHeight = value
            }
        }
        createAndCalculateText(text: text)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        calculateShowFrame()
        setupTopView()
        setupBottomView()
        if arrowUp {
            self.totalView.addSubview(wrapperView)
            wrapperView.snp.makeConstraints { (make) in
                make.top.equalToSuperview().inset(arrowViewHeight)
                make.left.right.bottom.equalToSuperview()
            }
            self.totalView.addSubview(arrowView)
            arrowView.snp.makeConstraints { (make) in
                make.top.centerX.equalToSuperview()
                make.width.equalTo(arrowViewWidth)
                make.left.equalTo(wrapperView.snp.left).offset(arrowOffset)
            }
        } else {
            self.totalView.addSubview(wrapperView)
            wrapperView.snp.makeConstraints { (make) in
                make.top.left.right.equalToSuperview()
                make.bottom.equalToSuperview().inset(arrowViewHeight)
            }
            arrowView.transform = CGAffineTransform.init(scaleX: 1, y: -1)
            self.totalView.addSubview(arrowView)
            arrowView.snp.makeConstraints { (make) in
                make.bottom.centerX.equalToSuperview()
                make.left.equalTo(wrapperView.snp.left).offset(arrowOffset)
            }
        }
        wrapperView.addSubview(bottomView)
        bottomView.snp.makeConstraints { (make) in
            make.bottom.left.right.equalToSuperview()
            make.height.equalTo(self.bottomHeight)
        }
        wrapperView.addSubview(topView)
        topView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(bottomView.snp.top)
        }
        self.addSubview(totalView)
    }

    private func setupTopView() {
        topView.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().inset(12)
            if self.numsOfLines == 1 {
                make.bottom.equalToSuperview().inset(12)
            } else {
                make.bottom.equalToSuperview().inset(4)
            }
        }
    }

    private func setupBottomView() {
        let triangleIcon1 = UIImageView()
        triangleIcon1.image = UDIcon.getIconByKey(.expandUpFilled, iconColor: UIColor.ud.textLinkNormal, size: CGSize(width: 8, height: 8))
        let triangleIcon2 = UIImageView()
        triangleIcon2.image = UDIcon.getIconByKey(.expandDownFilled, iconColor: UIColor.ud.textLinkNormal, size: CGSize(width: 8, height: 8))
        languageAndExpandView.addSubview(triangleIcon1)
        triangleIcon1.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.top.equalToSuperview().inset(3)
        }
        languageAndExpandView.addSubview(triangleIcon2)
        triangleIcon2.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.bottom.equalToSuperview().inset(4)
        }
        languageAndExpandView.addSubview(languageLabel)
        languageLabel.snp.makeConstraints { (make) in
            make.top.bottom.left.equalToSuperview()
            make.right.equalTo(triangleIcon2.snp.left).offset(-4)
        }
        bottomView.addSubview(languageAndExpandView)
        languageAndExpandView.snp.makeConstraints { (make) in
            make.right.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview().inset(8)
        }
        let iconView: UIImageView = UIImageView()
        iconView.image = UDIcon.getIconByKey(.translateColorful, size: CGSize(width: 20, height: 20))
        bottomView.addSubview(iconView)
        iconView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview().inset(8)
            make.left.equalToSuperview().inset(16)
        }
    }

    private func createAndCalculateText(text: [String]) {
        let font = UIFont.systemFont(ofSize: 17, weight: .regular)
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = 24
        style.maximumLineHeight = 24
        var maxWidth: CGFloat = 0
        for element in text {
            let attributedText = NSMutableAttributedString(string: element, attributes: [.paragraphStyle: style, .font: font])
            let elementWidth = element.vc.boundingWidth(height: lineHeight, font: font)
            let lines = Int(ceil(elementWidth / self.preferredMaxLayoutWidth))
            let textWidth = elementWidth < self.preferredMaxLayoutWidth ? elementWidth : self.preferredMaxLayoutWidth
            maxWidth = maxWidth > textWidth ? maxWidth : textWidth
            allAttributedText.append(attributedText)
            numsOfLines += lines
        }
        textWidth = maxWidth
    }

    private func calculateShowFrame() {
        guard let topVC = self.topVC else { return }
        var showPoint: CGPoint = .zero
        var arrowUp: Bool = true
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        // view多长
        if self.textWidth < self.minimumWidth - self.labelLeftAndRightMargin * 2 {
            totalWidth = self.minimumWidth
        } else if self.textWidth < self.maximumWidth - self.labelLeftAndRightMargin * 2 {
            totalWidth = self.textWidth + 2 * self.labelLeftAndRightMargin
        } else {
            totalWidth = self.maximumWidth
        }

        // view多高
        if numsOfLines == 1 {
            totalHeight = bottomHeight + minimumResultHeight + arrowViewHeight
        } else {
            if CGFloat(self.numsOfLines) * lineHeight > 168 {
                totalHeight = bottomHeight + maximumResultHeight + arrowViewHeight
                self.tableView.showsVerticalScrollIndicator = true
                self.tableView.isScrollEnabled = true
            } else {
                totalHeight = bottomHeight + arrowViewHeight + CGFloat(numsOfLines) * lineHeight + 16.0
            }
        }
        // y坐标 优先向下放 箭头向上
        var editBottom: CGFloat {
            let isRegular = Display.pad && VCScene.rootTraitCollection?.horizontalSizeClass == .regular
            return isRegular ? 0 : VCScene.safeAreaInsets.bottom
        }
        let bottomLimit = ChatMessageEditView.Layout.MinHeight + editBottom
        if selectRect.maxY + totalHeight + self.marginToLabel <= topVC.view.bounds.maxY - bottomLimit {
            showPoint.y = selectRect.maxY + self.marginToLabel
            arrowUp = true
        }
        // 下面放不下，尝试向上放 箭头向下
        else if selectRect.minY - totalHeight - self.marginToLabel >= 0 {
            showPoint.y = selectRect.minY - totalHeight - self.marginToLabel
            arrowUp = false
        }
        // 都放不下，放中间(说明选择的内容很多）箭头向上
        else {
            showPoint.y = (selectRect.minY + selectRect.maxY) / 2 - totalHeight / 2
            arrowUp = true
        }

        // x坐标
        if (selectRect.minX + selectRect.maxX) / 2 - totalWidth / 2 <= leftMargin {
            showPoint.x = leftMargin
            arrowOffset = (selectRect.minX + selectRect.maxX) / 2 - leftMargin - arrowViewWidth / 2
        } else if (selectRect.minX + selectRect.maxX) / 2 + totalWidth / 2 >= topVC.view.bounds.maxX - rightMargin {
            showPoint.x = topVC.view.bounds.maxX - rightMargin - totalWidth
            arrowOffset = (selectRect.minX + selectRect.maxX) / 2 - showPoint.x - arrowViewWidth / 2
        } else {
            showPoint.x = (selectRect.minX + selectRect.maxX) / 2 - totalWidth / 2
            arrowOffset = totalWidth / 2 - arrowViewWidth / 2
        }
        self.arrowUp = arrowUp
        self.totalView.frame = CGRect(origin: showPoint, size: CGSize(width: totalWidth, height: totalHeight))
    }

    @objc
    func changeLanguage(gesture: UIGestureRecognizer) {
        // 调接口
        guard  let delegate = delegate else { return }
        delegate.lanuageItemDidTap()
        dismissView()
    }

    private func updateTableViewConstraints() {
        tableView.snp.remakeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().inset(12)
            if self.numsOfLines == 1 {
                make.bottom.equalToSuperview().inset(12)
            } else {
                make.bottom.equalToSuperview().inset(4)
            }
        }
    }

    private func addDismissGesture() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleDismissGesuture(gesture:)))
        gesture.numberOfTouchesRequired = 1
        self.addGestureRecognizer(gesture)
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleDismissGesuture(gesture:)))
        longPressGesture.minimumPressDuration = 0.15
        self.addGestureRecognizer(longPressGesture)
    }

    private func addCounteractGesture() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleCounteractGesture(gesture:)))
        gesture.numberOfTouchesRequired = 1
        self.totalView.addGestureRecognizer(gesture)
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleCounteractGesture(gesture:)))
        longPressGesture.minimumPressDuration = 0.15
        self.totalView.addGestureRecognizer(longPressGesture)
    }

    @objc
    private func handleCounteractGesture(gesture: UIGestureRecognizer) {
        // do nothing
    }

    @objc
    private func handleDismissGesuture(gesture: UIGestureRecognizer) {
        dismissClosure?()
        dismissView()

    }
}

extension TranslateView {
    func show() {
        guard let topVC = self.topVC else { return }
        addCounteractGesture()
        addDismissGesture()
        topVC.view.addSubview(self)
    }

    private func dismissView() {
        self.removeFromSuperview()
    }
}

extension TranslateView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.allAttributedText.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: self.cellIdentifier, for: indexPath) as? TranslateViewCell else {
            return UITableViewCell()
        }
        cell.configCell(attributeText: self.allAttributedText[indexPath.item])
        cell.selectionStyle = .none
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}
