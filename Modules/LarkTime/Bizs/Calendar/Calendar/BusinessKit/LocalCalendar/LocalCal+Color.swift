//
//  LocalCal+Color.swift
//  Calendar
//
//  Created by jiayi zou on 2018/9/21.
//  Copyright © 2018 EE. All rights reserved.
//

import UIKit
import Foundation
import CalendarFoundation
import LarkRustClient
import RustPB
import RxSwift
import ThreadSafeDataStructure

final class LocalCalHelper {
    private static var calDic: SafeDictionary<Int32, ColorIndex> = [:] + .readWriteLock

    static var calendarApiGetter: CalendarApiGetter?

    static func preloadColors(colors: [CGColor]) {
        //预读取
        let colorInts = colors
            .map { $0.toInt32() }
            .filter { (key) -> Bool in
                return LocalCalHelper.calDic[key] == nil
            }

        if colorInts.isEmpty {
            return
        }

        var disposeBag = DisposeBag()
        calendarApiGetter?()?.getColorIndexMap(originalColor: colorInts).subscribe(onNext: { (result) in
            for (color, colorIndex) in result {
                LocalCalHelper.calDic[color] = colorIndex
            }
            disposeBag = DisposeBag()
        }, onError: { (_) in
            disposeBag = DisposeBag()
            assertionFailureLog()
        }).disposed(by: disposeBag)
    }

    static func getColor(color: CGColor) -> ColorIndex {
        if let colorIndex = LocalCalHelper.calDic[color.toInt32()] {
            return colorIndex
        } else {
            return .carmine
        }
    }
}

extension CGColor {
    func toInt32() -> Int32 {
        let color = UIColor(cgColor: self)
        let result = colorToRGB(color: color)
        return result
    }
}
