//
//  RankView.swift
//  AnimatedTabBar
//
//  Created by bytedance on 2020/12/2.
//

import Foundation
import UIKit
import LarkInteraction
import FigmaKit

final class RankView: UIView {

    let isPreviewEnabled: Bool

    /// 顶部导航栏容器
    lazy var navigationBar: UIView = {
       return UIView()
    }()

    lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgMask
        return view
    }()

    lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloatBase
        view.layer.cornerRadius = 8
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()

    private lazy var navTitleView: UIView = {
        let label = UILabel()
        label.text = BundleI18n.AnimatedTabBar.Lark_Navigation_EditBottomNavigationBar
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textTitle
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textAlignment = .center
        return label
    }()
    /// 取消
    lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.setTitle(BundleI18n.AnimatedTabBar.Lark_Legacy_Cancel, for: .normal)
        return button
    }()
    /// 完成
    lazy var confirmButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitle(BundleI18n.AnimatedTabBar.Lark_Legacy_Done, for: .normal)
        return button
    }()
    /// 编辑列表
    lazy var rankTableView: UITableView = {
        let tableView = RankTableView()
        tableView.estimatedRowHeight = 42
        tableView.register(RankViewCell.self, forCellReuseIdentifier: RankViewCell.Config.identifier)
        tableView.register(RankViewHeader.self, forHeaderFooterViewReuseIdentifier: RankViewHeader.Config.identifier)
        tableView.register(
            UITableViewHeaderFooterView.self,
            forHeaderFooterViewReuseIdentifier: "UITableViewHeaderFooterView"
        )
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 30, right: 0) // 拉到底部的时候留一些空白
        tableView.alwaysBounceVertical = false
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIColor.ud.lineDividerDefault
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 48, bottom: 0, right: 0)
        tableView.backgroundColor = .clear
        return tableView
    }()

    lazy var mockTabBar: VisualBlurView = {
        let view = VisualBlurView()
        view.fillColor = UIColor.ud.bgFloat
        view.fillOpacity = 0.85
        view.blurRadius = 40
        return view
    }()
    /// 预览界面
    lazy var preview: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        return stackView
    }()

    lazy var guideView: UIView = {
        let view = VisualBlurView()
        view.fillColor = UIColor.ud.bgFloat
        view.fillOpacity = 0.85
        view.blurRadius = 40

        let label = UILabel()
        label.font = Cons.guideLabelFont
        label.textColor = Cons.guideLabelColor
        label.text = BundleI18n.AnimatedTabBar.Lark_Legacy_NavigationPreview
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.center.equalToSuperview()
            make.width.lessThanOrEqualToSuperview()
        }
        let topBorder = UIView()
        topBorder.backgroundColor = UIColor.ud.lineDividerDefault
        view.addSubview(topBorder)
        topBorder.snp.makeConstraints { make in
            make.leading.trailing.width.equalToSuperview()
            make.top.equalToSuperview()
            make.height.equalTo(0.5)
        }
        return view
    }()

    init(previewEnabled: Bool) {
        self.isPreviewEnabled = previewEnabled
        super.init(frame: .zero)
        guideView.isHidden = !previewEnabled
        preview.isHidden = !previewEnabled
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        setupSubview()
        setupConstraints()
    }

    private func setupSubview() {
        addSubview(backgroundView)
        addSubview(contentView)
        addSubview(guideView)
        addSubview(mockTabBar)
        contentView.addSubview(navigationBar)
        contentView.addSubview(rankTableView)
        mockTabBar.addSubview(preview)
        navigationBar.addSubview(cancelButton)
        navigationBar.addSubview(confirmButton)
        navigationBar.addSubview(navTitleView)
    }

    private func setupConstraints() {
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top)
            make.leading.trailing.bottom.equalToSuperview()
        }
        navigationBar.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(56)
        }
        navTitleView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        mockTabBar.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-MainTabBar.Layout.tabBarHeight)
            make.leading.trailing.bottom.equalToSuperview()
        }
        guideView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(Cons.guideViewHeight)
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-MainTabBar.Layout.stackHeight)
        }
        preview.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(MainTabBar.Layout.stackHeight)
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
        }
        rankTableView.snp.makeConstraints { (make) in
            make.top.equalTo(navigationBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            if isPreviewEnabled {
                make.bottom.equalTo(guideView.snp.top)
            } else {
                make.bottom.equalToSuperview()
            }
        }
        cancelButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalTo(navTitleView)
            make.height.equalTo(20)
        }
        confirmButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalTo(navTitleView)
            make.height.equalTo(20)
        }
        if #available(iOS 13.4, *) {
            cancelButton.addLKInteraction(PointerInteraction(style: PointerStyle(effect: .automatic)))
            confirmButton.addLKInteraction(PointerInteraction(style: PointerStyle(effect: .automatic)))
        }
    }
}

