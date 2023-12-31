//
//  main.swift
//  BTSVG
//
//  Created by Crazy凡 on 2020/9/30.
//

import UIKit
import Foundation

// MARK: - Color START

// https://www.cs.rit.edu/~ncs/color/t_convert.html
struct RGB {
    // Percent
    let r: Float // [0,1]
    let g: Float // [0,1]
    let b: Float // [0,1]

    static func hsv(r: Float, g: Float, b: Float) -> HSV {
        let min = r < g ? (r < b ? r : b) : (g < b ? g : b)
        let max = r > g ? (r > b ? r : b) : (g > b ? g : b)

        let v = max
        let delta = max - min

        guard delta > 0.000_01 else { return HSV(h: 0, s: 0, v: max) }
        guard max > 0 else { return HSV(h: -1, s: 0, v: v) } // Undefined, achromatic grey
        let s = delta / max

        let hue: (Float, Float) -> Float = { max, delta -> Float in
            if r == max { return (g - b) / delta } // between yellow & magenta
            else if g == max { return 2 + (b - r) / delta } // between cyan & yellow
            else { return 4 + (r - g) / delta } // between magenta & cyan
        }

        let h = hue(max, delta) * 60 // In degrees

        return HSV(h: h < 0 ? h + 360 : h, s: s, v: v)
    }

    static func hsv(rgb: RGB) -> HSV {
        return RGB.hsv(r: rgb.r, g: rgb.g, b: rgb.b)
    }

    var hsv: HSV {
        return RGB.hsv(rgb: self)
    }
}

struct RGBA {
    let a: Float
    let rgb: RGB

    init(r: Float, g: Float, b: Float, a: Float) {
        self.a = a
        rgb = RGB(r: r, g: g, b: b)
    }
}

struct HSV {
    let h: Float // Angle in degrees [0,360] or -1 as Undefined
    let s: Float // Percent [0,1]
    let v: Float // Percent [0,1]

    static func rgb(h: Float, s: Float, v: Float) -> RGB {
        if s == 0 { return RGB(r: v, g: v, b: v) } // Achromatic grey

        let angle = (h >= 360 ? 0 : h)
        let sector = angle / 60 // Sector
        let i = floor(sector)
        let f = sector - i // Factorial part of h

        let p = v * (1 - s)
        let q = v * (1 - (s * f))
        let t = v * (1 - (s * (1 - f)))

        switch i {
        case 0:
            return RGB(r: v, g: t, b: p)
        case 1:
            return RGB(r: q, g: v, b: p)
        case 2:
            return RGB(r: p, g: v, b: t)
        case 3:
            return RGB(r: p, g: q, b: v)
        case 4:
            return RGB(r: t, g: p, b: v)
        default:
            return RGB(r: v, g: p, b: q)
        }
    }

    static func rgb(hsv: HSV) -> RGB {
        return HSV.rgb(h: hsv.h, s: hsv.s, v: hsv.v)
    }

    var rgb: RGB {
        return HSV.rgb(hsv: self)
    }

    /// Returns a normalized point with x=h and y=v
    var point: CGPoint {
        return CGPoint(x: CGFloat(h / 360), y: CGFloat(v))
    }
}

// MARK: - Color END

// MARK: - Parser START

class DataParser {
    private(set) var tasks: [Task] = []
    private(set) var total: TimeInterval = 1 { didSet { if total < 1 { total = 1 } } }
    private(set) var maxDuration: TimeInterval = 1

    var path: String? {
        didSet {
            if let path = path {
                startParseData(path)
            }
        }
    }

    init() {}

