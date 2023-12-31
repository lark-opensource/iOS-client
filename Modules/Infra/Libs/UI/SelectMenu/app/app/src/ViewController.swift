//
//  ViewController.swift
//  SelectMenuDev
//
//  Created by bytedance on 2021/6/18.
//

import Foundation
import UIKit
import SelectMenu
import UniverseDesignTheme

class ViewController: UIViewController {

    private var selectedCompactValue: String?
    private var selectedFullScreenValue: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            UDThemeManager.setUserInterfaceStyle(.unspecified)
        }

        view.backgroundColor = UIColor.ud.bgBody

        // Do any additional setup after loading the view.
        let button = UIButton()
        button.setTitle("compact menu", for: .normal)
        view.addSubview(button)
        button.frame = CGRect(x: 0, y: 0, width: 150, height: 50)
        button.center = view.center
        button.addTarget(self, action: #selector(didTapCompactMenuButton(_:)), for: .touchUpInside)

        let button2 = UIButton()
        button2.setTitle("full screen menu", for: .normal)
        view.addSubview(button2)
        button2.frame = CGRect(x: 0, y: 0, width: 150, height: 50)
        button2.center = CGPoint(x: view.center.x, y: view.center.y + 50)
        button2.addTarget(self, action: #selector(didTapFullScreenMenuButton(_:)), for: .touchUpInside)
    }

    @objc
    private func didTapCompactMenuButton(_ sender: UIButton) {
        let menu = SelectMenuCompactController(items: [
            SelectMenuViewModel.Item(name: "one", value: "1"),
            SelectMenuViewModel.Item(name: "two", value: "2"),
            SelectMenuViewModel.Item(name: "three", value: "3"),
            SelectMenuViewModel.Item(name: "four", value: "4")
        ], selectedValue: selectedCompactValue)
        menu.didSelectedItem = { [weak self] item in
            guard let self = self else { return }
            self.selectedCompactValue = item.value
            menu.dismiss(animated: true)
        }
        present(menu, animated: true)
    }

    @objc
    private func didTapFullScreenMenuButton(_ sender: UIButton) {
        let menu = SelectMenuController(items: [
            SelectMenuViewModel.Item(name: "one", value: "1"),
            SelectMenuViewModel.Item(name: "two", value: "2"),
            SelectMenuViewModel.Item(name: "three", value: "3"),
            SelectMenuViewModel.Item(name: "four", value: "4")
        ], selectedValue: selectedFullScreenValue)
        menu.didSelectedItem = { [weak self] item in
            guard let self = self else { return }
            self.selectedFullScreenValue = item.value
            menu.dismiss(animated: true)
        }
        present(menu, animated: true)
    }
}
