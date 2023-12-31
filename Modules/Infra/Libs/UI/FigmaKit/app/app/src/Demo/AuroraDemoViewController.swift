//
//  AuroraDemoViewController.swift
//  FigmaKitDev
//
//  Created by Hayden on 2023/6/1.
//

import UIKit
import FigmaKit

class AuroraDemoViewController: UIViewController {

    var auroraView: AuroraView {
        guard let auroraView = view as? AuroraView else {
            fatalError("should not happened")
        }
        return auroraView
    }

    private lazy var button: UIButton = {
        let button = UIButton()
        button.setTitle("Change Aurora", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 10
        return button
    }()

    override func loadView() {
        view = AuroraView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Aurora View"
        if #available(iOS 13.0, *) {
            view.backgroundColor = UIColor.systemBackground
        } else {
            view.backgroundColor = UIColor.white
        }
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1, constant: -40),
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            button.heightAnchor.constraint(equalToConstant: 60)
        ])
        button.addTarget(self, action: #selector(changeAurora), for: .touchUpInside)
        auroraView.updateAppearance(with: getCurrentAuroraConfig(), animated: false)
    }

    @objc
    private func changeAurora() {
        auroraView.updateAppearance(with: getCurrentAuroraConfig(), animated: true, duration: 1.0)
    }

    func getCurrentAuroraConfig() -> AuroraViewConfiguration {
        let config = auroraConfigs[index % auroraConfigs.count]
        index += 1
        return config
    }

    let auroraConfigs: [AuroraViewConfiguration] = [
        AuroraViewConfiguration(
            mainBlob: .init(color: .systemRed, frame: CGRect(x: -30, y: -44, width: 116, height: 117), opacity: 0.2, blurRadius: 80),
            subBlob: .init(color: .systemOrange, frame: CGRect(x: -16, y: -112, width: 198, height: 198), opacity: 0.2, blurRadius: 80),
            reflectionBlob: .init(color: .systemYellow, frame: CGRect(x: 83, y: -83, width: 168, height: 137), opacity: 0.2, blurRadius: 80)
        ), AuroraViewConfiguration(
            mainBlob: .init(color: .systemPurple, frame: CGRect(x: -74, y: -51, width: 192, height: 176), opacity: 0.2, blurRadius: 80),
            subBlob: .init(color: .systemBlue, frame: CGRect(x: -60, y: -181, width: 325, height: 306), opacity: 0.2, blurRadius: 80),
            reflectionBlob: .init(color: .systemGreen, frame: CGRect(x: 116, y: -102, width: 283, height: 228), opacity: 0.2, blurRadius: 80)
        )
    ]

    var index: Int = 0
}
