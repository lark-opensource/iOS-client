//
//  MeetingVC.swift
//  MultiUIWindowSolution
//
//  Created by bytedance on 2022/4/21.
//

import Foundation
import UIKit
import SnapKit

// swiftlint:disable all
class MeetingVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        addSubViews()
        makeConstraints()
        setAppearance()
    }

    lazy var containerView: UIStackView = UIStackView()
    lazy var exitButton: UIButton = UIButton()
    lazy var shareButton: UIButton = UIButton()
    lazy var leftView: UIView = UIView()
    lazy var rightView: UIView = UIView()
    lazy var textLabel: UILabel = UILabel()
    public var dismissWindowBlock: (()-> Void)?

    lazy var isAutorotated: Bool = false
    lazy var isShowDoc: Bool = false
    lazy var isLandmark: Bool = false {
        didSet {
            if isLandmark {
                UIDevice.current.updateDeviceOrientation(.landscapeLeft)
            } else {
                UIDevice.current.updateDeviceOrientation(.portrait)
            }
        }
    }
}
