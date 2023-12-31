//
//  EmptyPageViewController.swift
//  LarkAccount
//
//  Created by Nix Wang on 2022/7/26.
//

import Foundation
import UniverseDesignToast
import UniverseDesignEmpty

class EmptyPageViewController: BaseViewController {
    let vm: EmptyPageViewModel

    let imageView = UIImageView()
    let emptyTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        return label
    }()

    let emptySubtitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 14)
        return label
    }()

    lazy var primaryButton: NextButton = {
        let button = NextButton(title: "", style: .roundedRectBlue)
        button.addTarget(self, action: #selector(onButtonTap), for: .touchUpInside)
        return button
    }()

    init(vm: EmptyPageViewModel) {
        self.vm = vm

        super.init(viewModel: vm)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bottomView.isHidden = true
        switchButtonContainer.removeFromSuperview()

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = CL.itemSpace

        moveBoddyView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.leading.equalTo(40)
            make.trailing.equalTo(-40)
            make.center.equalToSuperview()
        }

        imageView.contentMode = .scaleAspectFit
        imageView.snp.makeConstraints { make in
            make.height.equalTo(100)
        }
        stackView.addArrangedSubview(imageView)
        stackView.setCustomSpacing(12, after: imageView)
        switch vm.showPageInfo.imageType {
        case .joinInSuccess:
            imageView.image = EmptyBundleResources.image(named: "emptyPositiveComplete")
        case .notJoinedIn:
            imageView.image = EmptyBundleResources.image(named: "emptyPositiveCommonDefault")
        default:
            break
        }

        emptyTitleLabel.text = vm.showPageInfo.title ?? ""
        stackView.addArrangedSubview(emptyTitleLabel)
        stackView.setCustomSpacing(4, after: emptyTitleLabel)

        emptySubtitleLabel.text = vm.showPageInfo.subtitle ?? ""
        stackView.addArrangedSubview(emptySubtitleLabel)
        stackView.setCustomSpacing(26, after: emptySubtitleLabel)

        if let buttonInfo = vm.showPageInfo.buttonList.first {
            primaryButton.title = buttonInfo.text
            stackView.addArrangedSubview(primaryButton)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let toast = vm.showPageInfo.toast, !toast.isEmpty {
            UDToast.showTips(with: toast, on: view)
        }
    }

    @objc
    func onButtonTap() {
        vm.onButtonTap()
    }
}
