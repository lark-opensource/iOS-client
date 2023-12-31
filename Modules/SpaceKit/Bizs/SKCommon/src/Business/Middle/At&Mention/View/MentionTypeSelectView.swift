//
//  MentionTypeSelectView.swift
//  SpaceKit
//
//  Created by chenjiahao.gill on 2019/6/26.
//  

import UIKit
import SnapKit
import UniverseDesignColor
import SpaceInterface

protocol MentionTypeSelectViewProtocol: AnyObject {
    func didClickCancel(_ selectView: MentionTypeSelectView)
    func selectView(_ selectView: MentionTypeSelectView, didSelectedAt index: Int)
}

class MentionTypeSelectView: UIView {
    // MARK: - Properties
    /// 开启Taptic Engine反馈
    var useTapticEngine: Bool = true
    weak var selectDelegate: MentionTypeSelectViewProtocol?

    private(set) var selectedIndex: Int = 0
    private let handlers: [MentionCard]

    // MARK: - views
    private lazy var feedbackGenerator = UISelectionFeedbackGenerator()

    private var buttonList: [UIButton] = [UIButton]()
    private lazy var backButton: UIButton = {
        let button = UIButton()
        button.imageEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        button.addTarget(self, action: #selector(onBackButtonClick(_:)), for: .touchUpInside)
        return button
    }()

    private lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.2) // 颜色可能需要调整
        return view
    }()
    // MARK: - Public
    init(handlers: [MentionCard]) {
        self.handlers = handlers
        super.init(frame: .zero)
        setUp()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateSelectedState(to index: Int) {
        buttonList[selectedIndex].isSelected = false
        buttonList[index].isSelected = false
        selectedIndex = index
    }

    func reset() {
        updateSelectedState(to: 0)
    }
}

// MARK: - Private
extension MentionTypeSelectView {
    private func setUp() {
        clipsToBounds = true
        self.layer.borderWidth = 1
        self.layer.ud.setBorderColor(UDColor.lineBorderCard)

        backgroundColor = UDColor.bgBody
        addSubview(backButton)
        addSubview(lineView)

        backButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.height.leading.equalToSuperview()
            make.width.equalTo(54)
        }
        lineView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.height.equalTo(26)
            make.width.equalTo(1)
            make.leading.equalTo(backButton.snp.trailing)
        }

        var lastButton = backButton

        // make buttons
        for (index, handler) in handlers.enumerated() {
            let button = UIButton()
            button.setImage(handler.image, for: .normal)
            button.setImage(handler.selectedImage ?? handler.image, for: .selected)
            addSubview(button)
            button.snp.makeConstraints { (make) in
                make.centerY.equalTo(lastButton)
                make.size.equalTo(24)
                make.leading.equalTo(lastButton.snp.trailing).offset(16)
            }
            button.addTarget(self, action: #selector(onButtonClick(_:)), for: .touchUpInside)
            button.tag = index
            lastButton = button
            buttonList.append(button)
        }

        buttonList.first?.isSelected = true
        selectedIndex = 0
    }

}

// MARK: - Click and Action
@objc extension MentionTypeSelectView {
    func onButtonClick(_ button: UIButton) {
        onTapticFeedback()
        selectDelegate?.selectView(self, didSelectedAt: button.tag)
    }

    private func onTapticFeedback() {
        guard useTapticEngine else { return }
        feedbackGenerator.prepare()
        feedbackGenerator.selectionChanged()
    }

    func onBackButtonClick(_ button: UIButton) {
        onTapticFeedback()
        selectDelegate?.didClickCancel(self)
    }
}