    private func startParseData(_ path: String) {
        // read data.
        guard let content = try? String(contentsOfFile: path) else { return }

        let decoder = JSONDecoder()

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        decoder.dateDecodingStrategy = .custom { (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            var dateString = try container.decode(String.self)
            if dateString.count > 10 { dateString.removeLast(11) }

            return formatter.date(from: dateString)!
        }

        let events = content.components(separatedBy: "\n")
            .compactMap { line -> Event? in
                var line = line
                if line.hasSuffix(",") { line.removeLast() }

                guard let data = line.data(using: .utf8) else {
                    return nil
                }

                do {
                    return try decoder.decode(Event.self, from: data)
                } catch {
                    print(error)
                    return nil
                }
            }
            .sorted(by: { $0.date < $1.date })

        // skip empty data.
        guard !events.isEmpty else { return }

        let min = events[0].date
        let max = events.last!.date

        total = min.distance(to: max)

        var cache = [String: (Event?, Event?)]()

        for event in events {
            var tmp = cache[event.taskName] ?? .init((nil, nil))
            if event.event == .start, tmp?.0 == nil {
                tmp?.0 = event
            } else if event.event == .end, tmp?.1 == nil {
                tmp?.1 = event
            }
            cache[event.taskName] = tmp
        }

        let tasks = cache.values.compactMap { (start, end) -> Task? in
            guard let start = start, let end = end else { return nil }

            let _start = min.distance(to: start.date)
            let _end = min.distance(to: end.date)

            return Task(
                start: _start,
                end: _end,
                name: start.taskName,
                textPosition: _start / total < 0.5 && _end / total < 0.7 ? .trailing : .leading
            )
        }
        .sorted(by: { $0.start < $1.start })
        maxDuration = tasks.max(by: { $0.duration < $1.duration })?.duration ?? 0

        self.tasks = tasks
    }
}

extension DataParser {
    enum EventType: String, Codable {
        case start
        case end
    }

    struct Event: Codable {
        var date: Date
        var taskName: String
        var event: EventType
    }
}

extension DataParser {
    enum TextPosition {
        case leading
        case center
        case trailing
    }

    struct Task: Hashable {
        var start: TimeInterval
        var end: TimeInterval
        var name: String
        var textPosition: TextPosition

        var duration: TimeInterval { end - start }
    }
}

// MARK: - Parser END

// MARK: - Generator START

private enum DurationType {
    case leading
    case trailing
}

class SVGGenerator {
    private(set) var data: DataParser

    private let svgWidth: Double = 1680
    private let colorOffset: Double = 200
    private let lineHieght: Int = 15
    private let lineSpace: Int = 7
    private let nameOffset: Double = 15
    private let elementSpace: Double = 7

    init(data: DataParser) {
        self.data = data
    }

    private func color(for taskDuration: TimeInterval) -> String {
        let rgb = HSV(h: Float((1 - taskDuration / data.maxDuration) * 120), s: 0.8, v: 0.8).rgb
        return String(format: "#%2X%2X%2X", Int(rgb.r * 255), Int(rgb.g * 255), Int(rgb.b * 255))
    }

    private func position(for task: DataParser.Task) -> DurationType {
        task.end / data.total < 0.7 ? .trailing : .leading
    }

    func svg() -> String {
        let colorAvailableWidth = svgWidth - colorOffset

        func single(for task: DataParser.Task, index: Int) -> String {
            let duration = task.duration
            let y = (lineHieght + lineSpace) * (index + 1)
            let start = colorOffset + colorAvailableWidth * (task.start / data.total)
            let end = colorOffset + colorAvailableWidth * (task.end / data.total)

            let isTrailing = position(for: task) == .trailing

            return """
            <text
                x="\(colorOffset - nameOffset)"
                y="\(y)"
                text-anchor="end"
                font-size="1em"
                transform="rotate(-45, \(colorOffset - nameOffset), \(y))"
                fill="black">\(task.name)</text>
            <line
                x1="\(colorOffset - (nameOffset - elementSpace))" y1="\(y)"
                x2="\(isTrailing ? start - elementSpace : start - elementSpace - 11 - 11 * ceil(log10(duration)))" y2="\(y)"
                stroke-dasharray="5,5"
                style="stroke:grey; stroke-width:1"/>
            <line x1="\(start)" y1="\(y)" x2="\(end)" y2="\(y)"
                style="stroke:\(color(for: duration));
                stroke-width:\(lineHieght)"/>
            <text x="\(isTrailing ? end + 5 : start - 5)" y="\(y + 5)"
                \(isTrailing ? " " : "text-anchor=\"end\"")
                font-size="0.8em"
                fill="black">\(duration)</text>
            """
        }

        return """
        <svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="\(svgWidth)" height="\(data.tasks.count * (lineHieght + lineSpace) + 50)">
            \(data.tasks.enumerated().map { single(for: $1, index: $0) }.joined(separator: "\n"))
        </svg>
        """
    }
}

// MARK: - Generator END

// MARK: - Main Start

func main() {
    guard CommandLine.arguments.count == 3 else {
        print("Call with data file and svg output file.")
        return
    }
    let p = DataParser()
    p.path = CommandLine.arguments[1]
    let g = SVGGenerator(data: p)

    try? g.svg().write(toFile: CommandLine.arguments[2], atomically: false, encoding: .utf8)
}

main()
