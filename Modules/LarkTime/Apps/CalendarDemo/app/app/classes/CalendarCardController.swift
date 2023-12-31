//
//  CalendarCardController.swift
//  CalendarDemo
//
//  Created by heng zhu on 2019/7/18.
//

import Foundation
import UIKit
import Calendar
import SnapKit
import RxSwift
import LarkUIKit
import AsyncComponent
import EEFlexiable
import RxRelay
import CalendarFoundation
import LarkContainer

final class CalendarCardController: UIViewController {

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            for view in self.view.subviews {
                view.removeFromSuperview()
            }
            self.testEventCard()
            self.testShareCard()
        }

    }
    private var binder: EventCardBinder?
    private var shareBinder: EventShareBinder?
    var sharecomponent: ShareCardComponent<EmptyContext>?

    @InjectedLazy var calendarInterface: CalendarInterface
    func testEventCard() {
        let cardView = EventCardView()
        scrollView.addSubview(cardView)

        let binder = calendarInterface.getCalendarEventCardBinder(controllerGetter: { [unowned self] () in
            return self
        }, model: CardViewModelMock.mockData())
        self.binder = binder
        let style = ASComponentStyle()
        style.position = .absolute
        style.marginLeft = 65
        style.marginTop = 10
        style.backgroundColor = .white
        style.width = CSSValue(cgfloat: self.view.frame.width - 76)
        style.border = Border(BorderEdge(width: 1, color: UIColorRGB(230, 232, 235), style: .solid))

        let component = EventCardComponent(props: binder.componentProps, style: style, context: EmptyContext())
        let render = ASComponentRenderer(tag: 1, component)
        render.render(cardView)
    }

    func testShareCard() {
        let cardView = EventCardView()
        scrollView.addSubview(cardView)

        let shareBinder = calendarInterface.getCalendarEventShareBinder(controllerGetter: { [unowned self] () in
            return self
            }, model: ShareCardModelMock())
        self.shareBinder = shareBinder
        let style = ASComponentStyle()
        style.position = .absolute
        style.marginLeft = 65
        style.marginTop = 480
        style.backgroundColor = .white
        style.width = CSSValue(cgfloat: self.view.frame.width - 76)
        style.border = Border(BorderEdge(width: 1, color: UIColorRGB(230, 232, 235), style: .solid))

        let component = ShareCardComponent(props: shareBinder.componentProps, style: style, context: EmptyContext())
        let render = ASComponentRenderer(tag: 2, component)
        self.sharecomponent = component
        render.render(cardView)

    }

    let scrollView = UIScrollView()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBase
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        testEventCard()
        testShareCard()

        return
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        scrollView.contentSize = CGSize(width: view.frame.width, height: 1500)
    }

}
