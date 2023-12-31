//
//  ViewController.swift
//  LarkInteractionDev
//
//  Created by 李晨 on 2020/3/15.
//

import Foundation
import UIKit
import LarkInteraction

class ViewController: UIViewController, UIPopoverPresentationControllerDelegate {

    let centerView = UIView()
    override func viewDidLoad() {
        super.viewDidLoad()

        centerView.backgroundColor = UIColor.red
        centerView.frame = CGRect(x: 100, y: 100, width: 50, height: 50)
        view.addSubview(centerView)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let textfield = UITextField()
        textfield.placeholder = "textfield"
        textfield.backgroundColor = UIColor.blue

        let textDropDelegate = TextViewDropDelegate()
        textDropDelegate.editableForDrop = { _, _ in
            return .no
        }
        textDropDelegate.dropProposalBlock = { (_, _) -> UITextDropProposal in
            return UITextDropProposal(operation: .cancel)
        }
        textfield.lkTextDropDelegate = textDropDelegate

        self.view.addSubview(textfield)
        textfield.frame = CGRect(x: 100, y: 30, width: 200, height: 66)

        let label = UILabel()
        label.text = "123123123"
        label.backgroundColor = UIColor.blue

        let rightClick = RightClickRecognizer(target: self, action: #selector(rightClick(ges:)))
        label.addGestureRecognizer(rightClick)

        let drag = DragInteraction()
        drag.itemDataSource.itemsForSession = { (interaction, session) -> [UIDragItem] in
            let item = NSItemProvider(object: "12312312313" as NSString)

            return [UIDragItem(itemProvider: item)]
        }
        label.addLKInteraction(drag)
        self.view.addSubview(label)
        label.frame = CGRect(x: 100, y: 100, width: 200, height: 66)

        let label1 = UILabel()
        label1.text = "123123123"
        label1.backgroundColor = UIColor.blue

        let drag1 = DragInteraction()
        drag1.itemDataSource.itemsForSession = { (interaction, session) -> [UIDragItem] in
            let item = NSItemProvider(object: "12312312313" as NSString)

            return [UIDragItem(itemProvider: item)]
        }
        label1.addLKInteraction(drag1)
        self.view.addSubview(label1)
        label1.frame = CGRect(x: 100, y: 200, width: 200, height: 66)

        let label2 = UILabel()
        label2.text = "123123123"
        label2.backgroundColor = UIColor.blue

        let drag2 = DragInteraction()
        drag2.itemDataSource.itemsForSession = { (interaction, session) -> [UIDragItem] in
            let item = NSItemProvider(object: "12312312313" as NSString)

            return [UIDragItem(itemProvider: item)]
        }

        drag2.itemDataSource.itemsForAddingTo = { (interaction, session, _) -> [UIDragItem] in
            let item = NSItemProvider(object: "12312312313" as NSString)
            let item2 = NSItemProvider(object: "12312312313" as NSString)

            return [UIDragItem(itemProvider: item), UIDragItem(itemProvider: item2)]
        }

        label2.addLKInteraction(drag2)
        self.view.addSubview(label2)
        label2.frame = CGRect(x: 100, y: 300, width: 200, height: 66)

        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.green

        /*
        let drop = DropInteraction()
        drop.dropItemHandler.canHandle = { (interaction, session) -> Bool in
            return session.canLoadObjects(ofClass: UIImage.self)
        }

        drop.dropItemHandler.handleDragSession = { [weak imageView] (interaction, session) -> Void in
            session.loadObjects(ofClass: UIImage.self) { (objects) in
                if let image = objects.first as? UIImage {
                    imageView?.image = image
                }
            }
        }*/

        let drop = DropInteraction.create(
            itemTypes: [
                .classType(UIImage.self),
                .UTIURLType(UTI.Data)
            ]
        ) { (results) in
            print("------ values number \(results.count)")
            results.forEach { (value) in
                print("--------- value name \(value.suggestedName) info \(value.itemData)")
            }
        }

        imageView.addLKInteraction(drop)

        self.view.addSubview(imageView)
        imageView.frame = CGRect(x: 100, y: 400, width: 100, height: 100)

        let spring = SpringLoadedInteraction { (_, _) in
            print("------------ spring")
        }
        spring.didFinishHandler = { (_) in
            print("------------ spring did finish")
        }
        spring.shouldBeginHandler = { (_, _) -> Bool in
            print("------------ spring should begin")
            return true
        }
        spring.didChangeHandler = { (_, _) in
            print("------------ spring did change")
        }
        label.addLKInteraction(spring)

        self.addContextMenu()
        self.addLongRight()
    }

    func addContextMenu() {
        if #available(iOS 13.0, *) {
            let contextView = UIView()
            contextView.backgroundColor = UIColor.yellow
            view.addSubview(contextView)
            contextView.frame = CGRect(x: 100, y: 600, width: 100, height: 100)

            let menu = ContextMenu { (elements) -> MenuGroup in
                var subItem1 = MenuAction(
                    title: "subitem1",
                    image: UIImage(systemName: "airplayaudio"),
                    discoverabilityTitle: "subitem1") {
                    print("subitem 1")
                }
                subItem1.attributes = .disabled

                var subItem2 = MenuAction(
                    title: "subitem2",
                    image: UIImage(systemName: "airplayvideo"),
                    discoverabilityTitle: "subitem2") {
                    print("subitem 2")
                }
                subItem2.state = .on

                var subItem3 = MenuAction(
                    title: "subitem3",
                    image: UIImage(systemName: "airpodspro"),
                    discoverabilityTitle: "subitem3") {
                    print("subitem 3")
                }
                subItem3.state = .mixed
                subItem3.attributes = .destructive

                var item1 = MenuGroup(
                    title: "group1",
                    image: UIImage(systemName: "airport.express"),
                    children: [subItem1, subItem2, subItem3]
                )
                item1.options = .destructive

                var item2 = MenuGroup(
                    title: "group2",
                    image: UIImage(systemName: "airport.extreme"),
                    children: [subItem1, subItem2, subItem3]
                )
                item2.options = .displayInline

                var item3 = MenuGroup(
                    title: "group3",
                    image: UIImage(systemName: "applescript")?.withAlignmentRectInsets(.init(top: 5, left: 5, bottom: 5, right: 5)),
                    children: [subItem1, subItem2, subItem3]
                )

                return MenuGroup(
                    title: "group",
                    image: UIImage(systemName: "applelogo"),
                    children: [item1, item2, item3]
                )
            }
            contextView.addContextMenu(menu)
        }
    }

    func addLongRight() {
        let contextView = UIView()
        contextView.backgroundColor = UIColor.yellow
        view.addSubview(contextView)
        contextView.frame = CGRect(x: 100, y: 800, width: 100, height: 100)

        let long = RightOrLongGestureRecognizer(target: self, action: #selector(rightClick(ges:)))
        long.minimumPressDuration = 2
        contextView.addGestureRecognizer(long)
    }

    @objc
    func rightClick(ges: UIGestureRecognizer) {
        if ges.state == .began {
            print("right \(ges.state.rawValue)")
        }
    }
}
