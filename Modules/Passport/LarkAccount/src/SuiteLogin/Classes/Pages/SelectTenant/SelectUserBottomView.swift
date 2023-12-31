//
//  SelectUserBottomView.swift
//  LarkAccount
//
//  Created by dengbo on 2021/6/3.
//

import Foundation
import SnapKit
import RxSwift
import RxCocoa
import UIKit
import UniverseDesignCheckBox
import LarkUIKit

class CustomTextImageControl: UIControl {
    let disposeBag: DisposeBag = DisposeBag()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var imgView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.backgroundColor = UIColor.clear
        return imageView
    }()

    lazy var textLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.systemFont(ofSize: Layout.fontSize)
        label.textColor = UIColor.ud.N950
        return label
    }()

    lazy var contentView: UIView = {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        return view
    }()

    init(text: String,
         image: UIImage?,
         action: @escaping () -> Void) {
        super.init(frame: .zero)

        self.rx.controlEvent(.touchUpInside)
            .subscribe { [weak self](_) in
                guard self != nil else { return }
                action()
            }.disposed(by: disposeBag)

        addSubview(contentView)
        contentView.addSubview(imgView)
        contentView.addSubview(textLabel)
        imgView.contentMode = .scaleAspectFit
        contentView.snp.makeConstraints { (make) in
            make.centerX.top.bottom.equalToSuperview()
        }
        imgView.snp.makeConstraints { (make) in
            make.height.equalTo(Layout.imageHeight)
            make.width.equalTo(imgView.snp.height)
            make.centerY.left.equalToSuperview()
        }
        textLabel.snp.makeConstraints { (make) in
            make.centerY.right.equalToSuperview()
            make.left.equalTo(imgView.snp.right).offset(Layout.titleLeft)
        }
        textLabel.setContentHuggingPriority(.required, for: .horizontal)
        textLabel.text = text

        imgView.image = image?.ud.withTintColor(UIColor.ud.iconN1)
    }

    enum Layout {
        static let fontSize: CGFloat = 16
        static let titleLeft: CGFloat = 6
        static let imageHeight: CGFloat = 18
    }
}

class CustomSubtitleImageControl: UIControl {
    let disposeBag: DisposeBag = DisposeBag()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var imgView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.backgroundColor = UIColor.clear
        return imageView
    }()

    lazy var textLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.systemFont(ofSize: Layout.fontSize)
        label.textColor = UIColor.ud.N950
        return label
    }()

    lazy var subTextLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.systemFont(ofSize: Layout.subFontSize)
        label.textColor = UIColor.ud.N600
        return label
    }()

    init(title: String,
         subtitle: String,
         image: UIImage?,
         action: @escaping () -> Void) {
        super.init(frame: .zero)
        self.rx.controlEvent(.touchUpInside)
            .subscribe { [weak self](_) in
                guard self != nil else { return }
                action()
            }.disposed(by: disposeBag)
        addSubview(imgView)
        addSubview(textLabel)
        addSubview(subTextLabel)
        imgView.snp.makeConstraints { (make) in
            make.height.equalTo(Layout.imageHeight)
            make.width.equalTo(imgView.snp.height)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(CL.itemSpace)
        }
        textLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(imgView.snp.centerY)
            make.left.equalTo(imgView.snp.right).offset(CL.itemSpace)
            make.right.lessThanOrEqualToSuperview().offset(-CL.itemSpace)
        }
        subTextLabel.snp.makeConstraints { (make) in
            make.top.equalTo(textLabel.snp.bottom).offset(Layout.space)
            make.left.equalTo(textLabel)
            make.right.lessThanOrEqualToSuperview().offset(-CL.itemSpace)
        }
        textLabel.setContentHuggingPriority(.required, for: .horizontal)
        textLabel.text = title
        subTextLabel.setContentHuggingPriority(.required, for: .horizontal)
        subTextLabel.text = subtitle

        imgView.image = image?.ud.withTintColor(UIColor.ud.iconN1)
    }

    enum Layout {
        static let fontSize: CGFloat = 16
        static let subFontSize: CGFloat = 14
        static let space: CGFloat = 3
        static let imageHeight: CGFloat = 24
    }
}

class SelectUserBottomView: UIView {

    struct Layout {
        static let space: CGFloat = 0
        static let lineHeight: CGFloat = 0.5
    }

    enum BtnAxis {
        case horizontal(btnHeight: CGFloat)
        case vertical(btnHeight: CGFloat)
    }

    enum TypeEnum {
        case createBtns([UIControl], axis: BtnAxis)
        case oneCommonBtn(UIControl, btnHeight: CGFloat)
    }

