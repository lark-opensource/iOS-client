//
//  PadGridCalculator.swift
//  ByteView
//
//  Created by liujianlong on 2022/7/26.
//

import Foundation

private let minCellWidth: Double = 144.0
private let minCellHeight: Double = 144.0

struct PadGridConfig: Equatable {
    var screenSize: CGSize
    var topPadding: CGFloat
    var bottomPadding: CGFloat
    var leftPadding: CGFloat
    var rightPadding: CGFloat
    var vSpacing: CGFloat
    var hSpacing: CGFloat
    var maxCol: Int
    var maxRow: Int
    var minWHRatio: Double
    var maxWHRatio: Double

    init(screenSize: CGSize,
         topPadding: CGFloat,
         bottomPadding: CGFloat,
         leftPadding: CGFloat,
         rightPadding: CGFloat,
         vSpacing: CGFloat,
         hSpacing: CGFloat,
         maxCellCount: Int,
         maxCol: Int,
         maxRow: Int,
         minWHRatio: Double,
         maxWHRatio: Double) {
        assert(maxCol > 0 && maxRow > 0)

        self.screenSize = screenSize
        self.topPadding = topPadding
        self.bottomPadding = bottomPadding
        self.leftPadding = leftPadding
        self.rightPadding = rightPadding
        self.vSpacing = vSpacing
        self.hSpacing = hSpacing
        self.minWHRatio = minWHRatio
        self.maxWHRatio = maxWHRatio
        let maxColCalc = Int((screenSize.width - leftPadding * 2.0 + hSpacing) / (minCellWidth + hSpacing))
        let maxRowCalc = Int((screenSize.height - topPadding - bottomPadding + vSpacing) / (minCellHeight + vSpacing))
        var maxCol = min(maxCol, max(maxColCalc, 1))
        var maxRow = min(maxRow, max(maxRowCalc, 1))
        while (maxCol > 1 || maxRow > 1) && maxCol * maxRow > maxCellCount {
            if maxCol > maxRow {
                maxCol -= 1
            } else {
                maxRow -= 1
            }
        }
        self.maxCol = maxCol
        self.maxRow = maxRow
    }
}

final class PadGridCalculator {
    private var minWHRatio: Double {
        padGridConfig.minWHRatio
    }
    private var maxWHRatio: Double {
        padGridConfig.maxWHRatio
    }

    struct Solution {
        var hMargin: Double
        var topMargin: Double
        var hSpacing: Double
        var vSpacing: Double
        var columnCount: Int
        var rowCount: Int
        var cellWidth: Double
        var cellHeight: Double
    }

    var leftPadding: Double {
        padGridConfig.leftPadding
    }

    var rightPadding: Double {
        padGridConfig.rightPadding
    }
    var topPadding: Double {
        padGridConfig.topPadding
    }
    var bottomPadding: Double {
        padGridConfig.bottomPadding
    }

    var hSpacing: Double {
        padGridConfig.hSpacing
    }
    var vSpacing: Double {
        padGridConfig.vSpacing
    }

    var screenWidth: Double {
        padGridConfig.screenSize.width
    }
    var screenHeight: Double {
        padGridConfig.screenSize.height
    }
    var maxRow: Int {
        padGridConfig.maxRow
    }
    var maxCol: Int {
        padGridConfig.maxCol
    }
    var solutions: [[Solution]] = []

    let padGridConfig: PadGridConfig

    init(padGridConfig: PadGridConfig) {
        self.padGridConfig = padGridConfig
        self.solutions = self.buildSolutions()
    }

    var fullPageSolution: Solution {
        solutions.last!.last!
    }

    private func computeArea(row: Int, column: Int,
                             hSpacing: Double,
                             vSpacing: Double,
                             width: inout Double, height: inout Double) -> Double {
        let candidateWidth = (screenWidth - self.leftPadding - self.rightPadding - hSpacing * Double(column - 1)) / Double(column)
        let candidateHeight = (screenHeight - self.topPadding - self.bottomPadding - vSpacing * Double(row - 1)) / Double(row)
        let candidateRatio = candidateWidth / candidateHeight

        if candidateRatio < minWHRatio {
            width = candidateWidth
            height = width / minWHRatio
        } else if candidateRatio > maxWHRatio {
            height = candidateHeight
            width = height * maxWHRatio
        } else {
            width = candidateWidth
            height = candidateHeight
        }
        return width * height * Double(column * row)
    }


