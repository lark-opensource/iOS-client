//
//  Style.cpp
//  TangramLayoutKit
//
//  Created by qihongye on 2021/4/7.
//

#include "Style.h"
#include "Macros.h"

const TLValue TLStyle::getMainAxisWidth(const TLOrientation orientation) const {
    switch (orientation) {
        case TLOrientationRow:
        case TLOrientationRowReverse:
            return width();
        case TLOrientationColumn:
        case TLOrientationColumnReverse:
            return height();
    }
}

const TLValue TLStyle::getCrossAxisWidth(const TLOrientation orientation) const {
    switch (orientation) {
        case TLOrientationRow:
        case TLOrientationRowReverse:
            return height();
        case TLOrientationColumn:
        case TLOrientationColumnReverse:
            return width();
    }
}

const TLValue TLStyle::getMainAxisMaxWidth(const TLOrientation orientation) const {
    switch (orientation) {
        case TLOrientationRow:
        case TLOrientationRowReverse:
            return maxWidth();
        case TLOrientationColumn:
        case TLOrientationColumnReverse:
            return maxHeight();
    }
}

const TLValue TLStyle::getCrossAxisMaxWidth(const TLOrientation orientation) const {
    switch (orientation) {
        case TLOrientationRow:
        case TLOrientationRowReverse:
            return maxHeight();
        case TLOrientationColumn:
        case TLOrientationColumnReverse:
            return maxWidth();
    }
}

const TLValue TLStyle::getMaixAxisMinWidth(const TLOrientation orientation) const {
    switch (orientation) {
        case TLOrientationRow:
        case TLOrientationRowReverse:
            return minWidth();
        case TLOrientationColumn:
        case TLOrientationColumnReverse:
            return minHeight();
    }
}

const TLValue TLStyle::getCrossAxisMinWidth(const TLOrientation orientation) const {
    switch (orientation) {
        case TLOrientationRow:
        case TLOrientationRowReverse:
            return minHeight();
        case TLOrientationColumn:
        case TLOrientationColumnReverse:
            return minWidth();
    }
}