    public init(type: TypeEnum) {
        let isPad = UIDevice.current.userInterfaceIdiom == .pad

        super.init(frame: .zero)
        switch type {
        case .createBtns(let btnList, let axis):
            switch axis {
            case .horizontal(let btnHeight):
                guard let firstBtn = btnList.first else { return }
                addSubview(firstBtn)
                firstBtn.snp.makeConstraints({ (make) in
                    make.left.top.bottom.equalToSuperview()
                    make.height.equalTo(btnHeight)
                })
                
                // iPad 上隐藏分割线
                var prevBtn = firstBtn
                btnList.forEach { (btn) in
                    if btn != firstBtn {
                        addSubview(btn)
                        
                        if !isPad {
                            let sepLine = line(height: btnHeight)
                            addSubview(sepLine)
                            sepLine.snp.makeConstraints { (make) in
                                make.left.equalTo(prevBtn.snp.right)
                                make.right.equalTo(btn.snp.left)
                                make.top.bottom.equalTo(btn)
                            }
                        }
                        
                        btn.snp.makeConstraints { (make) in
                            make.top.bottom.width.equalTo(firstBtn)
                            make.height.equalTo(btnHeight)
                            if isPad {
                                make.left.equalTo(prevBtn.snp.right)
                            }
                        }
                        prevBtn = btn
                    }
                }
                btnList.last?.snp.makeConstraints({ (make) in
                    make.right.equalToSuperview()
                })
                
                if !isPad {
                    let horiLine = line(height: Layout.lineHeight)
                    addSubview(horiLine)
                    horiLine.snp.makeConstraints { (make) in
                        make.left.right.top.equalToSuperview()
                        make.height.equalTo(Layout.lineHeight)
                    }
                }
            case .vertical(let btnHeight):
                let stackView = UIStackView(arrangedSubviews: btnList)
                stackView.axis = .vertical
                stackView.spacing = Layout.space
                addSubview(stackView)
                stackView.snp.makeConstraints { (make) in
                    make.edges.equalToSuperview()
                }
                btnList.forEach { (btn) in
                    btn.snp.makeConstraints { (make) in
                        make.height.equalTo(btnHeight)
                    }
                }

                if !isPad {
                    let topLine = line(height: Layout.lineHeight)
                    addSubview(topLine)
                    topLine.snp.makeConstraints { (make) in
                        make.left.right.top.equalToSuperview()
                        make.height.equalTo(Layout.lineHeight)
                    }

                    let separator = line(height: Layout.lineHeight)
                    addSubview(separator)
                    separator.snp.makeConstraints { (make) in
                        make.left.equalTo(16)
                        make.right.equalTo(-16)
                        make.centerY.equalToSuperview()
                    }
                }
            }
        case .oneCommonBtn(let btn, let btnHeight):
            addSubview(btn)
            btn.snp.makeConstraints { (make) in
                make.height.equalTo(btnHeight)
                make.edges.equalToSuperview()
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func line(height: CGFloat) -> UIView {
        let lineView = UIView()
        lineView.backgroundColor = UIColor.ud.N300
        let container = UIView()
        container.addSubview(lineView)
        lineView.snp.makeConstraints { (make) in
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.size.equalTo(CGSize(width: Layout.lineHeight, height: height))
        }
        container.setContentCompressionResistancePriority(.required, for: .horizontal)
        container.setContentHuggingPriority(.required, for: .horizontal)
        return container
    }
}

class RegisterItemView: UIView {
    struct Layout {
        static let space: CGFloat = 11
        static let lineHeight: CGFloat = 0.5
        static let fontSize: CGFloat = 16
        static let btnHeight: CGFloat = 74
    }

    lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.systemFont(ofSize: Layout.fontSize, weight: .medium)
        label.textColor = UIColor.ud.N900
        return label
    }()

    lazy var line: UIView = {
        let lineView = UIView()
        lineView.backgroundColor = UIColor.ud.N300
        return lineView
    }()

    var viewHeight: CGFloat = 0

    public init(title: String, btnList: [CustomSubtitleImageControl]) {
        super.init(frame: .zero)
        guard !btnList.isEmpty else { return }
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(CL.itemSpace)
            make.top.equalToSuperview().offset(Layout.space)
            make.right.lessThanOrEqualToSuperview().offset(-CL.itemSpace)
        }
        titleLabel.text = title

        addSubview(line)
        line.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.space)
            make.left.right.equalToSuperview()
            make.height.equalTo(Layout.lineHeight)
        }

        var prevView: UIView = line
        btnList.forEach { (btn) in
            addSubview(btn)
            btn.snp.makeConstraints { (make) in
                make.top.equalTo(prevView.snp.bottom)
                make.left.right.equalToSuperview()
                make.height.equalTo(Layout.btnHeight)
            }
            prevView = btn
        }
        btnList.last?.snp.makeConstraints({ (make) in
            make.bottom.equalToSuperview()
        })

