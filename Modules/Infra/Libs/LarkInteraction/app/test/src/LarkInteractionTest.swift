//
//  LarkInteractionTest.swift
//  LarkInteractionDevEEUnitTest
//
//  Created by 李晨 on 2020/3/26.
//

import UIKit
import Foundation
import XCTest
@testable import LarkInteraction

class LarkInteractionTest: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        super.setUp()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testItemProvider() {
        let item = NSItemProvider(
            contentsOf: Bundle.main.url(forResource: "ios-.pdf", withExtension: nil)
        )!
        XCTAssert(item.fullSuggestedName.hasSuffix(".pdf"))
        item.suggestedName = "123"
        XCTAssert(item.fullSuggestedName == "123.pdf")
        item.suggestedName = "123.png"
        XCTAssert(item.fullSuggestedName == "123.png")
    }

    func testViewExtension() {
        let drop = DropInteraction()
        let drag = DragInteraction()
        let view = UIView()
        view.addLKInteraction(drag)
        view.addLKInteraction(drop)
        XCTAssert(view.lkInteractions.count == 2)
        view.removeLKInteraction(drag)
        view.removeLKInteraction(drop)
        XCTAssert(view.lkInteractions.isEmpty)

        let tableView = UITableView()
        tableView.lkTableDragDelegate = TableViewDragDelegate()
        tableView.lkTableDropDelegate = TableViewDropDelegate()
        XCTAssert(tableView.lkTableDragDelegate != nil)
        XCTAssert(tableView.lkTableDropDelegate != nil)

        let textField = UITextField()
        textField.lkTextDragDelegate = TextViewDragDelegate()
        textField.lkTextDropDelegate = TextViewDropDelegate()
        XCTAssert(textField.lkTextDragDelegate != nil)
        XCTAssert(textField.lkTextDropDelegate != nil)

        let textView = UITextView()
        textView.lkTextDragDelegate = TextViewDragDelegate()
        textView.lkTextDropDelegate = TextViewDropDelegate()
        XCTAssert(textView.lkTextDragDelegate != nil)
        XCTAssert(textView.lkTextDropDelegate != nil)
    }

    func testItemResult() {
        let drag = UIDragItem(itemProvider: NSItemProvider(object: "123" as NSString))
        let result: Result<DropItemValue, Error> = .success(
            DropItemValue(
                suggestedName: "suggestedName",
                itemData: .classType("123" as NSString)) )
        drag.liItemResult = result
        XCTAssert(drag.liItemResult != nil)
    }

    func testSpringLoaded() {
        let springloaded = SpringLoadedInteraction { (_, _) in
        }
        var called = false
        springloaded.shouldBeginHandler = { (_, _) -> Bool in
            called = true
            return false
        }
        _ = springloaded.behavior.shouldAllow(springloaded.springLoadedInteraction, with: SpringTestContext())
        XCTAssert(called)

        called = false
        springloaded.didChangeHandler = { (_, _) in
            called = true
        }
        springloaded.effect.interaction(springloaded.springLoadedInteraction, didChangeWith: SpringTestContext())
        XCTAssert(called)

        called = false
        springloaded.didFinishHandler = { (_) in
            called = true
        }
        springloaded.behavior.interactionDidFinish(springloaded.springLoadedInteraction)
        XCTAssert(called)
    }

    func testTableView() {
        let tableView = UITableView()

        let drag = TableViewDragDelegate()
        let index = IndexPath()

        var called = 0
        drag.add { (_) in
            called += 1
        }
        drag.tableView(tableView, dragSessionWillBegin: TestDragSession())
        drag.tableView(tableView, dragSessionDidEnd: TestDragSession())
        XCTAssert(called == 2)

        called = 0
        drag.itemsBlock = { (_, _, _) in
            called += 1
            return []
        }
        _ = drag.tableView(tableView, itemsForBeginning: TestDragSession(), at: index)
        XCTAssert(called == 1)

        called = 0
        drag.itemsForAddingBlock = { (_, _, _, _)  in
            called += 1
            return []
        }
        _ = drag.tableView(tableView, itemsForAddingTo: TestDragSession(), at: index, point: .zero)
        XCTAssert(called == 1)

        called = 0
        drag.previewParameters = { (_, _) in
            called += 1
            return nil
        }
        _ = drag.tableView(tableView, dragPreviewParametersForRowAt: index)
        XCTAssert(called == 1)

        drag.allowsMoveOperation = false
        XCTAssertFalse(drag.tableView(tableView, dragSessionAllowsMoveOperation: TestDragSession()))

        drag.restricted = false
        XCTAssertFalse(drag.tableView(tableView, dragSessionIsRestrictedToDraggingApplication: TestDragSession()))

        let drop = TableViewDropDelegate()
        called = 0
        drop.add { (_) in
            called += 1
        }
        drop.tableView(tableView, dropSessionDidEnter: TestDropSession())
        _ = drop.tableView(tableView, dropSessionDidUpdate: TestDropSession(), withDestinationIndexPath: nil)
        drop.tableView(tableView, dropSessionDidExit: TestDropSession())
        drop.tableView(tableView, dropSessionDidEnd: TestDropSession())
        XCTAssert(called == 4)

        called = 0
        drop.handleBlock = { (_, _) in
            called += 1
        }
        drop.tableView(tableView, performDropWith: TestTableViewDropCoordinator())
        XCTAssert(called == 1)

        called = 0
        drop.canHandle = { (_, _) in
            called += 1
            return false
        }
        _ = drop.tableView(tableView, canHandle: TestDropSession())
        XCTAssert(called == 1)

        called = 0
        drop.previewParameters = { (_, _) in
            called += 1
            return nil
        }
        _ = drop.tableView(tableView, dropPreviewParametersForRowAt: IndexPath())
        XCTAssert(called == 1)
    }

    func testTextView() {
        let dragItem = UIDragItem(itemProvider: NSItemProvider(object: "123" as NSString))
        let textView = UITextView()
        UIApplication.shared.windows.first?.addSubview(textView)

        let drag = TextViewDragDelegate()
        var called = 0
        drag.add { (_) in
            called += 1
        }
        drag.textDraggableView(textView, dragSessionWillBegin: TestDragSession())
        XCTAssert(called == 1)
        called = 0
        drag.textDraggableView(textView, dragSessionDidEnd: TestDragSession(), with: .cancel)
        XCTAssert(called == 1)
        called = 0
        drag.itemsBlock = { (_, _) in
            called += 1
            return []
        }
        _ = drag.textDraggableView(textView, itemsForDrag: TestTextDragRequest())
        XCTAssert(called == 1)
        called = 0
        drag.addLift { (_, _) in
            called += 1
        }
        drag.addLift { (_, _, _) in
            called += 1
        }
        drag.textDraggableView(textView, willAnimateLiftWith: TestDragAnimating(), session: TestDragSession())
        XCTAssert(called == 2)
        called = 0
        drag.liftingPreview = { (_, _, _) in
            called += 1
            return nil
        }
        _ = drag.textDraggableView(textView, dragPreviewForLiftingItem: dragItem, session: TestDragSession())
        XCTAssert(called == 1)

        let drop = TextViewDropDelegate()
        called = 0
        drop.add { (_) in
            called += 1
        }
        drop.textDroppableView(textView, dropSessionDidEnter: TestDropSession())
        drop.textDroppableView(textView, dropSessionDidUpdate: TestDropSession())
        drop.textDroppableView(textView, dropSessionDidExit: TestDropSession())
        drop.textDroppableView(textView, dropSessionDidEnd: TestDropSession())
        XCTAssert(called == 4)

        called = 0
        drop.editableForDrop = { _, _ in
            called += 1
            return .no
        }
        _ = drop.textDroppableView(textView, willBecomeEditableForDrop: TestTextDropRequest())
        XCTAssert(called == 1)

        called = 0
        drop.dropProposalBlock = { _, _ in
            called += 1
            return .init(operation: .cancel)
        }
        _ = drop.textDroppableView(textView, proposalForDrop: TestTextDropRequest())
        XCTAssert(called == 1)

        called = 0
        drop.handleBlock = { _, _ in
            called += 1
        }
        drop.textDroppableView(textView, willPerformDrop: TestTextDropRequest())
        XCTAssert(called == 1)

        called = 0
        drop.dropPreview = { (_, _) in
            called += 1
            return nil
        }
        _ = drop.textDroppableView(
            textView,
            previewForDroppingAllItemsWithDefault: UITargetedDragPreview(view: textView)
        )
        XCTAssert(called == 1)
    }

    func testDragContainer() {
        let view = UIView()
        let testView = UIView()
        let proxy = DragContainerProxy(dragInteractionEnable: { (_) -> Bool in
            return false
        }, dragInteractionIgnore: { (_) -> Bool in
            return true
        }, dragInteractionContext: { (_) -> DragContext? in
            return DragContext()
        }) { (_) -> UIView? in
            return testView
        }
        view.dragContainerProxy = proxy
        XCTAssert(view.dragContainerProxy != nil)
        XCTAssert(!proxy.dragInteractionEnable(location: .zero))
        XCTAssert(proxy.dragInteractionIgnore(location: .zero))
        XCTAssert(proxy.dragInteractionContext(location: .zero) != nil)
        XCTAssert(proxy.dragInteractionForward(location: .zero) == testView)
    }

    func testDragContext() {
        let key = DragContextKey("1")
        let key2: DragContextKey = "2"
        XCTAssert(key.value == "1")
        XCTAssert(key2.value == "2")

        var context = DragContext()
        context.set(key: "key1", value: "123", identifier: "123")
        context.set(key: "key2", value: "123", identifier: "123")
        XCTAssert((context.getValue(key: "key1") as? String) == "123")
        XCTAssert(context.identifier == "key1_123_key2_123")
        context.remove(key: "key1")
        XCTAssert(context.identifier == "key2_123")
    }

    func testDragHandler() {
        let item = DragItem(dragItem: UIDragItem(itemProvider: NSItemProvider(object: "123" as NSString)))
        let handler = DragHandlerImpl(
            handleViewTag: "123",
            canHandle: { (_) -> Bool in
                return true
        }) { (_, _) -> [DragItem]? in
            return [item]
        }
        XCTAssert(handler.dragInteractionHandleViewTag() == "123")
        XCTAssert(handler.dragInteractionCanHandle(context: DragContext()))
        XCTAssert(
            (handler.dragInteractionHandle(
                    info: DragInteractionViewInfo(tag: "123", view: UIView()),
                    context: DragContext()
            ) != nil)
        )
    }

    func testDragManager() {
        let manager = DragInteractionManager()
        manager.viewTagBlock = { (view) -> String in
            return "\(view.tag)"
        }
        let handler = DragHandlerImpl(
            handleViewTag: "123",
            canHandle: { (_) -> Bool in
                return true
        }) { (_, _) -> [DragItem]? in
            return nil
        }
        manager.register(handler)
        XCTAssert(!manager.handlerDic.values.isEmpty)
        let observerID = manager.addLifeCycle { (_) in
        }
        XCTAssert(!manager.observerDic.isEmpty)
        manager.removeLiftCycle(observerID: observerID)
        XCTAssert(manager.observerDic.isEmpty)

    }

    func testPointer() {
        if #available(iOS 13.4, *) {
            let pointer1 = PointerInteraction(
                style: .init(
                    effect: .highlight,
                    shape: .roundedBounds({ (_, _) -> (CGRect, CGFloat) in
                        return (CGRect.zero, 0)
                    })
                )
            )

            let pointer2 = PointerInteraction(
                style: .init(
                    effect: .lift,
                    shape: .roundedSize({ (_, _) -> (CGSize, CGFloat) in
                        return (CGSize.zero, 0)
                    })
                )
            )

            let pointer3 = PointerInteraction(
                style: .init(
                    effect: .hover(),
                    shape: .path(path: { (_, _) -> UIBezierPath in
                        return UIBezierPath(rect: .zero)
                    })
                )
            )

            let view = UIView()
            view.addLKInteraction(pointer1)
            view.addLKInteraction(pointer2)
            view.addLKInteraction(pointer3)

            XCTAssertTrue(pointer1.isEnabled)
            pointer1.isEnabled = false
            XCTAssertFalse(pointer1.isEnabled)

            var result: Int = 0

            pointer1.animating.addWillEnter { (_, _) in
                result += 1
            }
            pointer1.animating.addWillEnter { (_, _, _) in
                result += 1
            }
            pointer1.animating.addWillExit { (_, _) in
                result += 1
            }
            pointer1.animating.addWillExit { (_, _, _) in
                result += 1
            }

            pointer1.pointerInteraction(
                pointer1.pointerInteraction,
                willEnter: .init(rect: .zero),
                animator: PointerAnimating()
            )
            pointer1.pointerInteraction(
                pointer1.pointerInteraction,
                willExit: .init(rect: .zero),
                animator: PointerAnimating()
            )
            XCTAssertEqual(result, 4)

            var handle: Bool = false
            pointer1.handler = { (_, _, region) -> UIPointerRegion? in
                handle = true
                return region
            }
            _ = pointer1.pointerInteraction(
                pointer1.pointerInteraction,
                regionFor: UIPointerRegionRequest(),
                defaultRegion: .init(rect: .zero)
            )
            XCTAssertTrue(handle)

            let btn = UIButton()
            XCTAssertNil(btn.lkPointerStyle)
            btn.lkPointerStyle = PointerStyle(
                effect: .automatic,
                shape: .roundedFrame({ (_, _) -> (CGRect, CGFloat) in
                    return (CGRect.zero, 0)
                }),
                targetProvider: .default,
                axis: .default
            )
            XCTAssertNotNil(btn.lkPointerStyle)
        }
    }

    func testNormalPointer() {

        let testView = UIView()
        testView.addPointer(.init(
            effect: .automatic,
            shape: { (size) -> PointerInfo.ShapeSizeInfo in
                return (size, 0)
            },
            targetView: { (view) -> UIView in
                return view
            }
        ))

        let testbBtn = UIButton()
        testbBtn.update(.init(
            effect: .automatic,
            shape: { (size) -> PointerInfo.ShapeSizeInfo in
                return (size, 0)
            },
            targetView: { (view) -> UIView in
                return view
            }
        ))
    }
}

