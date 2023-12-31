//
//  PointerDemo.swift
//  LarkInteractionDev
//
//  Created by Saafo on 2021/10/8.
//

import Foundation
import UIKit
import LarkInteraction
import SnapKit
import UniverseDesignColor

class PointerDemo: UIViewController {
    enum Cons {
        static let liftButtonSize: CGFloat = 60
        static let spacing: CGFloat = 20
        static let plusWidth: CGFloat = 6
        static var plusLength: CGFloat { liftButtonSize / 2 }
        static var plusCornerRadius: CGFloat { plusWidth / 2 }
        static let tableViewHeight: CGFloat = 400
        static let tableViewWidth: CGFloat = 200
    }

    // swiftlint:disable function_body_length
    override func viewDidLoad() {
        super.viewDidLoad()

        // MARK: UI

        view.backgroundColor = UIColor.ud.bgBody
        let vStack = Chainable(UIStackView())
            .axis(.vertical)
            .alignment(.center)
            .spacing(Cons.spacing)
            .unwrap()
        let hStack1 = Chainable(UIStackView())
            .axis(.horizontal)
            .alignment(.center)
            .spacing(Cons.spacing)
            .unwrap()

        let liftButton = Chainable(UIButton())
            .backgroundColor(.ud.colorfulBlue)
//            .layer.cornerRadius(Cons.liftButtonRadius / 2)
            .unwrap()
        hStack1.addArrangedSubview(liftButton)
        liftButton.layer.cornerRadius = Cons.liftButtonSize / 2
        liftButton.snp.makeConstraints {
            $0.size.equalTo(Cons.liftButtonSize)
        }
        // ➕
        let horizontalLine = Chainable(UIView())
            .backgroundColor(.white)
            .unwrap()
        let verticalLine = Chainable(UIView())
            .backgroundColor(.white)
            .unwrap()
        horizontalLine.layer.cornerRadius = Cons.plusCornerRadius
        verticalLine.layer.cornerRadius = Cons.plusCornerRadius
        liftButton.addSubview(horizontalLine)
        liftButton.addSubview(verticalLine)
        horizontalLine.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.height.equalTo(Cons.plusWidth)
            $0.width.equalTo(Cons.plusLength)
        }
        verticalLine.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.equalTo(Cons.plusWidth)
            $0.height.equalTo(Cons.plusLength)
        }
        let liftLabel = Chainable(UILabel())
            .text("Lift 效果")
            .textColor(UIColor.ud.textTitle)
            .unwrap()
        hStack1.addArrangedSubview(liftLabel)
        hStack1.snp.makeConstraints {
            $0.height.equalTo(Cons.liftButtonSize)
        }

        vStack.addArrangedSubview(hStack1)

        // Highlight buttons
        let hStack2 = Chainable(UIStackView())
            .axis(.horizontal)
            .alignment(.center)
            .spacing(Cons.spacing)
            .unwrap()
        let highlightHorizontalStack = Chainable(UIStackView())
            .axis(.horizontal)
            .alignment(.center)
            .spacing(Cons.spacing)
            .unwrap()
        let highlightButtons: [UIButton] = [
            UIButton(type: .detailDisclosure),
            UIButton(type: .contactAdd),
            UIButton(type: .infoLight)
        ]
        highlightButtons.forEach {
            highlightHorizontalStack.addArrangedSubview($0)
        }
        hStack2.addArrangedSubview(highlightHorizontalStack)
        let highlightLabel = Chainable(UILabel())
            .text("Highlight 效果")
            .textColor(UIColor.ud.textTitle)
            .unwrap()
        hStack2.addArrangedSubview(highlightLabel)
        hStack2.snp.makeConstraints {
            $0.height.equalTo(48)
        }
        vStack.addArrangedSubview(hStack2)

        // TableView
        let hStack3 = Chainable(UIStackView())
            .axis(.horizontal)
            .alignment(.center)
            .spacing(Cons.spacing)
            .unwrap()
        let tableView = Chainable(UITableView())
            .dataSource(self)
            .delegate(self)
            .rowHeight(50)
//            .register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
            .unwrap()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        hStack3.addArrangedSubview(tableView)
        let hoverLabel = Chainable(UILabel())
            .text("Hover 效果")
            .textColor(UIColor.ud.textTitle)
            .unwrap()
        hStack3.addArrangedSubview(hoverLabel)
        vStack.addArrangedSubview(hStack3)
        tableView.snp.makeConstraints {
            $0.width.equalTo(Cons.tableViewWidth)
            $0.height.equalTo(Cons.tableViewHeight)
        }

        view.addSubview(vStack)
        vStack.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide.snp.edges)
        }

        // MARK: Pointer

        liftButton.addPointer(.lift.targetView { $0.superview?.superview })

        highlightButtons.forEach {
            $0.addPointer(.highlight(insets: .init(edges: 10), cornerRadius: 12))
            $0.addPointer(.highlight(shape: {
                (CGSize(width: $0.width + 10, height: $0.height + 10), $0.width / 2)
            }))
        }
    }
}

extension PointerDemo: UITableViewDataSource, UITableViewDelegate {
    var colors: [UIColor] {
        [.red, .orange, .yellow, .green, .blue, .cyan, .purple]
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return colors.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = Chainable(tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath))
            .backgroundColor(colors[indexPath.row].withAlphaComponent(0.4))
            .unwrap()
        cell.textLabel?.text = String(indexPath.row)
        // MARK: TableView Cell Pointer
        cell.removeExistedPointers()
//        cell.addPointer(.hover)
        let pointer: PointerInfo = .hover
        if #available(iOS 15, *) {
            pointer.accessories = .init(handler: { _, _ in
                return indexPath.row % 2 == 0 ? [.arrow(.top), .arrow(.bottom)] : [.arrow(.left), .arrow(.right)]
            })
        }
        cell.addPointer(pointer)
        return cell
    }
}