    private func buildSolutions() -> [[Solution]] {

        assert(maxCol > 0 && maxRow > 0, "screen too small")
        if maxCol == 0 || maxCol == 0 {
            return [[Solution(hMargin: 0, topMargin: 0,
                              hSpacing: 0, vSpacing: 0,
                              columnCount: 1, rowCount: 1,
                              cellWidth: minCellWidth, cellHeight: minCellHeight)]]
        }
        var solutions: [[Solution]] = .init(repeating: [], count: maxCol)
        for col in 1...maxCol {
            for row in 1...maxRow {
                var width: Double = 0.0
                var height: Double = 0.0
                var hSpacing = self.hSpacing
                var vSpacing = self.vSpacing
                _ = computeArea(row: row, column: col,
                                hSpacing: hSpacing, vSpacing: vSpacing,
                                width: &width, height: &height)
                // UX 要求:
                // - 当单个视频流高度大于等于 200 时，视频流间距为 8
                // - 当单个视频流高度小于 200 时，视频流间距为 6
                if height < 200 {
                    hSpacing = 6.0
                    vSpacing = 6.0
                    _ = computeArea(row: row, column: col,
                                    hSpacing: hSpacing,
                                    vSpacing: vSpacing,
                                    width: &width, height: &height)
                }

                let verticalRemains = screenHeight - height * Double(row) - vSpacing * Double(row - 1)
                let horizontalRemains = screenWidth - width * Double(col) - hSpacing * Double(col - 1)

                let vMargin: Double
                if verticalRemains * 0.5 > self.bottomPadding && verticalRemains * 0.5 > self.topPadding {
                    vMargin = verticalRemains * 0.5
                } else {
                    vMargin = (verticalRemains - self.topPadding - self.bottomPadding) * 0.5 + self.topPadding
                }
                let hMargin: Double = horizontalRemains * 0.5

                let solution = Solution(hMargin: hMargin, topMargin: vMargin,
                                        hSpacing: hSpacing, vSpacing: vSpacing,
                                        columnCount: col, rowCount: row,
                                        cellWidth: width, cellHeight: height)
                solutions[col - 1].append(solution)
            }
        }
        return solutions
    }

    var solutionMap: [Int: Solution] = [:]
    func computeSolution(cellCount: Int) -> Solution {
        if cellCount < 1 {
            return solutions[0][0]
        }
        let pageCellCount = cellCount % (self.maxRow * self.maxCol)
        if pageCellCount == 0 {
            return self.fullPageSolution
        }
        if let solution = solutionMap[pageCellCount] {
            return solution
        }
        var solution: Solution?
        let prefer1x1 = padGridConfig.screenSize.height > padGridConfig.screenSize.width && cellCount >= 9
        for col in 1...maxCol {
            for row in 1...maxRow {
                if col * row >= pageCellCount && (col - 1) * row < pageCellCount && col * (row - 1) < pageCellCount {
                    let curSolution = solutions[col - 1][row - 1]
                    let curSolutionArea = curSolution.area(prefer1x1: prefer1x1)
                    let solutionArea = solution?.area(prefer1x1: prefer1x1) ?? -1.0
                    if solution == nil || solutionArea <= curSolutionArea {
                        solution = curSolution
                    }
                }
            }
        }
        let ret = solution ?? solutions[0][0]
        solutionMap[pageCellCount] = ret
        return ret
    }
}

extension PadGridCalculator.Solution {
    func area(prefer1x1: Bool) -> Double {
        prefer1x1 ? min(cellWidth, cellHeight) * min(cellWidth, cellHeight) : cellWidth * cellHeight
    }
}
