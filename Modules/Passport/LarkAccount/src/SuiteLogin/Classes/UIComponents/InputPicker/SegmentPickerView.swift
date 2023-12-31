//
//  SegmentPickerView.swift
//  SuiteLogin
//
//  Created by Miaoqi Wang on 2020/8/17.
//

import UIKit
import LarkUIKit

class SegmentPickerView: SegmentView {
    
    enum SegmentPickerHeaderStyle {
        case original   // 标题位于左侧，底部有高亮条，关闭位于右侧；目前的注册团队信息填写
        case standard   // 标题居中，关闭位于左侧；目前的 SSO 登录后缀选择
    }
    
    let dataSource: [(String, [SegPickerItem])]
    // 已选择
    private var selectedIndexes: [Int] = []
    // 选择结束回调
    private let didSelectIndexes: ([Int]) -> Void
    // 动态获取子集数据，如果需要的话，子集数据初始化就有 return nil 即可
    private var newDataGetter: SegementPickerDataGetter?
    // lists
    private var tables: [SegTableView] = []
    // 顶部切换按钮视图
    private let segmentView: PickerSegmentView
    // 关闭 Scroll View 滚动，避免联动问题（需要delegate解决，但不支持重载，简单处理）
    private lazy var scroll: UIScrollView? = {
        let v = self.subviews.first { (sub) -> Bool in
            sub.isKind(of: UIScrollView.self)
        } as? UIScrollView
        return v
    }()

    init(segStyle: PickerSegmentView.Style,
         dataSource: [(String, [SegPickerItem])],
         didSelect: @escaping ([Int]) -> Void,
         headerStyle: SegmentPickerView.SegmentPickerHeaderStyle = .original,
         newDataGetter: SegementPickerDataGetter? = nil,
         cancel: @escaping () -> Void = {}) {
        self.dataSource = dataSource
        self.didSelectIndexes = didSelect
        self.newDataGetter = newDataGetter
        self.segmentView = PickerSegmentView(style: segStyle)
        super.init(segment: segmentView)

        initView()
        
        if case .standard = headerStyle {
            let header = PickerHeaderView(title: dataSource.first?.0)
            addSubview(header)
            header.snp.makeConstraints { make in
                make.edges.equalTo(segmentView)
            }
            header.onCloseButtonTapped = {
                cancel()
            }
        } else {
            segmentView.selectedIndexDidChangeBlock = { [weak self] (_, to) in
                self?.segmentView.updateIndex(index: to)
            }
            segmentView.closeBtnClick = {
                cancel()
            }
        }
    }

    func initView() {
        var index = 0
        var views: [(String, UIView)] = []
        var initSelectedIndexes: [Int] = []
        var hasInvalidSelected = false
        for (name, data) in dataSource {
            let table = SegTableView(
                segIndex: index,
                data: data,
                didSelect: { [weak self](segIndex, index) in
                    self?.selectIndex(index: segIndex, subIndex: index)
                },
                reusableIdentifier: "PickerTableViewCell-\(index)",
                needSelectIndicator: index == dataSource.count - 1
            )
            views.append((name, table))
            segmentView.buttonTitles.append(name)
            tables.append(table)
            index += 1

            if !hasInvalidSelected, let selectedIndex = data.firstIndex(where: { $0.isSelected }) {
                initSelectedIndexes.append(selectedIndex)
            } else {
                initSelectedIndexes = []
                hasInvalidSelected = true
            }
        }
        set(views: views)
        // 初始化选中状态
        selectedIndexes = initSelectedIndexes
        // 初始化按钮选中状态
        segmentView.updateIndex(index: selectedIndexes.isEmpty ? 0 : selectedIndexes.count - 1)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func selectIndex(index: Int, subIndex: Int) {
        let next = index + 1
        if let data = newDataGetter?(index, subIndex), next < tables.count {
            let nextTable = tables[next]
            nextTable.updateData(data)
        }

        if index < selectedIndexes.count {
            selectedIndexes[index] = subIndex
        } else {
            selectedIndexes.append(subIndex)
        }

        if index == dataSource.count - 1 {
            didSelectIndexes(selectedIndexes)
        } else {
            setCurrentView(index: index + 1, animated: true)
        }
    }

    // 顶部圆角
    override func draw(_ rect: CGRect) {
        super.draw(rect)

        let cornerPath = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: 8, height: 8)
        )
        let maskLayer = CAShapeLayer()
        maskLayer.frame = rect
        maskLayer.path = cornerPath.cgPath
        layer.mask = maskLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        segmentView.spacing = SegPickerLayout.segSpacing
    }

    /// layout 后更新 index
    func updateInitIndexIfNeed() {
        if !selectedIndexes.isEmpty {
            setCurrentView(index: selectedIndexes.count - 1, animated: false)
        }
        self.scroll?.isScrollEnabled = false
    }
}