class PointerAnimating: NSObject, UIPointerInteractionAnimating {

    func addAnimations(_ animations: @escaping () -> Void) {
        animations()
    }

    func addCompletion(_ completion: @escaping (Bool) -> Void) {
        completion(true)
    }
}

class SpringTestContext: NSObject, UISpringLoadedInteractionContext {
    var state: UISpringLoadedInteractionEffectState = .activated

    var targetView: UIView?

    var targetItem: Any?

    func location(in view: UIView?) -> CGPoint {
        return .zero
    }
}

class TestDragSession: NSObject, UIDragSession {
    func canLoadObjects(ofClass aClass: NSItemProviderReading.Type) -> Bool {
        return false
    }

    var localContext: Any?

    var items: [UIDragItem] = []

    func location(in view: UIView) -> CGPoint {
        return .zero
    }

    var allowsMoveOperation: Bool = false

    var isRestrictedToDraggingApplication: Bool = false

    func hasItemsConforming(toTypeIdentifiers typeIdentifiers: [String]) -> Bool {
        return false
    }
}

class TestDropSession: NSObject, UIDropSession {
    func loadObjects(
        ofClass aClass: NSItemProviderReading.Type,
        completion: @escaping ([NSItemProviderReading]) -> Void
    ) -> Progress {
        return self.progress
    }

