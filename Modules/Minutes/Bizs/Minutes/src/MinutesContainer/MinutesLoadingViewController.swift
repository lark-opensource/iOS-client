//
//  MinutesLoadingViewController.swift
//  Minutes
//
//  Created by Todd Cheng on 2021/1/15.
//

import LarkUIKit
import MinutesFoundation
import UniverseDesignIcon

class MinutesLoadingViewController: UIViewController {

    private let tracker = BusinessTracker()
    
    var onClickBackButton: (() -> Void)?

    private lazy var backButton: UIButton = {
        let button: UIButton = UIButton(type: .custom)
        button.setImage(UDIcon.getIconByKey(.leftOutlined, iconColor: UIColor.ud.iconN1), for: .normal)
        button.addTarget(self, action: #selector(onClickBackButton(_:)), for: .touchUpInside)
        return button
    }()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    public override var shouldAutorotate: Bool {
        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        showMinutesLoadingView()

        trackerLoadingAppear()
    }

    private func trackerLoadingAppear() {
        let params = [AnyHashable: Any]()
        tracker.tracker(name: .deleteLoadingView, params: params)
    }

    @objc
    private func onClickBackButton(_ sender: UIButton) {
        onClickBackButton?()
    }

    private func addBackButton() {
        self.view.addSubview(backButton)
        backButton.snp.makeConstraints { maker in
            maker.top.equalTo(view.safeAreaLayoutGuide)
            maker.left.equalToSuperview()
            maker.width.equalTo(60)
            maker.height.equalTo(44)
        }
    }

    private func showMinutesLoadingView() {
        let minutesErrorStatusLoadingView = MinutesErrorStatusLoadingView(frame: .zero)
        view.addSubview(minutesErrorStatusLoadingView)
        minutesErrorStatusLoadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        if !Display.pad {
            addBackButton()
        }
    }
}