class PickerSegmentView: StandardSegment {

    var buttonTitles: [String] = []
    let rightBtn: UIButton = UIButton(type: .custom)
    var closeBtnClick: (() -> Void)?

    init(style: Style) {
        super.init()
        self.backgroundColor = UIColor.ud.bgBody
        titleNormalColor = UIColor.ud.textCaption
        titleFont = UIFont.boldSystemFont(ofSize: 16.0)

        switch style {
        case .default:
            titleSelectedColor = UIColor.ud.primaryContentDefault
        case .plain:
            titleSelectedColor = UIColor.ud.textTitle
            bottomViewColor = UIColor.clear
        }

        spacing = SegPickerLayout.segSpacing
        height = SegPickerLayout.segHeight

        contentView.alignment = .center
        contentView.distribution = .fill
        contentView.snp.remakeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.leading.equalTo(CL.itemSpace)
        }

        rightBtn.setBackgroundImage(Resource.V3.close_dark_gray.ud.withTintColor(UIColor.ud.iconN1), for: .normal)
        rightBtn.addTarget(self, action: #selector(close), for: .touchUpInside)
        addSubview(rightBtn)
        rightBtn.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.greaterThanOrEqualTo(contentView.snp.right).offset(CL.itemSpace)
            make.right.equalToSuperview().inset(CL.itemSpace)
            make.size.equalTo(CGSize(width: 25, height: 25))
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }

        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault //lk.N300
        addSubview(line)
        line.snp.makeConstraints { (make) in
            make.top.equalTo(contentView.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(1.0)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateIndex(index: Int) {
        guard index < buttonItems.count else {
            return
        }

        for i in 0..<buttonItems.count {
            let btn = buttonItems[i]
            if i <= index {
                btn.setTitle(buttonTitles[i], for: .normal)
                btn.isEnabled = true
            } else {
                btn.isEnabled = false
                btn.setTitle("", for: .normal)
            }
            // 及时更新尺寸：低层依赖 label.bounds 更新 bottomView width 
            btn.titleLabel?.sizeToFit()
        }
    }

    @objc
    func close() {
        closeBtnClick?()
    }

    /// remove unnessesory shadow
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        self.layer.shadowColor = nil
        self.layer.shadowOpacity = 0.0
        self.layer.shadowOffset = .zero
        self.layer.shadowPath = nil
    }

    enum Style {
        case `default`
        case plain
    }
}

enum SegPickerLayout {
    static let segSpacing: CGFloat = 40
    static let segHeight: CGFloat = 50
}

class PickerHeaderView: UIView {
    
    var onCloseButtonTapped: (() -> Void)?
    
    let leftButton = UIButton(type: .custom)
    let titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.backgroundColor = UIColor.ud.bgBody
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.boldSystemFont(ofSize: 17)
        label.textAlignment = .center
        return label
    }()
    
    init(title: String?) {
        super.init(frame: .zero)
        backgroundColor = UIColor.ud.bgBody
        
        titleLabel.text = title
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.right.equalToSuperview().inset(52)
        }
        
        leftButton.setBackgroundImage(Resource.V3.close_dark_gray.ud.withTintColor(UIColor.ud.iconN1), for: .normal)
        leftButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        addSubview(leftButton)
        leftButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().inset(CL.itemSpace)
            make.size.equalTo(CGSize(width: 25, height: 25))
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    func close() {
        onCloseButtonTapped?()
    }
    
}
