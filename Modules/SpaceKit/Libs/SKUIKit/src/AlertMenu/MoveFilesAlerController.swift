//
//  MoveFilesAlertController.swift
//  SpaceKit
//
//  Created by 杨子曦 on 2019/9/16.
//  

import UIKit
import SnapKit
import SKFoundation
import SKResource

public protocol MoveFilesAlertControllerDelegate: AnyObject {//点击移动按钮之后的代理
    func moveTo(_ moveFilesAlerController: MoveFilesAlertController)
}

public final class MoveFilesAlertController: UIViewController {

    private var managers: [String]
    private var managerCount: Int
    private var members: [String]?
    private var memberCount: Int?
    private var visitors: [String]?
    private var visitorCount: Int?

    public weak var delegate: MoveFilesAlertControllerDelegate?

    lazy var dimBackgroundView: UIControl = {
        let control = UIControl(frame: CGRect(x: 0,
                                              y: 0,
                                              width: view.bounds.width,
                                              height: view.bounds.height))
        control.backgroundColor = UIColor.ud.N1000.withAlphaComponent(0.8)
        control.addTarget(self, action: #selector(touchBackGround), for: .touchDown)
        return control
    }()

    lazy internal var alertView: UIView = {
        let alertView = UIView()
        alertView.backgroundColor = UIColor.ud.N00
        return alertView
    }()

    lazy var coverView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N00
        return view
    }()

    lazy var cancelButton: UIButton = {
        let btn = UIButton()
        btn.setTitle(BundleI18n.SKResource.Doc_Facade_Cancel, for: .normal)
        btn.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
        btn.layer.backgroundColor = UIColor.ud.N00.cgColor
        btn.layer.cornerRadius = 4
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        btn.titleLabel?.textAlignment = .center
        btn.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        btn.layer.borderColor = UIColor.ud.N300.cgColor
        btn.layer.borderWidth = 1
        return btn
    }()

    lazy var transferButton: UIButton = {
        let btn = UIButton()
        btn.setTitle(BundleI18n.SKResource.Doc_Facade_Ok, for: .normal)
        btn.setTitleColor(UIColor.ud.N00, for: .normal)
        btn.layer.backgroundColor = UIColor.ud.colorfulBlue.cgColor
        btn.layer.cornerRadius = 4
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        btn.addTarget(self, action: #selector(moveTo), for: .touchUpInside)
        btn.titleLabel?.textAlignment = .center
        return btn
    }()

    lazy var managerSepView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N300
        return view
    }()

    lazy var memberSepView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N300
        return view
    }()

    lazy var visitorSepView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N300
        return view
    }()

    lazy var headerLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.SKResource.Doc_Permission_FolderCollaborators
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.N600
        label.textAlignment = .left
        return label
    }()

    private let managerSView = UIStackView()

    private let memberSView = UIStackView()

    private let visitorSView = UIStackView()

    lazy var managerLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.SKResource.Doc_Permission_Managers
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.N900
        label.textAlignment = .left
        return label
    }()

    lazy var memberLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.SKResource.Doc_Permission_Members
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.N900
        label.textAlignment = .left
        return label
    }()

    lazy var visitorLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.SKResource.Doc_Permission_Visitors
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.N900
        label.textAlignment = .left
        return label
    }()

    lazy var managerText: UILabel = {
        let label = UILabel()
        label.text = makeLabel(roleMembers: managers, roleMemberCount: managerCount)
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.N500
        label.textAlignment = .left
        label.numberOfLines = 1
        return label
    }()

    lazy var memberText: UILabel = {
        let label = UILabel()
        label.text = makeLabel(roleMembers: members, roleMemberCount: memberCount)
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.N500
        label.textAlignment = .left
        label.numberOfLines = 1
        return label
    }()

    lazy var visitorText: UILabel = {
        let label = UILabel()
        label.text = makeLabel(roleMembers: visitors, roleMemberCount: visitorCount)
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.N500
        label.textAlignment = .left
        label.numberOfLines = 1
        return label
    }()
    // managerCount: Int, memberCount: Int?, visitorCount: Int?
    public init(managers: [String], members: [String]?, visitors: [String]?) {
        self.managers = managers
        self.managerCount = managers.count
        self.members = members
        self.memberCount = members?.count
        self.visitors = visitors
        self.visitorCount = visitors?.count
        super.init(nibName: nil, bundle: nil)
        self.view.backgroundColor = .clear
        transitioningDelegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
    }
}

extension MoveFilesAlertController {
    @objc
    func moveTo() {
        delegate?.moveTo(self)
        dismiss(animated: true, completion: nil)
    }

    @objc
    func cancel() {
        dismiss(animated: true, completion: nil)
    }

    @objc
    func touchBackGround() {
        dismiss(animated: true, completion: nil)
    }
}