    func canLoadObjects(ofClass aClass: NSItemProviderReading.Type) -> Bool {
        return false
    }

    var localDragSession: UIDragSession?

    var progressIndicatorStyle: UIDropSessionProgressIndicatorStyle = .default

    var items: [UIDragItem] = []

    func location(in view: UIView) -> CGPoint {
        return .zero
    }

    var allowsMoveOperation: Bool = false

    var isRestrictedToDraggingApplication: Bool = false

    func hasItemsConforming(toTypeIdentifiers typeIdentifiers: [String]) -> Bool {
        return true
    }

    var progress: Progress = Progress()
}

class TestTextDragRequest: NSObject, UITextDragRequest {
    var dragRange: UITextRange = UITextRange()

    var suggestedItems: [UIDragItem] = []

    var existingItems: [UIDragItem] = []

    var isSelected: Bool = false

    var dragSession: UIDragSession = TestDragSession()

}

class TestDragAnimating: NSObject, UIDragAnimating {
    func addAnimations(_ animations: @escaping () -> Void) {
        animations()
    }

    func addCompletion(_ completion: @escaping (UIViewAnimatingPosition) -> Void) {
        completion(.current)
    }
}

class TestTextDropRequest: NSObject, UITextDropRequest {
    var dropPosition: UITextPosition = .init()