        viewHeight = Layout.space + titleLabel.intrinsicContentSize.height + Layout.space + Layout.lineHeight + Layout.btnHeight * CGFloat(btnList.count)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class RefuseItemView: UIView {
    enum ActionType {
        case join, refuse, select
    }
    
    lazy var joinButton: NextButton = {
        let button = NextButton(title: "", style: .roundedRectBlue)
        button.addTarget(self, action: #selector(onJoin), for: .touchUpInside)
        button.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
        return button
    }()
    
    lazy var refuseButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.numberOfLines = 2
        button.addTarget(self, action: #selector(onRefuse), for: .touchUpInside)
        button.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
        return button
    }()
    
    var joinButtonInfo: V4ButtonInfo? {
        didSet {
            updateUI()
        }
    }
    
    var refuseItem: V4RefuseItem?
    
    var action: (_ type: ActionType) -> Void
    
    var showRefuseButton: Bool {
        didSet {
            updateUI()
        }
    }
    
    private func updateUI() {
        joinButton.setTitle(joinButtonInfo?.text, for: .normal)
        
        if showRefuseButton {
            refuseButton.setTitle(refuseItem?.refuseButton.text, for: .normal)
            refuseButton.setTitleColor(UIColor.ud.red, for: .normal)
        } else {
            refuseButton.setTitle(refuseItem?.selectButton?.text, for: .normal)
            refuseButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        }
    }
    
    init(joinButtonInfo: V4ButtonInfo?,
         refuseItem: V4RefuseItem?,
         action: @escaping (_ type: ActionType) -> Void) {
        self.refuseItem = refuseItem
        self.action = action
        self.showRefuseButton = refuseItem?.selectButton == nil
        
        super.init(frame: .zero)
        
        backgroundColor = UIColor.ud.bgLogin
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.addArrangedSubview(joinButton)
        stackView.addArrangedSubview(refuseButton)
        
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 0, bottom: 0, right: 0))
        }
        
        updateUI()
    }
    
    @objc
    private func onJoin() {
        action(.join)
    }
    
    @objc
    private func onRefuse() {
        action(showRefuseButton ? .refuse : .select)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class RefuseButton: UIButton {
    
    init() {
        super.init(frame: .zero)
        layer.cornerRadius = Common.Layer.commonButtonRadius
        contentEdgeInsets = UIEdgeInsets(horizontal: 16, vertical: 7)
        titleLabel?.font = .systemFont(ofSize: 16)
        isEnabled = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var isEnabled: Bool {
        didSet {
            backgroundColor = isEnabled ? UIColor.ud.functionDangerContentDefault : UIColor.ud.N400
        }
    }
}

class RefuseToolBar: UIView {
    enum ActionType {
        case selectAll, deselectAll, refuse
    }
    
    var isAllSelected: Bool = false {
        didSet {
            checkBox.isSelected = isAllSelected
        }
    }
    
    var isUserSelected: Bool = false {
        didSet {
            refuseButton.isEnabled = isUserSelected
        }
    }
    
    private lazy var checkBox: UDCheckBox = {
        let checkBox = UDCheckBox(boxType: .multiple)
        checkBox.tapCallBack = { [weak self] checkBox in
            self?.onTapCheckBox()
        }
        return checkBox
    }()
    
    private lazy var selectAllLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = .systemFont(ofSize: 16)
        label.text = I18N.Lark_Passport_Login_User_Enterprise_ChooseAll_PopuUpText
        label.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTapCheckBox))
        label.addGestureRecognizer(tap)
        return label
    }()
    
    private lazy var refuseButton: RefuseButton = {
        let button = RefuseButton()
        button.setTitle(refuseButtonInfo?.text ?? "", for: .normal)
        button.addTarget(self, action: #selector(onRefuse), for: .touchUpInside)
        return button
    }()
    
    private var refuseButtonInfo: V4ButtonInfo?
    private let action: (ActionType) -> Void
    
    init(refuseButtonInfo: V4ButtonInfo?, action: @escaping (ActionType) -> Void) {
        self.refuseButtonInfo = refuseButtonInfo
        self.action = action
        
        super.init(frame: .zero)
        
        backgroundColor = UIColor.ud.bgLogin
        
        if !Display.pad {
            let separator = UIView()
            separator.backgroundColor = UIColor.ud.lineBorderCard
            addSubview(separator)
            separator.snp.makeConstraints { make in
                make.left.top.right.equalToSuperview()
                make.height.equalTo(0.5)
            }
        }
        
        addSubview(checkBox)
        checkBox.snp.makeConstraints { make in
            make.left.equalTo(CL.itemSpace)
            make.centerY.equalToSuperview()
        }
        
        addSubview(selectAllLabel)
        selectAllLabel.snp.makeConstraints { make in
            make.left.equalTo(checkBox.snp.right).offset(12)
            make.centerY.equalToSuperview()
        }
        
        addSubview(refuseButton)
        refuseButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(CL.itemSpace)
            make.centerY.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 56)
    }
    
    @objc
    private func onRefuse() {
        action(.refuse)
    }
    
    @objc
    private func onTapCheckBox() {
        checkBox.isSelected.toggle()
        action(checkBox.isSelected ? .selectAll : .deselectAll)
    }
}