extension MoveFilesAlertController: UIViewControllerTransitioningDelegate {
    public func animationController(forPresented presented: UIViewController,
                                    presenting: UIViewController, source: UIViewController)
        -> UIViewControllerAnimatedTransitioning? {
            return  AlertMoveFilePresentSlideUp()
    }
    public func animationController(forDismissed dismissed: UIViewController )
        -> UIViewControllerAnimatedTransitioning? {
            return  AlertMoveFileDismissSlideDown()
    }
}

extension MoveFilesAlertController {
    private func makeLabel(roleMembers: [String]?, roleMemberCount: Int?) -> String {
        guard let realRoleMembers = roleMembers, let realRoleMemberCount = roleMemberCount else { return "" }
        if realRoleMemberCount == 0 {
            return ""
        }
        if realRoleMemberCount < 2 {
            return BundleI18n.SKResource.Doc_Permission_CollaboratorsDesc(realRoleMembers[0], "", realRoleMemberCount)
        }
        return BundleI18n.SKResource.Doc_Permission_CollaboratorsDesc(realRoleMembers[0], realRoleMembers[1], realRoleMemberCount)
    }
}

extension MoveFilesAlertController {
    // swiftlint:disable function_body_length
    func setUpUI() {
        view.addSubview(dimBackgroundView)
        view.addSubview(alertView)
        alertView.snp.makeConstraints { (make) in
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            make.width.equalToSuperview()
            make.height.equalTo(328)
        }
        dimBackgroundView.addSubview(coverView)
        if let window = view.window {
            coverView.snp.makeConstraints { (make) in
                make.bottom.equalTo(window.safeAreaInsets.bottom)
                make.height.equalTo(100)
                make.width.equalTo(window.bounds.width)
            }
        }
        alertView.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-16)
            make.width.equalTo(165)
            make.height.equalTo(40)
        }
        alertView.addSubview(transferButton)
        transferButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-16)
            make.width.equalTo(165)
            make.height.equalTo(40)
        }

        alertView.addSubview(headerLabel)
        headerLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.width.equalTo(160)
            make.height.equalTo(17)
            make.top.equalToSuperview().offset(14)
        }
        alertView.addSubview(managerSepView)
        alertView.addSubview(memberSepView)
        alertView.addSubview(visitorSepView)
        managerSepView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview()
            make.height.equalTo(0.5)
            make.top.equalToSuperview().offset(44)
        }
        memberSepView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview()
            make.height.equalTo(0.5)
            make.top.equalToSuperview().offset(116)
        }
        visitorSepView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview()
            make.height.equalTo(0.5)
            make.top.equalToSuperview().offset(188)
        }
        memberSView.axis = .vertical
        memberSView.distribution = .equalSpacing
        memberSView.alignment = .leading
        memberSView.spacing = 20
        memberSView.addArrangedSubview(memberLabel)
        memberSView.addArrangedSubview(memberText)
        alertView.addSubview(memberSView)
        managerSView.addSubview(managerLabel)
        managerSView.addSubview(managerText)
        alertView.addSubview(managerSView)
        visitorSView.axis = .vertical
        visitorSView.distribution = .equalSpacing
        visitorSView.alignment = .leading
        visitorSView.spacing = 20
        visitorSView.addArrangedSubview(visitorLabel)
        visitorSView.addArrangedSubview(visitorText)
        alertView.addSubview(visitorSView)
        if memberText.text?.isEmpty == true {
            memberText.isHidden = true
        } else {
            memberText.isHidden = false
        }
        if visitorText.text?.isEmpty == true {
            visitorText.isHidden = true
        } else {
            visitorText.isHidden = false
        }
        managerSView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.height.equalTo(44)
            make.width.equalTo(200)
            make.top.equalTo(managerSepView).offset(14)
        }
        memberSView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.height.equalTo(44)
            make.width.equalTo(200)
            make.top.equalTo(memberSepView).offset(14)
        }
        visitorSView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.height.equalTo(44)
            make.width.equalTo(200)
            make.top.equalTo(visitorSepView).offset(14)
        }
        managerLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview()
        }
        memberLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview()
        }
        visitorLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview()
        }
        managerText.snp.makeConstraints { (make) in
            make.top.equalTo(managerLabel.snp.bottom)
            make.left.right.equalTo(managerLabel)
            make.bottom.equalToSuperview()
        }
        memberText.snp.makeConstraints { (make) in
            make.top.equalTo(memberLabel.snp.bottom)
            make.left.right.equalTo(memberLabel)
            make.bottom.equalToSuperview()
        }
        visitorText.snp.makeConstraints { (make) in
            make.top.equalTo(visitorLabel.snp.bottom)
            make.left.right.equalTo(visitorLabel)
            make.bottom.equalToSuperview()
        }
    }
}