    var suggestedProposal: UITextDropProposal = .init(operation: .cancel)

    var isSameView: Bool = false

    var dropSession: UIDropSession = TestDropSession()
}

class TestTableViewDropPlaceholderContext: NSObject, UITableViewDropPlaceholderContext {
    var dragItem: UIDragItem = UIDragItem(itemProvider: NSItemProvider(object: "123" as NSString))

    func commitInsertion(dataSourceUpdates: (IndexPath) -> Void) -> Bool {
        return false
    }

    func deletePlaceholder() -> Bool {
        return false
    }

    func addAnimations(_ animations: @escaping () -> Void) {
    }

    func addCompletion(_ completion: @escaping (UIViewAnimatingPosition) -> Void) {
    }
}

class TestTableViewDropCoordinator: NSObject, UITableViewDropCoordinator {
    var items: [UITableViewDropItem] = []

    var destinationIndexPath: IndexPath?

    var proposal: UITableViewDropProposal = .init(operation: .cancel)

    var session: UIDropSession = TestDropSession()

    func drop(_ dragItem: UIDragItem, to placeholder: UITableViewDropPlaceholder) -> UITableViewDropPlaceholderContext {
        return TestTableViewDropPlaceholderContext()
    }

    func drop(_ dragItem: UIDragItem, toRowAt indexPath: IndexPath) -> UIDragAnimating {
        return TestDragAnimating()
    }

    func drop(_ dragItem: UIDragItem, intoRowAt indexPath: IndexPath, rect: CGRect) -> UIDragAnimating {
        return TestDragAnimating()
    }

    func drop(_ dragItem: UIDragItem, to target: UIDragPreviewTarget) -> UIDragAnimating {
        return TestDragAnimating()
    }
}
