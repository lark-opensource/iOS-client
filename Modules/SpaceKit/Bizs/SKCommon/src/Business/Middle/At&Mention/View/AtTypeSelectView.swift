//
//  AtTypeSelectView.swift
//  SpaceKit
//
//  Created by huahuahu on 2018/12/20.
//
// Atlist 底部，选择要@类型的view

import UIKit
import SnapKit
import SKFoundation
import SKResource
import UniverseDesignColor
import UniverseDesignIcon
import SpaceInterface

protocol AtTypeSelectViewProtocol: AnyObject {
    func didClickCancel(_ selectView: AtTypeSelectView)
    func selectView(_ selectView: AtTypeSelectView, requestTypeUpdateTo newType: Set<AtDataSource.RequestType>)
}

public final class AtTypeSelectView: UIView {
    /// 开启Taptic Engine反馈
    var useTapticEngine: Bool = true

    // MARK: - views
    private lazy var feedbackGenerator = UISelectionFeedbackGenerator()
    private lazy var backButton: UIButton = {
        let button = UIButton()
        button.imageEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        button.setImage(UDIcon.arrowLeftOutlined.ud.withTintColor(UDColor.iconN1), for: .normal)
        return button
    }()

    private lazy var peopleButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.memberOutlined.ud.withTintColor(UDColor.iconN1), for: .normal)
        button.layer.cornerRadius = 6
        button.backgroundColor = UIColor.ud.fillHover
        return button
    }()

    private lazy var groupButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.groupCardOutlined.ud.withTintColor(UDColor.iconN1), for: .normal)
        button.layer.cornerRadius = 6
        button.backgroundColor = UIColor.ud.fillHover
        return button
    }()

    private lazy var fileButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.spaceOutlined.ud.withTintColor(UDColor.iconN1), for: .normal)
        button.layer.cornerRadius = 6
        button.backgroundColor = UIColor.ud.fillHover
        return button
    }()

    private lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.2)
        return view
    }()

    private lazy var topLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineBorderCard
        return view
    }()

    private lazy var safeAreaButtomMask: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgBody
        view.isUserInteractionEnabled = false
        return view
    }()

    static private let defaultRequestType = AtDataSource.RequestType.userTypeSet
    public private(set) var requestType: Set<AtDataSource.RequestType> = AtTypeSelectView.defaultRequestType
    weak var selectDelegate: AtTypeSelectViewProtocol?

    private let type: AtViewType

    init(type: AtViewType = .docs, requestType: Set<AtDataSource.RequestType> = AtDataSource.RequestType.userTypeSet) {
        self.type = type
        self.requestType = requestType
        super.init(frame: .zero)
        setUp()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUp() {
//        clipsToBounds = true
        
        backgroundColor = UDColor.bgBody
        addSubview(topLineView)
        addSubview(backButton)
        addSubview(lineView)
        addSubview(peopleButton)
        addSubview(fileButton)
        addSubview(safeAreaButtomMask)

        safeAreaButtomMask.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.snp.bottom)
            //iOS15.1系统外接键盘时的悬浮小键盘后面没有遮罩
            //需要加高safeAreaButtomMask的高度，避免后面的内容被透出来
            make.height.equalTo(74)
        }

        topLineView.snp.makeConstraints { (make) in
            make.leading.trailing.top.equalToSuperview()
            make.height.equalTo(1)
        }
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
        peopleButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(backButton)
            make.size.equalTo(36)
            make.leading.equalTo(lineView.snp.trailing).offset(14.auto())
        }
        fileButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(peopleButton)
            make.size.equalTo(peopleButton)
            make.leading.equalTo(peopleButton.snp.trailing).offset(10.auto())
        }
        updateSelectedStateAccordingTo(self.requestType)

        fileButton.addTarget(self, action: #selector(onButtonClick(_:)), for: .touchUpInside)
        peopleButton.addTarget(self, action: #selector(onButtonClick(_:)), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(onBackButtonClick(_:)), for: .touchUpInside)

        if type.supportGroup {
            addSubview(groupButton)
            groupButton.snp.makeConstraints { (make) in
                make.centerY.equalTo(peopleButton)
                make.size.equalTo(peopleButton)
                make.leading.equalTo(fileButton.snp.trailing).offset(10.auto())
            }
            groupButton.addTarget(self, action: #selector(onButtonClick(_:)), for: .touchUpInside)
        }
    }

    func updateSelectedStateAccordingTo(_ requestType: Set<AtDataSource.RequestType>) {
        fileButton.isSelected = (requestType == AtDataSource.RequestType.fileTypeSet)
        if type.supportGroup {
            groupButton.isSelected = (requestType == AtDataSource.RequestType.chatTypeSet)
        }
        peopleButton.isSelected = (requestType == AtDataSource.RequestType.userTypeSet)
        resetBackgroundColor()
    }
    
    private func resetBackgroundColor() {
        for btn in [peopleButton, fileButton, groupButton] {
            btn.backgroundColor = btn.isSelected ? UIColor.ud.fillHover : .clear
        }
    }

    public func updateRequestType(to type: Set<AtDataSource.RequestType>) {
        requestType = type
        updateSelectedStateAccordingTo(requestType)
    }

    public func setBackButton(isHidden: Bool) {
        backButton.isHidden = isHidden
        lineView.isHidden = isHidden

        backButton.snp.updateConstraints { (make) in
            make.width.equalTo(isHidden ? 0.01 : 54)
        }
        
        lineView.snp.updateConstraints { (make) in
            make.width.equalTo(isHidden ? 0.01 : 1)
        }
        
        layoutIfNeeded()
    }
    
    func reset() {
        requestType = AtTypeSelectView.defaultRequestType
        updateSelectedStateAccordingTo(requestType)
    }
}

@objc extension AtTypeSelectView {
    func onButtonClick(_ button: UIButton) {
        let oldRequest = requestType
        requestType = []
        onTapticFeedback()
        switch button {
        case fileButton:
            requestType = requestType.union(AtDataSource.RequestType.fileTypeSet)
        case groupButton:
            requestType = requestType.union(AtDataSource.RequestType.chatTypeSet)
        case peopleButton:
            requestType = requestType.union(AtDataSource.RequestType.userTypeSet)
        default:
            spaceAssertionFailure("invalid Button")
        }
        updateSelectedStateAccordingTo(requestType)
        if oldRequest != requestType {
            selectDelegate?.selectView(self, requestTypeUpdateTo: requestType)
        }
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