extension RankView {

    enum Cons {
        static var guideViewHeight: CGFloat { 28 }
        static var guideLabelFont: UIFont { .systemFont(ofSize: 12) }
        static var guideLabelColor: UIColor { UIColor.ud.textCaption }
    }

}

public final class RankTableView: UITableView {

   private let kTableCellCornerRadius: CGFloat = 10.0

   public init(frame: CGRect = .zero) {
       var style: UITableView.Style = .grouped
       if #available(iOS 13, *) {
           style = .insetGrouped
       }
       super.init(frame: frame, style: style)
   }

   private override init(frame: CGRect, style: UITableView.Style) {
       super.init(frame: frame, style: style)
   }

   required init?(coder: NSCoder) {
       fatalError("init(coder:) has not been implemented")
   }

    public override var alignmentRectInsets: UIEdgeInsets {
        var inset = super.alignmentRectInsets
        if #available(iOS 13, *) { } else {
            inset.left -= 16
            inset.right -= 16
        }
        return inset
    }

   public override func didAddSubview(_ subview: UIView) {
       super.didAddSubview(subview)
       // Might handle KVO here.

       if #available(iOS 13, *) { } else {
           if isShadowView(subview) {
               subview.layer.opacity = 0.2
           }
       }
   }

   public override func layoutSubviews() {
       super.layoutSubviews()
       if #available(iOS 13, *) {} else {
           adjustTableElements()
       }

       if #available(iOS 14, *) { } else if #available(iOS 13, *) {
           tableContentWrapper?.subviews
               .filter { isShadowView($0) }
               .forEach { $0.layer.opacity = 0.2 }
       }
   }

   private var tableContentWrapper: UIView? {
       return nil
       /* 去除私有 API
       guard #available(iOS 13, *) else {
           return nil
       }
       // swiftlint:disable all
       guard let classStr = EncodedKeys.uiTableViewWrapper,
           let wrapperClass = NSClassFromString(classStr) else {
           return nil
       }
       // swiftlint:enable all
       return self.subviews.first(where: {
           $0.isMember(of: wrapperClass)
       })
        */
   }

   private func adjustTableElements() {
       for subview in subviews {
           if let cell = subview as? UITableViewCell {
               adjustCornerRadius(for: cell)
           }
       }
   }

   private func adjustCornerRadius(for cell: UITableViewCell) {
       guard let indexPath = indexPath(for: cell) else {
           return
       }
       let countOfRows = numberOfRows(inSection: indexPath.section)

       cell.clipsToBounds = true
       cell.layer.masksToBounds = true
       cell.layer.cornerRadius = kTableCellCornerRadius

       if countOfRows == 1 {
           cell.layer.maskedCorners = [
               .layerMinXMinYCorner,
               .layerMinXMaxYCorner,
               .layerMaxXMinYCorner,
               .layerMaxXMaxYCorner
           ]
       } else {
           switch indexPath.row {
           case 0:
               cell.layer.maskedCorners = [
                   .layerMinXMinYCorner,
                   .layerMaxXMinYCorner
               ]
           case countOfRows - 1:
               cell.layer.maskedCorners = [
                   .layerMinXMaxYCorner,
                   .layerMaxXMaxYCorner
               ]
           default:
               cell.layer.maskedCorners = []
           }
       }
   }
}

extension RankTableView {

   // swiftlint:disable all

   enum EncodedKeys {

       /* 去除私有 API
       /// UITableViewWrapperView
       static var uiTableViewWrapper: String? {
           if let data = Data(base64Encoded: "VUlUYWJsZVZpZXdXcmFwcGVyVmlldw==", options: .ignoreUnknownCharacters) {
               return String(data: data, encoding: .utf8)
           }
           return nil
       }
       /// UIShadowView
       static var uiShadowViewStr: String? {
           if let data = Data(base64Encoded: "VUlTaGFkb3dWaWV3", options: .ignoreUnknownCharacters) {
               return String(data: data, encoding: .utf8)
           }
           return nil
       }
        */
   }

   func isShadowView(_ view: UIView) -> Bool {
       return false
       /* 去除私有 API
       guard let classStr = EncodedKeys.uiShadowViewStr else { return false }
       return "\(type(of: view))" == classStr
        */
   }
   // swiftlint:enable all
}
