(window["webpackJsonp"] = window["webpackJsonp"] || []).push([[11],{

/***/ 1678:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.FullScreen = exports.Pickup = exports.FoldTrigger = exports.Comment = exports.Filter = exports.Dropdown = exports.FindAndReplace = exports.Img = exports.Link = exports.Formula = exports.Freeze = exports.Sort = exports.WordWrap = exports.VAlign = exports.HAlign = exports.SplitMerge = exports.BorderColor = exports.BorderLine = exports.BackColor = exports.ForeColor = exports.Strikethrough = exports.Underline = exports.Italic = exports.Bold = exports.FontSize = exports.Formatter = exports.Divider = exports.ClearFormat = exports.FormatPainterWidget = exports.Redo = exports.Undo = exports.setEmbedStyle = exports.StateComponent = exports.IgnoreFocus = exports.FillColorPath = undefined;

var _objectWithoutProperties2 = __webpack_require__(26);

var _objectWithoutProperties3 = _interopRequireDefault(_objectWithoutProperties2);

var _defineProperty2 = __webpack_require__(11);

var _defineProperty3 = _interopRequireDefault(_defineProperty2);

var _map2 = __webpack_require__(504);

var _map3 = _interopRequireDefault(_map2);

var _HorizontalAlignMap, _VerticalAlignMap;

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _classnames = __webpack_require__(29);

var _classnames2 = _interopRequireDefault(_classnames);

var _toolbar = __webpack_require__(1714);

var _FormatPainter = __webpack_require__(3145);

var _FormatPainter2 = _interopRequireDefault(_FormatPainter);

var _freezItem = __webpack_require__(3147);

var _colorPicker = __webpack_require__(2056);

var _borderLinePicker = __webpack_require__(3173);

var _sheet = __webpack_require__(713);

var _undo = __webpack_require__(3191);

var _undo2 = _interopRequireDefault(_undo);

var _redo = __webpack_require__(3192);

var _redo2 = _interopRequireDefault(_redo);

var _reset = __webpack_require__(3193);

var _reset2 = _interopRequireDefault(_reset);

var _bold = __webpack_require__(3194);

var _bold2 = _interopRequireDefault(_bold);

var _italic = __webpack_require__(3195);

var _italic2 = _interopRequireDefault(_italic);

var _underline = __webpack_require__(3196);

var _underline2 = _interopRequireDefault(_underline);

var _strikethrough = __webpack_require__(3197);

var _strikethrough2 = _interopRequireDefault(_strikethrough);

var _merge = __webpack_require__(3198);

var _merge2 = _interopRequireDefault(_merge);

var _alignLeft = __webpack_require__(3199);

var _alignLeft2 = _interopRequireDefault(_alignLeft);

var _alignRight = __webpack_require__(3200);

var _alignRight2 = _interopRequireDefault(_alignRight);

var _alignCenter = __webpack_require__(3201);

var _alignCenter2 = _interopRequireDefault(_alignCenter);

var _alignTop = __webpack_require__(3202);

var _alignTop2 = _interopRequireDefault(_alignTop);

var _alignBottom = __webpack_require__(3203);

var _alignBottom2 = _interopRequireDefault(_alignBottom);

var _alignMiddle = __webpack_require__(3204);

var _alignMiddle2 = _interopRequireDefault(_alignMiddle);

var _textWrap = __webpack_require__(3205);

var _textWrap2 = _interopRequireDefault(_textWrap);

var _textOverflow = __webpack_require__(3206);

var _textOverflow2 = _interopRequireDefault(_textOverflow);

var _sortAsc = __webpack_require__(3207);

var _sortAsc2 = _interopRequireDefault(_sortAsc);

var _sortDes = __webpack_require__(3208);

var _sortDes2 = _interopRequireDefault(_sortDes);

var _sum = __webpack_require__(3209);

var _sum2 = _interopRequireDefault(_sum);

var _filter = __webpack_require__(3210);

var _filter2 = _interopRequireDefault(_filter);

var _find = __webpack_require__(3211);

var _find2 = _interopRequireDefault(_find);

var _link = __webpack_require__(3212);

var _link2 = _interopRequireDefault(_link);

var _sheetComment = __webpack_require__(3213);

var _sheetComment2 = _interopRequireDefault(_sheetComment);

var _dropdown = __webpack_require__(3214);

var _dropdown2 = _interopRequireDefault(_dropdown);

var _sheetFold = __webpack_require__(3215);

var _sheetFold2 = _interopRequireDefault(_sheetFold);

var _jpg = __webpack_require__(3216);

var _jpg2 = _interopRequireDefault(_jpg);

var _packup = __webpack_require__(3217);

var _packup2 = _interopRequireDefault(_packup);

var _clip = __webpack_require__(3218);

var _clip2 = _interopRequireDefault(_clip);

var _qaFullscreen = __webpack_require__(2059);

var _qaFullscreen2 = _interopRequireDefault(_qaFullscreen);

var _fullBorder = __webpack_require__(2058);

var _fullBorder2 = _interopRequireDefault(_fullBorder);

var _borderColor = __webpack_require__(3219);

var _borderColor2 = _interopRequireDefault(_borderColor);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var FontColorPath = 'M17.4460925,15.0662932 L15.3862673,15.0662932 L14.5926162,12.8807003 L9.62938375,' + '12.8807003 L8.8357327,15.0662932 L6.77590751,15.0662932 L10.6129065,5.03106502 C10.8503281,' + '4.41011631 11.4462096,4 12.111,4 C12.7757904,4 13.3716719,4.41011631 13.6090935,5.03106502 ' + 'L17.4460925,15.0662932 Z M10.2103641,11.2871541 L14.0116359,11.2871541 ' + 'L12.1524986,6.09152941 L12.0861008,6.09152941 L10.2103641,11.2871541 Z';
var FillColorPath = exports.FillColorPath = 'M9.57128059,2.79740335 L15.9352416,9.16136438 C16.1305038,9.35662653 ' + '16.1305038,9.67320902 15.9352416,9.86847116 L10.2783874,15.5253254 C10.0831252,15.7205876 ' + '9.76654273,15.7205876 9.57128059,15.5253254 L4.62153312,10.5755779 C4.42627097,10.3803158 ' + '4.42627097,10.0637333 4.62153312,9.86847116 L8.86417381,5.62583048 C9.05943595,5.43056833 ' + '9.05943595,5.11398584 8.86417381,4.9187237 L8.15706703,4.21161691 C7.96180488,4.01635477 ' + '7.96180488,3.69977228 8.15706703,3.50451013 L8.86417381,2.79740335 C9.05943595,2.60214121 ' + '9.37601844,2.60214121 9.57128059,2.79740335 Z M10.6319408,6.68649065 L7.09640685,10.2220246 ' + 'L13.4603679,9.51491777 L10.6319408,6.68649065 Z M18.8893001,12.1154228 C19.6703487,12.9242251 ' + '19.6703487,14.2355527 18.8893001,15.044355 C18.1082515,15.8531573 16.8419215,15.8531573 ' + '16.0608729,15.044355 C15.2798244,14.2355527 15.2798244,12.9242251 16.0608729,12.1154228 ' + 'L17.4750865,10.6509567 L18.8893001,12.1154228 Z';
var DISABLED_COLOR = '#cbcfd3';
var ForeColorSvg = function ForeColorSvg(props) {
    var color = props.color;
    var className = props.className,
        disabled = props.disabled;

    if (disabled) {
        color = DISABLED_COLOR;
    }
    return _react2.default.createElement("svg", { className: className, xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 24 24", width: "24", height: "24", fill: "#424E5D" }, _react2.default.createElement("g", { id: "Page-1", stroke: "none", strokeWidth: "1" }, _react2.default.createElement("path", { fillRule: "nonzero", d: FontColorPath })), _react2.default.createElement("rect", { fill: color, width: "16", height: "2", x: "4", y: "17", rx: "1" }));
};
var BackColorSvg = function BackColorSvg(props) {
    var color = props.color;
    var className = props.className,
        disabled = props.disabled;

    if (disabled) {
        color = DISABLED_COLOR;
    }
    return _react2.default.createElement("svg", { className: className, xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 24 24", width: "24", height: "24", fill: "#424E5D" }, _react2.default.createElement("path", { fillRule: "nonzero", d: FillColorPath }), _react2.default.createElement("rect", { fill: color, width: "16", height: "2", x: "4", y: "17", rx: "1" }));
};
var BorderLineSvg = function BorderLineSvg(props) {
    var className = props.className;

    return _react2.default.createElement(_fullBorder2.default, { className: className });
};
var FORMATTERS = {
    normal: {
        name: t('sheet.conventional'),
        teaName: 'general'
    },
    '@': {
        name: t('sheet.plain_text'),
        teaName: 'plain_text'
    },
    divider1: '',
    '#,##0': {
        name: t('sheet.digital'),
        format: '1,024',
        teaName: 'number'
    },
    '#,##0.00': {
        name: t('sheet.digital_point'),
        format: '1,024.56',
        teaName: 'number(rounded)'
    },
    divider2: '',
    '0%': {
        name: t('sheet.percent'),
        format: '10%',
        teaName: 'percentage'
    },
    '0.00%': {
        name: t('sheet.percent_point'),
        format: '10.24%',
        teaName: 'percentage(rounded)'
    },
    '0.00E+00': {
        name: t('sheet.scientific_count'),
        format: '1.02E+03',
        teaName: 'scientific'
    },
    divider3: '',
    '￥#,##0': {
        name: t('sheet.currency'),
        format: '￥1,024',
        teaName: 'currency'
    },
    '￥#,##0.00': {
        name: t('sheet.currency_count'),
        format: '￥1,024.56',
        teaName: 'currency(rounded)'
    },
    divider4: '',
    'yyyy/mm/dd': {
        name: t('sheet.date'),
        format: '2017/08/10',
        teaName: 'date(yyyy/mm/dd)'
    },
    'yyyy-mm-dd': {
        name: t('sheet.date'),
        format: '2017-08-10',
        teaName: 'date(yyyy-mm-dd)'
    },
    'HH:mm:ss': {
        name: t('sheet.time'),
        format: '23:24:25',
        teaName: 'time'
    },
    'yyyy/mm/dd HH:mm:ss': {
        name: t('sheet.data_time'),
        format: '2017/08/10 23:24:25',
        teaName: 'datetime'
    }
};
var FORMATTER_LIST = (0, _map3.default)(FORMATTERS, function (props, key) {
    if (key.indexOf('divider') === 0) {
        return {
            divider: true
        };
    }
    if (props.format) {
        return {
            key: key,
            name: function name() {
                return _react2.default.createElement("div", { className: "formatter-item" }, _react2.default.createElement("span", { className: "formatter-item__name" }, props.name), _react2.default.createElement("span", { className: "formatter-item__format" }, props.format));
            }
        };
    }
    return {
        key: key,
        name: props.name
    };
});
var FONT_SIZE_LIST = [9, 10, 11, 12, 14, 18, 24, 30, 36];
var HorizontalAlignMap = (_HorizontalAlignMap = {}, (0, _defineProperty3.default)(_HorizontalAlignMap, _sheet.HorizontalAlign.Left, {
    icon: _alignLeft2.default,
    name: t('sheet.align_left')
}), (0, _defineProperty3.default)(_HorizontalAlignMap, _sheet.HorizontalAlign.Center, {
    icon: _alignCenter2.default,
    name: t('sheet.align_center')
}), (0, _defineProperty3.default)(_HorizontalAlignMap, _sheet.HorizontalAlign.Right, {
    icon: _alignRight2.default,
    name: t('sheet.align_right')
}), _HorizontalAlignMap);
var VerticalAlignMap = (_VerticalAlignMap = {}, (0, _defineProperty3.default)(_VerticalAlignMap, _sheet.VerticalAlign.Top, {
    icon: _alignTop2.default,
    name: t('sheet.align_top')
}), (0, _defineProperty3.default)(_VerticalAlignMap, _sheet.VerticalAlign.Center, {
    icon: _alignMiddle2.default,
    name: t('sheet.align_vertical_center')
}), (0, _defineProperty3.default)(_VerticalAlignMap, _sheet.VerticalAlign.Bottom, {
    icon: _alignBottom2.default,
    name: t('sheet.align_bottum')
}), _VerticalAlignMap);
var WordWrapMap = [{
    key: _sheet.WORD_WRAP_TYPE.AUTOWRAP.toString(),
    icon: _textWrap2.default,
    name: t('sheet.auto_wrap')
}, {
    key: _sheet.WORD_WRAP_TYPE.OVERFLOW.toString(),
    icon: _textOverflow2.default,
    name: t('sheet.overflow')
}, {
    key: _sheet.WORD_WRAP_TYPE.WORDCLIP.toString(),
    icon: _clip2.default,
    name: t('sheet.word_clip')
}];
var SortMap = {
    asc: {
        icon: _sortAsc2.default,
        name: t('sheet.ascending')
    },
    des: {
        icon: _sortDes2.default,
        name: t('sheet.descending')
    }
};
var FORMULA_LIST = [{
    key: 'SUM',
    name: t('sheet.fn_sum')
}, {
    key: 'AVERAGE',
    name: t('sheet.fn_average')
}, {
    key: 'COUNT',
    name: t('sheet.fn_count')
}, {
    key: 'MAX',
    name: t('sheet.fn_max')
}, {
    key: 'MIN',
    name: t('sheet.fn_min')
}];
var IGNORE_FOCUS_CLASS = 'J-ignore-focus';
var IgnoreFocus = exports.IgnoreFocus = function IgnoreFocus(_ref) {
    var children = _ref.children;

    if (!children) {
        return children;
    }
    return (0, _react.cloneElement)(children, {
        className: (0, _classnames2.default)(children.props.className, IGNORE_FOCUS_CLASS)
    });
};
var StateComponent = function StateComponent(Component) {
    var type = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : '';

    return function (props) {
        var _classNames;

        var active = props.active,
            disabled = props.disabled,
            other = (0, _objectWithoutProperties3.default)(props, ['active', 'disabled']);

        var className = (0, _classnames2.default)('toolbar-item', (_classNames = {}, (0, _defineProperty3.default)(_classNames, 'toolbar-item_' + type, type), (0, _defineProperty3.default)(_classNames, 'toolbar-item_active', active), (0, _defineProperty3.default)(_classNames, 'toolbar-item_disabled', disabled), _classNames));
        return _react2.default.createElement(Component, Object.assign({}, other, { className: className, disabled: disabled }));
    };
};
exports.StateComponent = StateComponent;
var makeSimpleButton = function makeSimpleButton(param) {
    var id = param.id,
        title = param.title,
        isActive = param.isActive,
        svg = param.svg,
        onClick = param.onClick;

    return _react2.default.createElement(_toolbar.ToolbarButton, { id: id, title: title, active: isActive, onClick: onClick, tipTop: isEmbedStyle }, StateComponent(svg, 'svg'));
};
var isEmbedStyle = false;
var setEmbedStyle = exports.setEmbedStyle = function setEmbedStyle(embedStyle) {
    isEmbedStyle = embedStyle;
};
var Undo = exports.Undo = function Undo(onClick) {
    return _react2.default.createElement(_toolbar.ToolbarButton, { id: "sheet-undo", title: t('common.undo'), onClick: onClick, tipTop: isEmbedStyle }, StateComponent(_undo2.default, 'svg'));
};
var Redo = exports.Redo = function Redo(onClick) {
    return _react2.default.createElement(_toolbar.ToolbarButton, { id: "sheet-redo", title: t('common.redo'), onClick: onClick, tipTop: isEmbedStyle }, StateComponent(_redo2.default, 'svg'));
};
var FormatPainterWidget = exports.FormatPainterWidget = function FormatPainterWidget(props, enabled) {
    return _react2.default.createElement(_FormatPainter2.default, { spread: props.spread, disabled: !enabled, active: props.formatPainter.painterFormatting, formatPainter: props.formatPainter, formatPainterToggle: props.formatPainterToggle });
};
var ClearFormat = exports.ClearFormat = function ClearFormat(onClick) {
    return _react2.default.createElement(_toolbar.ToolbarButton, { id: "sheet-do-clear", title: t('sheet.clean_format'), onClick: onClick, tipTop: isEmbedStyle }, StateComponent(_reset2.default, 'svg'));
};
var Divider = exports.Divider = function Divider() {
    return _react2.default.createElement(_toolbar.ToolbarDivider, null);
};
var Formatter = exports.Formatter = function Formatter(value, onVisibleChange, _onClick) {
    return _react2.default.createElement(_toolbar.ToolbarMenuButton, { id: "sheet-formatter", title: t('sheet.format'), onMenuVisibleChange: function onMenuVisibleChange(visible) {
            return onVisibleChange(visible);
        }, tipTop: isEmbedStyle, menu: _react2.default.createElement(_toolbar.ToolbarMenu, { id: "sheet-formatter-menu", selectedKeys: [value], items: FORMATTER_LIST, onClick: function onClick(e) {
                return _onClick(e.key);
            } }) }, StateComponent(function (props) {
        return _react2.default.createElement("span", { className: props.className }, (FORMATTERS[value] || FORMATTERS.normal).name);
    }, 'caption'));
};
var FontSize = exports.FontSize = function FontSize(value, onVisibleChange, _onClick2) {
    return _react2.default.createElement(_toolbar.ToolbarMenuButton, { id: "sheet-font-size", title: t('sheet.font_size'), onMenuVisibleChange: function onMenuVisibleChange(visible) {
            return onVisibleChange(visible);
        }, tipTop: isEmbedStyle, menu: _react2.default.createElement(_toolbar.ToolbarMenu, { id: "sheet-font-size-menu", selectedKeys: [value], items: FONT_SIZE_LIST, onClick: function onClick(e) {
                return _onClick2(e.key);
            } }) }, StateComponent(function (props) {
        return _react2.default.createElement("span", { className: props.className }, value);
    }, 'caption'));
};
var Bold = exports.Bold = function Bold(isBold, onClick) {
    return makeSimpleButton({
        id: 'sheet-bold',
        title: t('common.siderbar.bold'),
        isActive: isBold,
        svg: _bold2.default,
        onClick: onClick
    });
};
var Italic = exports.Italic = function Italic(isItalic, onClick) {
    return makeSimpleButton({
        id: 'sheet-italic',
        title: t('common.italic'),
        isActive: isItalic,
        svg: _italic2.default,
        onClick: onClick
    });
};
var Underline = exports.Underline = function Underline(isUnderline, onClick) {
    return makeSimpleButton({
        id: 'sheet-underline',
        title: t('common.underline'),
        isActive: isUnderline,
        svg: _underline2.default,
        onClick: onClick
    });
};
var Strikethrough = exports.Strikethrough = function Strikethrough(isStrikethrough, onClick) {
    return makeSimpleButton({
        id: 'sheet-line-through',
        title: t('common.strikethrough'),
        isActive: isStrikethrough,
        svg: _strikethrough2.default,
        onClick: onClick
    });
};
var ForeColor = exports.ForeColor = function ForeColor(value, onVisibleChange, _onClick3) {
    return _react2.default.createElement(_toolbar.ToolbarComboButton, { id: "sheet-fore-color", title: t('sheet.font_color'), tipTop: isEmbedStyle, buttonProps: {
            color: value,
            onClick: function onClick() {
                return _onClick3(value, true);
            }
        }, onMenuVisibleChange: function onMenuVisibleChange(visible) {
            return onVisibleChange(visible);
        }, menu: _react2.default.createElement(_colorPicker.ColorPicker, { color: value, onClick: function onClick(picked) {
                return _onClick3(picked && picked.hex, false);
            } }) }, StateComponent(ForeColorSvg, 'svg'));
};
var BackColor = exports.BackColor = function BackColor(value, onVisibleChange, _onClick4) {
    return _react2.default.createElement(_toolbar.ToolbarComboButton, { id: "sheet-back-color", title: t('sheet.back_color'), tipTop: isEmbedStyle, buttonProps: {
            color: value,
            onClick: function onClick() {
                return _onClick4(value, true);
            }
        }, onMenuVisibleChange: function onMenuVisibleChange(visible) {
            return onVisibleChange(visible);
        }, menu: _react2.default.createElement(_colorPicker.ColorPicker, { color: value, onClick: function onClick(picked) {
                return _onClick4(picked && picked.hex, false);
            } }) }, StateComponent(BackColorSvg, 'svg'));
};
var BorderLine = exports.BorderLine = function BorderLine(value, onVisibleChange, _onClick5) {
    return _react2.default.createElement(_toolbar.ToolbarComboButton, { id: "sheet-border-line", title: t('sheet.border_line'), buttonProps: {
            borderLine: value,
            onClick: function onClick() {
                return _onClick5(value, true);
            },
            tipTop: isEmbedStyle
        }, onMenuVisibleChange: function onMenuVisibleChange(visible) {
            return onVisibleChange(visible);
        }, menu: _react2.default.createElement(_borderLinePicker.BorderLinePicker, { onClick: function onClick(picked) {
                _onClick5(picked, false);
            } }) }, StateComponent(BorderLineSvg, 'svg'));
};
var BorderColor = exports.BorderColor = function BorderColor(value) {
    var isHidden = true;
    return _react2.default.createElement(_toolbar.ToolbarComplexComboButton, { id: "sheet-border-color", title: t('sheet.border_color'), tipHidden: isHidden, buttonProps: {
            color: value
        }, menu: null }, _react2.default.createElement(_borderColor2.default, { fill: value }));
};
var SplitMerge = exports.SplitMerge = function SplitMerge(isSplitable, isMergable, onClick) {
    return _react2.default.createElement(_toolbar.ToolbarButton, { id: "sheet-merge", title: isSplitable ? t('common.split_cells') : t('common.merge_cells'), active: isSplitable, disabled: !isSplitable && !isMergable, onClick: onClick, tipTop: isEmbedStyle }, StateComponent(_merge2.default, 'svg'));
};
var HAlign = exports.HAlign = function HAlign(value, onVisibleChange, _onClick6) {
    return _react2.default.createElement(_toolbar.ToolbarMenuButton, { id: "sheet-hAlign", title: t('sheet.horizontal_alignment'), onMenuVisibleChange: function onMenuVisibleChange(visible) {
            return onVisibleChange(visible);
        }, tipTop: isEmbedStyle, menu: _react2.default.createElement(_toolbar.ToolbarMenu, { id: "sheet-hAlign-menu", selectedKeys: [value], items: HorizontalAlignMap, onClick: function onClick(e) {
                return _onClick6(parseInt(e.key, 10));
            } }) }, StateComponent(HorizontalAlignMap[value].icon, 'svg'));
};
var VAlign = exports.VAlign = function VAlign(value, onVisibleChange, _onClick7) {
    return _react2.default.createElement(_toolbar.ToolbarMenuButton, { id: "sheet-vAlign", title: t('sheet.vertical_alignment'), onMenuVisibleChange: function onMenuVisibleChange(visible) {
            return onVisibleChange(visible);
        }, tipTop: isEmbedStyle, menu: _react2.default.createElement(_toolbar.ToolbarMenu, { id: "sheet-vAlign-menu", selectedKeys: [value], items: VerticalAlignMap, onClick: function onClick(e) {
                return _onClick7(parseInt(e.key, 10));
            } }) }, StateComponent(VerticalAlignMap[value].icon, 'svg'));
};
var WordWrap = exports.WordWrap = function WordWrap(value, onVisibleChange, _onClick8) {
    // icon 默认是溢出的icon
    var icon = WordWrapMap[1].icon;
    var _iteratorNormalCompletion = true;
    var _didIteratorError = false;
    var _iteratorError = undefined;

    try {
        for (var _iterator = WordWrapMap[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {
            var item = _step.value;

            if (value === item.key) {
                icon = item.icon;
            }
        }
    } catch (err) {
        _didIteratorError = true;
        _iteratorError = err;
    } finally {
        try {
            if (!_iteratorNormalCompletion && _iterator.return) {
                _iterator.return();
            }
        } finally {
            if (_didIteratorError) {
                throw _iteratorError;
            }
        }
    }

    return _react2.default.createElement(_toolbar.ToolbarMenuButton, { id: "sheet-word-wrap", title: t('sheet.text_wrap'), onMenuVisibleChange: function onMenuVisibleChange(visible) {
            return onVisibleChange(visible);
        }, tipTop: isEmbedStyle, menu: _react2.default.createElement(_toolbar.ToolbarMenu, { id: "sheet-word-wrap-menu", selectedKeys: [value], items: WordWrapMap, onClick: function onClick(e) {
                _onClick8(e.key);
            } }) }, StateComponent(icon, 'svg'));
};
var Sort = exports.Sort = function Sort(sortable, onVisibleChange, _onClick9) {
    return _react2.default.createElement(_toolbar.ToolbarMenuButton, { id: "sheet-sort", title: t('sheet.sorting'), disabled: !sortable, onMenuVisibleChange: function onMenuVisibleChange(visible) {
            return onVisibleChange(visible);
        }, tipTop: isEmbedStyle, menu: _react2.default.createElement(_toolbar.ToolbarMenu, { id: "sheet-sort-menu", selectable: false, items: SortMap, onClick: function onClick(e) {
                return _onClick9(e.key);
            } }) }, StateComponent(_sortAsc2.default, 'svg'));
};
var Freeze = exports.Freeze = function Freeze(spread) {
    return _react2.default.createElement(_freezItem.FreezeItem, { spread: spread });
};
var Formula = exports.Formula = function Formula(onVisibleChange, _onClick10) {
    return _react2.default.createElement(_toolbar.ToolbarComboButton, { id: "sheet-formula", title: t('sheet.function'), onMenuVisibleChange: function onMenuVisibleChange(visible) {
            return onVisibleChange(visible);
        }, buttonProps: {
            onClick: function onClick(e) {
                return _onClick10('SUM', true);
            },
            tipTop: isEmbedStyle
        }, menu: _react2.default.createElement(_toolbar.ToolbarMenu, { id: "sheet-formula-menu", selectable: false, items: FORMULA_LIST, onClick: function onClick(e) {
                return _onClick10(e.key, false);
            } }) }, StateComponent(_sum2.default, 'svg'));
};
var Link = exports.Link = function Link(isActive, _onClick11, enabled) {
    return _react2.default.createElement(_toolbar.ToolbarButton, { id: "sheet-link", title: t('common.link'), active: isActive, onClick: function onClick(e) {
            return _onClick11(e);
        }, disabled: !enabled, tipTop: isEmbedStyle }, StateComponent(_link2.default, 'svg'));
};
var Img = exports.Img = function Img(onClick) {
    return _react2.default.createElement(_toolbar.ToolbarButton, { id: "sheet-img", title: t('sheet.insert_inline_image'), onClick: onClick, tipTop: isEmbedStyle }, StateComponent(_jpg2.default, 'svg'));
};
var FindAndReplace = exports.FindAndReplace = function FindAndReplace(isVisible, onClick, showShortcutKey) {
    return _react2.default.createElement(_toolbar.ToolbarButton, { id: "sheet-find", title: t('sheet.find_replace'), active: isVisible, tipHidden: isVisible, onClick: onClick, specialDisabled: false, showShortcutKey: showShortcutKey, tipTop: isEmbedStyle }, StateComponent(_find2.default, 'svg'));
};
var Dropdown = exports.Dropdown = function Dropdown(isActive, onClick) {
    return _react2.default.createElement(_toolbar.ToolbarButton, { id: "sheet-dropdown", title: t('sheet.dropdown'), active: isActive, onClick: onClick, tipTop: isEmbedStyle }, StateComponent(_dropdown2.default, 'svg'));
};
var Filter = exports.Filter = function Filter(isFiltered, onClick) {
    return makeSimpleButton({
        id: 'sheet-filter',
        title: t('sheet.filter'),
        isActive: isFiltered,
        svg: _filter2.default,
        onClick: onClick
    });
};
var Comment = exports.Comment = function Comment(onClick, enabled) {
    return _react2.default.createElement(_toolbar.ToolbarButton, { id: "sheet-comment", title: '' + t('sheet.add_comment'), onClick: onClick, disabled: !enabled, specialDisabled: !enabled, tipTop: isEmbedStyle }, StateComponent(_sheetComment2.default, 'svg'));
};
var FoldTrigger = exports.FoldTrigger = function FoldTrigger(onClick) {
    return _react2.default.createElement(_toolbar.ToolbarButton, { id: "sheet-fold", title: '' + t('sheet.toolbar_more'), onClick: onClick, tipTop: isEmbedStyle }, StateComponent(_sheetFold2.default, 'svg'));
};
var Pickup = exports.Pickup = function Pickup(onClick, isPickUp) {
    var toolTipProps = {
        placement: 'bottomRight',
        animate: false,
        showDelay: 0,
        arrowAtCenter: true
    };
    // 默认是false, 默认要收起
    var hint = isPickUp ? t('sheet.toolbar_expand') : t('sheet.toolbar_packup');
    return _react2.default.createElement(_toolbar.ToolbarButton, { id: "sheet-pickup", title: '' + hint, onClick: onClick, specialDisabled: false, customToolTipProp: toolTipProps, tipTop: isEmbedStyle }, StateComponent(_packup2.default, 'svg'));
};
var FullScreen = exports.FullScreen = function FullScreen(onClick) {
    return _react2.default.createElement(_toolbar.ToolbarButton, { id: "sheet-fullscreen", title: t('sheet.fullscreen'), onClick: onClick, tipTop: isEmbedStyle }, StateComponent(_qaFullscreen2.default, 'svg'));
};
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 1679:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.ToolbarButton = undefined;

var _defineProperty2 = __webpack_require__(11);

var _defineProperty3 = _interopRequireDefault(_defineProperty2);

var _objectWithoutProperties2 = __webpack_require__(26);

var _objectWithoutProperties3 = _interopRequireDefault(_objectWithoutProperties2);

var _isFunction2 = __webpack_require__(100);

var _isFunction3 = _interopRequireDefault(_isFunction2);

var _reduce3 = __webpack_require__(160);

var _reduce4 = _interopRequireDefault(_reduce3);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _classnames2 = __webpack_require__(29);

var _classnames3 = _interopRequireDefault(_classnames2);

var _spark = __webpack_require__(1680);

var _string = __webpack_require__(158);

__webpack_require__(3129);

__webpack_require__(3130);

var _hotkeyHelper = __webpack_require__(1793);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var ToolbarButton = function ToolbarButton(props) {
    var _classnames;

    var id = props.id,
        className = props.className,
        blockClass = props.blockClass,
        children = props.children,
        title = props.title,
        specialDisabled = props.specialDisabled,
        _props$showShortcutKe = props.showShortcutKey,
        showShortcutKey = _props$showShortcutKe === undefined ? true : _props$showShortcutKe,
        tipHidden = props.tipHidden,
        tipTop = props.tipTop,
        customToolTipProp = props.customToolTipProp,
        other = (0, _objectWithoutProperties3.default)(props, ['id', 'className', 'blockClass', 'children', 'title', 'specialDisabled', 'showShortcutKey', 'tipHidden', 'tipTop', 'customToolTipProp']);

    if (specialDisabled !== undefined) {
        other.disabled = specialDisabled;
    }
    var disabled = other.disabled;

    var classString = (0, _classnames3.default)(className, blockClass, (_classnames = {}, (0, _defineProperty3.default)(_classnames, blockClass + '_active', other.active), (0, _defineProperty3.default)(_classnames, blockClass + '_disabled', disabled), _classnames));

    var _reduce2 = (0, _reduce4.default)(other, function (res, val, key) {
        if (/^on[A-Z]/.test(key)) {
            res.events[key] = val;
        } else {
            res.childProps[key] = val;
        }
        return res;
    }, { events: {}, childProps: {} }),
        events = _reduce2.events,
        childProps = _reduce2.childProps;

    var button = _react2.default.createElement("div", Object.assign({ id: id, className: classString }, disabled ? {} : events), (0, _isFunction3.default)(children) ? children(childProps) : children);
    if (!title) return button;
    var tooltipProps = {};
    if (tipHidden) {
        tooltipProps.visible = false;
    }
    var tooltipTitle = title;
    if (id) {
        var commandName = (0, _string.camelCase)(id.replace(/^sheet-/, ''));
        var shortcutKey = (0, _hotkeyHelper.getDisplayShortcutKey)(commandName);
        if (showShortcutKey && shortcutKey) {
            tooltipTitle = title + '\uFF08' + shortcutKey + '\uFF09';
        }
    }
    var placement = tipTop ? 'top' : 'bottom';
    return _react2.default.createElement(_spark.Tooltip, Object.assign({ placement: placement, title: tooltipTitle, hideActions: disabled ? ['onMouseLeave'] : ['onClick', 'onMouseLeave'] }, tooltipProps, customToolTipProp), button);
};
ToolbarButton.defaultProps = {
    blockClass: 'toolbar-button'
};
exports.ToolbarButton = ToolbarButton;

/***/ }),

/***/ 1714:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.ToolbarComplexComboButton = exports.ToolbarDivider = exports.ToolbarComboButton = exports.ToolbarMenu = exports.ToolbarMenuButton = exports.ToolbarButton = exports.Toolbar = undefined;

var _Toolbar = __webpack_require__(3127);

var _ToolbarButton = __webpack_require__(1679);

var _ToolbarMenuButton = __webpack_require__(2051);

var _ToolbarMenu = __webpack_require__(3135);

var _ToolbarComboButton = __webpack_require__(3141);

var _ToolbarDivider = __webpack_require__(3142);

var _ToolbarComplexComboButton = __webpack_require__(3144);

exports.Toolbar = _Toolbar.Toolbar;
exports.ToolbarButton = _ToolbarButton.ToolbarButton;
exports.ToolbarMenuButton = _ToolbarMenuButton.ToolbarMenuButton;
exports.ToolbarMenu = _ToolbarMenu.ToolbarMenu;
exports.ToolbarComboButton = _ToolbarComboButton.ToolbarComboButton;
exports.ToolbarDivider = _ToolbarDivider.ToolbarDivider;
exports.ToolbarComplexComboButton = _ToolbarComplexComboButton.ToolbarComplexComboButton;

/***/ }),

/***/ 1817:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 1818:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _defineProperty2 = __webpack_require__(11);

var _defineProperty3 = _interopRequireDefault(_defineProperty2);

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var React = _interopRequireWildcard(_react);

var _rcTooltip = __webpack_require__(3250);

var _rcTooltip2 = _interopRequireDefault(_rcTooltip);

var _classnames = __webpack_require__(29);

var _classnames2 = _interopRequireDefault(_classnames);

var _placements = __webpack_require__(3111);

var _placements2 = _interopRequireDefault(_placements);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj['default'] = obj; return newObj; } }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

var splitObject = function splitObject(obj, keys) {
    var picked = {};
    var omitted = (0, _extends3['default'])({}, obj);
    keys.forEach(function (key) {
        if (obj && key in obj) {
            picked[key] = obj[key];
            delete omitted[key];
        }
    });
    return { picked: picked, omitted: omitted };
};

var Tooltip = function (_React$Component) {
    (0, _inherits3['default'])(Tooltip, _React$Component);

    function Tooltip(props) {
        (0, _classCallCheck3['default'])(this, Tooltip);

        var _this = (0, _possibleConstructorReturn3['default'])(this, (Tooltip.__proto__ || Object.getPrototypeOf(Tooltip)).call(this, props));

        _this.onVisibleChange = function (visible) {
            var onVisibleChange = _this.props.onVisibleChange;

            if (!('visible' in _this.props)) {
                _this.setState({ visible: _this.isNoTitle() ? false : visible });
            }
            if (onVisibleChange && !_this.isNoTitle()) {
                onVisibleChange(visible);
            }
        };
        // 动态设置动画点
        _this.onPopupAlign = function (domNode, align) {
            var placements = _this.getPlacements();
            // 当前返回的位置
            var placement = Object.keys(placements).filter(function (key) {
                return placements[key].points[0] === align.points[0] && placements[key].points[1] === align.points[1];
            })[0];
            if (!placement) {
                return;
            }
            // 根据当前坐标设置动画点
            var rect = domNode.getBoundingClientRect();
            var transformOrigin = {
                top: '50%',
                left: '50%'
            };
            if (placement.indexOf('top') >= 0 || placement.indexOf('Bottom') >= 0) {
                transformOrigin.top = rect.height - align.offset[1] + 'px';
            } else if (placement.indexOf('Top') >= 0 || placement.indexOf('bottom') >= 0) {
                transformOrigin.top = -align.offset[1] + 'px';
            }
            if (placement.indexOf('left') >= 0 || placement.indexOf('Right') >= 0) {
                transformOrigin.left = rect.width - align.offset[0] + 'px';
            } else if (placement.indexOf('right') >= 0 || placement.indexOf('Left') >= 0) {
                transformOrigin.left = -align.offset[0] + 'px';
            }
            domNode.style.transformOrigin = transformOrigin.left + ' ' + transformOrigin.top;
        };
        _this.saveTooltip = function (node) {
            _this.tooltip = node;
        };
        _this.state = {
            visible: !!props.visible || !!props.defaultVisible
        };
        return _this;
    }

    (0, _createClass3['default'])(Tooltip, [{
        key: 'componentWillReceiveProps',
        value: function componentWillReceiveProps(nextProps) {
            if ('visible' in nextProps) {
                this.setState({ visible: nextProps.visible });
            }
        }
    }, {
        key: 'getPopupDomNode',
        value: function getPopupDomNode() {
            return this.tooltip.getPopupDomNode();
        }
    }, {
        key: 'getPlacements',
        value: function getPlacements() {
            var _props = this.props,
                builtinPlacements = _props.builtinPlacements,
                arrowPointAtCenter = _props.arrowPointAtCenter,
                autoAdjustOverflow = _props.autoAdjustOverflow;

            return builtinPlacements || (0, _placements2['default'])({
                arrowPointAtCenter: arrowPointAtCenter,
                verticalArrowShift: 8,
                autoAdjustOverflow: autoAdjustOverflow
            });
        }
    }, {
        key: 'isHoverTrigger',
        value: function isHoverTrigger() {
            var trigger = this.props.trigger;

            if (!trigger || trigger === 'hover') {
                return true;
            }
            if (Array.isArray(trigger)) {
                return trigger.indexOf('hover') >= 0;
            }
            return false;
        }
        // Fix Tooltip won't hide at disabled button
        // mouse events don't trigger at disabled button in Chrome
        // https://github.com/react-component/tooltip/issues/18

    }, {
        key: 'getDisabledCompatibleChildren',
        value: function getDisabledCompatibleChildren(element) {
            if ((element.type.__ANT_BUTTON || element.type === 'button') && element.props.disabled && this.isHoverTrigger()) {
                // Pick some layout related style properties up to span
                // Prevent layout bugs like https://github.com/ant-design/ant-design/issues/5254
                var _splitObject = splitObject(element.props.style, ['position', 'left', 'right', 'top', 'bottom', 'float', 'display', 'zIndex']),
                    picked = _splitObject.picked,
                    omitted = _splitObject.omitted;

                var spanStyle = (0, _extends3['default'])({ display: 'inline-block' }, picked, { cursor: 'not-allowed' });
                var buttonStyle = (0, _extends3['default'])({}, omitted, { pointerEvents: 'none' });
                var child = (0, _react.cloneElement)(element, {
                    style: buttonStyle,
                    className: null
                });
                return React.createElement(
                    'span',
                    { style: spanStyle, className: element.props.className },
                    child
                );
            }
            return element;
        }
    }, {
        key: 'isNoTitle',
        value: function isNoTitle() {
            var _props2 = this.props,
                title = _props2.title,
                overlay = _props2.overlay;

            return !title && !overlay; // overlay for old version compatibility
        }
    }, {
        key: 'render',
        value: function render() {
            var props = this.props,
                state = this.state;
            var prefixCls = props.prefixCls,
                title = props.title,
                overlay = props.overlay,
                openClassName = props.openClassName,
                getPopupContainer = props.getPopupContainer,
                getTooltipContainer = props.getTooltipContainer;

            var children = props.children;
            var visible = state.visible;
            // Hide tooltip when there is no title
            if (!('visible' in props) && this.isNoTitle()) {
                visible = false;
            }
            var child = this.getDisabledCompatibleChildren(React.isValidElement(children) ? children : React.createElement(
                'span',
                null,
                children
            ));
            var childProps = child.props;
            var childCls = (0, _classnames2['default'])(childProps.className, (0, _defineProperty3['default'])({}, openClassName || prefixCls + '-open', true));
            return React.createElement(
                _rcTooltip2['default'],
                (0, _extends3['default'])({}, this.props, { getTooltipContainer: getPopupContainer || getTooltipContainer, ref: this.saveTooltip, builtinPlacements: this.getPlacements(), overlay: overlay || title || '', visible: visible, onVisibleChange: this.onVisibleChange, onPopupAlign: this.onPopupAlign }),
                visible ? (0, _react.cloneElement)(child, { className: childCls }) : child
            );
        }
    }]);
    return Tooltip;
}(React.Component);

exports['default'] = Tooltip;

Tooltip.defaultProps = {
    prefixCls: 'ant-tooltip',
    placement: 'top',
    transitionName: 'zoom-big-fast',
    mouseEnterDelay: 0.1,
    mouseLeaveDelay: 0.1,
    arrowPointAtCenter: false,
    autoAdjustOverflow: true
};
module.exports = exports['default'];

/***/ }),

/***/ 1819:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _warning = __webpack_require__(20);

var _warning2 = _interopRequireDefault(_warning);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

var warned = {};

exports['default'] = function (valid, message) {
    if (!valid && !warned[message]) {
        (0, _warning2['default'])(false, message);
        warned[message] = true;
    }
};

module.exports = exports['default'];

/***/ }),

/***/ 1820:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.SheetStatusCollector = undefined;

var _SheetStatusCollector = __webpack_require__(3222);

var _SheetStatusCollector2 = _interopRequireDefault(_SheetStatusCollector);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.SheetStatusCollector = _SheetStatusCollector2.default;

/***/ }),

/***/ 2046:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.SheetPlaceholder = undefined;

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _classnames = __webpack_require__(29);

var _classnames2 = _interopRequireDefault(_classnames);

__webpack_require__(3065);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var SheetPlaceholder = exports.SheetPlaceholder = function SheetPlaceholder(props) {
    var style = Object.assign({}, props.style);
    var rowCount = props.rowCount,
        colCount = props.colCount,
        rowHeight = props.rowHeight,
        colWidth = props.colWidth;

    if (rowHeight && colWidth) {
        style.backgroundSize = colWidth + 'px ' + rowHeight + 'px';
        if (rowCount && colCount) {
            style.height = rowCount * rowHeight + 1;
            style.width = colCount * colWidth + 1;
        }
    }
    var className = (0, _classnames2.default)(props.className, 'sheet-place-holder', {
        'sheet-place-holder_inline': rowCount && colCount
    });
    return _react2.default.createElement("div", { className: className, style: style });
};
SheetPlaceholder.defaultProps = {
    colWidth: 102,
    rowHeight: 22
};

/***/ }),

/***/ 2047:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.MentionNotificationQueue = undefined;

var _toConsumableArray2 = __webpack_require__(135);

var _toConsumableArray3 = _interopRequireDefault(_toConsumableArray2);

var _regenerator = __webpack_require__(13);

var _regenerator2 = _interopRequireDefault(_regenerator);

var _asyncToGenerator2 = __webpack_require__(99);

var _asyncToGenerator3 = _interopRequireDefault(_asyncToGenerator2);

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _defineProperty2 = __webpack_require__(11);

var _defineProperty3 = _interopRequireDefault(_defineProperty2);

var _notifiers;

var _const = __webpack_require__(1581);

var _security = __webpack_require__(1616);

var _apis = __webpack_require__(1631);

var _utils = __webpack_require__(1590);

var _bytedXEditor = __webpack_require__(1569);

var _$store = __webpack_require__(83);

var _$store2 = _interopRequireDefault(_$store);

var _uniq = __webpack_require__(1665);

var _uniq2 = _interopRequireDefault(_uniq);

var _sharingConfirmationHelper = __webpack_require__(3077);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var notifiers = (_notifiers = {}, (0, _defineProperty3.default)(_notifiers, _const.TYPE_ENUM.USER, _apis.notifyAdd), (0, _defineProperty3.default)(_notifiers, _const.TYPE_ENUM.GROUP, _apis.notifyGroup), _notifiers);
function sleep(milliseconds) {
    return new Promise(function (resolve) {
        return window.setTimeout(resolve, milliseconds);
    });
}
/**
 * https://docs.bytedance.net/doc/zfi4FrZTeq1oxZtv6xzibe#NF5TsZ
 *
 * 这个 Queue 的主要功能是，等 toast 出结果（等 8 秒确认/点击撤销）后再发通知
 *
 * 使用思路是
 * 1. 在弹 toast 的时候使用 `.register` 方法注册 toast 的 `Promise`
 * 2. 发评论时，通过 `.addUserMention`、`.addGroupMention` 方法添加 mention 通知
 * 3. 调用 `.sendMentionNotifications()` 方法发通知，它会先等注册的 `Promise` resolve 后才真正发通知
 */

var MentionNotificationQueue = exports.MentionNotificationQueue = function () {
    function MentionNotificationQueue() {
        (0, _classCallCheck3.default)(this, MentionNotificationQueue);

        this.queue = [];
        this.decisionSet = new Set();
    }

    (0, _createClass3.default)(MentionNotificationQueue, [{
        key: 'getShareInfo',
        value: function getShareInfo() {
            return (0, _sharingConfirmationHelper.getCurrentShareInfo)(_$store2.default.getState());
        }
        /**
         * 返回重新组装的 html，并将收集到的 @ 列表加入通知队列
         */

    }, {
        key: 'calTextAndCollectMentionFromRep',
        value: function calTextAndCollectMentionFromRep(rep) {
            var param = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
            var alines = rep.alines,
                alltext = rep.alltext,
                apool = rep.apool;

            var source = param.source || _const.SOURCE_ENUM.DOC_COMMENT;
            var iterator = _bytedXEditor.Changeset.opIterator(alines.join(''));
            var html = '';
            var curIndex = 0;
            var list = [];
            // 对每个 op
            while (iterator.hasNext()) {
                var op = iterator.next();
                var chars = op.chars,
                    attribs = op.attribs;
                // 提取 mention 相关属性

                var attriArr = attribs.split('*');
                var mentionInfo = (0, _utils.getMentionInfoFromAttribs)(attriArr, apool);
                var token = mentionInfo['mention-token'],
                    href = mentionInfo['mention-link'],
                    shouldNotifyLark = mentionInfo['mention-notify'],
                    sharePermHeldBack = mentionInfo['mention-sharePermHeldBack'];

                var text = alltext.slice(curIndex, curIndex + chars);
                // 如果有 mention-token
                if (token) {
                    // 则把 mention 相关的属性塞进 list。html 拼上特殊的 <at>
                    var type = Number.parseInt(mentionInfo['mention-type']);
                    var link = decodeURIComponent(href);
                    if (type === _const.TYPE_ENUM.USER || type === _const.TYPE_ENUM.GROUP) {
                        link = '';
                        var targetName = text.startsWith('@') ? text.slice(1) : text;
                        list.push({ name: targetName, token: token, type: type, shouldNotifyLark: shouldNotifyLark, sharePermHeldBack: sharePermHeldBack });
                    }
                    html += '<at type="' + type + '" href="' + link + '" token="' + token + '">' + (0, _security.escapeHTML)(text) + '</at>';
                } else {
                    // 否则 html 直接拼上 text
                    html += (0, _security.escapeHTML)(text || '');
                }
                curIndex += chars;
            }
            // 这里的 toUsers、toGroup 都是 shouldNotifyLark 的 target 的 token

            var _getTokens = this.getTokens(list),
                toUsers = _getTokens.toUsers,
                toGroup = _getTokens.toGroup;
            // 现在 docs 评论里 @人 发的通知会被服务端无视，为避免引起误会，就不发通知了
            // sheet 评论 @人 仍需要发通知


            if (source !== _const.SOURCE_ENUM.DOC_COMMENT) {
                this.addUserMention(toUsers, source);
            }
            this.addGroupMention(toGroup, source, alltext.slice(0, alltext.length - 1));
            return html;
        }
        /**
         * 注册一个用户的 confirmation，使得要等待这个 confirmation 出结果后（是 CONFIRMED 还是 CANCELED）才能真正发送通知
         *
         * 该方法并不负责添加通知，只是注册 confirmation
         *
         * @param `timeout` 是 confirmation 的超时时间，超过这个时间后，发通知就不等待这个 confirmation 了
         */

    }, {
        key: 'register',
        value: function register(targetToken, confirmation, timeout) {
            var _this = this;

            var decision = this.createDecision(targetToken, confirmation, timeout);
            this.decisionSet.add(decision);
            decision.finally(function () {
                return _this.decisionSet.delete(decision);
            });
        }
    }, {
        key: 'createDecision',
        value: function () {
            var _ref = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee(targetToken, confirmation, timeout) {
                var result;
                return _regenerator2.default.wrap(function _callee$(_context) {
                    while (1) {
                        switch (_context.prev = _context.next) {
                            case 0:
                                _context.next = 2;
                                return Promise.race([confirmation, sleep(timeout)]);

                            case 2:
                                result = _context.sent;

                                if (result === _sharingConfirmationHelper.TOAST_CONFIRM_RESULT.CANCELED) {
                                    this.removeTargetToNotify(targetToken);
                                }

                            case 4:
                            case 'end':
                                return _context.stop();
                        }
                    }
                }, _callee, this);
            }));

            function createDecision(_x2, _x3, _x4) {
                return _ref.apply(this, arguments);
            }

            return createDecision;
        }()
    }, {
        key: 'addUserMention',
        value: function addUserMention(toUsers, source) {
            if (toUsers.length === 0) {
                return;
            }
            var shareInfo = this.getShareInfo();
            this.queue.push({
                type: _const.TYPE_ENUM.USER,
                config: {
                    to_user: (0, _uniq2.default)(toUsers),
                    note_token: shareInfo.fileToken,
                    source: source,
                    target: _const.TARGET_ENUM.LARK,
                    from_user: shareInfo.userId
                }
            });
        }
    }, {
        key: 'addGroupMention',
        value: function addGroupMention(toGroup, source, text) {
            if (toGroup.length === 0) {
                return;
            }
            var shareInfo = this.getShareInfo();
            this.queue.push({
                type: _const.TYPE_ENUM.GROUP,
                config: {
                    entities: {
                        group_chats: (0, _uniq2.default)(toGroup).map(function (id) {
                            return { id: id, text: text };
                        })
                    },
                    source: source,
                    target: _const.TARGET_ENUM.LARK,
                    token: shareInfo.fileToken
                }
            });
        }
        /**
         * 等注册的 confirmation 出结果再发通知
         */

    }, {
        key: 'sendMentionNotifications',
        value: function () {
            var _ref2 = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee2() {
                var decisions, queue;
                return _regenerator2.default.wrap(function _callee2$(_context2) {
                    while (1) {
                        switch (_context2.prev = _context2.next) {
                            case 0:
                                // 等待用户决定完（等8秒或点击撤销）
                                decisions = [].concat((0, _toConsumableArray3.default)(this.decisionSet));

                                this.decisionSet.clear();
                                _context2.next = 4;
                                return Promise.all(decisions);

                            case 4:
                                // 不需要通知自己
                                this.removeTargetToNotify(this.getShareInfo().userId);
                                queue = [].concat((0, _toConsumableArray3.default)(this.queue));

                                this.queue = [];
                                return _context2.abrupt('return', Promise.all(queue.map(function (_ref3) {
                                    var type = _ref3.type,
                                        config = _ref3.config;
                                    return notifiers[type](config);
                                })));

                            case 8:
                            case 'end':
                                return _context2.stop();
                        }
                    }
                }, _callee2, this);
            }));

            function sendMentionNotifications() {
                return _ref2.apply(this, arguments);
            }

            return sendMentionNotifications;
        }()
        /**
         * 不给指定的人发消息
         */

    }, {
        key: 'removeTargetToNotify',
        value: function removeTargetToNotify(tokenToRm) {
            this.queue = this.queue.reduce(function (newQueue, _ref4) {
                var type = _ref4.type,
                    oldConfig = _ref4.config;

                if (type === _const.TYPE_ENUM.USER) {
                    var config = Object.assign({}, oldConfig);
                    // 去掉 to_user 中需要删除的 tokens
                    config.to_user = config.to_user.filter(function (token) {
                        return token !== tokenToRm;
                    });
                    // 还有 to_user 才留下当前的 notification
                    if (config.to_user.length > 0) {
                        newQueue.push({ type: type, config: config });
                    }
                } else if (type === _const.TYPE_ENUM.GROUP) {
                    var _config = Object.assign({}, oldConfig);
                    // 去掉 group_chats 中需要删除的 tokens
                    var groupChats = _config.entities.group_chats.filter(function (_ref5) {
                        var id = _ref5.id;
                        return tokenToRm !== id;
                    });
                    // 还有 group_chats 才留下当前的 notification
                    if (groupChats.length > 0) {
                        _config.entities = Object.assign({}, _config.entities, { group_chats: groupChats });
                        newQueue.push({ type: type, config: _config });
                    }
                } else {
                    /* istanbul ignore next: 正常情况下不应该出现未知的 type */
                    newQueue.push({ type: type, config: oldConfig });
                }
                return newQueue;
            }, []);
        }
        /**
         * 将 list 中的 token 分类出 toUsers 和 toGroup
         */

    }, {
        key: 'getTokens',
        value: function getTokens(list) {
            var toUsers = [];
            var toGroup = [];
            list.forEach(function (item) {
                // 如果没有勾选「同时通知 Lark」，或者点了撤销
                if (item.shouldNotifyLark !== 'true' || item.sharePermHeldBack === 'true') return;
                if (item.type === _const.TYPE_ENUM.USER) {
                    toUsers.push(item.token);
                } else {
                    toGroup.push(item.token);
                }
            });
            return { toUsers: toUsers, toGroup: toGroup };
        }
    }]);
    return MentionNotificationQueue;
}();

exports.default = new MentionNotificationQueue();

/***/ }),

/***/ 2048:
/***/ (function(module, exports, __webpack_require__) {

(function webpackUniversalModuleDefinition(root, factory) {
	if(true)
		module.exports = factory(__webpack_require__(21), __webpack_require__(1));
	else {}
})(this, function(__WEBPACK_EXTERNAL_MODULE_4__, __WEBPACK_EXTERNAL_MODULE_6__) {
return /******/ (function(modules) { // webpackBootstrap
/******/ 	// The module cache
/******/ 	var installedModules = {};
/******/
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/
/******/ 		// Check if module is in cache
/******/ 		if(installedModules[moduleId]) {
/******/ 			return installedModules[moduleId].exports;
/******/ 		}
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = installedModules[moduleId] = {
/******/ 			i: moduleId,
/******/ 			l: false,
/******/ 			exports: {}
/******/ 		};
/******/
/******/ 		// Execute the module function
/******/ 		modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);
/******/
/******/ 		// Flag the module as loaded
/******/ 		module.l = true;
/******/
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/
/******/
/******/ 	// expose the modules object (__webpack_modules__)
/******/ 	__webpack_require__.m = modules;
/******/
/******/ 	// expose the module cache
/******/ 	__webpack_require__.c = installedModules;
/******/
/******/ 	// define getter function for harmony exports
/******/ 	__webpack_require__.d = function(exports, name, getter) {
/******/ 		if(!__webpack_require__.o(exports, name)) {
/******/ 			Object.defineProperty(exports, name, {
/******/ 				configurable: false,
/******/ 				enumerable: true,
/******/ 				get: getter
/******/ 			});
/******/ 		}
/******/ 	};
/******/
/******/ 	// getDefaultExport function for compatibility with non-harmony modules
/******/ 	__webpack_require__.n = function(module) {
/******/ 		var getter = module && module.__esModule ?
/******/ 			function getDefault() { return module['default']; } :
/******/ 			function getModuleExports() { return module; };
/******/ 		__webpack_require__.d(getter, 'a', getter);
/******/ 		return getter;
/******/ 	};
/******/
/******/ 	// Object.prototype.hasOwnProperty.call
/******/ 	__webpack_require__.o = function(object, property) { return Object.prototype.hasOwnProperty.call(object, property); };
/******/
/******/ 	// __webpack_public_path__
/******/ 	__webpack_require__.p = "";
/******/
/******/ 	// Load entry module and return exports
/******/ 	return __webpack_require__(__webpack_require__.s = 12);
/******/ })
/************************************************************************/
/******/ ([
/* 0 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.findInArray = findInArray;
exports.isFunction = isFunction;
exports.isNum = isNum;
exports.int = int;
exports.dontSetMe = dontSetMe;

// @credits https://gist.github.com/rogozhnikoff/a43cfed27c41e4e68cdc
function findInArray(array /*: Array<any> | TouchList*/, callback /*: Function*/) /*: any*/ {
  for (var i = 0, length = array.length; i < length; i++) {
    if (callback.apply(callback, [array[i], i, array])) return array[i];
  }
}

function isFunction(func /*: any*/) /*: boolean*/ {
  return typeof func === 'function' || Object.prototype.toString.call(func) === '[object Function]';
}

function isNum(num /*: any*/) /*: boolean*/ {
  return typeof num === 'number' && !isNaN(num);
}

function int(a /*: string*/) /*: number*/ {
  return parseInt(a, 10);
}

function dontSetMe(props /*: Object*/, propName /*: string*/, componentName /*: string*/) {
  if (props[propName]) {
    return new Error('Invalid prop ' + propName + ' passed to ' + componentName + ' - do not set this, set it on the child.');
  }
}

/***/ }),
/* 1 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


/**
 * Copyright (c) 2013-present, Facebook, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * 
 */

function makeEmptyFunction(arg) {
  return function () {
    return arg;
  };
}

/**
 * This function accepts and discards inputs; it has no side effects. This is
 * primarily useful idiomatically for overridable function endpoints which
 * always need to be callable, since JS lacks a null-call idiom ala Cocoa.
 */
var emptyFunction = function emptyFunction() {};

emptyFunction.thatReturns = makeEmptyFunction;
emptyFunction.thatReturnsFalse = makeEmptyFunction(false);
emptyFunction.thatReturnsTrue = makeEmptyFunction(true);
emptyFunction.thatReturnsNull = makeEmptyFunction(null);
emptyFunction.thatReturnsThis = function () {
  return this;
};
emptyFunction.thatReturnsArgument = function (arg) {
  return arg;
};

module.exports = emptyFunction;

/***/ }),
/* 2 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/**
 * Copyright (c) 2013-present, Facebook, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */



/**
 * Use invariant() to assert state which your program assumes to be true.
 *
 * Provide sprintf-style format (only %s is supported) and arguments
 * to provide information about what broke and what you were
 * expecting.
 *
 * The invariant message will be stripped in production, but the invariant
 * will remain to ensure logic does not differ in production.
 */

var validateFormat = function validateFormat(format) {};

if (Object({"DRAGGABLE_DEBUG":undefined}).NODE_ENV !== 'production') {
  validateFormat = function validateFormat(format) {
    if (format === undefined) {
      throw new Error('invariant requires an error message argument');
    }
  };
}

function invariant(condition, format, a, b, c, d, e, f) {
  validateFormat(format);

  if (!condition) {
    var error;
    if (format === undefined) {
      error = new Error('Minified exception occurred; use the non-minified dev environment ' + 'for the full error message and additional helpful warnings.');
    } else {
      var args = [a, b, c, d, e, f];
      var argIndex = 0;
      error = new Error(format.replace(/%s/g, function () {
        return args[argIndex++];
      }));
      error.name = 'Invariant Violation';
    }

    error.framesToPop = 1; // we don't care about invariant's own frame
    throw error;
  }
}

module.exports = invariant;

/***/ }),
/* 3 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/**
 * Copyright (c) 2013-present, Facebook, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */



var ReactPropTypesSecret = 'SECRET_DO_NOT_PASS_THIS_OR_YOU_WILL_BE_FIRED';

module.exports = ReactPropTypesSecret;


/***/ }),
/* 4 */
/***/ (function(module, exports) {

module.exports = __WEBPACK_EXTERNAL_MODULE_4__;

/***/ }),
/* 5 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

exports.matchesSelector = matchesSelector;
exports.matchesSelectorAndParentsTo = matchesSelectorAndParentsTo;
exports.addEvent = addEvent;
exports.removeEvent = removeEvent;
exports.outerHeight = outerHeight;
exports.outerWidth = outerWidth;
exports.innerHeight = innerHeight;
exports.innerWidth = innerWidth;
exports.offsetXYFromParent = offsetXYFromParent;
exports.createCSSTransform = createCSSTransform;
exports.createSVGTransform = createSVGTransform;
exports.getTouch = getTouch;
exports.getTouchIdentifier = getTouchIdentifier;
exports.addUserSelectStyles = addUserSelectStyles;
exports.removeUserSelectStyles = removeUserSelectStyles;
exports.styleHacks = styleHacks;
exports.addClassName = addClassName;
exports.removeClassName = removeClassName;

var _shims = __webpack_require__(0);

var _getPrefix = __webpack_require__(19);

var _getPrefix2 = _interopRequireDefault(_getPrefix);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

/*:: import type {ControlPosition, MouseTouchEvent} from './types';*/


var matchesSelectorFunc = '';
function matchesSelector(el /*: Node*/, selector /*: string*/) /*: boolean*/ {
  if (!matchesSelectorFunc) {
    matchesSelectorFunc = (0, _shims.findInArray)(['matches', 'webkitMatchesSelector', 'mozMatchesSelector', 'msMatchesSelector', 'oMatchesSelector'], function (method) {
      // $FlowIgnore: Doesn't think elements are indexable
      return (0, _shims.isFunction)(el[method]);
    });
  }

  // Might not be found entirely (not an Element?) - in that case, bail
  // $FlowIgnore: Doesn't think elements are indexable
  if (!(0, _shims.isFunction)(el[matchesSelectorFunc])) return false;

  // $FlowIgnore: Doesn't think elements are indexable
  return el[matchesSelectorFunc](selector);
}

// Works up the tree to the draggable itself attempting to match selector.
function matchesSelectorAndParentsTo(el /*: Node*/, selector /*: string*/, baseNode /*: Node*/) /*: boolean*/ {
  var node = el;
  do {
    if (matchesSelector(node, selector)) return true;
    if (node === baseNode) return false;
    node = node.parentNode;
  } while (node);

  return false;
}

function addEvent(el /*: ?Node*/, event /*: string*/, handler /*: Function*/) /*: void*/ {
  if (!el) {
    return;
  }
  if (el.attachEvent) {
    el.attachEvent('on' + event, handler);
  } else if (el.addEventListener) {
    el.addEventListener(event, handler, true);
  } else {
    // $FlowIgnore: Doesn't think elements are indexable
    el['on' + event] = handler;
  }
}

function removeEvent(el /*: ?Node*/, event /*: string*/, handler /*: Function*/) /*: void*/ {
  if (!el) {
    return;
  }
  if (el.detachEvent) {
    el.detachEvent('on' + event, handler);
  } else if (el.removeEventListener) {
    el.removeEventListener(event, handler, true);
  } else {
    // $FlowIgnore: Doesn't think elements are indexable
    el['on' + event] = null;
  }
}

function outerHeight(node /*: HTMLElement*/) /*: number*/ {
  // This is deliberately excluding margin for our calculations, since we are using
  // offsetTop which is including margin. See getBoundPosition
  var height = node.clientHeight;
  var computedStyle = node.ownerDocument.defaultView.getComputedStyle(node);
  height += (0, _shims.int)(computedStyle.borderTopWidth);
  height += (0, _shims.int)(computedStyle.borderBottomWidth);
  return height;
}

function outerWidth(node /*: HTMLElement*/) /*: number*/ {
  // This is deliberately excluding margin for our calculations, since we are using
  // offsetLeft which is including margin. See getBoundPosition
  var width = node.clientWidth;
  var computedStyle = node.ownerDocument.defaultView.getComputedStyle(node);
  width += (0, _shims.int)(computedStyle.borderLeftWidth);
  width += (0, _shims.int)(computedStyle.borderRightWidth);
  return width;
}
function innerHeight(node /*: HTMLElement*/) /*: number*/ {
  var height = node.clientHeight;
  var computedStyle = node.ownerDocument.defaultView.getComputedStyle(node);
  height -= (0, _shims.int)(computedStyle.paddingTop);
  height -= (0, _shims.int)(computedStyle.paddingBottom);
  return height;
}

function innerWidth(node /*: HTMLElement*/) /*: number*/ {
  var width = node.clientWidth;
  var computedStyle = node.ownerDocument.defaultView.getComputedStyle(node);
  width -= (0, _shims.int)(computedStyle.paddingLeft);
  width -= (0, _shims.int)(computedStyle.paddingRight);
  return width;
}

// Get from offsetParent
function offsetXYFromParent(evt /*: {clientX: number, clientY: number}*/, offsetParent /*: HTMLElement*/) /*: ControlPosition*/ {
  var isBody = offsetParent === offsetParent.ownerDocument.body;
  var offsetParentRect = isBody ? { left: 0, top: 0 } : offsetParent.getBoundingClientRect();

  var x = evt.clientX + offsetParent.scrollLeft - offsetParentRect.left;
  var y = evt.clientY + offsetParent.scrollTop - offsetParentRect.top;

  return { x: x, y: y };
}

function createCSSTransform(_ref) /*: Object*/ {
  var x = _ref.x,
      y = _ref.y;

  // Replace unitless items with px
  return _defineProperty({}, (0, _getPrefix.browserPrefixToKey)('transform', _getPrefix2.default), 'translate(' + x + 'px,' + y + 'px)');
}

function createSVGTransform(_ref3) /*: string*/ {
  var x = _ref3.x,
      y = _ref3.y;

  return 'translate(' + x + ',' + y + ')';
}

function getTouch(e /*: MouseTouchEvent*/, identifier /*: number*/) /*: ?{clientX: number, clientY: number}*/ {
  return e.targetTouches && (0, _shims.findInArray)(e.targetTouches, function (t) {
    return identifier === t.identifier;
  }) || e.changedTouches && (0, _shims.findInArray)(e.changedTouches, function (t) {
    return identifier === t.identifier;
  });
}

function getTouchIdentifier(e /*: MouseTouchEvent*/) /*: ?number*/ {
  if (e.targetTouches && e.targetTouches[0]) return e.targetTouches[0].identifier;
  if (e.changedTouches && e.changedTouches[0]) return e.changedTouches[0].identifier;
}

// User-select Hacks:
//
// Useful for preventing blue highlights all over everything when dragging.

// Note we're passing `document` b/c we could be iframed
function addUserSelectStyles(doc /*: ?Document*/) {
  if (!doc) return;
  var styleEl = doc.getElementById('react-draggable-style-el');
  if (!styleEl) {
    styleEl = doc.createElement('style');
    styleEl.type = 'text/css';
    styleEl.id = 'react-draggable-style-el';
    styleEl.innerHTML = '.react-draggable-transparent-selection *::-moz-selection {background: transparent;}\n';
    styleEl.innerHTML += '.react-draggable-transparent-selection *::selection {background: transparent;}\n';
    doc.getElementsByTagName('head')[0].appendChild(styleEl);
  }
  if (doc.body) addClassName(doc.body, 'react-draggable-transparent-selection');
}

function removeUserSelectStyles(doc /*: ?Document*/) {
  try {
    if (doc && doc.body) removeClassName(doc.body, 'react-draggable-transparent-selection');
    window.getSelection().removeAllRanges(); // remove selection caused by scroll
  } catch (e) {
    // probably IE
  }
}

function styleHacks() /*: Object*/ {
  var childStyle /*: Object*/ = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};

  // Workaround IE pointer events; see #51
  // https://github.com/mzabriskie/react-draggable/issues/51#issuecomment-103488278
  return _extends({
    touchAction: 'none'
  }, childStyle);
}

function addClassName(el /*: HTMLElement*/, className /*: string*/) {
  if (el.classList) {
    el.classList.add(className);
  } else {
    if (!el.className.match(new RegExp('(?:^|\\s)' + className + '(?!\\S)'))) {
      el.className += ' ' + className;
    }
  }
}

function removeClassName(el /*: HTMLElement*/, className /*: string*/) {
  if (el.classList) {
    el.classList.remove(className);
  } else {
    el.className = el.className.replace(new RegExp('(?:^|\\s)' + className + '(?!\\S)', 'g'), '');
  }
}

/***/ }),
/* 6 */
/***/ (function(module, exports) {

module.exports = __WEBPACK_EXTERNAL_MODULE_6__;

/***/ }),
/* 7 */
/***/ (function(module, exports, __webpack_require__) {

/**
 * Copyright (c) 2013-present, Facebook, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

if (Object({"DRAGGABLE_DEBUG":undefined}).NODE_ENV !== 'production') {
  var REACT_ELEMENT_TYPE = (typeof Symbol === 'function' &&
    Symbol.for &&
    Symbol.for('react.element')) ||
    0xeac7;

  var isValidElement = function(object) {
    return typeof object === 'object' &&
      object !== null &&
      object.$$typeof === REACT_ELEMENT_TYPE;
  };

  // By explicitly using `prop-types` you are opting into new development behavior.
  // http://fb.me/prop-types-in-prod
  var throwOnDirectAccess = true;
  module.exports = __webpack_require__(14)(isValidElement, throwOnDirectAccess);
} else {
  // By explicitly using `prop-types` you are opting into new production behavior.
  // http://fb.me/prop-types-in-prod
  module.exports = __webpack_require__(17)();
}


/***/ }),
/* 8 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/**
 * Copyright (c) 2014-present, Facebook, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */



var emptyFunction = __webpack_require__(1);

/**
 * Similar to invariant but only logs a warning if the condition is not met.
 * This can be used to log issues in development environments in critical
 * paths. Removing the logging code for production environments will keep the
 * same logic and follow the same code paths.
 */

var warning = emptyFunction;

if (Object({"DRAGGABLE_DEBUG":undefined}).NODE_ENV !== 'production') {
  var printWarning = function printWarning(format) {
    for (var _len = arguments.length, args = Array(_len > 1 ? _len - 1 : 0), _key = 1; _key < _len; _key++) {
      args[_key - 1] = arguments[_key];
    }

    var argIndex = 0;
    var message = 'Warning: ' + format.replace(/%s/g, function () {
      return args[argIndex++];
    });
    if (typeof console !== 'undefined') {
      console.error(message);
    }
    try {
      // --- Welcome to debugging React ---
      // This error was thrown as a convenience so that you can use this stack
      // to find the callsite that caused this warning to fire.
      throw new Error(message);
    } catch (x) {}
  };

  warning = function warning(condition, format) {
    if (format === undefined) {
      throw new Error('`warning(condition, format, ...args)` requires a warning ' + 'message argument');
    }

    if (format.indexOf('Failed Composite propType: ') === 0) {
      return; // Ignore CompositeComponent proptype check.
    }

    if (!condition) {
      for (var _len2 = arguments.length, args = Array(_len2 > 2 ? _len2 - 2 : 0), _key2 = 2; _key2 < _len2; _key2++) {
        args[_key2 - 2] = arguments[_key2];
      }

      printWarning.apply(undefined, [format].concat(args));
    }
  };
}

module.exports = warning;

/***/ }),
/* 9 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.getBoundPosition = getBoundPosition;
exports.snapToGrid = snapToGrid;
exports.canDragX = canDragX;
exports.canDragY = canDragY;
exports.getControlPosition = getControlPosition;
exports.createCoreData = createCoreData;
exports.createDraggableData = createDraggableData;

var _shims = __webpack_require__(0);

var _reactDom = __webpack_require__(4);

var _reactDom2 = _interopRequireDefault(_reactDom);

var _domFns = __webpack_require__(5);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/*:: import type Draggable from '../Draggable';*/
/*:: import type {Bounds, ControlPosition, DraggableData, MouseTouchEvent} from './types';*/
/*:: import type DraggableCore from '../DraggableCore';*/
function getBoundPosition(draggable /*: Draggable*/, x /*: number*/, y /*: number*/) /*: [number, number]*/ {
  // If no bounds, short-circuit and move on
  if (!draggable.props.bounds) return [x, y];

  // Clone new bounds
  var bounds = draggable.props.bounds;

  bounds = typeof bounds === 'string' ? bounds : cloneBounds(bounds);
  var node = findDOMNode(draggable);

  if (typeof bounds === 'string') {
    var ownerDocument = node.ownerDocument;

    var ownerWindow = ownerDocument.defaultView;
    var boundNode = void 0;
    if (bounds === 'parent') {
      boundNode = node.parentNode;
    } else {
      boundNode = ownerDocument.querySelector(bounds);
    }
    if (!(boundNode instanceof HTMLElement)) {
      throw new Error('Bounds selector "' + bounds + '" could not find an element.');
    }
    var nodeStyle = ownerWindow.getComputedStyle(node);
    var boundNodeStyle = ownerWindow.getComputedStyle(boundNode);
    // Compute bounds. This is a pain with padding and offsets but this gets it exactly right.
    bounds = {
      left: -node.offsetLeft + (0, _shims.int)(boundNodeStyle.paddingLeft) + (0, _shims.int)(nodeStyle.marginLeft),
      top: -node.offsetTop + (0, _shims.int)(boundNodeStyle.paddingTop) + (0, _shims.int)(nodeStyle.marginTop),
      right: (0, _domFns.innerWidth)(boundNode) - (0, _domFns.outerWidth)(node) - node.offsetLeft + (0, _shims.int)(boundNodeStyle.paddingRight) - (0, _shims.int)(nodeStyle.marginRight),
      bottom: (0, _domFns.innerHeight)(boundNode) - (0, _domFns.outerHeight)(node) - node.offsetTop + (0, _shims.int)(boundNodeStyle.paddingBottom) - (0, _shims.int)(nodeStyle.marginBottom)
    };
  }

  // Keep x and y below right and bottom limits...
  if ((0, _shims.isNum)(bounds.right)) x = Math.min(x, bounds.right);
  if ((0, _shims.isNum)(bounds.bottom)) y = Math.min(y, bounds.bottom);

  // But above left and top limits.
  if ((0, _shims.isNum)(bounds.left)) x = Math.max(x, bounds.left);
  if ((0, _shims.isNum)(bounds.top)) y = Math.max(y, bounds.top);

  return [x, y];
}

function snapToGrid(grid /*: [number, number]*/, pendingX /*: number*/, pendingY /*: number*/) /*: [number, number]*/ {
  var x = Math.round(pendingX / grid[0]) * grid[0];
  var y = Math.round(pendingY / grid[1]) * grid[1];
  return [x, y];
}

function canDragX(draggable /*: Draggable*/) /*: boolean*/ {
  return draggable.props.axis === 'both' || draggable.props.axis === 'x';
}

function canDragY(draggable /*: Draggable*/) /*: boolean*/ {
  return draggable.props.axis === 'both' || draggable.props.axis === 'y';
}

// Get {x, y} positions from event.
function getControlPosition(e /*: MouseTouchEvent*/, touchIdentifier /*: ?number*/, draggableCore /*: DraggableCore*/) /*: ?ControlPosition*/ {
  var touchObj = typeof touchIdentifier === 'number' ? (0, _domFns.getTouch)(e, touchIdentifier) : null;
  if (typeof touchIdentifier === 'number' && !touchObj) return null; // not the right touch
  var node = findDOMNode(draggableCore);
  // User can provide an offsetParent if desired.
  var offsetParent = draggableCore.props.offsetParent || node.offsetParent || node.ownerDocument.body;
  return (0, _domFns.offsetXYFromParent)(touchObj || e, offsetParent);
}

// Create an data object exposed by <DraggableCore>'s events
function createCoreData(draggable /*: DraggableCore*/, x /*: number*/, y /*: number*/) /*: DraggableData*/ {
  var state = draggable.state;
  var isStart = !(0, _shims.isNum)(state.lastX);
  var node = findDOMNode(draggable);

  if (isStart) {
    // If this is our first move, use the x and y as last coords.
    return {
      node: node,
      deltaX: 0, deltaY: 0,
      lastX: x, lastY: y,
      x: x, y: y
    };
  } else {
    // Otherwise calculate proper values.
    return {
      node: node,
      deltaX: x - state.lastX, deltaY: y - state.lastY,
      lastX: state.lastX, lastY: state.lastY,
      x: x, y: y
    };
  }
}

// Create an data exposed by <Draggable>'s events
function createDraggableData(draggable /*: Draggable*/, coreData /*: DraggableData*/) /*: DraggableData*/ {
  return {
    node: coreData.node,
    x: draggable.state.x + coreData.deltaX,
    y: draggable.state.y + coreData.deltaY,
    deltaX: coreData.deltaX,
    deltaY: coreData.deltaY,
    lastX: draggable.state.x,
    lastY: draggable.state.y
  };
}

// A lot faster than stringify/parse
function cloneBounds(bounds /*: Bounds*/) /*: Bounds*/ {
  return {
    left: bounds.left,
    top: bounds.top,
    right: bounds.right,
    bottom: bounds.bottom
  };
}

function findDOMNode(draggable /*: Draggable | DraggableCore*/) /*: HTMLElement*/ {
  var node = _reactDom2.default.findDOMNode(draggable);
  if (!node) {
    throw new Error('<DraggableCore>: Unmounted during event!');
  }
  // $FlowIgnore we can't assert on HTMLElement due to tests... FIXME
  return node;
}

/***/ }),
/* 10 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(process) {

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _slicedToArray = function () { function sliceIterator(arr, i) { var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"]) _i["return"](); } finally { if (_d) throw _e; } } return _arr; } return function (arr, i) { if (Array.isArray(arr)) { return arr; } else if (Symbol.iterator in Object(arr)) { return sliceIterator(arr, i); } else { throw new TypeError("Invalid attempt to destructure non-iterable instance"); } }; }();

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

var _react = __webpack_require__(6);

var _react2 = _interopRequireDefault(_react);

var _propTypes = __webpack_require__(7);

var _propTypes2 = _interopRequireDefault(_propTypes);

var _reactDom = __webpack_require__(4);

var _reactDom2 = _interopRequireDefault(_reactDom);

var _domFns = __webpack_require__(5);

var _positionFns = __webpack_require__(9);

var _shims = __webpack_require__(0);

var _log = __webpack_require__(11);

var _log2 = _interopRequireDefault(_log);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

/*:: import type {EventHandler, MouseTouchEvent} from './utils/types';*/


// Simple abstraction for dragging events names.
/*:: import type {Element as ReactElement} from 'react';*/
var eventsFor = {
  touch: {
    start: 'touchstart',
    move: 'touchmove',
    stop: 'touchend'
  },
  mouse: {
    start: 'mousedown',
    move: 'mousemove',
    stop: 'mouseup'
  }
};

// Default to mouse events.
var dragEventFor = eventsFor.mouse;

/*:: type DraggableCoreState = {
  dragging: boolean,
  lastX: number,
  lastY: number,
  touchIdentifier: ?number
};*/
/*:: export type DraggableBounds = {
  left: number,
  right: number,
  top: number,
  bottom: number,
};*/
/*:: export type DraggableData = {
  node: HTMLElement,
  x: number, y: number,
  deltaX: number, deltaY: number,
  lastX: number, lastY: number,
};*/
/*:: export type DraggableEventHandler = (e: MouseEvent, data: DraggableData) => void;*/
/*:: export type ControlPosition = {x: number, y: number};*/


//
// Define <DraggableCore>.
//
// <DraggableCore> is for advanced usage of <Draggable>. It maintains minimal internal state so it can
// work well with libraries that require more control over the element.
//

/*:: export type DraggableCoreProps = {
  allowAnyClick: boolean,
  cancel: string,
  children: ReactElement<any>,
  disabled: boolean,
  enableUserSelectHack: boolean,
  offsetParent: HTMLElement,
  grid: [number, number],
  handle: string,
  onStart: DraggableEventHandler,
  onDrag: DraggableEventHandler,
  onStop: DraggableEventHandler,
  onMouseDown: (e: MouseEvent) => void,
};*/

var DraggableCore = function (_React$Component) {
  _inherits(DraggableCore, _React$Component);

  function DraggableCore() {
    var _ref;

    var _temp, _this, _ret;

    _classCallCheck(this, DraggableCore);

    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return _ret = (_temp = (_this = _possibleConstructorReturn(this, (_ref = DraggableCore.__proto__ || Object.getPrototypeOf(DraggableCore)).call.apply(_ref, [this].concat(args))), _this), _this.state = {
      dragging: false,
      // Used while dragging to determine deltas.
      lastX: NaN, lastY: NaN,
      touchIdentifier: null
    }, _this.handleDragStart = function (e) {
      // Make it possible to attach event handlers on top of this one.
      _this.props.onMouseDown(e);

      // Only accept left-clicks.
      if (!_this.props.allowAnyClick && typeof e.button === 'number' && e.button !== 0) return false;

      // Get nodes. Be sure to grab relative document (could be iframed)
      var thisNode = _reactDom2.default.findDOMNode(_this);
      if (!thisNode || !thisNode.ownerDocument || !thisNode.ownerDocument.body) {
        throw new Error('<DraggableCore> not mounted on DragStart!');
      }
      var ownerDocument = thisNode.ownerDocument;

      // Short circuit if handle or cancel prop was provided and selector doesn't match.

      if (_this.props.disabled || !(e.target instanceof ownerDocument.defaultView.Node) || _this.props.handle && !(0, _domFns.matchesSelectorAndParentsTo)(e.target, _this.props.handle, thisNode) || _this.props.cancel && (0, _domFns.matchesSelectorAndParentsTo)(e.target, _this.props.cancel, thisNode)) {
        return;
      }

      // Set touch identifier in component state if this is a touch event. This allows us to
      // distinguish between individual touches on multitouch screens by identifying which
      // touchpoint was set to this element.
      var touchIdentifier = (0, _domFns.getTouchIdentifier)(e);
      _this.setState({ touchIdentifier: touchIdentifier });

      // Get the current drag point from the event. This is used as the offset.
      var position = (0, _positionFns.getControlPosition)(e, touchIdentifier, _this);
      if (position == null) return; // not possible but satisfies flow
      var x = position.x,
          y = position.y;

      // Create an event object with all the data parents need to make a decision here.

      var coreEvent = (0, _positionFns.createCoreData)(_this, x, y);

      (0, _log2.default)('DraggableCore: handleDragStart: %j', coreEvent);

      // Call event handler. If it returns explicit false, cancel.
      (0, _log2.default)('calling', _this.props.onStart);
      var shouldUpdate = _this.props.onStart(e, coreEvent);
      if (shouldUpdate === false) return;

      // Add a style to the body to disable user-select. This prevents text from
      // being selected all over the page.
      if (_this.props.enableUserSelectHack) (0, _domFns.addUserSelectStyles)(ownerDocument);

      // Initiate dragging. Set the current x and y as offsets
      // so we know how much we've moved during the drag. This allows us
      // to drag elements around even if they have been moved, without issue.
      _this.setState({
        dragging: true,

        lastX: x,
        lastY: y
      });

      // Add events to the document directly so we catch when the user's mouse/touch moves outside of
      // this element. We use different events depending on whether or not we have detected that this
      // is a touch-capable device.
      (0, _domFns.addEvent)(ownerDocument, dragEventFor.move, _this.handleDrag);
      (0, _domFns.addEvent)(ownerDocument, dragEventFor.stop, _this.handleDragStop);
    }, _this.handleDrag = function (e) {

      // Prevent scrolling on mobile devices, like ipad/iphone.
      if (e.type === 'touchmove') e.preventDefault();

      // Get the current drag point from the event. This is used as the offset.
      var position = (0, _positionFns.getControlPosition)(e, _this.state.touchIdentifier, _this);
      if (position == null) return;
      var x = position.x,
          y = position.y;

      // Snap to grid if prop has been provided

      if (Array.isArray(_this.props.grid)) {
        var _deltaX = x - _this.state.lastX,
            _deltaY = y - _this.state.lastY;

        var _snapToGrid = (0, _positionFns.snapToGrid)(_this.props.grid, _deltaX, _deltaY);

        var _snapToGrid2 = _slicedToArray(_snapToGrid, 2);

        _deltaX = _snapToGrid2[0];
        _deltaY = _snapToGrid2[1];

        if (!_deltaX && !_deltaY) return; // skip useless drag
        x = _this.state.lastX + _deltaX, y = _this.state.lastY + _deltaY;
      }

      var coreEvent = (0, _positionFns.createCoreData)(_this, x, y);

      (0, _log2.default)('DraggableCore: handleDrag: %j', coreEvent);

      // Call event handler. If it returns explicit false, trigger end.
      var shouldUpdate = _this.props.onDrag(e, coreEvent);
      if (shouldUpdate === false) {
        try {
          // $FlowIgnore
          _this.handleDragStop(new MouseEvent('mouseup'));
        } catch (err) {
          // Old browsers
          var event = ((document.createEvent('MouseEvents') /*: any*/) /*: MouseTouchEvent*/);
          // I see why this insanity was deprecated
          // $FlowIgnore
          event.initMouseEvent('mouseup', true, true, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null);
          _this.handleDragStop(event);
        }
        return;
      }

      _this.setState({
        lastX: x,
        lastY: y
      });
    }, _this.handleDragStop = function (e) {
      if (!_this.state.dragging) return;

      var position = (0, _positionFns.getControlPosition)(e, _this.state.touchIdentifier, _this);
      if (position == null) return;
      var x = position.x,
          y = position.y;

      var coreEvent = (0, _positionFns.createCoreData)(_this, x, y);

      var thisNode = _reactDom2.default.findDOMNode(_this);
      if (thisNode) {
        // Remove user-select hack
        if (_this.props.enableUserSelectHack) (0, _domFns.removeUserSelectStyles)(thisNode.ownerDocument);
      }

      (0, _log2.default)('DraggableCore: handleDragStop: %j', coreEvent);

      // Reset the el.
      _this.setState({
        dragging: false,
        lastX: NaN,
        lastY: NaN
      });

      // Call event handler
      _this.props.onStop(e, coreEvent);

      if (thisNode) {
        // Remove event handlers
        (0, _log2.default)('DraggableCore: Removing handlers');
        (0, _domFns.removeEvent)(thisNode.ownerDocument, dragEventFor.move, _this.handleDrag);
        (0, _domFns.removeEvent)(thisNode.ownerDocument, dragEventFor.stop, _this.handleDragStop);
      }
    }, _this.onMouseDown = function (e) {
      dragEventFor = eventsFor.mouse; // on touchscreen laptops we could switch back to mouse

      return _this.handleDragStart(e);
    }, _this.onMouseUp = function (e) {
      dragEventFor = eventsFor.mouse;

      return _this.handleDragStop(e);
    }, _this.onTouchStart = function (e) {
      // We're on a touch device now, so change the event handlers
      dragEventFor = eventsFor.touch;

      return _this.handleDragStart(e);
    }, _this.onTouchEnd = function (e) {
      // We're on a touch device now, so change the event handlers
      dragEventFor = eventsFor.touch;

      return _this.handleDragStop(e);
    }, _temp), _possibleConstructorReturn(_this, _ret);
  }

  _createClass(DraggableCore, [{
    key: 'componentWillUnmount',
    value: function componentWillUnmount() {
      // Remove any leftover event handlers. Remove both touch and mouse handlers in case
      // some browser quirk caused a touch event to fire during a mouse move, or vice versa.
      var thisNode = _reactDom2.default.findDOMNode(this);
      if (thisNode) {
        var ownerDocument = thisNode.ownerDocument;

        (0, _domFns.removeEvent)(ownerDocument, eventsFor.mouse.move, this.handleDrag);
        (0, _domFns.removeEvent)(ownerDocument, eventsFor.touch.move, this.handleDrag);
        (0, _domFns.removeEvent)(ownerDocument, eventsFor.mouse.stop, this.handleDragStop);
        (0, _domFns.removeEvent)(ownerDocument, eventsFor.touch.stop, this.handleDragStop);
        if (this.props.enableUserSelectHack) (0, _domFns.removeUserSelectStyles)(ownerDocument);
      }
    }

    // Same as onMouseDown (start drag), but now consider this a touch device.

  }, {
    key: 'render',
    value: function render() {
      // Reuse the child provided
      // This makes it flexible to use whatever element is wanted (div, ul, etc)
      return _react2.default.cloneElement(_react2.default.Children.only(this.props.children), {
        style: (0, _domFns.styleHacks)(this.props.children.props.style),

        // Note: mouseMove handler is attached to document so it will still function
        // when the user drags quickly and leaves the bounds of the element.
        onMouseDown: this.onMouseDown,
        onTouchStart: this.onTouchStart,
        onMouseUp: this.onMouseUp,
        onTouchEnd: this.onTouchEnd
      });
    }
  }]);

  return DraggableCore;
}(_react2.default.Component);

DraggableCore.displayName = 'DraggableCore';
DraggableCore.propTypes = {
  /**
   * `allowAnyClick` allows dragging using any mouse button.
   * By default, we only accept the left button.
   *
   * Defaults to `false`.
   */
  allowAnyClick: _propTypes2.default.bool,

  /**
   * `disabled`, if true, stops the <Draggable> from dragging. All handlers,
   * with the exception of `onMouseDown`, will not fire.
   */
  disabled: _propTypes2.default.bool,

  /**
   * By default, we add 'user-select:none' attributes to the document body
   * to prevent ugly text selection during drag. If this is causing problems
   * for your app, set this to `false`.
   */
  enableUserSelectHack: _propTypes2.default.bool,

  /**
   * `offsetParent`, if set, uses the passed DOM node to compute drag offsets
   * instead of using the parent node.
   */
  offsetParent: function offsetParent(props /*: DraggableCoreProps*/, propName /*: $Keys<DraggableCoreProps>*/) {
    if (process.browser === true && props[propName] && props[propName].nodeType !== 1) {
      throw new Error('Draggable\'s offsetParent must be a DOM Node.');
    }
  },

  /**
   * `grid` specifies the x and y that dragging should snap to.
   */
  grid: _propTypes2.default.arrayOf(_propTypes2.default.number),

  /**
   * `handle` specifies a selector to be used as the handle that initiates drag.
   *
   * Example:
   *
   * ```jsx
   *   let App = React.createClass({
   *       render: function () {
   *         return (
   *            <Draggable handle=".handle">
   *              <div>
   *                  <div className="handle">Click me to drag</div>
   *                  <div>This is some other content</div>
   *              </div>
   *           </Draggable>
   *         );
   *       }
   *   });
   * ```
   */
  handle: _propTypes2.default.string,

  /**
   * `cancel` specifies a selector to be used to prevent drag initialization.
   *
   * Example:
   *
   * ```jsx
   *   let App = React.createClass({
   *       render: function () {
   *           return(
   *               <Draggable cancel=".cancel">
   *                   <div>
   *                     <div className="cancel">You can't drag from here</div>
   *                     <div>Dragging here works fine</div>
   *                   </div>
   *               </Draggable>
   *           );
   *       }
   *   });
   * ```
   */
  cancel: _propTypes2.default.string,

  /**
   * Called when dragging starts.
   * If this function returns the boolean false, dragging will be canceled.
   */
  onStart: _propTypes2.default.func,

  /**
   * Called while dragging.
   * If this function returns the boolean false, dragging will be canceled.
   */
  onDrag: _propTypes2.default.func,

  /**
   * Called when dragging stops.
   * If this function returns the boolean false, the drag will remain active.
   */
  onStop: _propTypes2.default.func,

  /**
   * A workaround option which can be passed if onMouseDown needs to be accessed,
   * since it'll always be blocked (as there is internal use of onMouseDown)
   */
  onMouseDown: _propTypes2.default.func,

  /**
   * These properties should be defined on the child, not here.
   */
  className: _shims.dontSetMe,
  style: _shims.dontSetMe,
  transform: _shims.dontSetMe
};
DraggableCore.defaultProps = {
  allowAnyClick: false, // by default only accept left click
  cancel: null,
  disabled: false,
  enableUserSelectHack: true,
  offsetParent: null,
  handle: null,
  grid: null,
  transform: null,
  onStart: function onStart() {},
  onDrag: function onDrag() {},
  onStop: function onStop() {},
  onMouseDown: function onMouseDown() {}
};
exports.default = DraggableCore;
/* WEBPACK VAR INJECTION */}.call(exports, __webpack_require__(20)))

/***/ }),
/* 11 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = log;

/*eslint no-console:0*/
function log() {
  var _console;

  if (undefined) (_console = console).log.apply(_console, arguments);
}

/***/ }),
/* 12 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


var Draggable = __webpack_require__(13).default;

// Previous versions of this lib exported <Draggable> as the root export. As to not break
// them, or TypeScript, we export *both* as the root and as 'default'.
// See https://github.com/mzabriskie/react-draggable/pull/254
// and https://github.com/mzabriskie/react-draggable/issues/266
module.exports = Draggable;
module.exports.default = Draggable;
module.exports.DraggableCore = __webpack_require__(10).default;

/***/ }),
/* 13 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

var _slicedToArray = function () { function sliceIterator(arr, i) { var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"]) _i["return"](); } finally { if (_d) throw _e; } } return _arr; } return function (arr, i) { if (Array.isArray(arr)) { return arr; } else if (Symbol.iterator in Object(arr)) { return sliceIterator(arr, i); } else { throw new TypeError("Invalid attempt to destructure non-iterable instance"); } }; }();

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

var _react = __webpack_require__(6);

var _react2 = _interopRequireDefault(_react);

var _propTypes = __webpack_require__(7);

var _propTypes2 = _interopRequireDefault(_propTypes);

var _reactDom = __webpack_require__(4);

var _reactDom2 = _interopRequireDefault(_reactDom);

var _classnames = __webpack_require__(18);

var _classnames2 = _interopRequireDefault(_classnames);

var _domFns = __webpack_require__(5);

var _positionFns = __webpack_require__(9);

var _shims = __webpack_require__(0);

var _DraggableCore = __webpack_require__(10);

var _DraggableCore2 = _interopRequireDefault(_DraggableCore);

var _log = __webpack_require__(11);

var _log2 = _interopRequireDefault(_log);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

/*:: import type {ControlPosition, DraggableBounds, DraggableCoreProps} from './DraggableCore';*/
/*:: import type {DraggableEventHandler} from './utils/types';*/
/*:: import type {Element as ReactElement} from 'react';*/
/*:: type DraggableState = {
  dragging: boolean,
  dragged: boolean,
  x: number, y: number,
  slackX: number, slackY: number,
  isElementSVG: boolean
};*/


//
// Define <Draggable>
//

/*:: export type DraggableProps = {
  ...$Exact<DraggableCoreProps>,
  axis: 'both' | 'x' | 'y' | 'none',
  bounds: DraggableBounds | string | false,
  defaultClassName: string,
  defaultClassNameDragging: string,
  defaultClassNameDragged: string,
  defaultPosition: ControlPosition,
  position: ControlPosition,
};*/

var Draggable = function (_React$Component) {
  _inherits(Draggable, _React$Component);

  function Draggable(props /*: DraggableProps*/) {
    _classCallCheck(this, Draggable);

    var _this = _possibleConstructorReturn(this, (Draggable.__proto__ || Object.getPrototypeOf(Draggable)).call(this, props));

    _this.onDragStart = function (e, coreData) {
      (0, _log2.default)('Draggable: onDragStart: %j', coreData);

      // Short-circuit if user's callback killed it.
      var shouldStart = _this.props.onStart(e, (0, _positionFns.createDraggableData)(_this, coreData));
      // Kills start event on core as well, so move handlers are never bound.
      if (shouldStart === false) return false;

      _this.setState({ dragging: true, dragged: true });
    };

    _this.onDrag = function (e, coreData) {
      if (!_this.state.dragging) return false;
      (0, _log2.default)('Draggable: onDrag: %j', coreData);

      var uiData = (0, _positionFns.createDraggableData)(_this, coreData);

      var newState /*: $Shape<DraggableState>*/ = {
        x: uiData.x,
        y: uiData.y
      };

      // Keep within bounds.
      if (_this.props.bounds) {
        // Save original x and y.
        var _x = newState.x,
            _y = newState.y;

        // Add slack to the values used to calculate bound position. This will ensure that if
        // we start removing slack, the element won't react to it right away until it's been
        // completely removed.

        newState.x += _this.state.slackX;
        newState.y += _this.state.slackY;

        // Get bound position. This will ceil/floor the x and y within the boundaries.

        var _getBoundPosition = (0, _positionFns.getBoundPosition)(_this, newState.x, newState.y),
            _getBoundPosition2 = _slicedToArray(_getBoundPosition, 2),
            newStateX = _getBoundPosition2[0],
            newStateY = _getBoundPosition2[1];

        newState.x = newStateX;
        newState.y = newStateY;

        // Recalculate slack by noting how much was shaved by the boundPosition handler.
        newState.slackX = _this.state.slackX + (_x - newState.x);
        newState.slackY = _this.state.slackY + (_y - newState.y);

        // Update the event we fire to reflect what really happened after bounds took effect.
        uiData.x = newState.x;
        uiData.y = newState.y;
        uiData.deltaX = newState.x - _this.state.x;
        uiData.deltaY = newState.y - _this.state.y;
      }

      // Short-circuit if user's callback killed it.
      var shouldUpdate = _this.props.onDrag(e, uiData);
      if (shouldUpdate === false) return false;

      _this.setState(newState);
    };

    _this.onDragStop = function (e, coreData) {
      if (!_this.state.dragging) return false;

      // Short-circuit if user's callback killed it.
      var shouldStop = _this.props.onStop(e, (0, _positionFns.createDraggableData)(_this, coreData));
      if (shouldStop === false) return false;

      (0, _log2.default)('Draggable: onDragStop: %j', coreData);

      var newState /*: $Shape<DraggableState>*/ = {
        dragging: false,
        slackX: 0,
        slackY: 0
      };

      // If this is a controlled component, the result of this operation will be to
      // revert back to the old position. We expect a handler on `onDragStop`, at the least.
      var controlled = Boolean(_this.props.position);
      if (controlled) {
        var _this$props$position = _this.props.position,
            _x2 = _this$props$position.x,
            _y2 = _this$props$position.y;

        newState.x = _x2;
        newState.y = _y2;
      }

      _this.setState(newState);
    };

    _this.state = {
      // Whether or not we are currently dragging.
      dragging: false,

      // Whether or not we have been dragged before.
      dragged: false,

      // Current transform x and y.
      x: props.position ? props.position.x : props.defaultPosition.x,
      y: props.position ? props.position.y : props.defaultPosition.y,

      // Used for compensating for out-of-bounds drags
      slackX: 0, slackY: 0,

      // Can only determine if SVG after mounting
      isElementSVG: false
    };
    return _this;
  }

  _createClass(Draggable, [{
    key: 'componentWillMount',
    value: function componentWillMount() {
      if (this.props.position && !(this.props.onDrag || this.props.onStop)) {
        // eslint-disable-next-line
        console.warn('A `position` was applied to this <Draggable>, without drag handlers. This will make this ' + 'component effectively undraggable. Please attach `onDrag` or `onStop` handlers so you can adjust the ' + '`position` of this element.');
      }
    }
  }, {
    key: 'componentDidMount',
    value: function componentDidMount() {
      // Check to see if the element passed is an instanceof SVGElement
      if (typeof window.SVGElement !== 'undefined' && _reactDom2.default.findDOMNode(this) instanceof window.SVGElement) {
        this.setState({ isElementSVG: true });
      }
    }
  }, {
    key: 'componentWillReceiveProps',
    value: function componentWillReceiveProps(nextProps /*: Object*/) {
      // Set x/y if position has changed
      if (nextProps.position && (!this.props.position || nextProps.position.x !== this.props.position.x || nextProps.position.y !== this.props.position.y)) {
        this.setState({ x: nextProps.position.x, y: nextProps.position.y });
      }
    }
  }, {
    key: 'componentWillUnmount',
    value: function componentWillUnmount() {
      this.setState({ dragging: false }); // prevents invariant if unmounted while dragging
    }
  }, {
    key: 'render',
    value: function render() /*: ReactElement<any>*/ {
      var _classNames;

      var style = {},
          svgTransform = null;

      // If this is controlled, we don't want to move it - unless it's dragging.
      var controlled = Boolean(this.props.position);
      var draggable = !controlled || this.state.dragging;

      var position = this.props.position || this.props.defaultPosition;
      var transformOpts = {
        // Set left if horizontal drag is enabled
        x: (0, _positionFns.canDragX)(this) && draggable ? this.state.x : position.x,

        // Set top if vertical drag is enabled
        y: (0, _positionFns.canDragY)(this) && draggable ? this.state.y : position.y
      };

      // If this element was SVG, we use the `transform` attribute.
      if (this.state.isElementSVG) {
        svgTransform = (0, _domFns.createSVGTransform)(transformOpts);
      } else {
        // Add a CSS transform to move the element around. This allows us to move the element around
        // without worrying about whether or not it is relatively or absolutely positioned.
        // If the item you are dragging already has a transform set, wrap it in a <span> so <Draggable>
        // has a clean slate.
        style = (0, _domFns.createCSSTransform)(transformOpts);
      }

      var _props = this.props,
          defaultClassName = _props.defaultClassName,
          defaultClassNameDragging = _props.defaultClassNameDragging,
          defaultClassNameDragged = _props.defaultClassNameDragged;


      var children = _react2.default.Children.only(this.props.children);

      // Mark with class while dragging
      var className = (0, _classnames2.default)(children.props.className || '', defaultClassName, (_classNames = {}, _defineProperty(_classNames, defaultClassNameDragging, this.state.dragging), _defineProperty(_classNames, defaultClassNameDragged, this.state.dragged), _classNames));

      // Reuse the child provided
      // This makes it flexible to use whatever element is wanted (div, ul, etc)
      return _react2.default.createElement(
        _DraggableCore2.default,
        _extends({}, this.props, { onStart: this.onDragStart, onDrag: this.onDrag, onStop: this.onDragStop }),
        _react2.default.cloneElement(children, {
          className: className,
          style: _extends({}, children.props.style, style),
          transform: svgTransform
        })
      );
    }
  }]);

  return Draggable;
}(_react2.default.Component);

Draggable.displayName = 'Draggable';
Draggable.propTypes = _extends({}, _DraggableCore2.default.propTypes, {

  /**
   * `axis` determines which axis the draggable can move.
   *
   *  Note that all callbacks will still return data as normal. This only
   *  controls flushing to the DOM.
   *
   * 'both' allows movement horizontally and vertically.
   * 'x' limits movement to horizontal axis.
   * 'y' limits movement to vertical axis.
   * 'none' limits all movement.
   *
   * Defaults to 'both'.
   */
  axis: _propTypes2.default.oneOf(['both', 'x', 'y', 'none']),

  /**
   * `bounds` determines the range of movement available to the element.
   * Available values are:
   *
   * 'parent' restricts movement within the Draggable's parent node.
   *
   * Alternatively, pass an object with the following properties, all of which are optional:
   *
   * {left: LEFT_BOUND, right: RIGHT_BOUND, bottom: BOTTOM_BOUND, top: TOP_BOUND}
   *
   * All values are in px.
   *
   * Example:
   *
   * ```jsx
   *   let App = React.createClass({
   *       render: function () {
   *         return (
   *            <Draggable bounds={{right: 300, bottom: 300}}>
   *              <div>Content</div>
   *           </Draggable>
   *         );
   *       }
   *   });
   * ```
   */
  bounds: _propTypes2.default.oneOfType([_propTypes2.default.shape({
    left: _propTypes2.default.number,
    right: _propTypes2.default.number,
    top: _propTypes2.default.number,
    bottom: _propTypes2.default.number
  }), _propTypes2.default.string, _propTypes2.default.oneOf([false])]),

  defaultClassName: _propTypes2.default.string,
  defaultClassNameDragging: _propTypes2.default.string,
  defaultClassNameDragged: _propTypes2.default.string,

  /**
   * `defaultPosition` specifies the x and y that the dragged item should start at
   *
   * Example:
   *
   * ```jsx
   *      let App = React.createClass({
   *          render: function () {
   *              return (
   *                  <Draggable defaultPosition={{x: 25, y: 25}}>
   *                      <div>I start with transformX: 25px and transformY: 25px;</div>
   *                  </Draggable>
   *              );
   *          }
   *      });
   * ```
   */
  defaultPosition: _propTypes2.default.shape({
    x: _propTypes2.default.number,
    y: _propTypes2.default.number
  }),

  /**
   * `position`, if present, defines the current position of the element.
   *
   *  This is similar to how form elements in React work - if no `position` is supplied, the component
   *  is uncontrolled.
   *
   * Example:
   *
   * ```jsx
   *      let App = React.createClass({
   *          render: function () {
   *              return (
   *                  <Draggable position={{x: 25, y: 25}}>
   *                      <div>I start with transformX: 25px and transformY: 25px;</div>
   *                  </Draggable>
   *              );
   *          }
   *      });
   * ```
   */
  position: _propTypes2.default.shape({
    x: _propTypes2.default.number,
    y: _propTypes2.default.number
  }),

  /**
   * These properties should be defined on the child, not here.
   */
  className: _shims.dontSetMe,
  style: _shims.dontSetMe,
  transform: _shims.dontSetMe
});
Draggable.defaultProps = _extends({}, _DraggableCore2.default.defaultProps, {
  axis: 'both',
  bounds: false,
  defaultClassName: 'react-draggable',
  defaultClassNameDragging: 'react-draggable-dragging',
  defaultClassNameDragged: 'react-draggable-dragged',
  defaultPosition: { x: 0, y: 0 },
  position: null
});
exports.default = Draggable;

/***/ }),
/* 14 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/**
 * Copyright (c) 2013-present, Facebook, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */



var emptyFunction = __webpack_require__(1);
var invariant = __webpack_require__(2);
var warning = __webpack_require__(8);
var assign = __webpack_require__(15);

var ReactPropTypesSecret = __webpack_require__(3);
var checkPropTypes = __webpack_require__(16);

module.exports = function(isValidElement, throwOnDirectAccess) {
  /* global Symbol */
  var ITERATOR_SYMBOL = typeof Symbol === 'function' && Symbol.iterator;
  var FAUX_ITERATOR_SYMBOL = '@@iterator'; // Before Symbol spec.

  /**
   * Returns the iterator method function contained on the iterable object.
   *
   * Be sure to invoke the function with the iterable as context:
   *
   *     var iteratorFn = getIteratorFn(myIterable);
   *     if (iteratorFn) {
   *       var iterator = iteratorFn.call(myIterable);
   *       ...
   *     }
   *
   * @param {?object} maybeIterable
   * @return {?function}
   */
  function getIteratorFn(maybeIterable) {
    var iteratorFn = maybeIterable && (ITERATOR_SYMBOL && maybeIterable[ITERATOR_SYMBOL] || maybeIterable[FAUX_ITERATOR_SYMBOL]);
    if (typeof iteratorFn === 'function') {
      return iteratorFn;
    }
  }

  /**
   * Collection of methods that allow declaration and validation of props that are
   * supplied to React components. Example usage:
   *
   *   var Props = require('ReactPropTypes');
   *   var MyArticle = React.createClass({
   *     propTypes: {
   *       // An optional string prop named "description".
   *       description: Props.string,
   *
   *       // A required enum prop named "category".
   *       category: Props.oneOf(['News','Photos']).isRequired,
   *
   *       // A prop named "dialog" that requires an instance of Dialog.
   *       dialog: Props.instanceOf(Dialog).isRequired
   *     },
   *     render: function() { ... }
   *   });
   *
   * A more formal specification of how these methods are used:
   *
   *   type := array|bool|func|object|number|string|oneOf([...])|instanceOf(...)
   *   decl := ReactPropTypes.{type}(.isRequired)?
   *
   * Each and every declaration produces a function with the same signature. This
   * allows the creation of custom validation functions. For example:
   *
   *  var MyLink = React.createClass({
   *    propTypes: {
   *      // An optional string or URI prop named "href".
   *      href: function(props, propName, componentName) {
   *        var propValue = props[propName];
   *        if (propValue != null && typeof propValue !== 'string' &&
   *            !(propValue instanceof URI)) {
   *          return new Error(
   *            'Expected a string or an URI for ' + propName + ' in ' +
   *            componentName
   *          );
   *        }
   *      }
   *    },
   *    render: function() {...}
   *  });
   *
   * @internal
   */

  var ANONYMOUS = '<<anonymous>>';

  // Important!
  // Keep this list in sync with production version in `./factoryWithThrowingShims.js`.
  var ReactPropTypes = {
    array: createPrimitiveTypeChecker('array'),
    bool: createPrimitiveTypeChecker('boolean'),
    func: createPrimitiveTypeChecker('function'),
    number: createPrimitiveTypeChecker('number'),
    object: createPrimitiveTypeChecker('object'),
    string: createPrimitiveTypeChecker('string'),
    symbol: createPrimitiveTypeChecker('symbol'),

    any: createAnyTypeChecker(),
    arrayOf: createArrayOfTypeChecker,
    element: createElementTypeChecker(),
    instanceOf: createInstanceTypeChecker,
    node: createNodeChecker(),
    objectOf: createObjectOfTypeChecker,
    oneOf: createEnumTypeChecker,
    oneOfType: createUnionTypeChecker,
    shape: createShapeTypeChecker,
    exact: createStrictShapeTypeChecker,
  };

  /**
   * inlined Object.is polyfill to avoid requiring consumers ship their own
   * https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/is
   */
  /*eslint-disable no-self-compare*/
  function is(x, y) {
    // SameValue algorithm
    if (x === y) {
      // Steps 1-5, 7-10
      // Steps 6.b-6.e: +0 != -0
      return x !== 0 || 1 / x === 1 / y;
    } else {
      // Step 6.a: NaN == NaN
      return x !== x && y !== y;
    }
  }
  /*eslint-enable no-self-compare*/

  /**
   * We use an Error-like object for backward compatibility as people may call
   * PropTypes directly and inspect their output. However, we don't use real
   * Errors anymore. We don't inspect their stack anyway, and creating them
   * is prohibitively expensive if they are created too often, such as what
   * happens in oneOfType() for any type before the one that matched.
   */
  function PropTypeError(message) {
    this.message = message;
    this.stack = '';
  }
  // Make `instanceof Error` still work for returned errors.
  PropTypeError.prototype = Error.prototype;

  function createChainableTypeChecker(validate) {
    if (Object({"DRAGGABLE_DEBUG":undefined}).NODE_ENV !== 'production') {
      var manualPropTypeCallCache = {};
      var manualPropTypeWarningCount = 0;
    }
    function checkType(isRequired, props, propName, componentName, location, propFullName, secret) {
      componentName = componentName || ANONYMOUS;
      propFullName = propFullName || propName;

      if (secret !== ReactPropTypesSecret) {
        if (throwOnDirectAccess) {
          // New behavior only for users of `prop-types` package
          invariant(
            false,
            'Calling PropTypes validators directly is not supported by the `prop-types` package. ' +
            'Use `PropTypes.checkPropTypes()` to call them. ' +
            'Read more at http://fb.me/use-check-prop-types'
          );
        } else if (Object({"DRAGGABLE_DEBUG":undefined}).NODE_ENV !== 'production' && typeof console !== 'undefined') {
          // Old behavior for people using React.PropTypes
          var cacheKey = componentName + ':' + propName;
          if (
            !manualPropTypeCallCache[cacheKey] &&
            // Avoid spamming the console because they are often not actionable except for lib authors
            manualPropTypeWarningCount < 3
          ) {
            warning(
              false,
              'You are manually calling a React.PropTypes validation ' +
              'function for the `%s` prop on `%s`. This is deprecated ' +
              'and will throw in the standalone `prop-types` package. ' +
              'You may be seeing this warning due to a third-party PropTypes ' +
              'library. See https://fb.me/react-warning-dont-call-proptypes ' + 'for details.',
              propFullName,
              componentName
            );
            manualPropTypeCallCache[cacheKey] = true;
            manualPropTypeWarningCount++;
          }
        }
      }
      if (props[propName] == null) {
        if (isRequired) {
          if (props[propName] === null) {
            return new PropTypeError('The ' + location + ' `' + propFullName + '` is marked as required ' + ('in `' + componentName + '`, but its value is `null`.'));
          }
          return new PropTypeError('The ' + location + ' `' + propFullName + '` is marked as required in ' + ('`' + componentName + '`, but its value is `undefined`.'));
        }
        return null;
      } else {
        return validate(props, propName, componentName, location, propFullName);
      }
    }

    var chainedCheckType = checkType.bind(null, false);
    chainedCheckType.isRequired = checkType.bind(null, true);

    return chainedCheckType;
  }

  function createPrimitiveTypeChecker(expectedType) {
    function validate(props, propName, componentName, location, propFullName, secret) {
      var propValue = props[propName];
      var propType = getPropType(propValue);
      if (propType !== expectedType) {
        // `propValue` being instance of, say, date/regexp, pass the 'object'
        // check, but we can offer a more precise error message here rather than
        // 'of type `object`'.
        var preciseType = getPreciseType(propValue);

        return new PropTypeError('Invalid ' + location + ' `' + propFullName + '` of type ' + ('`' + preciseType + '` supplied to `' + componentName + '`, expected ') + ('`' + expectedType + '`.'));
      }
      return null;
    }
    return createChainableTypeChecker(validate);
  }

  function createAnyTypeChecker() {
    return createChainableTypeChecker(emptyFunction.thatReturnsNull);
  }

  function createArrayOfTypeChecker(typeChecker) {
    function validate(props, propName, componentName, location, propFullName) {
      if (typeof typeChecker !== 'function') {
        return new PropTypeError('Property `' + propFullName + '` of component `' + componentName + '` has invalid PropType notation inside arrayOf.');
      }
      var propValue = props[propName];
      if (!Array.isArray(propValue)) {
        var propType = getPropType(propValue);
        return new PropTypeError('Invalid ' + location + ' `' + propFullName + '` of type ' + ('`' + propType + '` supplied to `' + componentName + '`, expected an array.'));
      }
      for (var i = 0; i < propValue.length; i++) {
        var error = typeChecker(propValue, i, componentName, location, propFullName + '[' + i + ']', ReactPropTypesSecret);
        if (error instanceof Error) {
          return error;
        }
      }
      return null;
    }
    return createChainableTypeChecker(validate);
  }

  function createElementTypeChecker() {
    function validate(props, propName, componentName, location, propFullName) {
      var propValue = props[propName];
      if (!isValidElement(propValue)) {
        var propType = getPropType(propValue);
        return new PropTypeError('Invalid ' + location + ' `' + propFullName + '` of type ' + ('`' + propType + '` supplied to `' + componentName + '`, expected a single ReactElement.'));
      }
      return null;
    }
    return createChainableTypeChecker(validate);
  }

  function createInstanceTypeChecker(expectedClass) {
    function validate(props, propName, componentName, location, propFullName) {
      if (!(props[propName] instanceof expectedClass)) {
        var expectedClassName = expectedClass.name || ANONYMOUS;
        var actualClassName = getClassName(props[propName]);
        return new PropTypeError('Invalid ' + location + ' `' + propFullName + '` of type ' + ('`' + actualClassName + '` supplied to `' + componentName + '`, expected ') + ('instance of `' + expectedClassName + '`.'));
      }
      return null;
    }
    return createChainableTypeChecker(validate);
  }

  function createEnumTypeChecker(expectedValues) {
    if (!Array.isArray(expectedValues)) {
      Object({"DRAGGABLE_DEBUG":undefined}).NODE_ENV !== 'production' ? warning(false, 'Invalid argument supplied to oneOf, expected an instance of array.') : void 0;
      return emptyFunction.thatReturnsNull;
    }

    function validate(props, propName, componentName, location, propFullName) {
      var propValue = props[propName];
      for (var i = 0; i < expectedValues.length; i++) {
        if (is(propValue, expectedValues[i])) {
          return null;
        }
      }

      var valuesString = JSON.stringify(expectedValues);
      return new PropTypeError('Invalid ' + location + ' `' + propFullName + '` of value `' + propValue + '` ' + ('supplied to `' + componentName + '`, expected one of ' + valuesString + '.'));
    }
    return createChainableTypeChecker(validate);
  }

  function createObjectOfTypeChecker(typeChecker) {
    function validate(props, propName, componentName, location, propFullName) {
      if (typeof typeChecker !== 'function') {
        return new PropTypeError('Property `' + propFullName + '` of component `' + componentName + '` has invalid PropType notation inside objectOf.');
      }
      var propValue = props[propName];
      var propType = getPropType(propValue);
      if (propType !== 'object') {
        return new PropTypeError('Invalid ' + location + ' `' + propFullName + '` of type ' + ('`' + propType + '` supplied to `' + componentName + '`, expected an object.'));
      }
      for (var key in propValue) {
        if (propValue.hasOwnProperty(key)) {
          var error = typeChecker(propValue, key, componentName, location, propFullName + '.' + key, ReactPropTypesSecret);
          if (error instanceof Error) {
            return error;
          }
        }
      }
      return null;
    }
    return createChainableTypeChecker(validate);
  }

  function createUnionTypeChecker(arrayOfTypeCheckers) {
    if (!Array.isArray(arrayOfTypeCheckers)) {
      Object({"DRAGGABLE_DEBUG":undefined}).NODE_ENV !== 'production' ? warning(false, 'Invalid argument supplied to oneOfType, expected an instance of array.') : void 0;
      return emptyFunction.thatReturnsNull;
    }

    for (var i = 0; i < arrayOfTypeCheckers.length; i++) {
      var checker = arrayOfTypeCheckers[i];
      if (typeof checker !== 'function') {
        warning(
          false,
          'Invalid argument supplied to oneOfType. Expected an array of check functions, but ' +
          'received %s at index %s.',
          getPostfixForTypeWarning(checker),
          i
        );
        return emptyFunction.thatReturnsNull;
      }
    }

    function validate(props, propName, componentName, location, propFullName) {
      for (var i = 0; i < arrayOfTypeCheckers.length; i++) {
        var checker = arrayOfTypeCheckers[i];
        if (checker(props, propName, componentName, location, propFullName, ReactPropTypesSecret) == null) {
          return null;
        }
      }

      return new PropTypeError('Invalid ' + location + ' `' + propFullName + '` supplied to ' + ('`' + componentName + '`.'));
    }
    return createChainableTypeChecker(validate);
  }

  function createNodeChecker() {
    function validate(props, propName, componentName, location, propFullName) {
      if (!isNode(props[propName])) {
        return new PropTypeError('Invalid ' + location + ' `' + propFullName + '` supplied to ' + ('`' + componentName + '`, expected a ReactNode.'));
      }
      return null;
    }
    return createChainableTypeChecker(validate);
  }

  function createShapeTypeChecker(shapeTypes) {
    function validate(props, propName, componentName, location, propFullName) {
      var propValue = props[propName];
      var propType = getPropType(propValue);
      if (propType !== 'object') {
        return new PropTypeError('Invalid ' + location + ' `' + propFullName + '` of type `' + propType + '` ' + ('supplied to `' + componentName + '`, expected `object`.'));
      }
      for (var key in shapeTypes) {
        var checker = shapeTypes[key];
        if (!checker) {
          continue;
        }
        var error = checker(propValue, key, componentName, location, propFullName + '.' + key, ReactPropTypesSecret);
        if (error) {
          return error;
        }
      }
      return null;
    }
    return createChainableTypeChecker(validate);
  }

  function createStrictShapeTypeChecker(shapeTypes) {
    function validate(props, propName, componentName, location, propFullName) {
      var propValue = props[propName];
      var propType = getPropType(propValue);
      if (propType !== 'object') {
        return new PropTypeError('Invalid ' + location + ' `' + propFullName + '` of type `' + propType + '` ' + ('supplied to `' + componentName + '`, expected `object`.'));
      }
      // We need to check all keys in case some are required but missing from
      // props.
      var allKeys = assign({}, props[propName], shapeTypes);
      for (var key in allKeys) {
        var checker = shapeTypes[key];
        if (!checker) {
          return new PropTypeError(
            'Invalid ' + location + ' `' + propFullName + '` key `' + key + '` supplied to `' + componentName + '`.' +
            '\nBad object: ' + JSON.stringify(props[propName], null, '  ') +
            '\nValid keys: ' +  JSON.stringify(Object.keys(shapeTypes), null, '  ')
          );
        }
        var error = checker(propValue, key, componentName, location, propFullName + '.' + key, ReactPropTypesSecret);
        if (error) {
          return error;
        }
      }
      return null;
    }

    return createChainableTypeChecker(validate);
  }

  function isNode(propValue) {
    switch (typeof propValue) {
      case 'number':
      case 'string':
      case 'undefined':
        return true;
      case 'boolean':
        return !propValue;
      case 'object':
        if (Array.isArray(propValue)) {
          return propValue.every(isNode);
        }
        if (propValue === null || isValidElement(propValue)) {
          return true;
        }

        var iteratorFn = getIteratorFn(propValue);
        if (iteratorFn) {
          var iterator = iteratorFn.call(propValue);
          var step;
          if (iteratorFn !== propValue.entries) {
            while (!(step = iterator.next()).done) {
              if (!isNode(step.value)) {
                return false;
              }
            }
          } else {
            // Iterator will provide entry [k,v] tuples rather than values.
            while (!(step = iterator.next()).done) {
              var entry = step.value;
              if (entry) {
                if (!isNode(entry[1])) {
                  return false;
                }
              }
            }
          }
        } else {
          return false;
        }

        return true;
      default:
        return false;
    }
  }

  function isSymbol(propType, propValue) {
    // Native Symbol.
    if (propType === 'symbol') {
      return true;
    }

    // 19.4.3.5 Symbol.prototype[@@toStringTag] === 'Symbol'
    if (propValue['@@toStringTag'] === 'Symbol') {
      return true;
    }

    // Fallback for non-spec compliant Symbols which are polyfilled.
    if (typeof Symbol === 'function' && propValue instanceof Symbol) {
      return true;
    }

    return false;
  }

  // Equivalent of `typeof` but with special handling for array and regexp.
  function getPropType(propValue) {
    var propType = typeof propValue;
    if (Array.isArray(propValue)) {
      return 'array';
    }
    if (propValue instanceof RegExp) {
      // Old webkits (at least until Android 4.0) return 'function' rather than
      // 'object' for typeof a RegExp. We'll normalize this here so that /bla/
      // passes PropTypes.object.
      return 'object';
    }
    if (isSymbol(propType, propValue)) {
      return 'symbol';
    }
    return propType;
  }

  // This handles more types than `getPropType`. Only used for error messages.
  // See `createPrimitiveTypeChecker`.
  function getPreciseType(propValue) {
    if (typeof propValue === 'undefined' || propValue === null) {
      return '' + propValue;
    }
    var propType = getPropType(propValue);
    if (propType === 'object') {
      if (propValue instanceof Date) {
        return 'date';
      } else if (propValue instanceof RegExp) {
        return 'regexp';
      }
    }
    return propType;
  }

  // Returns a string that is postfixed to a warning about an invalid type.
  // For example, "undefined" or "of type array"
  function getPostfixForTypeWarning(value) {
    var type = getPreciseType(value);
    switch (type) {
      case 'array':
      case 'object':
        return 'an ' + type;
      case 'boolean':
      case 'date':
      case 'regexp':
        return 'a ' + type;
      default:
        return type;
    }
  }

  // Returns class name of the object, if any.
  function getClassName(propValue) {
    if (!propValue.constructor || !propValue.constructor.name) {
      return ANONYMOUS;
    }
    return propValue.constructor.name;
  }

  ReactPropTypes.checkPropTypes = checkPropTypes;
  ReactPropTypes.PropTypes = ReactPropTypes;

  return ReactPropTypes;
};


/***/ }),
/* 15 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/*
object-assign
(c) Sindre Sorhus
@license MIT
*/


/* eslint-disable no-unused-vars */
var getOwnPropertySymbols = Object.getOwnPropertySymbols;
var hasOwnProperty = Object.prototype.hasOwnProperty;
var propIsEnumerable = Object.prototype.propertyIsEnumerable;

function toObject(val) {
	if (val === null || val === undefined) {
		throw new TypeError('Object.assign cannot be called with null or undefined');
	}

	return Object(val);
}

function shouldUseNative() {
	try {
		if (!Object.assign) {
			return false;
		}

		// Detect buggy property enumeration order in older V8 versions.

		// https://bugs.chromium.org/p/v8/issues/detail?id=4118
		var test1 = new String('abc');  // eslint-disable-line no-new-wrappers
		test1[5] = 'de';
		if (Object.getOwnPropertyNames(test1)[0] === '5') {
			return false;
		}

		// https://bugs.chromium.org/p/v8/issues/detail?id=3056
		var test2 = {};
		for (var i = 0; i < 10; i++) {
			test2['_' + String.fromCharCode(i)] = i;
		}
		var order2 = Object.getOwnPropertyNames(test2).map(function (n) {
			return test2[n];
		});
		if (order2.join('') !== '0123456789') {
			return false;
		}

		// https://bugs.chromium.org/p/v8/issues/detail?id=3056
		var test3 = {};
		'abcdefghijklmnopqrst'.split('').forEach(function (letter) {
			test3[letter] = letter;
		});
		if (Object.keys(Object.assign({}, test3)).join('') !==
				'abcdefghijklmnopqrst') {
			return false;
		}

		return true;
	} catch (err) {
		// We don't expect any of the above to throw, but better to be safe.
		return false;
	}
}

module.exports = shouldUseNative() ? Object.assign : function (target, source) {
	var from;
	var to = toObject(target);
	var symbols;

	for (var s = 1; s < arguments.length; s++) {
		from = Object(arguments[s]);

		for (var key in from) {
			if (hasOwnProperty.call(from, key)) {
				to[key] = from[key];
			}
		}

		if (getOwnPropertySymbols) {
			symbols = getOwnPropertySymbols(from);
			for (var i = 0; i < symbols.length; i++) {
				if (propIsEnumerable.call(from, symbols[i])) {
					to[symbols[i]] = from[symbols[i]];
				}
			}
		}
	}

	return to;
};


/***/ }),
/* 16 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/**
 * Copyright (c) 2013-present, Facebook, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */



if (Object({"DRAGGABLE_DEBUG":undefined}).NODE_ENV !== 'production') {
  var invariant = __webpack_require__(2);
  var warning = __webpack_require__(8);
  var ReactPropTypesSecret = __webpack_require__(3);
  var loggedTypeFailures = {};
}

/**
 * Assert that the values match with the type specs.
 * Error messages are memorized and will only be shown once.
 *
 * @param {object} typeSpecs Map of name to a ReactPropType
 * @param {object} values Runtime values that need to be type-checked
 * @param {string} location e.g. "prop", "context", "child context"
 * @param {string} componentName Name of the component for error messages.
 * @param {?Function} getStack Returns the component stack.
 * @private
 */
function checkPropTypes(typeSpecs, values, location, componentName, getStack) {
  if (Object({"DRAGGABLE_DEBUG":undefined}).NODE_ENV !== 'production') {
    for (var typeSpecName in typeSpecs) {
      if (typeSpecs.hasOwnProperty(typeSpecName)) {
        var error;
        // Prop type validation may throw. In case they do, we don't want to
        // fail the render phase where it didn't fail before. So we log it.
        // After these have been cleaned up, we'll let them throw.
        try {
          // This is intentionally an invariant that gets caught. It's the same
          // behavior as without this statement except with a better message.
          invariant(typeof typeSpecs[typeSpecName] === 'function', '%s: %s type `%s` is invalid; it must be a function, usually from ' + 'the `prop-types` package, but received `%s`.', componentName || 'React class', location, typeSpecName, typeof typeSpecs[typeSpecName]);
          error = typeSpecs[typeSpecName](values, typeSpecName, componentName, location, null, ReactPropTypesSecret);
        } catch (ex) {
          error = ex;
        }
        warning(!error || error instanceof Error, '%s: type specification of %s `%s` is invalid; the type checker ' + 'function must return `null` or an `Error` but returned a %s. ' + 'You may have forgotten to pass an argument to the type checker ' + 'creator (arrayOf, instanceOf, objectOf, oneOf, oneOfType, and ' + 'shape all require an argument).', componentName || 'React class', location, typeSpecName, typeof error);
        if (error instanceof Error && !(error.message in loggedTypeFailures)) {
          // Only monitor this failure once because there tends to be a lot of the
          // same error.
          loggedTypeFailures[error.message] = true;

          var stack = getStack ? getStack() : '';

          warning(false, 'Failed %s type: %s%s', location, error.message, stack != null ? stack : '');
        }
      }
    }
  }
}

module.exports = checkPropTypes;


/***/ }),
/* 17 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/**
 * Copyright (c) 2013-present, Facebook, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */



var emptyFunction = __webpack_require__(1);
var invariant = __webpack_require__(2);
var ReactPropTypesSecret = __webpack_require__(3);

module.exports = function() {
  function shim(props, propName, componentName, location, propFullName, secret) {
    if (secret === ReactPropTypesSecret) {
      // It is still safe when called from React.
      return;
    }
    invariant(
      false,
      'Calling PropTypes validators directly is not supported by the `prop-types` package. ' +
      'Use PropTypes.checkPropTypes() to call them. ' +
      'Read more at http://fb.me/use-check-prop-types'
    );
  };
  shim.isRequired = shim;
  function getShim() {
    return shim;
  };
  // Important!
  // Keep this list in sync with production version in `./factoryWithTypeCheckers.js`.
  var ReactPropTypes = {
    array: shim,
    bool: shim,
    func: shim,
    number: shim,
    object: shim,
    string: shim,
    symbol: shim,

    any: shim,
    arrayOf: getShim,
    element: shim,
    instanceOf: getShim,
    node: shim,
    objectOf: getShim,
    oneOf: getShim,
    oneOfType: getShim,
    shape: getShim,
    exact: getShim
  };

  ReactPropTypes.checkPropTypes = emptyFunction;
  ReactPropTypes.PropTypes = ReactPropTypes;

  return ReactPropTypes;
};


/***/ }),
/* 18 */
/***/ (function(module, exports, __webpack_require__) {

var __WEBPACK_AMD_DEFINE_ARRAY__, __WEBPACK_AMD_DEFINE_RESULT__;/*!
  Copyright (c) 2016 Jed Watson.
  Licensed under the MIT License (MIT), see
  http://jedwatson.github.io/classnames
*/
/* global define */

(function () {
	'use strict';

	var hasOwn = {}.hasOwnProperty;

	function classNames () {
		var classes = [];

		for (var i = 0; i < arguments.length; i++) {
			var arg = arguments[i];
			if (!arg) continue;

			var argType = typeof arg;

			if (argType === 'string' || argType === 'number') {
				classes.push(arg);
			} else if (Array.isArray(arg)) {
				classes.push(classNames.apply(null, arg));
			} else if (argType === 'object') {
				for (var key in arg) {
					if (hasOwn.call(arg, key) && arg[key]) {
						classes.push(key);
					}
				}
			}
		}

		return classes.join(' ');
	}

	if (typeof module !== 'undefined' && module.exports) {
		module.exports = classNames;
	} else if (true) {
		// register as 'classnames', consistent with npm package name
		!(__WEBPACK_AMD_DEFINE_ARRAY__ = [], __WEBPACK_AMD_DEFINE_RESULT__ = function () {
			return classNames;
		}.apply(exports, __WEBPACK_AMD_DEFINE_ARRAY__),
				__WEBPACK_AMD_DEFINE_RESULT__ !== undefined && (module.exports = __WEBPACK_AMD_DEFINE_RESULT__));
	} else {}
}());


/***/ }),
/* 19 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.getPrefix = getPrefix;
exports.browserPrefixToKey = browserPrefixToKey;
exports.browserPrefixToStyle = browserPrefixToStyle;
var prefixes = ['Moz', 'Webkit', 'O', 'ms'];
function getPrefix() /*: string*/ {
  var prop /*: string*/ = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : 'transform';

  // Checking specifically for 'window.document' is for pseudo-browser server-side
  // environments that define 'window' as the global context.
  // E.g. React-rails (see https://github.com/reactjs/react-rails/pull/84)
  if (typeof window === 'undefined' || typeof window.document === 'undefined') return '';

  var style = window.document.documentElement.style;

  if (prop in style) return '';

  for (var i = 0; i < prefixes.length; i++) {
    if (browserPrefixToKey(prop, prefixes[i]) in style) return prefixes[i];
  }

  return '';
}

function browserPrefixToKey(prop /*: string*/, prefix /*: string*/) /*: string*/ {
  return prefix ? '' + prefix + kebabToTitleCase(prop) : prop;
}

function browserPrefixToStyle(prop /*: string*/, prefix /*: string*/) /*: string*/ {
  return prefix ? '-' + prefix.toLowerCase() + '-' + prop : prop;
}

function kebabToTitleCase(str /*: string*/) /*: string*/ {
  var out = '';
  var shouldCapitalize = true;
  for (var i = 0; i < str.length; i++) {
    if (shouldCapitalize) {
      out += str[i].toUpperCase();
      shouldCapitalize = false;
    } else if (str[i] === '-') {
      shouldCapitalize = true;
    } else {
      out += str[i];
    }
  }
  return out;
}

// Default export is the prefix itself, like 'Moz', 'Webkit', etc
// Note that you may have to re-test for certain things; for instance, Chrome 50
// can handle unprefixed `transform`, but not unprefixed `user-select`
exports.default = getPrefix();

/***/ }),
/* 20 */
/***/ (function(module, exports) {

// shim for using process in browser
var process = module.exports = {};

// cached from whatever global is present so that test runners that stub it
// don't break things.  But we need to wrap it in a try catch in case it is
// wrapped in strict mode code which doesn't define any globals.  It's inside a
// function because try/catches deoptimize in certain engines.

var cachedSetTimeout;
var cachedClearTimeout;

function defaultSetTimout() {
    throw new Error('setTimeout has not been defined');
}
function defaultClearTimeout () {
    throw new Error('clearTimeout has not been defined');
}
(function () {
    try {
        if (typeof setTimeout === 'function') {
            cachedSetTimeout = setTimeout;
        } else {
            cachedSetTimeout = defaultSetTimout;
        }
    } catch (e) {
        cachedSetTimeout = defaultSetTimout;
    }
    try {
        if (typeof clearTimeout === 'function') {
            cachedClearTimeout = clearTimeout;
        } else {
            cachedClearTimeout = defaultClearTimeout;
        }
    } catch (e) {
        cachedClearTimeout = defaultClearTimeout;
    }
} ())
function runTimeout(fun) {
    if (cachedSetTimeout === setTimeout) {
        //normal enviroments in sane situations
        return setTimeout(fun, 0);
    }
    // if setTimeout wasn't available but was latter defined
    if ((cachedSetTimeout === defaultSetTimout || !cachedSetTimeout) && setTimeout) {
        cachedSetTimeout = setTimeout;
        return setTimeout(fun, 0);
    }
    try {
        // when when somebody has screwed with setTimeout but no I.E. maddness
        return cachedSetTimeout(fun, 0);
    } catch(e){
        try {
            // When we are in I.E. but the script has been evaled so I.E. doesn't trust the global object when called normally
            return cachedSetTimeout.call(null, fun, 0);
        } catch(e){
            // same as above but when it's a version of I.E. that must have the global object for 'this', hopfully our context correct otherwise it will throw a global error
            return cachedSetTimeout.call(this, fun, 0);
        }
    }


}
function runClearTimeout(marker) {
    if (cachedClearTimeout === clearTimeout) {
        //normal enviroments in sane situations
        return clearTimeout(marker);
    }
    // if clearTimeout wasn't available but was latter defined
    if ((cachedClearTimeout === defaultClearTimeout || !cachedClearTimeout) && clearTimeout) {
        cachedClearTimeout = clearTimeout;
        return clearTimeout(marker);
    }
    try {
        // when when somebody has screwed with setTimeout but no I.E. maddness
        return cachedClearTimeout(marker);
    } catch (e){
        try {
            // When we are in I.E. but the script has been evaled so I.E. doesn't  trust the global object when called normally
            return cachedClearTimeout.call(null, marker);
        } catch (e){
            // same as above but when it's a version of I.E. that must have the global object for 'this', hopfully our context correct otherwise it will throw a global error.
            // Some versions of I.E. have different rules for clearTimeout vs setTimeout
            return cachedClearTimeout.call(this, marker);
        }
    }



}
var queue = [];
var draining = false;
var currentQueue;
var queueIndex = -1;

function cleanUpNextTick() {
    if (!draining || !currentQueue) {
        return;
    }
    draining = false;
    if (currentQueue.length) {
        queue = currentQueue.concat(queue);
    } else {
        queueIndex = -1;
    }
    if (queue.length) {
        drainQueue();
    }
}

function drainQueue() {
    if (draining) {
        return;
    }
    var timeout = runTimeout(cleanUpNextTick);
    draining = true;

    var len = queue.length;
    while(len) {
        currentQueue = queue;
        queue = [];
        while (++queueIndex < len) {
            if (currentQueue) {
                currentQueue[queueIndex].run();
            }
        }
        queueIndex = -1;
        len = queue.length;
    }
    currentQueue = null;
    draining = false;
    runClearTimeout(timeout);
}

process.nextTick = function (fun) {
    var args = new Array(arguments.length - 1);
    if (arguments.length > 1) {
        for (var i = 1; i < arguments.length; i++) {
            args[i - 1] = arguments[i];
        }
    }
    queue.push(new Item(fun, args));
    if (queue.length === 1 && !draining) {
        runTimeout(drainQueue);
    }
};

// v8 likes predictible objects
function Item(fun, array) {
    this.fun = fun;
    this.array = array;
}
Item.prototype.run = function () {
    this.fun.apply(null, this.array);
};
process.title = 'browser';
process.browser = true;
process.env = {};
process.argv = [];
process.version = ''; // empty string to avoid regexp issues
process.versions = {};

function noop() {}

process.on = noop;
process.addListener = noop;
process.once = noop;
process.off = noop;
process.removeListener = noop;
process.removeAllListeners = noop;
process.emit = noop;
process.prependListener = noop;
process.prependOnceListener = noop;

process.listeners = function (name) { return [] }

process.binding = function (name) {
    throw new Error('process.binding is not supported');
};

process.cwd = function () { return '/' };
process.chdir = function (dir) {
    throw new Error('process.chdir is not supported');
};
process.umask = function() { return 0; };


/***/ })
/******/ ]);
});
//# sourceMappingURL=react-draggable.js.map

/***/ }),

/***/ 2049:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _button = __webpack_require__(3093);

var _button2 = _interopRequireDefault(_button);

var _buttonGroup = __webpack_require__(3096);

var _buttonGroup2 = _interopRequireDefault(_buttonGroup);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

_button2['default'].Group = _buttonGroup2['default'];
exports['default'] = _button2['default'];
module.exports = exports['default'];

/***/ }),

/***/ 2050:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.getLinkBoxPosition = getLinkBoxPosition;
var HOST_BOTTOM_OFFSET = exports.HOST_BOTTOM_OFFSET = 40;
function getLinkBoxPosition(hostBounds, rect, boxLayout, needOffset, embed) {
    var menuStyles = {
        top: rect.y + rect.height,
        left: rect.x,
        position: 'top',
        arrowLeft: '50%'
    };
    var realHostHeight = hostBounds.height,
        realHostTop = hostBounds.top,
        realHostLeft = hostBounds.left;

    var hostHeight = needOffset ? realHostHeight - HOST_BOTTOM_OFFSET : realHostHeight;
    if (!embed && menuStyles.top + boxLayout.height > hostHeight) {
        menuStyles.top = menuStyles.top - (boxLayout.height + rect.height) - 6;
        menuStyles.position = 'bottom';
    }
    if (menuStyles.left < 0) {
        menuStyles.left = 0;
    }
    var top = menuStyles.top;
    var left = menuStyles.left;
    if (embed) {
        top += realHostTop;
        left += realHostLeft;
    }
    return {
        top: top + 'px',
        left: left + 'px',
        position: menuStyles.position
    };
}

/***/ }),

/***/ 2051:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.ToolbarMenuButton = undefined;

var _dropdown = __webpack_require__(3131);

var _dropdown2 = _interopRequireDefault(_dropdown);

var _objectWithoutProperties2 = __webpack_require__(26);

var _objectWithoutProperties3 = _interopRequireDefault(_objectWithoutProperties2);

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _isFunction2 = __webpack_require__(100);

var _isFunction3 = _interopRequireDefault(_isFunction2);

var _omit2 = __webpack_require__(720);

var _omit3 = _interopRequireDefault(_omit2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _caret = __webpack_require__(2053);

var _caret2 = _interopRequireDefault(_caret);

var _ToolbarButton = __webpack_require__(1679);

__webpack_require__(3133);

__webpack_require__(3134);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

// 此处请保持?react,而不要使用?clean清除期填充色
var ToolbarMenuButton = exports.ToolbarMenuButton = function (_React$Component) {
    (0, _inherits3.default)(ToolbarMenuButton, _React$Component);

    function ToolbarMenuButton() {
        (0, _classCallCheck3.default)(this, ToolbarMenuButton);

        // etherpad 滚动区，如果有，则说明是在 Doc 插 Sheet 中
        var _this = (0, _possibleConstructorReturn3.default)(this, (ToolbarMenuButton.__proto__ || Object.getPrototypeOf(ToolbarMenuButton)).apply(this, arguments));

        _this._scrollDom = null;
        _this.state = {
            menuVisible: false
        };
        _this.handleUpdateTargetPosition = function () {
            if (_this.state.menuVisible) {
                _this.setState({
                    menuVisible: false
                });
            }
        };
        _this.onVisibleChange = function (visible) {
            _this.setState({
                menuVisible: visible
            });
            var onMenuVisibleChange = _this.props.onMenuVisibleChange;

            if (onMenuVisibleChange) {
                onMenuVisibleChange(visible);
            }
        };
        _this.onClick = function (param) {
            if (!param || !param.menuVisible) {
                _this.onVisibleChange(false);
            } else if (param.menuVisible !== _this.state.menuVisible) {
                _this.onVisibleChange(param.menuVisible); // 点击选择dropmenu里的选项时是否关闭dropmenu
            }
            var menu = _this.props.menu;
            menu.props.onClick(param);
        };
        _this.handleOnScroll = function () {
            _this.setState({
                menuVisible: false
            });
        };
        return _this;
    }

    (0, _createClass3.default)(ToolbarMenuButton, [{
        key: 'componentDidMount',
        value: function componentDidMount() {
            this._scrollDom = document.querySelector('.etherpad-container-wrapper');
        }
    }, {
        key: 'componentDidUpdate',
        value: function componentDidUpdate() {
            if (this._scrollDom) {
                if (this.state.menuVisible) {
                    this._scrollDom.addEventListener('scroll', this.handleOnScroll);
                } else {
                    this._scrollDom.removeEventListener('scroll', this.handleOnScroll);
                }
            }
        }
        // // 获取当前dropdown的父组件ref. 注意是方法调用
        // getContainerDomRef = () => {
        //   const { getDomRef } = this.props;
        //   const popupContainer = getDomRef && getDomRef() || document.body;
        //   return popupContainer;
        // }

    }, {
        key: 'render',
        value: function render() {
            var prefixCls = this.props.prefixCls;
            var _props = this.props,
                menu = _props.menu,
                children = _props.children,
                onMenuVisibleChange = _props.onMenuVisibleChange,
                other = (0, _objectWithoutProperties3.default)(_props, ['menu', 'children', 'onMenuVisibleChange']);

            var sheetComponentName = other.title || 'toolbar-menu-button';
            var menuVisible = this.state.menuVisible;

            var newMenu = menu;
            if (_react2.default.isValidElement(menu)) {
                newMenu = _react2.default.cloneElement(menu, {
                    onClick: this.onClick,
                    menuVisible: menuVisible
                });
            }
            prefixCls = prefixCls || 'sheet-dropdown';
            return _react2.default.createElement(_dropdown2.default, { prefixCls: prefixCls, overlay: newMenu, placement: "bottomCenter", trigger: other.disabled ? [] : ['click'], disabled: other.disabled, visible: menuVisible,
                // getPopupContainer={this.getContainerDomRef}
                onVisibleChange: this.onVisibleChange }, _react2.default.createElement("div", { "data-sheet-component": sheetComponentName }, _react2.default.createElement(_ToolbarButton.ToolbarButton, Object.assign({ blockClass: "toolbar-menu-button", tipHidden: menuVisible }, other), function (prop) {
                var propWithoutRef = (0, _omit3.default)(prop, 'getDomRef');
                var child = (0, _isFunction3.default)(children) ? children(propWithoutRef) : children;
                return [child && _react2.default.cloneElement(child, { key: 'button' }), _react2.default.createElement(_caret2.default, { key: "caret", className: "toolbar-menu-button__caret" })];
            })));
        }
    }]);
    return ToolbarMenuButton;
}(_react2.default.Component);

/***/ }),

/***/ 2052:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var React = _interopRequireWildcard(_react);

var _rcDropdown = __webpack_require__(3251);

var _rcDropdown2 = _interopRequireDefault(_rcDropdown);

var _classnames = __webpack_require__(29);

var _classnames2 = _interopRequireDefault(_classnames);

var _warning = __webpack_require__(1819);

var _warning2 = _interopRequireDefault(_warning);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj['default'] = obj; return newObj; } }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

var Dropdown = function (_React$Component) {
    (0, _inherits3['default'])(Dropdown, _React$Component);

    function Dropdown() {
        (0, _classCallCheck3['default'])(this, Dropdown);
        return (0, _possibleConstructorReturn3['default'])(this, (Dropdown.__proto__ || Object.getPrototypeOf(Dropdown)).apply(this, arguments));
    }

    (0, _createClass3['default'])(Dropdown, [{
        key: 'getTransitionName',
        value: function getTransitionName() {
            var _props = this.props,
                _props$placement = _props.placement,
                placement = _props$placement === undefined ? '' : _props$placement,
                transitionName = _props.transitionName;

            if (transitionName !== undefined) {
                return transitionName;
            }
            if (placement.indexOf('top') >= 0) {
                return 'slide-down';
            }
            return 'slide-up';
        }
    }, {
        key: 'componentDidMount',
        value: function componentDidMount() {
            var overlay = this.props.overlay;

            if (overlay) {
                var overlayProps = overlay.props;
                (0, _warning2['default'])(!overlayProps.mode || overlayProps.mode === 'vertical', 'mode="' + overlayProps.mode + '" is not supported for Dropdown\'s Menu.');
            }
        }
    }, {
        key: 'render',
        value: function render() {
            var _props2 = this.props,
                children = _props2.children,
                prefixCls = _props2.prefixCls,
                overlayElements = _props2.overlay,
                trigger = _props2.trigger,
                disabled = _props2.disabled;

            var child = React.Children.only(children);
            var overlay = React.Children.only(overlayElements);
            var dropdownTrigger = React.cloneElement(child, {
                className: (0, _classnames2['default'])(child.props.className, prefixCls + '-trigger'),
                disabled: disabled
            });
            // menu cannot be selectable in dropdown defaultly
            // menu should be focusable in dropdown defaultly
            var _overlay$props = overlay.props,
                _overlay$props$select = _overlay$props.selectable,
                selectable = _overlay$props$select === undefined ? false : _overlay$props$select,
                _overlay$props$focusa = _overlay$props.focusable,
                focusable = _overlay$props$focusa === undefined ? true : _overlay$props$focusa;

            var fixedModeOverlay = typeof overlay.type === 'string' ? overlay : React.cloneElement(overlay, {
                mode: 'vertical',
                selectable: selectable,
                focusable: focusable
            });
            var triggerActions = disabled ? [] : trigger;
            var alignPoint = void 0;
            if (triggerActions && triggerActions.indexOf('contextMenu') !== -1) {
                alignPoint = true;
            }
            return React.createElement(
                _rcDropdown2['default'],
                (0, _extends3['default'])({ alignPoint: alignPoint }, this.props, { transitionName: this.getTransitionName(), trigger: triggerActions, overlay: fixedModeOverlay }),
                dropdownTrigger
            );
        }
    }]);
    return Dropdown;
}(React.Component);

exports['default'] = Dropdown;

Dropdown.defaultProps = {
    prefixCls: 'ant-dropdown',
    mouseEnterDelay: 0.15,
    mouseLeaveDelay: 0.1,
    placement: 'bottomLeft'
};
module.exports = exports['default'];

/***/ }),

/***/ 2053:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "12", height: "12", viewBox: "0 0 12 12", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M6 6.3l2.65-2.65a.5.5 0 1 1 .7.7L6 7.71 2.65 4.35a.5.5 0 1 1 .7-.7L6 6.29z", fill: "#606873", fillRule: "nonzero" })
  );
};

/***/ }),

/***/ 2054:
/***/ (function(module, exports, __webpack_require__) {

var arrayMap = __webpack_require__(161),
    baseIteratee = __webpack_require__(90),
    basePickBy = __webpack_require__(773),
    getAllKeysIn = __webpack_require__(539);

/**
 * Creates an object composed of the `object` properties `predicate` returns
 * truthy for. The predicate is invoked with two arguments: (value, key).
 *
 * @static
 * @memberOf _
 * @since 4.0.0
 * @category Object
 * @param {Object} object The source object.
 * @param {Function} [predicate=_.identity] The function invoked per property.
 * @returns {Object} Returns the new object.
 * @example
 *
 * var object = { 'a': 1, 'b': '2', 'c': 3 };
 *
 * _.pickBy(object, _.isNumber);
 * // => { 'a': 1, 'c': 3 }
 */
function pickBy(object, predicate) {
  if (object == null) {
    return {};
  }
  var props = arrayMap(getAllKeysIn(object), function(prop) {
    return [prop];
  });
  predicate = baseIteratee(predicate);
  return basePickBy(object, props, function(value, path) {
    return predicate(value, path[0]);
  });
}

module.exports = pickBy;


/***/ }),

/***/ 2055:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 2056:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _ColorPicker = __webpack_require__(3152);

Object.keys(_ColorPicker).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function get() {
      return _ColorPicker[key];
    }
  });
});

/***/ }),

/***/ 2057:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.ColorWrap = undefined;

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _debounce = __webpack_require__(275);

var _debounce2 = _interopRequireDefault(_debounce);

var _colorHelper = __webpack_require__(3156);

var colorHelper = _interopRequireWildcard(_colorHelper);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var ColorWrap = exports.ColorWrap = function ColorWrap(Picker) {
    return _a = function (_PureComponent) {
        (0, _inherits3.default)(ColorPicker, _PureComponent);

        function ColorPicker(props) {
            (0, _classCallCheck3.default)(this, ColorPicker);

            var _this = (0, _possibleConstructorReturn3.default)(this, (ColorPicker.__proto__ || Object.getPrototypeOf(ColorPicker)).call(this, props));

            _this.handleChange = function (data) {
                var colors = colorHelper.toState(data, data.h || _this.state.oldHue);
                _this.setState(colors);
                _this.props.onClick && _this.props.onClick(colors);
                _this.props.onChange && _this.props.onChange(colors);
                _this.props.onChangeComplete && _this.debounce(_this.props.onChangeComplete, colors);
            };
            _this.state = colorHelper.toState(props.color, 0);
            _this.debounce = (0, _debounce2.default)(function (fn, data) {
                return fn(data);
            }, 100);
            return _this;
        }

        (0, _createClass3.default)(ColorPicker, [{
            key: 'componentWillReceiveProps',
            value: function componentWillReceiveProps(nextProps) {
                if (this.props.color !== nextProps.color) {
                    this.setState(colorHelper.toState(nextProps.color, this.state.oldHue));
                }
            }
        }, {
            key: 'componentWillUnmount',
            value: function componentWillUnmount() {
                this.debounce.cancel();
            }
        }, {
            key: 'render',
            value: function render() {
                return _react2.default.createElement(Picker, Object.assign({}, this.props, this.state, { onChange: this.handleChange }));
            }
        }]);
        return ColorPicker;
    }(_react.PureComponent), _a.defaultProps = {
        color: {
            h: 250,
            s: 0.50,
            l: 0.20,
            a: 1
        }
    }, _a;
    var _a;
};

/***/ }),

/***/ 2058:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ xmlns: "http://www.w3.org/2000/svg", width: "24", height: "24", viewBox: "0 0 24 24", fill: "#424E5D" }, props),
    _react2.default.createElement("path", { d: "M13 7v4h4V7h-4zm-2 0H7v4h4V7zm2 10h4v-4h-4v4zm-2 0v-4H7v4h4zM5.5 5h13c.28 0 .5.22.5.5v13a.5.5 0 0 1-.5.5h-13a.5.5 0 0 1-.5-.5v-13c0-.28.22-.5.5-.5z", fillRule: "nonzero" })
  );
};

/***/ }),

/***/ 2059:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M17 15.59V14a1 1 0 0 1 2 0v5h-5a1 1 0 0 1 0-2h1.59l-2.62-2.62a1 1 0 0 1 1.41-1.41L17 15.59zM8.41 7l2.54 2.54a1 1 0 0 1-1.41 1.41L7 8.41V10a1 1 0 1 1-2 0V5h5a1 1 0 1 1 0 2H8.41z", fillRule: "evenodd" })
  );
};

/***/ }),

/***/ 2060:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.SheetToolbarBase = exports.FORMATTERS = undefined;

var _regenerator = __webpack_require__(13);

var _regenerator2 = _interopRequireDefault(_regenerator);

var _defineProperty2 = __webpack_require__(11);

var _defineProperty3 = _interopRequireDefault(_defineProperty2);

var _asyncToGenerator2 = __webpack_require__(99);

var _asyncToGenerator3 = _interopRequireDefault(_asyncToGenerator2);

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _sheet2 = __webpack_require__(713);

var _slardar = __webpack_require__(2022);

var Slardar = _interopRequireWildcard(_slardar);

var _tea = __webpack_require__(47);

var _string = __webpack_require__(158);

var _utils = __webpack_require__(1575);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _logHelper = __webpack_require__(2021);

var _toolbarHelper = __webpack_require__(1606);

var toolbarHelper = _interopRequireWildcard(_toolbarHelper);

var _modal = __webpack_require__(1623);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var SHEET_HEAD_TOOLBAR = 'sheet_head_toolbar';
var SHEET_OPRATION = 'sheet_opration';
// const IGNORE_FOCUS_CLASS = 'J-ignore-focus';
var FORMATTERS = exports.FORMATTERS = {
    normal: {
        name: t('sheet.conventional'),
        teaName: 'general'
    },
    '@': {
        name: t('sheet.plain_text'),
        teaName: 'plain_text'
    },
    divider1: '',
    '#,##0': {
        name: t('sheet.digital'),
        format: '1,024',
        teaName: 'number'
    },
    '#,##0.00': {
        name: t('sheet.digital_point'),
        format: '1,024.56',
        teaName: 'number(rounded)'
    },
    divider2: '',
    '0%': {
        name: t('sheet.percent'),
        format: '10%',
        teaName: 'percentage'
    },
    '0.00%': {
        name: t('sheet.percent_point'),
        format: '10.24%',
        teaName: 'percentage(rounded)'
    },
    '0.00E+00': {
        name: t('sheet.scientific_count'),
        format: '1.02E+03',
        teaName: 'scientific'
    },
    divider3: '',
    '￥#,##0': {
        name: t('sheet.currency'),
        format: '￥1,024',
        teaName: 'currency'
    },
    '￥#,##0.00': {
        name: t('sheet.currency_count'),
        format: '￥1,024.56',
        teaName: 'currency(rounded)'
    },
    divider4: '',
    'yyyy/mm/dd': {
        name: t('sheet.date'),
        format: '2017/08/10',
        teaName: 'date(yyyy/mm/dd)'
    },
    'yyyy-mm-dd': {
        name: t('sheet.date'),
        format: '2017-08-10',
        teaName: 'date(yyyy-mm-dd)'
    },
    'HH:mm:ss': {
        name: t('sheet.time'),
        format: '23:24:25',
        teaName: 'time'
    },
    'yyyy/mm/dd HH:mm:ss': {
        name: t('sheet.data_time'),
        format: '2017/08/10 23:24:25',
        teaName: 'datetime'
    }
};

var SheetToolbarBase = exports.SheetToolbarBase = function (_React$Component) {
    (0, _inherits3.default)(SheetToolbarBase, _React$Component);

    function SheetToolbarBase(props, context) {
        (0, _classCallCheck3.default)(this, SheetToolbarBase);

        var _this = (0, _possibleConstructorReturn3.default)(this, (SheetToolbarBase.__proto__ || Object.getPrototypeOf(SheetToolbarBase)).call(this, props, context));

        _this.mode = 'default';
        return _this;
    }

    (0, _createClass3.default)(SheetToolbarBase, [{
        key: '_handleButtonClick',
        value: function () {
            var _ref = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee(type, value) {
                var isDefault = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : false;
                var eventArgs = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : null;

                var _props, spread, isFiltered, _props2, cellStatus, rangeStatus, hyperlinkEditor, findbar, dropdownMenu, onComment, hideHyperlinkEditor, showHyperlinkEditor, coord, showFormulaList, hideFindbar, showFindbar, toggleCommentPanel, hideDropdownMenu, showDropdownMenu, sheet, s, cellsCount, _row, col, _sheet, sels, sel, index, spans, _ref2, confirm, shouldExpand, expand, Range, range, frozenRowCount, row, lastSelRow, result, filterSheet, filterRange, allIsHorizonSpan, _range;

                return _regenerator2.default.wrap(function _callee$(_context) {
                    while (1) {
                        switch (_context.prev = _context.next) {
                            case 0:
                                _props = this.props, spread = _props.spread, isFiltered = _props.isFiltered;
                                _props2 = this.props, cellStatus = _props2.cellStatus, rangeStatus = _props2.rangeStatus, hyperlinkEditor = _props2.hyperlinkEditor, findbar = _props2.findbar, dropdownMenu = _props2.dropdownMenu, onComment = _props2.onComment, hideHyperlinkEditor = _props2.hideHyperlinkEditor, showHyperlinkEditor = _props2.showHyperlinkEditor, coord = _props2.coord, showFormulaList = _props2.showFormulaList, hideFindbar = _props2.hideFindbar, showFindbar = _props2.showFindbar, toggleCommentPanel = _props2.toggleCommentPanel, hideDropdownMenu = _props2.hideDropdownMenu, showDropdownMenu = _props2.showDropdownMenu;
                                sheet = spread.getActiveSheet();

                                this._teaHandleButtonClick(type, value, isDefault);
                                if (type !== 'comment' || !spread._context.embed) {
                                    spread.focus();
                                }
                                _context.t0 = type;
                                _context.next = _context.t0 === 'undo' ? 8 : _context.t0 === 'redo' ? 10 : _context.t0 === 'clear' ? 12 : _context.t0 === 'formatter' ? 14 : _context.t0 === 'fontSize' ? 20 : _context.t0 === 'bold' ? 23 : _context.t0 === 'hyperlink' ? 25 : _context.t0 === 'img' ? 28 : _context.t0 === 'italic' ? 30 : _context.t0 === 'underline' ? 32 : _context.t0 === 'lineThrough' ? 32 : _context.t0 === 'foreColor' ? 34 : _context.t0 === 'backColor' ? 34 : _context.t0 === 'frame' ? 37 : _context.t0 === 'merge' ? 39 : _context.t0 === 'hAlign' ? 41 : _context.t0 === 'vAlign' ? 41 : _context.t0 === 'wordWrap' ? 41 : _context.t0 === 'sort' ? 43 : _context.t0 === 'formula' ? 78 : _context.t0 === 'filter' ? 80 : _context.t0 === 'find' ? 85 : _context.t0 === 'comment' ? 88 : _context.t0 === 'dropdownMenu' ? 90 : 93;
                                break;

                            case 8:
                                toolbarHelper.undo(spread);
                                return _context.abrupt('break', 94);

                            case 10:
                                toolbarHelper.redo(spread);
                                return _context.abrupt('break', 94);

                            case 12:
                                toolbarHelper.clear(spread);
                                return _context.abrupt('break', 94);

                            case 14:
                                Slardar.timeStart(_logHelper.SheetEvents.SET_FORMATTER);
                                toolbarHelper.setFormatter(spread, value);
                                s = spread.getActiveSheet();
                                cellsCount = s.getSelections().reduce(function (count, selection) {
                                    var range = s._getActualRange(selection);
                                    return count + range.rowCount * range.colCount;
                                }, 0);

                                Slardar.timeEnd(_logHelper.SheetEvents.SET_FORMATTER, (0, _logHelper.getTagFromCount)(cellsCount));
                                return _context.abrupt('break', 94);

                            case 20:
                                value += 'pt';
                                toolbarHelper.setFontStyle(spread, 'font-size', false, [value], value);
                                return _context.abrupt('break', 94);

                            case 23:
                                toolbarHelper.setFontStyle(spread, 'font-weight', false, [cellStatus.bold ? 'normal' : 'bold']);
                                return _context.abrupt('break', 94);

                            case 25:
                                if (eventArgs) {
                                    eventArgs.nativeEvent.fromSheetToolbar = true;
                                }
                                if (hyperlinkEditor) {
                                    hideHyperlinkEditor();
                                } else {
                                    _row = coord.row, col = coord.col;
                                    _sheet = spread.getActiveSheet();

                                    showHyperlinkEditor(_row, col, _sheet.id(), 'cell');
                                }
                                return _context.abrupt('break', 94);

                            case 28:
                                sheet.trigger(_sheet2.Events.ShowImageUploader);
                                return _context.abrupt('break', 94);

                            case 30:
                                toolbarHelper.setFontStyle(spread, 'font-style', false, [cellStatus.italic ? 'normal' : 'italic']);
                                return _context.abrupt('break', 94);

                            case 32:
                                toolbarHelper.setTextDecoration(spread, _sheet2.TextDecorationType[type], cellStatus[type]);
                                return _context.abrupt('break', 94);

                            case 34:
                                this.setState((0, _defineProperty3.default)({}, type, value));
                                toolbarHelper.setRangeValue(spread, type, value);
                                return _context.abrupt('break', 94);

                            case 37:
                                toolbarHelper.setRangeValue(spread, type, value);
                                return _context.abrupt('break', 94);

                            case 39:
                                if (rangeStatus.mergable) {
                                    if (toolbarHelper.isCleanMerge(spread) || !_utils.utils.canMergeWithFilter(spread.getActiveSheet())) {
                                        toolbarHelper.mergeCells(spread, true);
                                    } else {
                                        (0, _modal.showError)(_modal.ErrorTypes.ERROR_MERGE_CONTAIN_VALUE, {
                                            onConfirm: function onConfirm() {
                                                toolbarHelper.mergeCells(spread, true);
                                                spread.focus();
                                            }
                                        });
                                    }
                                } else if (rangeStatus.splitable) {
                                    toolbarHelper.mergeCells(spread, false);
                                }
                                return _context.abrupt('break', 94);

                            case 41:
                                toolbarHelper.setRangeValue(spread, type, Number(value));
                                return _context.abrupt('break', 94);

                            case 43:
                                if (rangeStatus.sortable) {
                                    _context.next = 45;
                                    break;
                                }

                                return _context.abrupt('return');

                            case 45:
                                sels = sheet.getSelections();
                                sel = sheet._getActualRange(sels[0]);
                                index = sel.col;
                                spans = sheet.getSpans(sel);

                                if (!spans.length) {
                                    _context.next = 52;
                                    break;
                                }

                                (0, _modal.showError)(_modal.ErrorTypes.ERROR_SORT_INCLUDE_MERGE);
                                return _context.abrupt('return');

                            case 52:
                                if (!(sel.colCount === 1)) {
                                    _context.next = 69;
                                    break;
                                }

                                _context.next = 55;
                                return (0, _modal.showExpandSortModal)();

                            case 55:
                                _ref2 = _context.sent;
                                confirm = _ref2.confirm;
                                shouldExpand = _ref2.shouldExpand;

                                if (confirm) {
                                    _context.next = 60;
                                    break;
                                }

                                return _context.abrupt('return');

                            case 60:
                                if (!shouldExpand) {
                                    _context.next = 69;
                                    break;
                                }

                                expand = _utils.utils.getResponsableRange(sheet, sel);
                                Range = GC.Spread.Sheets.Range;
                                range = new Range(expand.row, expand.col, expand.rowCount, expand.colCount);

                                if (!sheet.getSpans(range).length) {
                                    _context.next = 67;
                                    break;
                                }

                                (0, _modal.showError)(_modal.ErrorTypes.ERROR_SORT_INCLUDE_MERGE);
                                return _context.abrupt('return');

                            case 67:
                                sheet.setSelection(range.row, range.col, range.rowCount, range.colCount);
                                sel = sheet._getActualRange(sheet.getSelections()[0]);

                            case 69:
                                // 冻结区域排序规则
                                frozenRowCount = sheet.frozenRowCount();
                                row = sel.row;
                                lastSelRow = sel.rowCount - 1 + row;
                                // 只要处于冻结行内，都不参与排序

                                if (!(lastSelRow <= frozenRowCount)) {
                                    _context.next = 74;
                                    break;
                                }

                                return _context.abrupt('return');

                            case 74:
                                if (row <= frozenRowCount - 1) {
                                    sel.row = frozenRowCount;
                                    sel.rowCount = lastSelRow - frozenRowCount + 1;
                                }
                                result = toolbarHelper.sortRange(spread, sel, index, value === 'asc');

                                if (!result) {
                                    (0, _modal.showError)(_modal.ErrorTypes.ERROR_SORT_INCLUDE_MERGE);
                                }
                                return _context.abrupt('break', 94);

                            case 78:
                                if (value === 'MORE') {
                                    showFormulaList();
                                } else {
                                    toolbarHelper.setFormula(spread, value);
                                }
                                return _context.abrupt('break', 94);

                            case 80:
                                filterSheet = spread.getActiveSheet();
                                filterRange = void 0;

                                if (isFiltered) {
                                    status = 'delFilter';
                                } else {
                                    filterRange = _utils.utils.getFilterRange(filterSheet);
                                    if (filterRange) {
                                        allIsHorizonSpan = filterSheet.getSpans(filterRange).every(function (range) {
                                            return range.rowCount === 1;
                                        });

                                        if (allIsHorizonSpan) {
                                            // 判断选区里合并单元格，只有全是横向合并单元格 || 没有合并单元格，才发筛选command
                                            status = 'setFilter';
                                        } else {
                                            status = 'doNothing';
                                            (0, _modal.showModal)({
                                                title: t('common.prompt'),
                                                body: t('sheet.no_filter_with_merge'),
                                                confirmText: t('common.confirm'),
                                                closable: false,
                                                cancelText: '',
                                                maskClosable: false,
                                                onConfirm: function onConfirm() {
                                                    // todo end filter event
                                                }
                                            });
                                        }
                                    }
                                }
                                toolbarHelper.setFilterAction(status, filterSheet, filterRange);
                                return _context.abrupt('break', 94);

                            case 85:
                                if (!findbar.visible) {
                                    _context.next = 87;
                                    break;
                                }

                                return _context.abrupt('return', hideFindbar());

                            case 87:
                                return _context.abrupt('return', showFindbar(true));

                            case 88:
                                if (spread._context.embed === true) {
                                    onComment && onComment();
                                } else {
                                    _range = sheet._getActiveSelectedRange();

                                    if (_range.row >= 0 && _range.col >= 0) {
                                        toggleCommentPanel(true, {
                                            row: _range.row,
                                            col: _range.col,
                                            focus: true
                                        });
                                    }
                                }
                                return _context.abrupt('break', 94);

                            case 90:
                                if (!dropdownMenu.visible) {
                                    _context.next = 92;
                                    break;
                                }

                                return _context.abrupt('return', hideDropdownMenu());

                            case 92:
                                return _context.abrupt('return', showDropdownMenu());

                            case 93:
                                return _context.abrupt('return', null);

                            case 94:
                            case 'end':
                                return _context.stop();
                        }
                    }
                }, _callee, this);
            }));

            function _handleButtonClick(_x, _x2) {
                return _ref.apply(this, arguments);
            }

            return _handleButtonClick;
        }()
        // open 下拉菜单打点

    }, {
        key: '_handleMenuVisible',
        value: function _handleMenuVisible(type, visable) {
            var spread = this.props.spread;

            spread.focus();
            if (!visable) return;
            (0, _tea.collectSuiteEvent)(SHEET_OPRATION, {
                action: (0, _string.snakeCase)(type) + '_open',
                source: SHEET_HEAD_TOOLBAR,
                eventType: 'click',
                mode: this.mode
            });
        }
    }, {
        key: '_isHyperlinkActive',
        value: function _isHyperlinkActive() {
            var _props3 = this.props,
                cellStatus = _props3.cellStatus,
                hyperlinkEditor = _props3.hyperlinkEditor,
                coord = _props3.coord;
            var hyperlink = cellStatus.hyperlink;

            if (hyperlink) {
                return true;
            }
            if (hyperlinkEditor && hyperlinkEditor.row === coord.row && hyperlinkEditor.col === coord.col) {
                return true;
            }
            return false;
        }
    }, {
        key: '_isHyperlinkDisable',
        value: function _isHyperlinkDisable() {
            var _props4 = this.props,
                spread = _props4.spread,
                coord = _props4.coord;

            if (!spread) {
                return true;
            }
            var sheet = spread.getActiveSheet();
            if (!sheet) {
                return true;
            }
            var formula = sheet.getFormula(coord.row, coord.col);
            if (formula) {
                return true;
            }
            return false;
        }
        // tea 打点
        // isDefault 直接点击 toolbar 按钮触发 true, 点击下拉菜单中的选项触发 false

    }, {
        key: '_teaHandleButtonClick',
        value: function _teaHandleButtonClick(type, value) {
            var isDefault = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : false;
            var spread = this.props.spread;

            var action = '';
            var opStatus = '';
            switch (type) {
                case 'bold':
                    opStatus = value ? 'effective' : 'cancel';
                    break;
                case 'italic':
                    opStatus = value ? 'effective' : 'cancel';
                    break;
                case 'underline':
                    opStatus = value ? 'effective' : 'cancel';
                    break;
                case 'lineThrough':
                    opStatus = value ? 'effective' : 'cancel';
                    break;
                case 'clear':
                    action = 'clear_sheet';
                    break;
                case 'merge':
                    var splitable = value.splitable,
                        mergable = value.mergable;

                    if (mergable) {
                        opStatus = 'effective';
                    } else if (splitable) {
                        opStatus = 'cancel';
                    }
                    action = 'merge_cells';
                    break;
                case 'lineThrough':
                    action = 'font_delete';
                    break;
                case 'underline':
                case 'italic':
                    action = 'font_' + type;
                    break;
                case 'hAlign':
                    action = 'h_align_' + (0, _utils.transHAlignTeaName)(value);
                    break;
                case 'vAlign':
                    action = 'v_align_' + (0, _utils.transVAlignTeaName)(value);
                    break;
                case 'wordWrap':
                    action = 'word_wrap_' + (0, _utils.transWordWrapTeaName)(value);
                    break;
                case 'formula':
                    action = value === 'MORE' ? 'formula_more' : 'formula';
                    break;
                case 'img':
                    action = value + '_img_insert';
                    break;
                case 'pickupToolbar':
                    action = 'pickup_toolbar';
                    break;
                case 'expandToolbar':
                    action = 'expand_toolbar';
                    break;
                case 'filter':
                    opStatus = value ? 'effective' : 'cancel';
                    break;
                case 'frame':
                    action = value.selected === 'color' ? 'frame_color' : 'frame';
                    break;
                default:
                    action = (0, _string.snakeCase)(type);
            }
            action = action || type;
            var data = {
                action: isDefault ? action + '_default' : action,
                source: SHEET_HEAD_TOOLBAR,
                eventType: 'click',
                mode: this.mode,
                file_id: spread._context.token,
                file_type: 'sheet',
                attr_op_status: opStatus
            };
            if (value) {
                data.op_item = type === 'formatter' ? FORMATTERS[value].teaName : type === 'frame' ? value[value.selected] : value;
            }
            (0, _tea.collectSuiteEvent)(SHEET_OPRATION, data);
            // 公式需要上报两个事件
            if (type === 'formula' && value !== 'MORE') {
                (0, _tea.collectSuiteEvent)('click_insert_formula', data);
            }
        }
    }]);
    return SheetToolbarBase;
}(_react2.default.Component);
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 2061:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 2062:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.UndoManger = undefined;

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _cloneDeep2 = __webpack_require__(1620);

var _cloneDeep3 = _interopRequireDefault(_cloneDeep2);

var _bytedXEditor = __webpack_require__(1569);

var _commandManager = __webpack_require__(1672);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var BlockRef = _bytedXEditor.BlockUndoDispatcher.BlockRef;

var BLOCK = 'SHEET';
var MAX_LENGTH = 2147483647;

var UndoManger = exports.UndoManger = function () {
    function UndoManger() {
        (0, _classCallCheck3.default)(this, UndoManger);

        this.blockId = BLOCK;
        this.undoStack = [];
        this.redoStack = [];
        this.embedManageCbs = [];
    }

    (0, _createClass3.default)(UndoManger, [{
        key: 'register',
        value: function register(dispatcher) {
            dispatcher.register(this);
            this.undoDispatcher = dispatcher;
        }
    }, {
        key: 'do',
        value: function _do(cmdData) {
            var undoStackLength = this.undoStack.length;
            if (undoStackLength >= MAX_LENGTH) {
                this.undoStack = this.undoStack.slice(undoStackLength - MAX_LENGTH);
            }
            this.undoStack.push(cmdData);
            this.redoStack = [];
            this.undoDispatcher.do(new BlockRef(BLOCK));
        }
    }, {
        key: 'undo',
        value: function undo() {
            this.undoDispatcher.undo();
        }
    }, {
        key: 'redo',
        value: function redo() {
            this.undoDispatcher.redo();
        }
    }, {
        key: 'clear',
        value: function clear() {
            this.undoStack = [];
            this.redoStack = [];
            this.embedManageCbs = [];
            this.undoDispatcher = null;
        }
    }, {
        key: 'clearBySheetId',
        value: function clearBySheetId(sheetId) {
            this.undoStack = this.undoStack.filter(function (cmdData) {
                return cmdData.sheetId !== sheetId;
            });
            this.redoStack = this.redoStack.filter(function (cmdData) {
                return cmdData.sheetId !== sheetId;
            });
        }
    }, {
        key: 'onUndo',
        value: function onUndo() {
            var cmdData = this.undoStack.pop();
            if (cmdData) {
                this.redoStack.push(cmdData);
                this.notify(cmdData, _commandManager.ActionType.undo);
            }
        }
    }, {
        key: 'onRedo',
        value: function onRedo() {
            var cmdData = this.redoStack.pop();
            if (cmdData) {
                this.undoStack.push(cmdData);
                this.notify(cmdData, _commandManager.ActionType.redo);
            }
        }
    }, {
        key: 'onDo',
        value: function onDo() {
            this.redoStack = [];
        }
    }, {
        key: 'notify',
        value: function notify(cmdData, type) {
            this.embedManageCbs.forEach(function (cb) {
                return cb(cmdData, type);
            });
        }
    }, {
        key: 'onNotify',
        value: function onNotify(embedCb) {
            this.embedManageCbs.push(embedCb);
        }
    }, {
        key: 'offNotify',
        value: function offNotify(embedCb) {
            this.embedManageCbs = this.embedManageCbs.filter(function (cb) {
                return cb !== embedCb;
            });
        }
    }, {
        key: 'export',
        value: function _export() {
            return (0, _cloneDeep3.default)({
                undoStack: this.undoStack,
                redoStack: this.redoStack
            });
        }
    }, {
        key: 'import',
        value: function _import(undoStack, redoStack) {
            if (undoStack) {
                this.undoStack = (0, _cloneDeep3.default)(undoStack);
            }
            if (redoStack) {
                this.redoStack = (0, _cloneDeep3.default)(redoStack);
            }
        }
    }]);
    return UndoManger;
}();

var undoManger = new UndoManger();
exports.default = undoManger;

/***/ }),

/***/ 3056:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.EmbedSheetQuickAccess = exports.EmbedSheetStatusCollector = undefined;

var _DocSheet = __webpack_require__(3057);

var DocSheet = _interopRequireWildcard(_DocSheet);

var _EmbedSheetQuickAccess = __webpack_require__(3241);

var _EmbedSheetQuickAccess2 = _interopRequireDefault(_EmbedSheetQuickAccess);

var _EmbedSheetStatusCollector = __webpack_require__(3246);

var _EmbedSheetStatusCollector2 = _interopRequireDefault(_EmbedSheetStatusCollector);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

exports.EmbedSheetStatusCollector = _EmbedSheetStatusCollector2.default;
exports.EmbedSheetQuickAccess = _EmbedSheetQuickAccess2.default;
exports.default = DocSheet;

/***/ }),

/***/ 3057:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.screenshotPromise = exports.findMention = undefined;

var _regenerator = __webpack_require__(13);

var _regenerator2 = _interopRequireDefault(_regenerator);

var _asyncToGenerator2 = __webpack_require__(99);

var _asyncToGenerator3 = _interopRequireDefault(_asyncToGenerator2);

var findMention = exports.findMention = function () {
    var _ref = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee(mentionId, scrollElement, scrollTopFunc) {
        return _regenerator2.default.wrap(function _callee$(_context) {
            while (1) {
                switch (_context.prev = _context.next) {
                    case 0:
                        _context.t0 = manager;

                        if (!_context.t0) {
                            _context.next = 5;
                            break;
                        }

                        _context.next = 4;
                        return manager.findMention(mentionId, scrollElement, scrollTopFunc);

                    case 4:
                        _context.t0 = _context.sent;

                    case 5:
                        return _context.abrupt('return', _context.t0);

                    case 6:
                    case 'end':
                        return _context.stop();
                }
            }
        }, _callee, this);
    }));

    return function findMention(_x, _x2, _x3) {
        return _ref.apply(this, arguments);
    };
}();

var screenshotPromise = exports.screenshotPromise = function () {
    var _ref2 = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee3() {
        var _this2 = this;

        return _regenerator2.default.wrap(function _callee3$(_context3) {
            while (1) {
                switch (_context3.prev = _context3.next) {
                    case 0:
                        if (!manager) {
                            _context3.next = 6;
                            break;
                        }

                        _context3.next = 3;
                        return manager.screenshot(true);

                    case 3:
                        return _context3.abrupt('return', {
                            done: function () {
                                var _ref3 = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee2() {
                                    return _regenerator2.default.wrap(function _callee2$(_context2) {
                                        while (1) {
                                            switch (_context2.prev = _context2.next) {
                                                case 0:
                                                    if (!manager) {
                                                        _context2.next = 3;
                                                        break;
                                                    }

                                                    _context2.next = 3;
                                                    return manager.screenshot(false);

                                                case 3:
                                                case 'end':
                                                    return _context2.stop();
                                            }
                                        }
                                    }, _callee2, _this2);
                                }));

                                return function done() {
                                    return _ref3.apply(this, arguments);
                                };
                            }()
                        });

                    case 6:
                        throw new Error('EmbedSheetManager NULL');

                    case 7:
                    case 'end':
                        return _context3.stop();
                }
            }
        }, _callee3, this);
    }));

    return function screenshotPromise() {
        return _ref2.apply(this, arguments);
    };
}();

exports.mountSheet = mountSheet;
exports.unmountSheet = unmountSheet;
exports.handleCopy = handleCopy;
exports.setMaxWidth = setMaxWidth;
exports.setSize = setSize;
exports.setZoom = setZoom;
exports.destroy = destroy;
exports.getUpdateTime = getUpdateTime;
exports.freeze = freeze;
exports.unfreeze = unfreeze;
exports.addSheet = addSheet;
exports.pasteSheet = pasteSheet;
exports.delSheet = delSheet;
exports.wakeup = wakeup;
exports.suspend = suspend;
exports.syncVirtualScroll = syncVirtualScroll;
exports.updateSheetSelectionState = updateSheetSelectionState;

var _EmbedSheetManager = __webpack_require__(3058);

var _actions = __webpack_require__(1572);

var _utils = __webpack_require__(1575);

var _undoManager = __webpack_require__(2062);

var _undoManager2 = _interopRequireDefault(_undoManager);

var _html2Snapshot = __webpack_require__(3240);

var _$moirae = __webpack_require__(378);

var _$moirae2 = _interopRequireDefault(_$moirae);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var manager = null;
var maxWidth = 240;
var stashActionList = [];
var mountedToken = '';
// const deletedSheetInfo: Map<string, any> = new Map();
// 方便出问题调试
window.embedSheetManager = manager;
function ensureManager(editor, token, sheetId) {
    if (manager) {
        return manager;
    }
    manager = new _EmbedSheetManager.EmbedSheetManager(token, editor, sheetId);
    manager.setMaxWidth(maxWidth);
    return manager;
}
function mountSheet(options) {
    var _this = this;

    var editor = options.editor,
        token = options.token,
        csQueue = options.csQueue,
        undoDispatcher = options.undoDispatcher,
        sheetId = options.sheetId;

    if (mountedToken.length > 0 && mountedToken !== token) {
        return _$moirae2.default.count('ee.docs.sheet.embed_manager_token_diff');
    }
    mountedToken = token;
    manager = ensureManager(editor, token, sheetId);
    if (stashActionList) {
        stashActionList.forEach(function (item) {
            manager[item.key] && manager[item.key].call(_this, item.action);
        });
        stashActionList = [];
    }
    manager.registerCSQueue(csQueue);
    manager.mountSheet(options);
    _undoManager2.default.register(undoDispatcher);
}
function unmountSheet(sheetId) {
    if (!manager) {
        return;
    }
    console.log('UnMountSheet: ' + sheetId);
    manager.unmountSheet(sheetId);
}
function handleCopy(editor, token, sheetId) {
    manager = ensureManager(editor, token);
    if (!manager) {
        return '';
    }
    return manager.handleCopy(sheetId);
}
function setMaxWidth(width) {
    if (manager && width !== maxWidth) {
        maxWidth = width;
        manager.setMaxWidth(width);
    }
}
function setSize(width, height) {
    if (manager) {
        manager.setSize(width, height);
    }
}
function setZoom(zoom) {
    manager && manager.setZoom(zoom);
}
function destroy() {
    mountedToken = '';
    if (manager) {
        manager.destroy();
        window.embedSheetManagers = manager = null;
    }
    _undoManager2.default.clear();
}
function getUpdateTime() {
    return manager ? manager.updateTime : 0;
}
function freeze() {
    if (manager) {
        manager.freezeView();
    }
}
function unfreeze(token) {
    if (manager) {
        manager.unfreezeView();
    }
}
function getCopySheetAction(sheetId, sheetName, index, rowCount, columnCount) {
    return {
        action: _actions.ACTIONS.COPY_SHEET,
        sheet_id: sheetId,
        value: {
            index: index,
            sheet_id: sheetId,
            sheet_name: sheetName,
            snapshot: {
                id: sheetId,
                index: index,
                name: sheetName,
                rowCount: rowCount,
                columnCount: columnCount
            }
        }
    };
}
function getSheetInfo() {
    var id = (0, _utils.genSheetId)();
    var index = 0;
    var baseRev = 0;
    var name = id;
    if (manager) {
        var ids = manager.sheetIds;
        id = (0, _utils.genSheetId)(ids);
        name = id;
        index = ids.length;
        baseRev = manager.baseRev;
    }
    return { id: id, name: name, index: index, baseRev: baseRev };
}
function addSheet(rowCount, columnCount) {
    var _getSheetInfo = getSheetInfo(),
        id = _getSheetInfo.id,
        name = _getSheetInfo.name,
        index = _getSheetInfo.index,
        baseRev = _getSheetInfo.baseRev;

    var action = getCopySheetAction(id, name, index, rowCount, columnCount);
    if (manager) {
        manager.addSheet(action);
    } else {
        stashActionList.push({
            key: 'addSheet',
            action: action
        });
    }
    return {
        base_rev: baseRev,
        content: [action]
    };
}
function pasteSheet(styles, table) {
    var _getSheetInfo2 = getSheetInfo(),
        id = _getSheetInfo2.id,
        name = _getSheetInfo2.name,
        index = _getSheetInfo2.index,
        baseRev = _getSheetInfo2.baseRev;

    var action = getCopySheetAction(id, name, index, 1, 1);
    if (Array.isArray(styles)) table = styles.join('') + table;
    var snap = (0, _html2Snapshot.parseHtml2Snapshot)(table);
    if (snap !== null) {
        Object.assign(action.value.snapshot, snap);
    }
    if (manager) {
        manager.pasteSheet(action);
    } else {
        stashActionList.push({
            key: 'pasteSheet',
            action: action
        });
    }
    return {
        base_rev: baseRev,
        content: [action]
    };
}
function delSheet(sheetId) {
    unmountSheet(sheetId);
}
function wakeup(sheetToken, sheetId) {
    manager && manager.wakeup(sheetId);
}
function suspend(sheetToken, sheetId) {
    manager && manager.suspend(sheetId);
}
/**
 * 让每个 sheet 检查一下是否需要 wakeup 或 suspend
 */
function syncVirtualScroll(sheetToken) {
    manager && manager.syncVirtualScroll();
}
function updateSheetSelectionState(sheetId, isSelect) {
    manager && manager.updateSheetSelectionState(sheetId, isSelect);
}

window.findMention = findMention;
window.screenshotPromise = screenshotPromise;

/***/ }),

/***/ 3058:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.EmbedSheetManager = undefined;

var _regenerator = __webpack_require__(13);

var _regenerator2 = _interopRequireDefault(_regenerator);

var _asyncToGenerator2 = __webpack_require__(99);

var _asyncToGenerator3 = _interopRequireDefault(_asyncToGenerator2);

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _range2 = __webpack_require__(1739);

var _range3 = _interopRequireDefault(_range2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _reactDom = __webpack_require__(21);

var _reactDom2 = _interopRequireDefault(_reactDom);

var _reactRedux = __webpack_require__(238);

var _$store = __webpack_require__(83);

var _$store2 = _interopRequireDefault(_$store);

var _sheet = __webpack_require__(715);

var _encode = __webpack_require__(1676);

var _collaborative = __webpack_require__(1607);

var _sync = __webpack_require__(2027);

var _engine = __webpack_require__(2025);

var _Spread = __webpack_require__(1802);

var _backup = __webpack_require__(1713);

var _sheetHelper = __webpack_require__(1615);

var _DataStore = __webpack_require__(3059);

var _modal = __webpack_require__(1623);

var _PerformanceEmbedSheet = __webpack_require__(3062);

var _PerformanceEmbedSheet2 = _interopRequireDefault(_PerformanceEmbedSheet);

var _tea = __webpack_require__(47);

var _utils = __webpack_require__(1575);

var _EmbedSheetManagerImp = __webpack_require__(3066);

var _EmbedSheetManagerImp2 = _interopRequireDefault(_EmbedSheetManagerImp);

var _$moirae = __webpack_require__(378);

var _$moirae2 = _interopRequireDefault(_$moirae);

var _browserHelper = __webpack_require__(34);

var _browserHelper2 = _interopRequireDefault(_browserHelper);

__webpack_require__(2061);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var raf = window.setTimeout;
var unraf = window.clearTimeout;
// 如果是Edge浏览器，需要将raf绑定至window
if (window.requestAnimationFrame) {
    raf = window.requestAnimationFrame;
    unraf = window.cancelAnimationFrame;
    if (_browserHelper2.default.isEdge || _browserHelper2.default.isIE) {
        raf = raf.bind(window);
        unraf = unraf.bind(window);
    }
}

var EmbedSheetManager = function () {
    function EmbedSheetManager(token, _editor, sheetId) {
        var _this = this;

        (0, _classCallCheck3.default)(this, EmbedSheetManager);

        this._editor = _editor;
        this.maxWidth = 1;
        this.mountOptions = {};
        this.sheetComponents = new Map();
        this.hosts = {};
        this.mountCallbacks = {};
        this.mountQueue = [];
        this.mounting = null;
        this.rafId = null;
        this.spreadLoaded = false;
        this.needUniqFitRow = {};
        this.actionAfterLoaded = [];
        this.clientVarsLoadingTimer = null;
        this.clientVarsReady = false;
        this.sheetSelectionState = [];
        this.updateSheetSelectionStateCoreTimer = 0;
        this.unusableSheets = [];
        /**
         * watchdog需要记录的时间
         */
        this._updateTime = 0;
        this.getContextBindList = function () {
            return [{ key: _collaborative.CollaborativeEvents.RestoreSheet, handler: _this.onRestoreSheet }];
        };
        this.bindSheetEvents = function () {
            var context = _this.tokenContext;
            _this.getContextBindList().forEach(function (event) {
                context.bind(event.key, event.handler);
            });
        };
        this.unbindSheetEvents = function () {
            var context = _this.tokenContext;
            _this.getContextBindList().forEach(function (event) {
                context.unbind(event.key, event.handler);
            });
        };
        this.onRestoreSheet = function (sheetId) {
            if (!_this.imp) return;
            _this.imp.createSheetFromDataStore(sheetId);
            _this.updateEmbedSheet(sheetId);
        };
        this.checkSpreadLoaded = function () {
            _this.spreadLoaded = _this.imp && _this.imp.isCollaSpreadLoaded() || false;
            return _this.spreadLoaded;
        };
        this.onSpreadLoaded = function () {
            _this.checkSpreadLoaded();
            if (_this.spreadLoaded) {
                _this.imp && _this.imp.handleSpreadLoaded();
                Object.getOwnPropertyNames(_this.hosts).forEach(function (sheetId) {
                    _this.updateEmbedSheet(sheetId);
                });
                setTimeout(function () {
                    _this.updateUnusableSheet(true);
                }, 200);
            }
            clearTimeout(_this.clientVarsLoadingTimer);
        };
        this.onSpreadLoading = function () {
            _this.spreadLoaded = false;
        };
        this.registerCSQueue = function (csQueue) {
            _this.engine.registerCSQueue(csQueue);
        };
        this.onApplyActions = function (actions) {
            _this._updateTime = Date.now();
            _this.imp && _this.imp.applyActions(actions, false);
            _this.updateUnusableSheet(true);
        };
        this.onProduceChangeset = function () {
            _this._updateTime = Date.now();
        };
        this.onLocalConflict = function () {
            (0, _tea.collectSuiteEvent)('client_sheet_edit_conflict_local');
        };
        this.onRejectCommit = function () {
            (0, _tea.collectSuiteEvent)('client_sheet_edit_conflict');
            _this.onConflict();
        };
        this.onError = function (data) {
            _this.freezeSheet(true);
            (0, _modal.showServerErrorModal)(data.code, 'embed-sheet-manager');
        };
        this.onConflict = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee() {
            var context, token, userId, memberId, record, backupActions;
            return _regenerator2.default.wrap(function _callee$(_context) {
                while (1) {
                    switch (_context.prev = _context.next) {
                        case 0:
                            _this.freezeSheet(true);
                            // doc 插 sheet 遇到冲突时候存成冲突记录, 删掉 local 数据
                            context = _this.tokenContext;
                            token = context.getToken();
                            userId = context.userId;
                            memberId = context.getMemberId();
                            _context.prev = 5;
                            record = {
                                timestamp: Date.now(),
                                baseRev: -1,
                                actions: ''
                            };
                            _context.next = 9;
                            return (0, _backup.getBackupActions)(token, userId, memberId);

                        case 9:
                            backupActions = _context.sent;

                            record.actions = (0, _encode.gzip)(JSON.stringify(backupActions));
                            _context.next = 13;
                            return (0, _backup.checkBackupRev)(token, userId, memberId);

                        case 13:
                            record.baseRev = _context.sent;
                            _context.next = 16;
                            return (0, _backup.clearBackup)(token, userId, memberId);

                        case 16:
                            _context.next = 18;
                            return (0, _backup.addLocalRecord)(token, userId, memberId, record);

                        case 18:
                            _context.next = 24;
                            break;

                        case 20:
                            _context.prev = 20;
                            _context.t0 = _context['catch'](5);

                            // Raven上报
                            window.Raven && window.Raven.captureException(_context.t0);
                            // ConsoleError
                            console.error(_context.t0);

                        case 24:
                            (0, _modal.showError)(_modal.ErrorTypes.ERROR_ACTION_CONFLICT, {
                                onConfirm: function onConfirm() {
                                    _this.tokenContext.trigger(_collaborative.CollaborativeEvents.CONFLICT_HANDLE);
                                }
                            });

                        case 25:
                        case 'end':
                            return _context.stop();
                    }
                }
            }, _callee, _this, [[5, 20]]);
        }));
        this.screenshot = function (isScreenShotMode) {
            return _this.imp && _this.imp.screenshot(isScreenShotMode);
        };
        this.addSheet = function (action, sheetId) {
            _this.executeLocal(action);
        };
        this.pasteSheet = function (action) {
            _this.executeLocal(action);
            _this.needUniqFitRow[action.sheet_id] = true;
        };
        this.collectUserChange = function (actions) {
            _this.tokenContext.trigger(_collaborative.CollaborativeEvents.PRODUCE_ACTIONS, actions);
        };
        this.onMountSheetComp = function (sheetId, comp) {
            _this.sheetComponents.set(sheetId, comp);
            _this.imp && _this.imp.createSheetFromDataStore(sheetId);
            var result = _this.updateEmbedSheet(sheetId);
            if (_this.spreadLoaded && !result) {
                _this.sync.forceHeartbeatSync(function () {
                    return;
                }, function () {
                    return;
                });
            }
        };
        this.onUnmountSheetComp = function (sheetId, comp) {
            _this.sheetComponents.delete(sheetId);
            var snapshot = _this.imp && _this.imp.getSheetSnapshot(sheetId);
            var s = _this.dataStore.sheets[sheetId];
            if (snapshot && s && s.loaded) {
                _this.dataStore.sheets[sheetId] = {
                    snapshot: (0, _sheetHelper.pickSheetSnapshot)(snapshot),
                    loaded: true,
                    actions: []
                };
            }
        };
        this.onMountEmbedSheet = function (sheetId) {
            var cb = _this.mountCallbacks[sheetId];
            if (typeof cb === 'function') {
                cb();
            }
            delete _this.mountCallbacks[sheetId];
        };
        this.mountSheet = function (options) {
            var sheetId = options.sheetId,
                container = options.host,
                mountCb = options.mountCb,
                order = options.order;

            if (!container) {
                return _$moirae2.default.count('ee.docs.sheet.embed_manager_no_container');
            }
            // TODO: 现在同个 sheetId 只能挂载在一个 DOM
            // 后续调整 UI 架构解决
            if (_this.mountQueue.filter(function (item) {
                return item.sheetId === sheetId;
            }).length > 0) {
                return _$moirae2.default.count('ee.docs.sheet.embed_manager_mount_queue_repeat');
            }
            // 建立一个属于我们sheet的挂载点，保证不受doc改动的影响。
            var host = document.createElement('div');
            container.innerHTML = '';
            container.appendChild(host);
            _this.hosts[sheetId] = host;
            _this.dataStore.mountSheet.next({ sheetId: sheetId, order: order });
            _this.mountCallbacks[sheetId] = function () {
                mountCb && mountCb();
            };
            _this.innerMountSheet(sheetId, options);
        };
        this.mountNext = function () {
            var mountSheetInfo = _this.mountQueue.shift();
            _this.mounting = null;
            if (!mountSheetInfo) {
                return;
            }
            var sheetId = mountSheetInfo.sheetId,
                options = mountSheetInfo.options;

            _this.mountOptions[sheetId] = options;
            if (!sheetId) {
                return;
            }
            _this.mounting = mountSheetInfo;
            _this.rafId = raf(function () {
                if (!_this.imp) {
                    return _$moirae2.default.count('ee.docs.sheet.embed_manager_no_imp');
                }
                var host = _this.hosts[sheetId];
                _this.rafId = null;
                _reactDom2.default.render(_react2.default.createElement(_reactRedux.Provider, { store: _$store2.default }, _react2.default.createElement(_PerformanceEmbedSheet2.default, { editor: _this._editor, maxWidth: _this.maxWidth, sheetId: sheetId, onMount: _this.onMountSheetComp, onUnmount: _this.onUnmountSheetComp, onMountEmbedSheet: _this.onMountEmbedSheet, dataStore: _this.dataStore, collaSpread: _this.imp.collaSpread })), host);
                // 强制超时处理
                setTimeout(function () {
                    _this.mounting = null;
                    _this.onMountEmbedSheet(sheetId);
                    _this.mountNext();
                }, 200);
            });
        };
        this.freezeView = function () {
            _this.freezeSheet(true);
        };
        this.unfreezeView = function () {
            _this.freezeSheet(false);
        };
        this.findMention = function () {
            var _ref2 = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee2(mentionId, scrollElement, scrollTopFunc) {
                return _regenerator2.default.wrap(function _callee2$(_context2) {
                    while (1) {
                        switch (_context2.prev = _context2.next) {
                            case 0:
                                return _context2.abrupt('return', new Promise(function (resolve, reject) {
                                    var core = function core() {
                                        if (_this.checkSpreadLoaded() && _this.imp) {
                                            resolve(_this.imp.findMention(mentionId, scrollElement, scrollTopFunc));
                                        } else {
                                            setTimeout(function () {
                                                core();
                                            }, 100);
                                        }
                                    };
                                    core();
                                }));

                            case 1:
                            case 'end':
                                return _context2.stop();
                        }
                    }
                }, _callee2, _this);
            }));

            return function (_x, _x2, _x3) {
                return _ref2.apply(this, arguments);
            };
        }();
        this.updateSheetSelectionState = function (sheetId, isSelect) {
            var updateSheetSelectionStateCore = function updateSheetSelectionStateCore() {
                if (_this.sheetSelectionState.length === 1) {
                    _this.sheetSelectionState.forEach(function (selectedSheetId) {
                        var sheet = _this.imp && _this.imp.collaSpread.spread.getSheetFromId(selectedSheetId);
                        if (!sheet) {
                            return;
                        }
                        var selectionModel = sheet._selectionModel.toArray();
                        if (selectionModel.length === 0) {
                            _this.updateEmbedSheet(selectedSheetId, true);
                        } else {
                            _this.updateEmbedSheet(selectedSheetId, false);
                        }
                    });
                } else {
                    _this.sheetSelectionState.forEach(function (selectedSheetId) {
                        _this.updateEmbedSheet(selectedSheetId, true);
                    });
                }
            };
            window.clearTimeout(_this.updateSheetSelectionStateCoreTimer);
            if (isSelect === true) {
                _this.sheetSelectionState.push(sheetId);
                _this.updateSheetSelectionStateCoreTimer = window.setTimeout(updateSheetSelectionStateCore, 10);
            } else {
                _this.sheetSelectionState = _this.sheetSelectionState.filter(function (item) {
                    return item !== sheetId;
                });
                _this.updateEmbedSheet(sheetId, false);
            }
        };
        this.destroy = function () {
            _this.mountQueue = [];
            _this.mounting = null;
            if (_this.rafId) {
                unraf(_this.rafId);
                _this.rafId = null;
            }
            _this.sheetComponents.forEach(function (comp, sheetId) {
                return _this.unmountSheet(sheetId);
            });
            _this.unbindSheetEvents();
            _this.tokenContext.removeEventHandler(_this.dataStore);
            _this.tokenContext.removeEventHandler(_this);
            _this.engine.unbindCollaborativeEvents();
            _this.engine.reset();
            _this.sync.unbindCollaborativeEvents();
            _this.sync.disconnect();
            _this.hosts = {};
            _this.imp && _this.imp.destroy();
        };
        var context = new _collaborative.CollaborativeContext();
        var sync = this.sync = new _sync.Sync(context);
        var engine = this.engine = new _engine.Engine(context);
        this.tokenContext = context;
        this.dataStore = new _DataStore.DataStore();
        context.setEmbed(true);
        context.setToken(token);
        _Spread.Spread.sync = sync;
        _Spread.Spread.engine = engine;
        sync.bindCollaborativeEvents();
        engine.bindCollaborativeEvents();
        context.addEventHandler(this.dataStore);
        context.addEventHandler(this);
        sync.connect(token, sheetId, this.dataStore);
        this.createImp();
        this.bindSheetEvents();
    }

    (0, _createClass3.default)(EmbedSheetManager, [{
        key: 'createImp',
        value: function createImp() {
            // 先注释已确保Imp被初始化（代价是打包后文件变大500KB）
            // const { default: EmbedSheetManagerImp } = await import('./EmbedSheetManagerImp');
            this.imp = new _EmbedSheetManagerImp2.default(this);
            // 先注释已确保Imp被初始化（代价是打包后文件变大500KB）
            // this.imp.handleClientVars();
            // this.imp.handleSpreadLoaded();
        }
    }, {
        key: 'getNewSheet',
        value: function getNewSheet() {
            var ids = Array.from(this.sheetComponents.keys());
            var id = (0, _utils.genSheetId)(ids);
            var index = ids.length;
            var name = 'Sheet' + id;
            return {
                id: id,
                name: name,
                index: index
            };
        }
    }, {
        key: 'onClientVars',
        value: function onClientVars() {
            this.clientVarsReady = true;
            this.imp && this.imp.handleClientVars();
            this.updateUnusableSheet(false);
            // 10s 如果没有调用 spreadLoaded 的话，则上报超时
            clearTimeout(this.clientVarsLoadingTimer);
            this.clientVarsLoadingTimer = setTimeout(function () {
                (0, _tea.collectSuiteEvent)('client_dev_embedsheet_clientvars_timeout');
            }, 10000); // 10s
        }
        // execute action and collect actions

    }, {
        key: 'executeLocal',
        value: function executeLocal(action) {
            this.checkSpreadLoaded();
            if (this.spreadLoaded && this.imp) {
                this.imp.executeLocal([action]);
            } else {
                this.actionAfterLoaded.push([action]);
            }
        }
    }, {
        key: 'freezeSheet',
        value: function freezeSheet(freeze) {
            _$store2.default.dispatch((0, _sheet.freezeSheetToggle)(freeze));
        }
    }, {
        key: 'setMaxWidth',
        value: function setMaxWidth(maxWidth) {
            this.maxWidth = maxWidth;
            this.sheetComponents.forEach(function (comp) {
                return comp.onMaxWidthChange(maxWidth);
            });
        }
    }, {
        key: 'setSize',
        value: function setSize(width, height) {
            this.sheetComponents.forEach(function (comp) {
                return comp.onSizeChange(width, height);
            });
        }
    }, {
        key: 'wakeup',
        value: function wakeup(sheetId) {
            this.tokenContext.trigger(_collaborative.CollaborativeEvents.WAKEUP, sheetId);
        }
    }, {
        key: 'suspend',
        value: function suspend(sheetId) {
            this.tokenContext.trigger(_collaborative.CollaborativeEvents.SUSPEND, sheetId);
        }
    }, {
        key: 'syncVirtualScroll',
        value: function syncVirtualScroll() {
            this.tokenContext.trigger(_collaborative.CollaborativeEvents.SYNC_VIRTUAL_SCROLL);
        }
    }, {
        key: 'setZoom',
        value: function setZoom(zoom) {
            this.sheetComponents.forEach(function (comp) {
                return comp.onZoomChange(zoom);
            });
        }
    }, {
        key: 'handleFitRow',
        value: function handleFitRow(sheetId) {
            var sheet = this.imp && this.imp.collaSpread.spread.getSheetFromId(sheetId);
            if (!sheet) return;
            var changedRows = (0, _range3.default)(sheet.getRowCount());
            var changesets = (0, _sheetHelper.uniqFitRow)(sheet, changedRows);
            this.collectUserChange(changesets);
            delete this.needUniqFitRow[sheetId];
        }
    }, {
        key: 'addUnusableSheet',
        value: function addUnusableSheet(sheetId) {
            if (this.unusableSheets.indexOf(sheetId) === -1) {
                this.unusableSheets.push(sheetId);
            }
        }
    }, {
        key: 'updateUnusableSheet',
        value: function updateUnusableSheet(withReport) {
            var _this2 = this;

            var readySheets = [];
            if (this.unusableSheets.length === 0) {
                return;
            }
            if (withReport) {
                _$moirae2.default.count('ee.docs.sheet.embed_manager_update_unusable_2');
            }
            this.unusableSheets.forEach(function (sheetId) {
                var sheet = _this2.imp && _this2.imp.collaSpread.spread.getSheetFromId(sheetId) || null;
                if (!sheet) {
                    _this2.imp && _this2.imp.createSheetFromDataStore(sheetId, withReport);
                }
                if (_this2.updateEmbedSheet(sheetId, false, withReport)) {
                    readySheets.push(sheetId);
                }
            });
            this.unusableSheets = this.unusableSheets.filter(function (sheetId) {
                return readySheets.indexOf(sheetId) === -1;
            });
            if (withReport) {
                if (this.unusableSheets.length === 0) {
                    _$moirae2.default.count('ee.docs.sheet.embed_manager_update_unusable_fin_2');
                } else {
                    _$moirae2.default.count('ee.docs.sheet.embed_manager_update_unusable_fail_2');
                }
            }
        }
    }, {
        key: 'updateEmbedSheet',
        value: function updateEmbedSheet(sheetId) {
            var isSelect = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : false;
            var withReport = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : false;

            var comp = this.sheetComponents.get(sheetId);
            if (!this.imp) {
                this.addUnusableSheet(sheetId);
                if (withReport) {
                    _$moirae2.default.count('ee.docs.sheet.embed_manager_no_imp_reuse_2');
                }
                return false;
            }
            if (!comp) {
                this.addUnusableSheet(sheetId);
                if (withReport) {
                    _$moirae2.default.count('ee.docs.sheet.embed_manager_no_comp_reuse_2');
                }
                return false;
            }
            var content = this.imp.getEmbedSheet(sheetId, isSelect);
            if (!content) {
                this.addUnusableSheet(sheetId);
                if (withReport) {
                    _$moirae2.default.count('ee.docs.sheet.embed_manager_no_embed_content_reuse_2');
                }
                return false;
            }
            comp.setEmbedSheet(content);
            if (this.needUniqFitRow[sheetId] === true) {
                this.handleFitRow(sheetId);
            }
            return true;
        }
    }, {
        key: 'innerMountSheet',
        value: function innerMountSheet(sheetId, options) {
            this.mountQueue.push({
                sheetId: sheetId,
                options: options
            });
            if (!this.mounting) {
                this.mountNext();
            } else {
                return _$moirae2.default.count('ee.docs.sheet.embed_manager_still_mounting');
            }
        }
    }, {
        key: 'handleCopy',
        value: function handleCopy(sheetId) {
            return this.imp ? this.imp.handleCopy(sheetId) : '';
        }
    }, {
        key: 'unmountSheet',
        value: function unmountSheet(sheetId) {
            var _this3 = this;

            var host = this.hosts[sheetId];
            // 同一个sheet可能被unmount多次
            if (!host) {
                return;
            }
            console.log('UnmountSheet ' + sheetId);
            delete this.hosts[sheetId];
            this.sheetSelectionState = this.sheetSelectionState.filter(function (item) {
                return item !== sheetId;
            });
            this.dataStore.unmountSheet.next(sheetId);
            this.mountQueue.forEach(function (item, index) {
                if (item.sheetId === sheetId) {
                    _this3.mountQueue.splice(index, 1);
                }
            });
            if (this.rafId && this.mounting && this.mounting.sheetId === sheetId) {
                unraf(this.rafId);
                this.rafId = null;
                this.mountNext();
                return;
            }
            try {
                _reactDom2.default.unmountComponentAtNode(host);
            } catch (e) {
                // Raven上报
                window.Raven && window.Raven.captureException(e);
                // ConsoleError
                console.error(e);
            }
        }
    }, {
        key: 'updateTime',
        get: function get() {
            return this._updateTime;
        }
    }, {
        key: 'sheetIds',
        get: function get() {
            return Object.keys(this.dataStore.sheets);
        }
    }, {
        key: 'baseRev',
        get: function get() {
            return this.engine.getBaseRev();
        }
    }]);
    return EmbedSheetManager;
}();

exports.EmbedSheetManager = EmbedSheetManager;

/***/ }),

/***/ 3059:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.DataStore = undefined;

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

exports.getSnapshotByAction = getSnapshotByAction;

var _actions = __webpack_require__(1572);

var _utils = __webpack_require__(1575);

var _Subject = __webpack_require__(3060);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function getSnapshotByAction(action) {
    if (action.action === _actions.ACTIONS.ADD_SHEET) {
        return {
            id: action.sheet_id,
            index: action.value.index,
            name: action.sheet_name
        };
    } else if (action.action === _actions.ACTIONS.COPY_SHEET) {
        return action.value.snapshot || {
            id: action.value.sheet_id,
            name: action.value.sheet_name,
            index: action.value.index
        };
    }
    return null;
}
function defaultSheets() {
    return {
        1: {
            snapshot: {
                id: '1',
                index: 0,
                name: 'Sheet1'
            },
            actions: [],
            loaded: false
        }
    };
}

var DataStore = exports.DataStore = function () {
    function DataStore() {
        var _this = this;

        (0, _classCallCheck3.default)(this, DataStore);

        this.sheets = {};
        this.loaded = false;
        this.mountedSheets = [];
        this.mountSheet = new _Subject.Subject();
        this.unmountSheet = new _Subject.Subject();
        this.mountSheet.subscribe(function (_ref) {
            var sheetId = _ref.sheetId,
                order = _ref.order;

            _this.mountedSheets.splice(order, 0, sheetId);
        });
        this.unmountSheet.subscribe(function (sheetId) {
            var index = _this.mountedSheets.indexOf(sheetId);
            if (index > -1) {
                _this.mountedSheets.splice(index, 1);
            }
        });
    }

    (0, _createClass3.default)(DataStore, [{
        key: 'getNewSheet',
        value: function getNewSheet() {
            var ids = [];
            for (var sheetId in this.sheets) {
                ids.push(sheetId);
            }
            var id = (0, _utils.genSheetId)(ids);
            var index = ids.length;
            var name = 'Sheet' + id;
            return {
                id: id,
                name: name,
                index: index
            };
        }
    }, {
        key: 'onClientVars',
        value: function onClientVars(args) {
            var _this2 = this;

            var sheetSnapshots = args.snapshot.sheets || {};
            this.sheets = defaultSheets();
            for (var name in sheetSnapshots) {
                var sheetSnapshot = sheetSnapshots[name];
                var sheetId = sheetSnapshot.id;
                this.sheets[sheetId] = {
                    snapshot: sheetSnapshot,
                    actions: [],
                    loaded: false
                };
            }
            var changesets = args.changeset_list || args.changesets || [];
            changesets.forEach(function (changeset) {
                _this2.groupActions(changeset.content);
            });
            for (var _sheetId in this.sheets) {
                this.sheets[_sheetId].loaded = false;
            }
        }
    }, {
        key: 'onDataTable',
        value: function onDataTable(sheetId, rowData) {
            var sheet = this.sheets[sheetId];
            if (sheet) {
                if (!sheet.snapshot.data) {
                    sheet.snapshot.data = { dataTable: {} };
                }
                Object.assign(sheet.snapshot.data.dataTable, rowData);
            }
        }
    }, {
        key: 'onSpreadLoaded',
        value: function onSpreadLoaded() {
            var sheets = this.sheets;

            for (var sheetId in sheets) {
                sheets[sheetId].loaded = true;
            }
            this.loaded = true;
        }
    }, {
        key: 'onApplyActions',
        value: function onApplyActions(actions) {
            this.groupActions(actions);
        }
    }, {
        key: 'onProduceActions',
        value: function onProduceActions(actions) {
            this.groupActions(actions);
        }
    }, {
        key: 'groupActions',
        value: function groupActions(actions) {
            var sheets = this.sheets;

            actions.forEach(function (action) {
                var sheetId = action.action === _actions.ACTIONS.COPY_SHEET ? action.value.sheet_id : action.sheet_id;
                switch (action.action) {
                    case _actions.ACTIONS.COPY_SHEET:
                    case _actions.ACTIONS.ADD_SHEET:
                        var snapshot = getSnapshotByAction(action);
                        if (sheets[sheetId]) {
                            sheets[sheetId].snapshot = snapshot;
                        } else {
                            sheets[sheetId] = {
                                snapshot: snapshot,
                                actions: [],
                                loaded: true
                            };
                        }
                        break;
                    case _actions.ACTIONS.DEL_SHEET:
                        delete sheets[sheetId];
                        break;
                    case _actions.ACTIONS.SET_SHEET:
                        if (sheets[sheetId]) {
                            sheets[sheetId].snapshot.name = action.value.sheet_name;
                        }
                        break;
                    default:
                        if (sheets[sheetId]) {
                            sheets[sheetId].actions.push(action);
                        }
                }
            });
        }
    }, {
        key: 'onRefetchClientVars',
        value: function onRefetchClientVars() {
            this.loaded = false;
            this.sheets = {};
        }
    }]);
    return DataStore;
}();

/***/ }),

/***/ 3060:
/***/ (function(module, exports, __webpack_require__) {

"use strict";

function __export(m) {
    for (var p in m) if (!exports.hasOwnProperty(p)) exports[p] = m[p];
}
Object.defineProperty(exports, "__esModule", { value: true });
__export(__webpack_require__(3061));
//# sourceMappingURL=Subject.js.map

/***/ }),

/***/ 3061:
/***/ (function(module, exports, __webpack_require__) {

"use strict";

Object.defineProperty(exports, "__esModule", { value: true });
var rxjs_1 = __webpack_require__(731);
exports.Subject = rxjs_1.Subject;
//# sourceMappingURL=Subject.js.map

/***/ }),

/***/ 3062:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.default = undefined;

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _sheetPlaceholder = __webpack_require__(3063);

var _$moirae = __webpack_require__(378);

var _$moirae2 = _interopRequireDefault(_$moirae);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var checkTimer = 0;
var tick = 0;
var dataStoreMonitor = null;
var spreadMonitor = null;
var spreadLoadedMonitor = false;
var isInitCheck = true;
var loadStateMap = {};
var checkLoadState = function checkLoadState() {
    tick += 1;
    if (tick > 60 && spreadLoadedMonitor === true) {
        window.clearInterval(checkTimer);
        var keys = Object.getOwnPropertyNames(loadStateMap);
        var badCase = 0;
        keys.forEach(function (item) {
            if (loadStateMap[item] !== true) {
                badCase += 1;
            }
        });
        if (badCase !== 0) {
            if (isInitCheck) {
                _$moirae2.default.mean('ee.docs.sheet.embed.load_succ_initial', 0);
            } else {
                _$moirae2.default.mean('ee.docs.sheet.embed.load_succ_edit', 0);
            }
            findoutWhy();
        } else {
            if (isInitCheck) {
                _$moirae2.default.mean('ee.docs.sheet.embed.load_succ_initial', 1);
            } else {
                _$moirae2.default.mean('ee.docs.sheet.embed.load_succ_edit', 1);
            }
        }
        isInitCheck = false;
    }
};
var findoutWhy = function findoutWhy() {
    var keys = Object.getOwnPropertyNames(loadStateMap);
    if (!dataStoreMonitor || !spreadMonitor) {
        return;
    }
    var dataStoreSheets = Object.getOwnPropertyNames(dataStoreMonitor.sheets);
    var dataStoreMountedSheets = dataStoreMonitor.mountedSheets;
    keys.forEach(function (item) {
        // 查找出未成功的ID
        if (loadStateMap[item] !== true) {
            var hasReason = true;
            var sheet = spreadMonitor.getSheetFromId(item);
            if (dataStoreSheets.indexOf(item) === -1) {
                hasReason = true;
                _$moirae2.default.count('ee.docs.sheet.embed_manager_datastore_target_sheet_not_in');
            }
            if (dataStoreMountedSheets.indexOf(item) === -1) {
                hasReason = true;
                _$moirae2.default.count('ee.docs.sheet.embed_manager_datastore_mounted_target_sheet_not_in');
            }
            if (!sheet) {
                hasReason = true;
                _$moirae2.default.count('ee.docs.sheet.embed_manager_sheet_not_in_spread');
            }
            if (!hasReason) {
                _$moirae2.default.count('ee.docs.sheet.embed_manager_unknow');
            }
        }
    });
};

var PerformanceEmbedSheet = function (_React$PureComponent) {
    (0, _inherits3.default)(PerformanceEmbedSheet, _React$PureComponent);

    function PerformanceEmbedSheet(props) {
        (0, _classCallCheck3.default)(this, PerformanceEmbedSheet);

        var _this = (0, _possibleConstructorReturn3.default)(this, (PerformanceEmbedSheet.__proto__ || Object.getPrototypeOf(PerformanceEmbedSheet)).call(this, props));

        _this.comp = null;
        _this.onMountEmbedSheet = function (ref) {
            if (ref) {
                _this.props.onMountEmbedSheet(_this.props.sheetId);
            }
        };
        _this.state = {
            zoom: 1,
            maxWidth: props.maxWidth,
            content: null,
            isScreenShotMode: false
        };
        return _this;
    }

    (0, _createClass3.default)(PerformanceEmbedSheet, [{
        key: 'componentDidMount',
        value: function componentDidMount() {
            this.props.onMount(this.props.sheetId, this);
        }
    }, {
        key: 'componentWillUnmount',
        value: function componentWillUnmount() {
            var sheetId = this.props.sheetId;

            delete loadStateMap[sheetId];
            this.props.onUnmount(this.props.sheetId, this);
        }
    }, {
        key: 'onMaxWidthChange',
        value: function onMaxWidthChange(maxWidth) {
            this.setState({ maxWidth: maxWidth, maxHeight: Infinity });
        }
    }, {
        key: 'onSizeChange',
        value: function onSizeChange(maxWidth, maxHeight) {
            this.setState({ maxWidth: maxWidth, maxHeight: maxHeight });
        }
    }, {
        key: 'setEmbedSheet',
        value: function setEmbedSheet(embedSheet) {
            this.setState({ content: embedSheet });
        }
    }, {
        key: 'onZoomChange',
        value: function onZoomChange(zoom) {
            this.setState({ zoom: zoom });
        }
    }, {
        key: 'onScreenShot',
        value: function onScreenShot(isScreenShotMode) {
            this.setState({
                isScreenShotMode: isScreenShotMode
            });
        }
    }, {
        key: 'render',
        value: function render() {
            var state = this.state;
            var _props = this.props,
                sheetId = _props.sheetId,
                dataStore = _props.dataStore,
                collaSpread = _props.collaSpread;
            var spread = collaSpread.spread;

            dataStoreMonitor = dataStore;
            spreadMonitor = spread;
            if (spreadLoadedMonitor !== true) {
                spreadLoadedMonitor = collaSpread.spreadLoaded;
            }
            if (state.content !== null) {
                loadStateMap[sheetId] = true;
                this.comp = _react2.default.cloneElement(state.content, {
                    zoom: state.zoom,
                    editor: this.props.editor,
                    maxWidth: state.maxWidth,
                    maxHeight: state.maxHeight,
                    isScreenShotMode: state.isScreenShotMode,
                    ref: this.onMountEmbedSheet
                });
            } else {
                loadStateMap[sheetId] = false;
            }
            tick = 0;
            window.clearInterval(checkTimer);
            checkTimer = window.setInterval(checkLoadState, 1000);
            return this.comp || _react2.default.createElement(_sheetPlaceholder.SheetLoadingPlaceholder, { rowCount: 3, colCount: 3 });
        }
    }]);
    return PerformanceEmbedSheet;
}(_react2.default.PureComponent);

exports.default = PerformanceEmbedSheet;

/***/ }),

/***/ 3063:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.SheetPlaceholder = undefined;

var _SheetLoadingPlaceHolder = __webpack_require__(3064);

Object.keys(_SheetLoadingPlaceHolder).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function get() {
      return _SheetLoadingPlaceHolder[key];
    }
  });
});

var _SheetPlaceholder = __webpack_require__(2046);

exports.SheetPlaceholder = _SheetPlaceholder.SheetPlaceholder;
exports.default = _SheetPlaceholder.SheetPlaceholder;

/***/ }),

/***/ 3064:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.SheetLoadingPlaceholder = undefined;

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _spin = __webpack_require__(1811);

var _spin2 = _interopRequireDefault(_spin);

var _SheetPlaceholder = __webpack_require__(2046);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var SheetLoadingPlaceholder = exports.SheetLoadingPlaceholder = function SheetLoadingPlaceholder(props) {
    return _react2.default.createElement(_spin2.default, { wrapperClassName: props.wrapperClassName }, _react2.default.createElement(_SheetPlaceholder.SheetPlaceholder, { rowHeight: props.rowHeight, colWidth: props.colWidth, rowCount: props.rowCount, colCount: props.colCount, style: props.style }));
};

/***/ }),

/***/ 3065:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3066:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.default = undefined;

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _find2 = __webpack_require__(376);

var _find3 = _interopRequireDefault(_find2);

var _each2 = __webpack_require__(716);

var _each3 = _interopRequireDefault(_each2);

var _toArray2 = __webpack_require__(2028);

var _toArray3 = _interopRequireDefault(_toArray2);

var _some2 = __webpack_require__(736);

var _some3 = _interopRequireDefault(_some2);

var _collaborative_spread = __webpack_require__(1971);

var _sheet = __webpack_require__(713);

var _collaborative = __webpack_require__(1607);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _reactDom = __webpack_require__(21);

var _reactDom2 = _interopRequireDefault(_reactDom);

var _reactRedux = __webpack_require__(238);

var _$store = __webpack_require__(83);

var _$store2 = _interopRequireDefault(_$store);

var _FullSpreadsheet = __webpack_require__(3067);

var _FullSpreadsheet2 = _interopRequireDefault(_FullSpreadsheet);

var _EmbedSheet = __webpack_require__(3237);

var _EmbedSheet2 = _interopRequireDefault(_EmbedSheet);

var _actions = __webpack_require__(1572);

var _EmbedUndoManager = __webpack_require__(3239);

var _EmbedUndoManager2 = _interopRequireDefault(_EmbedUndoManager);

var _undoManager = __webpack_require__(2062);

var _undoManager2 = _interopRequireDefault(_undoManager);

var _utils = __webpack_require__(1575);

var _sheet2 = __webpack_require__(1597);

var _tea = __webpack_require__(47);

var _shellNotify = __webpack_require__(1576);

var _browserHelper = __webpack_require__(34);

var _browserHelper2 = _interopRequireDefault(_browserHelper);

var _$moirae = __webpack_require__(378);

var _$moirae2 = _interopRequireDefault(_$moirae);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var _GC$Spread$Sheets = GC.Spread.Sheets,
    HorizontalPosition = _GC$Spread$Sheets.HorizontalPosition,
    VerticalPosition = _GC$Spread$Sheets.VerticalPosition;

var showCellTimer = void 0;
var highCellTimer = void 0;
function createOverlay() {
    var overlay = document.createElement('div');
    Object.assign(overlay.style, {
        position: 'absolute',
        top: '0',
        left: '0',
        right: '0',
        bottom: '0',
        zIndex: '88',
        backgroundColor: '#fff'
    });
    overlay.className = 'layout-column flex';
    var wrapper = document.getElementById('mainContainer');
    wrapper.appendChild(overlay);
    return overlay;
}
function removeOverlay(overlay) {
    overlay && overlay.parentElement && overlay.parentElement.removeChild(overlay);
}
var raf = window.setTimeout;
if (window.requestAnimationFrame) {
    raf = window.requestAnimationFrame;
    if (_browserHelper2.default.isEdge || _browserHelper2.default.isIE) {
        raf = raf.bind(window);
    }
}

var EmbedSheetManagerImp = function () {
    function EmbedSheetManagerImp(manager) {
        var _this = this;

        (0, _classCallCheck3.default)(this, EmbedSheetManagerImp);

        this.manager = manager;
        this.overlay = null;
        this.actionAfterLoaded = [];
        this.spreadLoaded = false;
        this.screenShotKeys = [];
        this.screenShotIdx = 0;
        this.screenShotResolve = null;
        this.isScreenShotMode = false;
        this.fetchRemoteSheetData = function (s, sheetId) {
            console.log('FetchingRemoteData ' + sheetId);
            _this.manager.sync.fetchSheetSplitData(s);
            _this.collaSpread.spreadLoaded = _this.isCollaSpreadLoaded();
        };
        this.findMention = function (mentionId, scrollElement, scrollTopFunc) {
            if (_this.isCollaSpreadLoaded()) {
                var targetCol = -1;
                var targetRow = -1;
                var targetSheetId = '';
                var sheetList = _this.collaSpread.spread.sheets;
                var target = (0, _some3.default)((0, _toArray3.default)(sheetList), function (item) {
                    var founded = false;
                    var dataTable = item._dataModel.dataTable;
                    (0, _each3.default)(dataTable, function (row, rowKey) {
                        if (founded) {
                            return;
                        }
                        (0, _each3.default)(row, function (cell, colKey) {
                            if (founded) {
                                return;
                            }
                            if (cell.segmentArray && cell.segmentArray.length > 0) {
                                (0, _each3.default)(cell.segmentArray, function (sItem) {
                                    if (sItem.mentionId && sItem.mentionId === mentionId) {
                                        targetCol = parseInt(colKey, 10);
                                        targetRow = parseInt(rowKey, 10);
                                        targetSheetId = item.id();
                                        founded = true;
                                    }
                                });
                            }
                        });
                    });
                    return founded;
                });
                if (target) {
                    var spread = _this.collaSpread.spread;
                    var targetSheet = spread.getSheetFromId(targetSheetId);
                    var cellRect = targetSheet.getCellRect(targetRow, targetCol);
                    var host = targetSheet._host;
                    if (!host) {
                        return;
                    }
                    var box = host.getBoundingClientRect();
                    var doc = host.ownerDocument;
                    var etherPadContianer = scrollElement || document.querySelector('.etherpad-container-wrapper');
                    if (doc && etherPadContianer) {
                        var offsetTop = box.top + etherPadContianer.scrollTop;
                        // 滚动Doc视口至合适位置
                        var clientHeight = document.documentElement.clientHeight;
                        var newScrollTop = offsetTop + cellRect.y - 128;
                        if (_browserHelper2.default.isMobile) {
                            clientHeight = clientHeight * 0.2;
                        }
                        if (etherPadContianer && (newScrollTop > etherPadContianer.scrollTop + clientHeight || newScrollTop < etherPadContianer.scrollTop - clientHeight)) {
                            if (scrollTopFunc) {
                                scrollTopFunc(newScrollTop);
                            } else {
                                etherPadContianer.scrollTop = newScrollTop;
                            }
                        }
                    }
                    targetSheet.setActiveCell(targetRow, targetCol);
                    // 先激活才行
                    _this.context.trigger(_collaborative.CollaborativeEvents.WAKEUP, targetSheetId);
                    if (showCellTimer) {
                        clearTimeout(showCellTimer);
                        showCellTimer = null;
                    }
                    showCellTimer = setTimeout(function () {
                        targetSheet._highlightCells = targetSheet._highlightCells || new Map();
                        targetSheet._highlightCells.set(targetRow + '_' + targetCol, 1);
                        targetSheet.showCell(targetRow, targetCol, VerticalPosition.center, HorizontalPosition.center);
                        targetSheet.notifyShell(_shellNotify.ShellNotifyType.SearchChanged);
                        clearTimeout(showCellTimer);
                        showCellTimer = null;
                    }, 200);
                    var deleteHighCell = function deleteHighCell() {
                        targetSheet._highlightCells = null;
                        targetSheet.notifyShell(_shellNotify.ShellNotifyType.SearchChanged);
                    };
                    if (highCellTimer) {
                        clearTimeout(highCellTimer);
                        highCellTimer = null;
                        deleteHighCell();
                    }
                    highCellTimer = setTimeout(function () {
                        deleteHighCell();
                        clearTimeout(highCellTimer);
                        highCellTimer = null;
                    }, 2200);
                }
                return !!target;
            } else {
                return false;
            }
        };
        this.screenshot = function (isScreenShotMode) {
            return new Promise(function (resolve, reject) {
                var keys = [];
                _this.manager.sheetComponents.forEach(function (v, k) {
                    keys.push(k);
                });
                _this.screenShotKeys = keys;
                _this.screenShotIdx = 0;
                _this.screenShotResolve = resolve;
                _this.isScreenShotMode = isScreenShotMode;
                _this.screenShotNext();
            });
        };
        this.screenShotNext = function () {
            var comp = _this.manager.sheetComponents.get(_this.screenShotKeys[_this.screenShotIdx]);
            if (comp) {
                comp.onScreenShot(_this.isScreenShotMode);
            } else {
                _this.screenShotResolve && _this.screenShotResolve();
            }
        };
        this.enterFullScreenMode = function (sheetId, options) {
            var overlay = createOverlay();
            var spread = _this.collaSpread.spread;
            var onFullScreen = options ? options.onFullScreen : null;
            var onExitFullScreen = options ? options.onExitFullScreen : null;
            spread.reorder(_this.dataStore.mountedSheets);
            spread.sheets.forEach(function (sheet) {
                sheet.defaults.rowHeaderColWidth = 40;
                sheet.endEdit();
            });
            spread.options.embed = false;
            spread._context.setFullScreenMode(true);
            raf(function () {
                _reactDom2.default.render(_react2.default.createElement(_reactRedux.Provider, { store: _$store2.default }, _react2.default.createElement(_FullSpreadsheet2.default, { defaultActiveSheetId: sheetId, onExitClick: function onExitClick() {
                        _this.exitFullScreenMode();
                        onExitFullScreen && onExitFullScreen();
                    }, collaSpread: _this.collaSpread })), overlay);
                _this.overlay = overlay;
                _this.context.trigger(_collaborative.CollaborativeEvents.EnterFullScreenMode);
                (0, _tea.collectSuiteEvent)('click_enter_full_screen', { source: 'click_btn' });
                onFullScreen && onFullScreen();
            });
        };
        this.exitFullScreenMode = function () {
            var overlay = _this.overlay;

            if (!overlay) {
                return;
            }
            var spread = _this.collaSpread.spread;
            spread.sheets.forEach(function (sheet) {
                return sheet.defaults.rowHeaderColWidth = 24;
            });
            spread.options.embed = true;
            spread._context.setFullScreenMode(false);
            _reactDom2.default.unmountComponentAtNode(overlay);
            removeOverlay(overlay);
            _this.overlay = null;
            _this.context.trigger(_collaborative.CollaborativeEvents.ExitFullScreenMode);
        };
        this.context = manager.tokenContext;
        this.dataStore = manager.dataStore;
        this.createCollaborativeSpread();
    }

    (0, _createClass3.default)(EmbedSheetManagerImp, [{
        key: 'isCollaSpreadLoaded',
        value: function isCollaSpreadLoaded() {
            if (!this.spreadLoaded) {
                var reduxState = _$store2.default.getState();
                var spreadState = reduxState.sheet.fetchState.spreadState;
                this.spreadLoaded = spreadState.loaded;
            }
            return this.spreadLoaded;
        }
    }, {
        key: 'createCollaborativeSpread',
        value: function createCollaborativeSpread() {
            this.collaSpread = new _collaborative_spread.CollaborativeSpread(this.context, {
                scrollbarMaxAlign: true,
                showHorizontalScrollbar: false,
                showVerticalScrollbar: false,
                hideSelection: true,
                embed: true
            });
            var spread = this.collaSpread.spread;
            spread.defaults = {
                rowHeaderColWidth: 24
            };
            spread.defaultStyle = {
                wordWrap: _sheet.WORD_WRAP_TYPE.AUTOWRAP,
                vAlign: _sheet.VerticalAlign.Center
            };
            this.collaSpread.spreadLoaded = this.manager.spreadLoaded;
            this.collaSpread.bindEvents();
            this.collaSpread.bindCollaborativeEvents();
            spread.setUndoManger(new _EmbedUndoManager2.default(spread, _undoManager2.default));
        }
    }, {
        key: 'handleClientVars',
        value: function handleClientVars() {
            var _this2 = this;

            if (!this.manager.clientVarsReady) {
                return;
            }
            var snapshot = { sheets: {} };
            var mountedSheets = this.dataStore.mountedSheets;
            mountedSheets.forEach(function (sheetId, index) {
                var s = _this2.dataStore.sheets[sheetId];
                // 如果出现了不存在的Sheet，则跳出
                if (!s) {
                    return;
                }
                snapshot.sheets[sheetId] = Object.assign({}, s.snapshot, { index: index });
                _this2.actionAfterLoaded = _this2.actionAfterLoaded.concat(s.actions);
            });
            var clientVarData = {
                snapshot: snapshot,
                sheetCount: mountedSheets.length
            };
            this.collaSpread.onClientVars(clientVarData);
            mountedSheets.forEach(function (sheetId) {
                _this2.manager.updateEmbedSheet(sheetId);
            });
        }
    }, {
        key: 'createSheetFromDataStore',
        value: function createSheetFromDataStore(sheetId) {
            var withReport = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : false;

            var sheet = this.collaSpread.spread.getSheetFromId(sheetId);
            var s = this.dataStore.sheets[sheetId];
            if (!sheet) {
                // 没有在restore action中恢复，从data store中恢复。
                if (!s) {
                    this.manager.addUnusableSheet(sheetId);
                    if (withReport) {
                        _$moirae2.default.count('ee.docs.sheet.embed_manager_imp_no_worksheet_2');
                    }
                    return;
                }
                var index = this.dataStore.mountedSheets.indexOf(sheetId);
                if (index === -1) {
                    index = s.snapshot.index || 0;
                }
                if (!s.snapshot.data) {
                    this.fetchRemoteSheetData(s, sheetId);
                }
                var action = {
                    action: _actions.ACTIONS.COPY_SHEET,
                    sheet_id: sheetId,
                    value: {
                        index: index,
                        sheet_id: sheetId,
                        sheet_name: s.snapshot.name,
                        snapshot: s.snapshot
                    }
                };
                this.collaSpread.applyActions([action].concat(s.actions));
            }
        }
    }, {
        key: 'getEmbedSheet',
        value: function getEmbedSheet(sheetId) {
            var _this3 = this;

            var isSelect = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : false;

            var sheet = this.collaSpread.spread.getSheetFromId(sheetId);
            if (!sheet) {
                return null;
            }
            return _react2.default.createElement(_EmbedSheet2.default, { sheetId: sheetId, isSelect: isSelect, collaSpread: this.collaSpread, collaSpreadLoaded: this.isCollaSpreadLoaded(), shell: {
                    onDeleteSheet: function onDeleteSheet() {
                        var mountOption = _this3.manager.mountOptions[sheetId];
                        mountOption && mountOption.deleteFn();
                    },
                    onFullScreenMode: function onFullScreenMode() {
                        var mountOption = _this3.manager.mountOptions[sheetId];
                        _this3.enterFullScreenMode(sheetId, mountOption);
                    },
                    onScreenShotReady: function onScreenShotReady() {
                        _this3.screenShotIdx += 1;
                        _this3.screenShotNext();
                    }
                } });
        }
    }, {
        key: 'getSheetSnapshot',
        value: function getSheetSnapshot(sheetId) {
            var ret = null;
            var spread = this.collaSpread.spread;
            var sheet = spread.getSheetFromId(sheetId);
            if (sheet) {
                ret = sheet.toJSON();
            }
            return ret;
        }
    }, {
        key: 'handleSpreadLoaded',
        value: function handleSpreadLoaded() {
            var _this4 = this;

            if (!this.isCollaSpreadLoaded()) {
                return;
            }
            var spread = this.collaSpread.spread;
            this.collaSpread.spreadLoaded = true;
            if (this.actionAfterLoaded.length) {
                this.applyActions(this.actionAfterLoaded, false);
                // 执行完进行清理以确保不会被重复执行
                this.actionAfterLoaded = [];
            }
            if (this.manager.actionAfterLoaded.length) {
                // this.manager.actionAfterLoaded 是二维数组，所以此处需要做遍历
                this.manager.actionAfterLoaded.forEach(function (item) {
                    _this4.applyActions(item, true);
                });
                // 执行完进行清理以确保不会被重复执行
                this.manager.actionAfterLoaded = [];
            }
            // 设置编辑权限
            _utils.utils.setSpreadEdit(spread, (0, _sheet2.editableSelector)(_$store2.default.getState()));
        }
    }, {
        key: 'handleCopy',
        value: function handleCopy(sheetId) {
            var spread = this.collaSpread.spread;
            var sheet = spread.getSheetFromId(sheetId);
            return sheet ? sheet.toHtml() : '';
        }
        // execute and collect local actions

    }, {
        key: 'executeLocal',
        value: function executeLocal(actions) {
            this.applyActions(actions, true);
        }
        // 可能是远程action也可能是本地操作产生的
        // 如果有创建sheet的action，随即应该创建EmbedSheet替换placeholder

    }, {
        key: 'applyActions',
        value: function applyActions(actions) {
            var local = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : false;

            var sheets = this.collaSpread.spread.sheets;
            // 新建 sheet 的 action，如果 sheet 存在，则去掉这个 action
            actions = actions.filter(function (action) {
                if (action.action === _actions.ACTIONS.COPY_SHEET) {
                    var copyAction = action;
                    var sheetId = copyAction.sheet_id;
                    var sheetExist = (0, _find3.default)(sheets, function (sheet) {
                        return sheet.id() === sheetId;
                    });
                    return !sheetExist;
                } else {
                    return true;
                }
            });
            this.collaSpread.applyActions(actions, false, local);
        }
    }, {
        key: 'destroy',
        value: function destroy() {
            this.exitFullScreenMode();
            this.collaSpread.unbindCollaborativeEvents();
            this.collaSpread.destroy();
            this.spreadLoaded = false;
        }
    }]);
    return EmbedSheetManagerImp;
}();

exports.default = EmbedSheetManagerImp;

/***/ }),

/***/ 3067:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _redux = __webpack_require__(65);

var _reactRedux = __webpack_require__(238);

var _tea = __webpack_require__(47);

var _sheet = __webpack_require__(1597);

var _shrink = __webpack_require__(3068);

var _shrink2 = _interopRequireDefault(_shrink);

var _sheet2 = __webpack_require__(715);

var _FullSheetTabs = __webpack_require__(3069);

var _spreadsheet = __webpack_require__(3076);

var _spreadsheet2 = _interopRequireDefault(_spreadsheet);

__webpack_require__(3236);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var FullSpreadsheet = function (_React$PureComponent) {
    (0, _inherits3.default)(FullSpreadsheet, _React$PureComponent);

    function FullSpreadsheet(props) {
        (0, _classCallCheck3.default)(this, FullSpreadsheet);

        var _this = (0, _possibleConstructorReturn3.default)(this, (FullSpreadsheet.__proto__ || Object.getPrototypeOf(FullSpreadsheet)).call(this, props));

        _this.handleExitClick = function () {
            (0, _tea.collectSuiteEvent)('click_exit_full_screen');
            _tea.collectWithCustomizeFn.setParam('mode', 'default');
            _this.props.onExitClick();
        };
        _tea.collectWithCustomizeFn.setParam('mode', 'full_screen');
        return _this;
    }

    (0, _createClass3.default)(FullSpreadsheet, [{
        key: 'render',
        value: function render() {
            var props = this.props;

            return _react2.default.createElement(_spreadsheet2.default, { tabEditable: false, showComment: false, className: "full-spreadsheet-wrap", token: this.props.collaSpread.context.getToken(), editable: props.editable, mode: "full_screen", freezeSheetToggle: props.freezeSheetToggle, showFindbar: props.showFindbar, showHyperlinkEditor: props.showHyperlinkEditor, exitFullScreenMode: this.handleExitClick, hideHistory: function hideHistory() {
                    return;
                }, collaSpread: this.props.collaSpread, tabElement: _FullSheetTabs.FullSheetTabs, tabLeft: _react2.default.createElement("button", { className: "full-spreadsheet__shrink", onClick: this.handleExitClick }, _react2.default.createElement(_shrink2.default, { className: "full-spreadsheet__shrink-icon" })) });
        }
    }]);
    return FullSpreadsheet;
}(_react2.default.PureComponent);
// import { Subscription } from 'rxjs/Subscription';
// import { VerticalAlign, WORD_WRAP_TYPE } from '$constants/sheet';


exports.default = (0, _reactRedux.connect)(function (state) {
    return {
        editable: (0, _sheet.editableSelector)(state)
    };
}, function (dispatch) {
    return (0, _redux.bindActionCreators)({
        freezeSheetToggle: _sheet2.freezeSheetToggle,
        showFindbar: _sheet2.showFindbar,
        showHyperlinkEditor: _sheet2.showHyperlinkEditor
    }, dispatch);
})(FullSpreadsheet);

/***/ }),

/***/ 3068:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M15.57 14.16l3.54 3.54a1 1 0 1 1-1.41 1.41l-3.54-3.54v1.59a1 1 0 0 1-2 0v-5h5a1 1 0 1 1 0 2h-1.59zM9.16 7.75V6.16a1 1 0 0 1 2 0v5h-5a1 1 0 0 1 0-2h1.59L4.29 5.71a1 1 0 0 1 1.42-1.42l3.45 3.46z", fillRule: "evenodd" })
  );
};

/***/ }),

/***/ 3069:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.FullSheetTabs = undefined;

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _pager = __webpack_require__(3070);

__webpack_require__(3075);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var FullSheetTabs = exports.FullSheetTabs = function (_React$PureComponent) {
    (0, _inherits3.default)(FullSheetTabs, _React$PureComponent);

    function FullSheetTabs() {
        (0, _classCallCheck3.default)(this, FullSheetTabs);

        var _this = (0, _possibleConstructorReturn3.default)(this, (FullSheetTabs.__proto__ || Object.getPrototypeOf(FullSheetTabs)).apply(this, arguments));

        _this.handlePageChange = function (page) {
            var workbook = _this.props.spread;
            var activeSheet = workbook.getActiveSheet();
            if (activeSheet && activeSheet.isEditing()) {
                activeSheet.endEdit();
            }
            workbook._doSheetTabClickChange(page);
            _this.forceUpdate();
        };
        return _this;
    }

    (0, _createClass3.default)(FullSheetTabs, [{
        key: 'componentDidMount',
        value: function componentDidMount() {
            this.props.spread._tab = this;
        }
    }, {
        key: 'componentWillUnmount',
        value: function componentWillUnmount() {
            this.props.spread._tab = null;
        }
    }, {
        key: 'componentDidUpdate',
        value: function componentDidUpdate() {
            var props = this.props;
            var spread = props.spread;

            if (spread.sheets.length === 0 && props.exitFullScreenMode) {
                props.exitFullScreenMode();
            } else {
                spread.sheets.forEach(function (sheet) {
                    sheet.defaults.rowHeaderColWidth = 40;
                    sheet.endEdit();
                });
            }
        }
    }, {
        key: 'repaint',
        value: function repaint() {
            this.forceUpdate();
        }
    }, {
        key: 'render',
        value: function render() {
            var props = this.props;
            var spread = props.spread;

            return _react2.default.createElement("div", { className: "full-sheet-tabs layout-row layout-main-cross-center", style: { height: 64 } }, _react2.default.createElement("div", { className: "full-sheet-tabs__left" }, props.leftExtra), _react2.default.createElement(_pager.Pager, { value: spread.getActiveSheetIndex(), size: spread.sheets.length, onChange: this.handlePageChange }), _react2.default.createElement("div", { className: "full-sheet-tabs__right" }, props.rightExtra));
        }
    }]);
    return FullSheetTabs;
}(_react2.default.PureComponent);

/***/ }),

/***/ 3070:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _Pager = __webpack_require__(3071);

Object.keys(_Pager).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function get() {
      return _Pager[key];
    }
  });
});

/***/ }),

/***/ 3071:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.Pager = undefined;

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _left = __webpack_require__(3072);

var _left2 = _interopRequireDefault(_left);

var _right = __webpack_require__(3073);

var _right2 = _interopRequireDefault(_right);

__webpack_require__(3074);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var Pager = exports.Pager = function (_React$PureComponent) {
    (0, _inherits3.default)(Pager, _React$PureComponent);

    function Pager() {
        (0, _classCallCheck3.default)(this, Pager);

        var _this = (0, _possibleConstructorReturn3.default)(this, (Pager.__proto__ || Object.getPrototypeOf(Pager)).apply(this, arguments));

        _this.handlePrevClick = function () {
            var props = _this.props;

            props.onChange(props.value - 1);
        };
        _this.handleNextClick = function () {
            var props = _this.props;

            props.onChange(props.value + 1);
        };
        return _this;
    }

    (0, _createClass3.default)(Pager, [{
        key: 'render',
        value: function render() {
            var props = this.props;
            var value = props.value,
                size = props.size;

            var page = value + 1;
            return _react2.default.createElement("div", { className: "pager layout-row layout-main-cross-center" }, _react2.default.createElement("button", { className: "pager__btn", disabled: page <= 1, onClick: this.handlePrevClick }, _react2.default.createElement(_left2.default, { className: "pager__btn-icon" })), _react2.default.createElement("span", { className: "pager__text" }, page, "/", size), _react2.default.createElement("button", { className: "pager__btn", disabled: page >= size, onClick: this.handleNextClick }, _react2.default.createElement(_right2.default, { className: "pager__btn-icon" })));
        }
    }]);
    return Pager;
}(_react2.default.PureComponent);

/***/ }),

/***/ 3072:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ xmlns: "http://www.w3.org/2000/svg", width: "12", height: "12", viewBox: "0 0 12 12" }, props),
    _react2.default.createElement("path", { d: "M3.7 6l4.65-4.65a.5.5 0 1 0-.7-.7L2.29 6l5.36 5.35a.5.5 0 0 0 .7-.7L3.71 6z" })
  );
};

/***/ }),

/***/ 3073:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ xmlns: "http://www.w3.org/2000/svg", width: "12", height: "12", viewBox: "0 0 12 12" }, props),
    _react2.default.createElement("path", { d: "M8.09 6L3.44 1.35a.5.5 0 1 1 .7-.7L9.5 6l-5.35 5.35a.5.5 0 0 1-.71-.7L8.09 6z" })
  );
};

/***/ }),

/***/ 3074:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3075:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3076:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});

var _regenerator = __webpack_require__(13);

var _regenerator2 = _interopRequireDefault(_regenerator);

var _asyncToGenerator2 = __webpack_require__(99);

var _asyncToGenerator3 = _interopRequireDefault(_asyncToGenerator2);

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _typeof2 = __webpack_require__(76);

var _typeof3 = _interopRequireDefault(_typeof2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _bind = __webpack_require__(503);

var _classnames = __webpack_require__(29);

var _classnames2 = _interopRequireDefault(_classnames);

var _browserHelper = __webpack_require__(34);

var _browserHelper2 = _interopRequireDefault(_browserHelper);

var _teaCollector = __webpack_require__(517);

var _teaCollector2 = _interopRequireDefault(_teaCollector);

var _tea = __webpack_require__(47);

var _sheet = __webpack_require__(713);

var _dom = __webpack_require__(1610);

var _spin = __webpack_require__(1811);

var _toast = __webpack_require__(500);

var _toast2 = _interopRequireDefault(_toast);

var _MentionNotificationQueue = __webpack_require__(2047);

var _MentionNotificationQueue2 = _interopRequireDefault(_MentionNotificationQueue);

var _const = __webpack_require__(1581);

var _formulabar = __webpack_require__(3078);

var _formulabar2 = _interopRequireDefault(_formulabar);

var _formula_list = __webpack_require__(3081);

var _formula_list2 = _interopRequireDefault(_formula_list);

var _findbar = __webpack_require__(3084);

var _findbar2 = _interopRequireDefault(_findbar);

var _dropdown = __webpack_require__(3091);

var _dropdown2 = _interopRequireDefault(_dropdown);

var _hyperlinkEditor = __webpack_require__(3106);

var _imageUploader = __webpack_require__(3115);

var _optionPasteDialog = __webpack_require__(3121);

var _toolbar = __webpack_require__(3125);

var _status = __webpack_require__(1820);

var _comment = __webpack_require__(2031);

var _comment2 = _interopRequireDefault(_comment);

var _footerstatus = __webpack_require__(3223);

var _footerstatus2 = _interopRequireDefault(_footerstatus);

var _exportFile = __webpack_require__(3226);

var _exportFile2 = _interopRequireDefault(_exportFile);

var _addRows = __webpack_require__(3229);

var _tabs = __webpack_require__(2032);

var _collaborative = __webpack_require__(1607);

var _utils = __webpack_require__(1575);

var _constants = __webpack_require__(1614);

var _Spread = __webpack_require__(1802);

var _modal = __webpack_require__(1623);

var _Mention = __webpack_require__(1805);

var _Mention2 = _interopRequireDefault(_Mention);

var _io = __webpack_require__(717);

var _backup = __webpack_require__(1713);

var _sheet2 = __webpack_require__(713);

__webpack_require__(2041);

var _ui_sheet = __webpack_require__(1807);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var __decorate = undefined && undefined.__decorate || function (decorators, target, key, desc) {
    var c = arguments.length,
        r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc,
        d;
    if ((typeof Reflect === "undefined" ? "undefined" : (0, _typeof3.default)(Reflect)) === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);else for (var i = decorators.length - 1; i >= 0; i--) {
        if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    }return c > 3 && r && Object.defineProperty(target, key, r), r;
};
// import FilterMenu from '../filtermenu';

var OFFLINE_TOAST_KEY = '__OFFLINE_TOAST__';

var Spreadsheet = function (_React$Component) {
    (0, _inherits3.default)(Spreadsheet, _React$Component);

    function Spreadsheet(props) {
        var _this2 = this;

        (0, _classCallCheck3.default)(this, Spreadsheet);

        var _this = (0, _possibleConstructorReturn3.default)(this, (Spreadsheet.__proto__ || Object.getPrototypeOf(Spreadsheet)).call(this, props));

        _this._network = _io.NetworkState.online;
        _this._disableOfflineEdit = false;
        _this.getBindList = function () {
            return {
                context: [{ key: _collaborative.CollaborativeEvents.CLIENT_VARS, handler: _this.onClientVars }, { key: _collaborative.CollaborativeEvents.SPREAD_LOADED, handler: _this.onSpreadLoaded }, { key: _collaborative.CollaborativeEvents.ERROR, handler: _this.onError }, { key: _collaborative.CollaborativeEvents.LOCAL_CONFLICT, handler: _this.onConflict }, { key: _collaborative.CollaborativeEvents.REJECT_COMMIT, handler: _this.onConflict }, { key: _collaborative.CollaborativeEvents.RECEIVE_RECOVER, handler: _this.onReceiveRecover }, { key: _collaborative.CollaborativeEvents.FREEZE_SPREAD, handler: _this.freezeSpread }, { key: _collaborative.CollaborativeEvents.REFETCH_CLIENT_VARS, handler: _this.refetchClientVars }, { key: _collaborative.CollaborativeEvents.CHANNEL_STATE_CHANGE, handler: _this.onChannelStateChange }, { key: _collaborative.CollaborativeEvents.OFFLINE_SAVE_ERROR, handler: _this.onOfflineSaveError }, { key: _collaborative.CollaborativeEvents.SoftDelSheet, handler: _this.handleActiveSheetChanged }],
                spread: [{ key: _sheet.Events.ValueChanged, handler: _this.handleCellValueChanged }, { key: _sheet.Events.InvalidOperation, handler: _this.handleInvalidOperation }, { key: _sheet.Events.DragDropBlockCompleted, handler: _this.handleDragDrop }, { key: _sheet.Events.ActiveSheetChanged, handler: _this.handleActiveSheetChanged }, { key: _sheet.Events.FormulatextboxActiveSheetChanged, handler: _this.handleActiveSheetChanged }]
            };
        };
        _this._doResize = function () {
            var height = _this._fasterDom.clientHeight;
            var width = _this._fasterDom.clientWidth;
            _this._shell && _this._shell.ui().updateByCfg({ width: width, height: height });
        };
        // 同一文档别的 tab 有编辑时候, 当前页面禁止编辑
        _this.onLocalStorage = function (e) {
            var key = e.key,
                newValue = e.newValue;

            if (key === _backup.OFFLINE_SYNC && newValue && _this._network === _io.NetworkState.offline && _this.props.editable && !_this._disableOfflineEdit) {
                var ctx = _this._context;

                var _JSON$parse = JSON.parse(newValue),
                    memberId = _JSON$parse.memberId,
                    token = _JSON$parse.token;

                if (token === ctx.getToken() && memberId !== ctx.getMemberId()) {
                    _this._disableOfflineEdit = true;
                    _this.freezeSheet(true);
                    _toast2.default.show({
                        key: OFFLINE_TOAST_KEY,
                        type: 'error',
                        content: t('common.offline.disable_multi_edit'),
                        duration: 0,
                        closable: true
                    });
                }
            }
        };
        _this.handleActiveSheetChanged = function () {
            var activeSheet = _this._collaSpread.getActiveSheet();
            activeSheet.setSheetHost(_this._fasterDom);
            _this._shell.updateSheet(activeSheet);
            var sel = activeSheet.getSelections();
            if (sel.length === 0) {
                activeSheet.setSelection(0, 0, 1, 1);
            }
        };
        _this.handleCellValueChanged = function (type, event) {
            var segmentArray = event.newValue;
            var oldArray = event.oldValue;
            if (!Array.isArray(segmentArray)) {
                return;
            }
            // 单元格里目前不能at group，因此只考虑过滤user
            var oldUser = [];
            if (Array.isArray(oldArray)) {
                oldUser = oldArray.reduce(function (pre, seg) {
                    if (seg.type === 'mention' && seg.mentionType === 0 && seg.mentionNotify) {
                        pre.push(seg.token);
                    }
                    return pre;
                }, []);
            }
            var toUsers = segmentArray.reduce(function (pre, seg) {
                if (seg.type === 'mention' && seg.mentionType === 0 && seg.mentionNotify && !oldUser.includes(seg.token)) {
                    pre.push(seg.token);
                }
                return pre;
            }, []);
            var toGroup = segmentArray.reduce(function (pre, seg) {
                if (seg.type === 'mention' && seg.mentionType === 6 && seg.mentionNotify) {
                    pre.push(seg.token);
                }
                return pre;
            }, []);
            var source = _this.props.mode === 'full_screen' ? _const.SOURCE_ENUM.DOC : _const.SOURCE_ENUM.SHEET;
            _MentionNotificationQueue2.default.addGroupMention(toGroup, source, '');
            _MentionNotificationQueue2.default.addUserMention(toUsers, source);
            _MentionNotificationQueue2.default.sendMentionNotifications();
        };
        _this.handleInvalidOperation = function (event, args) {
            if (args.invalidType === _sheet.InvalidOperationType.invalidSheetName) {
                var subInvalidType = args.subInvalidType;
                var invalidSheetName = args.invalidSheetName;
                var options = {};
                switch (subInvalidType) {
                    case _utils.SheetNameValidType.repeat:
                        Object.assign(options, { body: t('sheet.error.repeat_sheet_name', invalidSheetName) });
                        break;
                    case _utils.SheetNameValidType.length:
                        Object.assign(options, {
                            body: t('sheet.error.name_rule', t('sheet.error.sheet_name_too_long')).split('\\n').map(function (text) {
                                return _react2.default.createElement("div", { key: text }, text);
                            })
                        });
                        break;
                    case _utils.SheetNameValidType.invalid:
                        Object.assign(options, {
                            body: t('sheet.error.name_rule', t('sheet.error.sheet_name_invalid_symbols')).split('\\n').map(function (text) {
                                return _react2.default.createElement("div", { key: text }, text);
                            })
                        });
                }
                (0, _modal.showError)(_modal.ErrorTypes.ERROR_INVALID_SHEET_NAME, options);
            }
        };
        _this.onSpreadLoaded = function () {
            // 如果是全屏模式
            _this.freezeSheet(false);
            _this.setEditable(_this.props.editable);
            _this._collaSpread.spread.focus(true);
            (0, _modal.removeSpreadToast)();
            _this.setState({ spreadLoaded: true });
            var hostElement = _this._fasterDom;
            if (!hostElement) {
                console.error('检测不到 host');
            } else {
                hostElement.className += ' spread-loaded';
            }
            window.dispatchEvent((0, _dom.createCustomEvent)('sheetDidRender'));
        };
        _this.onClientVars = function () {
            (0, _modal.removeSpreadToast)();
            (0, _modal.showSpreadLoadingToast)(t('sheet.still_loading_tips'));
            _this.handleActiveSheetChanged();
            _this.setEditable(_this.props.editable);
            _this._doResize();
            _this._shell.exec();
            _this.setState({ loading: false });
        };
        _this.refetchClientVars = function () {
            _this.setState({ loading: true, spreadLoaded: false });
            _this.freezeSheet(true);
            (0, _modal.showSpreadLoadingToast)(t('sheet.syncing'));
        };
        _this.onChannelStateChange = function () {
            var _ref = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee(data) {
                var context, localBaseRev;
                return _regenerator2.default.wrap(function _callee$(_context2) {
                    while (1) {
                        switch (_context2.prev = _context2.next) {
                            case 0:
                                _this._network = data.channelState;
                                _context2.t0 = data.channelState;
                                _context2.next = _context2.t0 === _io.NetworkState.online ? 4 : _context2.t0 === _io.NetworkState.offline ? 11 : 14;
                                break;

                            case 4:
                                if (_this._disableOfflineEdit) {
                                    _this._disableOfflineEdit = false;
                                    _this.freezeSheet(false);
                                }
                                context = _this._context;
                                _context2.next = 8;
                                return (0, _backup.checkBackupRev)(context.getToken(), context.userId, context.getMemberId());

                            case 8:
                                localBaseRev = _context2.sent;

                                if (localBaseRev >= 0) {
                                    _toast2.default.show({
                                        key: OFFLINE_TOAST_KEY,
                                        type: 'success',
                                        content: t('common.reconnected_tips'),
                                        duration: 3000
                                    });
                                } else {
                                    _toast2.default.remove(OFFLINE_TOAST_KEY);
                                }
                                return _context2.abrupt("break", 14);

                            case 11:
                                _toast2.default.remove(OFFLINE_TOAST_KEY);
                                _toast2.default.show({
                                    key: OFFLINE_TOAST_KEY,
                                    type: 'error',
                                    content: t('common.disconnected_tips'),
                                    duration: 0,
                                    closable: true
                                });
                                return _context2.abrupt("break", 14);

                            case 14:
                            case "end":
                                return _context2.stop();
                        }
                    }
                }, _callee, _this2);
            }));

            return function (_x) {
                return _ref.apply(this, arguments);
            };
        }();
        _this.onError = function () {
            var _ref2 = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee2(data) {
                var context, token, userId, memberId, localBaseRev;
                return _regenerator2.default.wrap(function _callee2$(_context3) {
                    while (1) {
                        switch (_context3.prev = _context3.next) {
                            case 0:
                                context = _this._context;
                                token = context.getToken();
                                userId = context.userId;
                                memberId = context.getMemberId();
                                // 版本太旧同时本地有版本则走冲突处理逻辑

                                if (!(data.code === _constants.Errors.ERR_OLD_VERSION)) {
                                    _context3.next = 12;
                                    break;
                                }

                                _context3.next = 7;
                                return (0, _backup.checkBackupRev)(token, userId, memberId);

                            case 7:
                                localBaseRev = _context3.sent;

                                if (!(localBaseRev >= 0)) {
                                    _context3.next = 10;
                                    break;
                                }

                                return _context3.abrupt("return");

                            case 10:
                                _context3.next = 12;
                                return (0, _backup.clearBackup)(token, userId, memberId);

                            case 12:
                                if (!(data.code === _constants.Errors.ERR_CHANGESET_EXCEED_LIMIT || data.code === _constants.Errors.ERROR_MAX_CELL_LIMIT)) {
                                    _context3.next = 15;
                                    break;
                                }

                                _context3.next = 15;
                                return (0, _backup.clearBackup)(token, userId, memberId);

                            case 15:
                                _this.freezeSheet(true);
                                _this.setState({
                                    loading: false
                                });
                                (0, _modal.showServerErrorModal)(data.code, 'spreadsheet');

                            case 18:
                            case "end":
                                return _context3.stop();
                        }
                    }
                }, _callee2, _this2);
            }));

            return function (_x2) {
                return _ref2.apply(this, arguments);
            };
        }();
        _this.onConflict = function () {
            _this.freezeSheet(true);
            _toast2.default.remove(OFFLINE_TOAST_KEY);
        };
        _this.onOfflineSaveError = function () {
            _this.freezeSheet(true);
            _toast2.default.show({
                key: OFFLINE_TOAST_KEY,
                type: 'error',
                content: t('common.save_local_error'),
                duration: 0,
                closable: true
            });
        };
        _this.onReceiveRecover = function (rev) {
            (0, _tea.collectSuiteEvent)('show_history_restore_tips', { revision_id: rev });
            _this.freezeSheet(true);
            (0, _modal.showError)(_modal.ErrorTypes.ERROR_RECEIVE_RECOVER, {
                onConfirm: function onConfirm() {
                    _this._context.trigger(_collaborative.CollaborativeEvents.CONFIRM_RECOVER);
                    _this.props.hideHistory();
                    (0, _tea.collectSuiteEvent)('click_history_restore_tips_action', {
                        revision_id: rev,
                        action: 'refresh'
                    });
                },
                onCancel: function onCancel() {
                    _this.props.hideHistory();
                    (0, _tea.collectSuiteEvent)('click_history_restore_tips_action', {
                        revision_id: rev,
                        action: 'close'
                    });
                }
            });
        };
        _this.freezeSpread = function () {
            _this.freezeSheet(true);
            (0, _modal.showSpreadErrorToast)(t('sheet.forzen_refresh'));
        };
        _this._onKeydown = function (e) {
            // 加载就不能使用快捷键
            if (_this.state.loading) {
                return;
            }
            // 处理查找替换 key f, h
            if (e.keyCode === 70 || e.keyCode === 72) {
                _this.handleFindReplace(e);
                return;
            }
            // f2 快捷键 进入编辑模式
            if (e.keyCode === 113) {
                var spread = _this._collaSpread.spread;
                spread.getActiveSheet().startEdit(false);
                return;
            }
            // 不能编辑不能使用快捷键
            if (_this.props.editable) {
                // 超链接快捷键
                if (e.keyCode === 75) {
                    var _spread = _this._collaSpread.spread;
                    _this.handleHyperLink(e, _spread);
                    return;
                }
                _this._collaSpread.doKeydown(e);
            }
        };
        _this._setFasterDom = function (elem) {
            _this._fasterDom = elem;
        };
        _this.getCanvasBoundingRect = function () {
            if (_this._fasterDom) return _this._fasterDom.getBoundingClientRect();else return document.body.getBoundingClientRect();
        };
        _this.state = {
            loading: true,
            spreadLoaded: props.collaSpread.spreadLoaded
        };
        _this._context = props.collaSpread.context;
        _this._collaSpread = props.collaSpread;
        _this.freezeSheet = _this.freezeSheet.bind(_this);
        _this._alreadyLoaded = _this.state.spreadLoaded === true;
        return _this;
    }

    (0, _createClass3.default)(Spreadsheet, [{
        key: "componentDidMount",
        value: function componentDidMount() {
            var showTips = false;
            // 部分操作系统和浏览器版本会有性能问题，弹出提示
            if (_browserHelper2.default.chrome) {
                var chromeVersion = _browserHelper2.default.version.toString().slice(0, 2);
                if (chromeVersion === '65') {
                    // Chrome 65
                    if (_browserHelper2.default.mac) {
                        var macVersion = _browserHelper2.default.osversion.toString().slice(0, 5);
                        if (macVersion === '10.10' || macVersion === '10.11') {
                            // Mac 10.10 / 10.11
                            showTips = true;
                        }
                    } else if (_browserHelper2.default.windows) {
                        // windows
                        showTips = true;
                    }
                }
            }
            if (showTips) {
                _toast2.default.error({
                    closable: true,
                    duration: 0,
                    content: t('warn.low_chrome_and_mac_version_tips')
                });
            }
            var props = this.props;

            var collaSpread = this._collaSpread;
            this.createShell(this._fasterDom);
            _Spread.Spread.spread = collaSpread.spread;
            this.switch(props.token);
            this._mention = new _Mention2.default({
                spread: this._collaSpread.spread,
                context: this._context,
                container: this._workbookContainer,
                getCanvasBoundingRect: this.getCanvasBoundingRect
            });
            window.addEventListener('keydown', this._onKeydown);
            window.addEventListener('resize', this._doResize);
            // full spread
            if (this._alreadyLoaded) {
                this.onClientVars();
                this.onSpreadLoaded();
            }
        }
    }, {
        key: "componentWillUpdate",
        value: function componentWillUpdate(nextProps) {
            var _this3 = this;

            var props = this.props,
                _context = this._context; // 切换了文档

            if (nextProps.token !== props.token) {
                if (props.token) {
                    this.reset();
                }
                this.switch(nextProps.token);
            }
            if (nextProps.editable !== props.editable) {
                this._collaSpread.setEditable(nextProps.editable);
            }
            // 从没有编辑权限到获得编辑权限, 检测本地是否有离线编辑, 如果有则刷新
            if (nextProps.editablePermission && nextProps.editablePermission !== props.editablePermission) {
                (0, _backup.checkBackupRev)(_context.getToken(), _context.userId, _context.getMemberId()).then(function (rev) {
                    if (rev > -1) {
                        _this3._context.trigger(_collaborative.CollaborativeEvents.CONFLICT_HANDLE);
                    }
                });
                return;
            }
            if (nextProps.editable !== props.editable) {
                this.setEditable(nextProps.editable);
            }
        }
    }, {
        key: "componentWillUnmount",
        value: function componentWillUnmount() {
            _toast2.default.remove(OFFLINE_TOAST_KEY);
            (0, _modal.removeSpreadToast)();
            this.freezeSheet(false);
            this.unbindCollaborativeEvents();
            this._mention.destory();
            _Spread.Spread.spread = null;
            window.removeEventListener('keydown', this._onKeydown);
            window.removeEventListener('resize', this._doResize);
            this._shell && this._shell.exit();
        }
    }, {
        key: "createShell",
        value: function createShell(container) {
            this._shell = new _ui_sheet.SheetShell(container, this._collaSpread.spread, this._context);
        }
        /**
         * 切换文档
         */

    }, {
        key: "switch",
        value: function _switch(token) {
            if (token) {
                this._collaSpread.bindEvents();
                this.bindCollaborativeEvents();
            }
        }
    }, {
        key: "reset",
        value: function reset() {
            (0, _modal.removeSpreadToast)();
            this.setState({
                loading: true
            });
            this.freezeSheet(false);
            this.unbindCollaborativeEvents();
            this._collaSpread.reset();
        }
    }, {
        key: "bindCollaborativeEvents",
        value: function bindCollaborativeEvents() {
            var context = this._context;
            var spread = this._collaSpread.spread;
            this._collaSpread.bindCollaborativeEvents();
            var bindList = this.getBindList();
            bindList.context.forEach(function (event) {
                context.bind(event.key, event.handler);
            });
            bindList.spread.forEach(function (event) {
                spread.bind(event.key, event.handler);
            });
            window.addEventListener('storage', this.onLocalStorage);
        }
    }, {
        key: "unbindCollaborativeEvents",
        value: function unbindCollaborativeEvents() {
            var context = this._context;
            var spread = this._collaSpread.spread;
            var bindList = this.getBindList();
            bindList.context.forEach(function (event) {
                context.unbind(event.key, event.handler);
            });
            bindList.spread.forEach(function (event) {
                spread.unbind(event.key, event.handler);
            });
            window.removeEventListener('storage', this.onLocalStorage);
        }
    }, {
        key: "handleDragDrop",
        value: function handleDragDrop() {
            (0, _tea.collectSuiteEvent)('sheet_opration', {
                action: 'drag_drop',
                source: 'body',
                eventType: 'click'
            });
        }
    }, {
        key: "setEditable",
        value: function setEditable(b) {
            this._collaSpread.setEditable(b);
            this._shell && this._shell.setEditable(b);
        }
    }, {
        key: "handleFindReplace",
        value: function handleFindReplace(e) {
            var shiftKey = e.shiftKey,
                altKey = e.altKey,
                keyCode = e.keyCode;
            var ctrlKey = e.ctrlKey,
                metaKey = e.metaKey;

            if (_browserHelper2.default.mac) {
                var _ref3 = [metaKey, ctrlKey];
                // mac与window的ctrl与win键是相反的
                // 这里将他们的值调换，以window的快捷键思考即可

                ctrlKey = _ref3[0];
                metaKey = _ref3[1];
            } // ctrl + f, open find
            if (keyCode === _sheet2.KeyCode.F && ctrlKey && !shiftKey && !metaKey && !altKey) {
                e.preventDefault();
                this.props.showFindbar();
                return;
            } // ctrl + shift + h, open find and replace
            if (keyCode === _sheet2.KeyCode.H && ctrlKey && shiftKey && !metaKey && !altKey) {
                e.preventDefault();
                this.props.showFindbar(true);
                return;
            }
        }
    }, {
        key: "handleHyperLink",
        value: function handleHyperLink(e, spread) {
            var shiftKey = e.shiftKey,
                altKey = e.altKey,
                keyCode = e.keyCode;
            var ctrlKey = e.ctrlKey,
                metaKey = e.metaKey;

            if (_browserHelper2.default.mac) {
                var _ref4 = [metaKey, ctrlKey];
                ctrlKey = _ref4[0];
                metaKey = _ref4[1];
            }
            // ctrl + k, 打开超链接编辑框
            if (keyCode === _sheet2.KeyCode.K && ctrlKey && !shiftKey && !metaKey && !altKey) {
                e.preventDefault();
                var sheet = spread && spread.getActiveSheet();
                if (sheet) {
                    var row = sheet.getActiveRowIndex();
                    var col = sheet.getActiveColumnIndex();
                    var id = sheet.id();
                    this.props.showHyperlinkEditor(row, col, id, 'cell');
                }
                return;
            }
        }
        /**
         * TODO: 是否冻结并且不让编辑应该由多种状态决定
         * error, permission, loading, setting等
         * 要改为位存储，而不是一个简单的boolean
         */

    }, {
        key: "freezeSheet",
        value: function freezeSheet(freeze) {
            this.props.freezeSheetToggle && this.props.freezeSheetToggle(freeze);
        }
    }, {
        key: "render",
        value: function render() {
            var _this4 = this;

            var props = this.props,
                state = this.state;

            var context = this._context;
            var editable = props.editable,
                showComment = props.showComment,
                token = props.token;
            var loading = state.loading,
                spreadLoaded = state.spreadLoaded;

            var spread = this._collaSpread.spread;
            var getCanvasBoundingRect = this.getCanvasBoundingRect;
            return _react2.default.createElement("div", { className: (0, _classnames2.default)('spreadsheet-wrap layout-column flex', props.className) }, loading && _react2.default.createElement("div", { className: "spreadsheet-wrap__spin layout-column layout-main-cross-center" }, _react2.default.createElement(_spin.Spin, null)), _react2.default.createElement(props.tabElement || _tabs.SheetTabs, {
                editable: props.tabEditable !== false && editable,
                spread: spread,
                leftExtra: props.tabLeft || _react2.default.createElement("div", { style: { width: 40 } }),
                rightExtra: !loading && _react2.default.createElement(_footerstatus2.default, null),
                exitFullScreenMode: props.exitFullScreenMode
            }), _react2.default.createElement(_status.SheetStatusCollector, { spread: loading ? null : spread }), _react2.default.createElement(_exportFile2.default, { spread: loading ? null : spread, freezeSheet: this.freezeSheet }), _react2.default.createElement(_toolbar.SheetToolbar, { className: "sheet-toolbar modern-ui layout-row layout-cross-center", disabled: !editable || loading, showComment: showComment, spread: spread, doResize: this._doResize, mode: props.mode || 'default' }), _react2.default.createElement("div", { className: "flex layout-row" }, _react2.default.createElement("div", { className: "flex layout-column" }, _react2.default.createElement(_formulabar2.default, { editable: editable && !loading, spread: spread, doResize: this._doResize }), _react2.default.createElement("div", { className: "workbook-wrap layout-column flex", ref: function ref(_ref5) {
                    return _this4._workbookContainer = _ref5;
                } }, _react2.default.createElement("div", { className: "spreadsheet flex", ref: this._setFasterDom }), _react2.default.createElement(_hyperlinkEditor.HyperlinkEditor, { spread: spread, context: context, getCanvasBoundingRect: this.getCanvasBoundingRect }), _react2.default.createElement(_imageUploader.ImageUploader, { spread: spread, context: context }), _react2.default.createElement(_optionPasteDialog.OptionPasteDialog, { spread: spread, context: context }), _react2.default.createElement(_dropdown.DropdownList, { spread: spread, editable: editable, getCanvasBoundingRect: this.getCanvasBoundingRect }), _react2.default.createElement(_dropdown.DropdownPop, { spread: spread, editable: editable }), !loading && _react2.default.createElement(_addRows.AddRows, { spread: spread, context: context, editable: editable })), _react2.default.createElement(_formula_list2.default, { spread: spread }), _react2.default.createElement(_findbar2.default, { spread: spread }), _react2.default.createElement(_dropdown2.default, { spread: spread })), showComment === false ? null : _react2.default.createElement(_react2.default.Fragment, null, _react2.default.createElement("div", { className: "doc-position" }), _react2.default.createElement("div", { className: "spreadsheet-comment-wrapper layout-column" }, spreadLoaded && _react2.default.createElement(_comment2.default, { doResize: this._doResize, spread: spread, context: context, token: token })))));
        }
    }]);
    return Spreadsheet;
}(_react2.default.Component);

__decorate([(0, _bind.Bind)(), (0, _teaCollector2.default)('sheet_opration', 'keydown', 'body', function (self, e) {
    var shiftKey = e.shiftKey,
        altKey = e.altKey,
        keyCode = e.keyCode;
    var metaKey = e.metaKey,
        ctrlKey = e.ctrlKey;

    if (_browserHelper2.default.mac) {
        var _ref6 = [metaKey, ctrlKey];
        ctrlKey = _ref6[0];
        metaKey = _ref6[1];
    }
    if (keyCode === _sheet2.KeyCode.F && ctrlKey && !metaKey && !shiftKey && !altKey) {
        return 'ctrl_f';
    }
    if (keyCode === _sheet2.KeyCode.H && ctrlKey && !metaKey && shiftKey && !altKey) {
        return 'ctrl_shift_h';
    }
    return '';
})], Spreadsheet.prototype, "handleFindReplace", null);
__decorate([(0, _bind.Bind)(), (0, _teaCollector2.default)('sheet_opration', 'keydown', 'body', function (self, e) {
    var shiftKey = e.shiftKey,
        altKey = e.altKey,
        keyCode = e.keyCode;
    var metaKey = e.metaKey,
        ctrlKey = e.ctrlKey;

    if (_browserHelper2.default.mac) {
        var _ref7 = [metaKey, ctrlKey];
        ctrlKey = _ref7[0];
        metaKey = _ref7[1];
    }
    if (keyCode === _sheet2.KeyCode.K && ctrlKey && !metaKey && !shiftKey && !altKey) {
        return _browserHelper2.default.mac ? 'command_k' : 'ctrl_k';
    }
    return '';
})], Spreadsheet.prototype, "handleHyperLink", null);
exports.default = Spreadsheet;
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 3077:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.isGroupReadable = exports.isUserReadable = exports.confirmSharing = exports.DURATION_BEFORE_CLOSING = exports.TOAST_CONFIRM_RESULT = undefined;

var _regenerator = __webpack_require__(13);

var _regenerator2 = _interopRequireDefault(_regenerator);

var _asyncToGenerator2 = __webpack_require__(99);

var _asyncToGenerator3 = _interopRequireDefault(_asyncToGenerator2);

// 8s
/**
 * 弹出 toast 让用户确认是否分享文档
 *
 * 返回 `TOAST_CONFIRM_RESULT` 类型表示用户的决定
 */
var confirmSharing = exports.confirmSharing = function () {
    var _ref = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee(targetNames) {
        return _regenerator2.default.wrap(function _callee$(_context) {
            while (1) {
                switch (_context.prev = _context.next) {
                    case 0:
                        return _context.abrupt('return', new Promise(function (resolve) {
                            var key = generateToastKey();
                            var text = t('permission.mention.user', targetNames.join('' + t('common.separator')));
                            _toast2.default.show({
                                key: key,
                                content: _react2.default.createElement("div", { className: "toast-confirm" }, _react2.default.createElement("p", { className: "toast-text" }, text), _react2.default.createElement("button", { className: "toast-button", onClick: function onClick(e) {
                                        _toast2.default.remove(key);
                                        resolve(TOAST_CONFIRM_RESULT.CANCELED);
                                    } }, t('common.undo'))),
                                duration: DURATION_BEFORE_CLOSING,
                                className: 'permissionToast',
                                cancelText: t('common.undo'),
                                onClose: function onClose() {
                                    return resolve(TOAST_CONFIRM_RESULT.CONFIRMED);
                                }
                            });
                        }));

                    case 1:
                    case 'end':
                        return _context.stop();
                }
            }
        }, _callee, this);
    }));

    return function confirmSharing(_x) {
        return _ref.apply(this, arguments);
    };
}();
/**
 * 从 state 获取当前的文档和用户信息
 */


/**
 * 检查指定用户是否可读当前文档
 *
 * 返回 null 表示请求失败
 */
var isUserReadable = exports.isUserReadable = function () {
    var _ref2 = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee2(shareInfo, userId) {
        var fileType, fileToken, res, code, data;
        return _regenerator2.default.wrap(function _callee2$(_context2) {
            while (1) {
                switch (_context2.prev = _context2.next) {
                    case 0:
                        fileType = shareInfo.fileType, fileToken = shareInfo.fileToken;
                        _context2.next = 3;
                        return (0, _apis.fetchUserPermission)({ fileType: fileType, fileToken: fileToken, userId: userId });

                    case 3:
                        res = _context2.sent;
                        code = res.code, data = res.data;

                        if (!(code !== 0)) {
                            _context2.next = 7;
                            break;
                        }

                        return _context2.abrupt('return', null);

                    case 7:
                        return _context2.abrupt('return', (0, _permissionHelper.permission2Booleans)(data.permissions).readable);

                    case 8:
                    case 'end':
                        return _context2.stop();
                }
            }
        }, _callee2, this);
    }));

    return function isUserReadable(_x2, _x3) {
        return _ref2.apply(this, arguments);
    };
}();
/**
 * 检查指定用户是否可读当前文档
 *
 * 返回 null 表示请求失败
 */


var isGroupReadable = exports.isGroupReadable = function () {
    var _ref3 = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee3(shareInfo, ownerId) {
        var type, token, res, code, data;
        return _regenerator2.default.wrap(function _callee3$(_context3) {
            while (1) {
                switch (_context3.prev = _context3.next) {
                    case 0:
                        type = shareInfo.fileType, token = shareInfo.fileToken;
                        _context3.next = 3;
                        return (0, _apis.fetchOwnerPermission)({ token: token, ownerType: _common.OWNER_TYPE.LARK_CHAT_GROUP, type: type, ownerId: ownerId });

                    case 3:
                        res = _context3.sent;
                        code = res.code, data = res.data;

                        if (!(code !== 0 || data.existed === null)) {
                            _context3.next = 7;
                            break;
                        }

                        return _context3.abrupt('return', null);

                    case 7:
                        return _context3.abrupt('return', Boolean(data.existed));

                    case 8:
                    case 'end':
                        return _context3.stop();
                }
            }
        }, _callee3, this);
    }));

    return function isGroupReadable(_x4, _x5) {
        return _ref3.apply(this, arguments);
    };
}();

exports.getCurrentShareInfo = getCurrentShareInfo;
exports.grantReadablePerm = grantReadablePerm;

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _toast = __webpack_require__(500);

var _toast2 = _interopRequireDefault(_toast);

var _apis = __webpack_require__(1631);

var _share = __webpack_require__(375);

var _permissionHelper = __webpack_require__(274);

var _suite = __webpack_require__(69);

var _user = __webpack_require__(56);

var _const = __webpack_require__(1581);

var _common = __webpack_require__(19);

var _common2 = __webpack_require__(19);

var _share2 = __webpack_require__(62);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var seed = 0; /**
               * 确认是否分享权限这方面逻辑的 helper
               */

function generateToastKey() {
    seed += 1;
    return 'toast_' + Date.now() + '_' + seed;
}
var TOAST_CONFIRM_RESULT = exports.TOAST_CONFIRM_RESULT = undefined;
(function (TOAST_CONFIRM_RESULT) {
    TOAST_CONFIRM_RESULT[TOAST_CONFIRM_RESULT["CONFIRMED"] = 0] = "CONFIRMED";
    TOAST_CONFIRM_RESULT[TOAST_CONFIRM_RESULT["CANCELED"] = 1] = "CANCELED";
})(TOAST_CONFIRM_RESULT || (exports.TOAST_CONFIRM_RESULT = TOAST_CONFIRM_RESULT = {}));
/** 撤销框停留的时间 */
var DURATION_BEFORE_CLOSING = exports.DURATION_BEFORE_CLOSING = 8 * 1000;function getCurrentShareInfo(state) {
    var fileToken = (0, _suite.selectCurrentSuiteToken)(state);
    var currentSuit = (0, _suite.selectCurrentSuiteByObjToken)(state);
    var fileType = currentSuit.get('type');
    var currentUser = (0, _user.selectCurrentUser)(state);
    var userId = currentUser.get('id');
    var userPermission = (0, _share.selectCurrentPermission)(state);
    var isShareable = (0, _permissionHelper.getUserPermissions)(userPermission.toJS()).shareable;
    return { fileType: fileType, fileToken: fileToken, userId: userId, isShareable: isShareable };
}
function getOwnerType(type) {
    return type === _const.TYPE_ENUM.USER ? _common.OWNER_TYPE.LARK : _common.OWNER_TYPE.LARK_CHAT_GROUP;
}
/**
 * 授予 targets 当前文档「可阅读」的权限
 */
function grantReadablePerm(_ref4) {
    var store = _ref4.store,
        shareInfo = _ref4.shareInfo,
        targets = _ref4.targets,
        source = _ref4.source;

    if (targets.length === 0) {
        return;
    }
    var fileType = shareInfo.fileType,
        fileToken = shareInfo.fileToken;

    var permission = _common2.PERMISSION.READABLE;
    var owners = targets.map(function (_ref5) {
        var type = _ref5.type,
            token = _ref5.token;
        return { owner_id: token, owner_type: getOwnerType(type), permission: permission };
    });
    return store.dispatch((0, _share2.bulkSetUserPermission)({
        token: fileToken,
        type: fileType,
        owners: owners,
        shouldNotifyLark: false,
        source: source
    }));
}
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 3078:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _formulabar = __webpack_require__(3079);

var _formulabar2 = _interopRequireDefault(_formulabar);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.default = _formulabar2.default;

/***/ }),

/***/ 3079:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.Formulabar = undefined;

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _typeof2 = __webpack_require__(76);

var _typeof3 = _interopRequireDefault(_typeof2);

var _isEqual2 = __webpack_require__(501);

var _isEqual3 = _interopRequireDefault(_isEqual2);

var _debounce2 = __webpack_require__(275);

var _debounce3 = _interopRequireDefault(_debounce2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _reactRedux = __webpack_require__(238);

var _sheet = __webpack_require__(1597);

var _bind = __webpack_require__(503);

var _string = __webpack_require__(158);

__webpack_require__(3080);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var __decorate = undefined && undefined.__decorate || function (decorators, target, key, desc) {
    var c = arguments.length,
        r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc,
        d;
    if ((typeof Reflect === "undefined" ? "undefined" : (0, _typeof3.default)(Reflect)) === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);else for (var i = decorators.length - 1; i >= 0; i--) {
        if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    }return c > 3 && r && Object.defineProperty(target, key, r), r;
};

var FormulaTextBox = GC.Spread.Sheets.FormulaTextBox.FormulaTextBox;
var FORMULABAR_MINI_HEIGHT = 24;
var FORMULABAR_MAX_HEIGHT = 224;

var Formulabar = exports.Formulabar = function (_Component) {
    (0, _inherits3.default)(Formulabar, _Component);

    function Formulabar(props) {
        (0, _classCallCheck3.default)(this, Formulabar);

        var _this = (0, _possibleConstructorReturn3.default)(this, (Formulabar.__proto__ || Object.getPrototypeOf(Formulabar)).call(this, props));

        _this.state = {
            formulabarHeight: FORMULABAR_MINI_HEIGHT
        };
        _this.draggerMouseDownHandler = function (e) {
            _this._dragging = true;
            _this._draggingY = e.clientY;
            _this._draggerHeight = _this.state.formulabarHeight;
            e.preventDefault();
        };
        _this.draggerMoveHandler = function (e) {
            if (!_this._dragging) {
                return;
            }
            var deltaY = e.clientY - _this._draggingY;
            var formulabarHeight = _this._draggerHeight + deltaY;
            if (formulabarHeight > FORMULABAR_MAX_HEIGHT) {
                formulabarHeight = FORMULABAR_MAX_HEIGHT;
            }
            if (formulabarHeight < FORMULABAR_MINI_HEIGHT) {
                formulabarHeight = FORMULABAR_MINI_HEIGHT;
            }
            _this.setState({ formulabarHeight: formulabarHeight });
        };
        _this.draggerMouseUpHandler = function (e) {
            _this._dragging = false;
        };
        _this.spreadDoResize = (0, _debounce3.default)(function () {
            _this.props.doResize && _this.props.doResize();
        }, 100);
        return _this;
    }

    (0, _createClass3.default)(Formulabar, [{
        key: "componentDidMount",
        value: function componentDidMount() {
            this.setFormulaTextBox(this.props.spread);
            this.bindDraggerEvent();
        }
    }, {
        key: "shouldComponentUpdate",
        value: function shouldComponentUpdate(nextProps, nextState) {
            var currProps = this.props;
            var currState = this.state;
            return !(0, _isEqual3.default)(nextProps, currProps) || !(0, _isEqual3.default)(nextState, currState);
        }
    }, {
        key: "componentWillUpdate",
        value: function componentWillUpdate(nextProps) {
            if (!(0, _isEqual3.default)(this.props.coord, nextProps.coord)) {
                this._formulabox && (this._formulabox.scrollTop = 0);
            }
            if (nextProps.spread !== this.props.spread) {
                this.setFormulaTextBox(nextProps.spread);
            }
        }
    }, {
        key: "componentDidUpdate",
        value: function componentDidUpdate(prevProps, prevState) {
            if (prevState.formulabarHeight !== this.state.formulabarHeight) {
                this.spreadDoResize();
            }
        }
    }, {
        key: "componentWillUnmount",
        value: function componentWillUnmount() {
            this.unbindDraggerEvent();
            this._fbx && this._fbx.destroy();
            this._fbx = null;
        }
    }, {
        key: "setFormulaElement",
        value: function setFormulaElement(el) {
            this._formulabox = el;
        }
    }, {
        key: "setFormulaTextBox",
        value: function setFormulaTextBox(spread) {
            if (spread) {
                this._fbx = new FormulaTextBox(this._formulabox, { menuContainer: this._formulabox.parentElement });
                this._fbx.workbook(spread);
            } else {
                this._fbx && this._fbx.destroy();
                this._fbx = null;
            }
        }
    }, {
        key: "bindDraggerEvent",
        value: function bindDraggerEvent() {
            window.addEventListener('mousemove', this.draggerMoveHandler);
            window.addEventListener('mouseup', this.draggerMouseUpHandler);
        }
    }, {
        key: "unbindDraggerEvent",
        value: function unbindDraggerEvent() {
            window.removeEventListener('mousemove', this.draggerMoveHandler);
            window.removeEventListener('mouseup', this.draggerMouseUpHandler);
        }
    }, {
        key: "render",
        value: function render() {
            var formulabarHeight = this.state.formulabarHeight;

            return _react2.default.createElement("div", { className: "formulabar", style: {
                    pointerEvents: this.props.editable ? 'initial' : 'none',
                    height: formulabarHeight + 'px'
                } }, _react2.default.createElement("div", { className: "formulabar__map layout-row" }, this.coord), _react2.default.createElement("div", { className: "formulabar__dragger", onMouseDown: this.draggerMouseDownHandler }), _react2.default.createElement("div", { ref: this.setFormulaElement, className: "formulabar__inputarea", contentEditable: true, spellCheck: false }));
        }
    }, {
        key: "coord",
        get: function get() {
            var _props$coord = this.props.coord,
                row = _props$coord.row,
                col = _props$coord.col;

            return (0, _string.intToAZ)(col) + (row + 1);
        }
    }]);
    return Formulabar;
}(_react.Component);

Formulabar.defaultProps = {
    coord: { row: 0, col: 0 }
};
__decorate([(0, _bind.Bind)()], Formulabar.prototype, "setFormulaElement", null);
exports.default = (0, _reactRedux.connect)(function (state) {
    return {
        coord: (0, _sheet.coordSelector)(state)
    };
})(Formulabar);

/***/ }),

/***/ 3080:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3081:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _redux = __webpack_require__(65);

var _reactRedux = __webpack_require__(238);

var _classnames = __webpack_require__(29);

var _classnames2 = _interopRequireDefault(_classnames);

var _reactTransitionGroup = __webpack_require__(1775);

var _tea = __webpack_require__(47);

var _sheet = __webpack_require__(715);

var _toolbarHelper = __webpack_require__(1606);

var _formulas = __webpack_require__(3082);

var _formulas2 = _interopRequireDefault(_formulas);

__webpack_require__(3083);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var FormulaList = function (_PureComponent) {
    (0, _inherits3.default)(FormulaList, _PureComponent);

    function FormulaList() {
        (0, _classCallCheck3.default)(this, FormulaList);

        var _this = (0, _possibleConstructorReturn3.default)(this, (FormulaList.__proto__ || Object.getPrototypeOf(FormulaList)).apply(this, arguments));

        _this.state = {
            exited: true
        };
        _this.onEnter = function () {
            _this.setState({ exited: false });
        };
        _this.onExited = function () {
            _this.setState({ exited: true });
        };
        _this.onClickFormula = function (formula) {
            (0, _toolbarHelper.setFormula)(_this.props.spread, formula);
            (0, _tea.collectSuiteEvent)('click_insert_formula', {
                source: 'sheet_formula_list',
                op_item: formula,
                eventType: 'click'
            });
        };
        return _this;
    }

    (0, _createClass3.default)(FormulaList, [{
        key: 'render',
        value: function render() {
            var _this2 = this;

            var props = this.props;

            var className = (0, _classnames2.default)('formulas-panel layout-column', {
                'formulas-panel_hidden': !props.visible && this.state.exited
            });
            return _react2.default.createElement(_reactTransitionGroup.CSSTransition, { in: props.visible, timeout: 150, classNames: "slide-right", onEnter: this.onEnter, onExited: this.onExited }, _react2.default.createElement("div", { className: className }, _react2.default.createElement("h3", { className: "formulas-panel__head layout-row layout-cross-center" }, t('sheet.insert_function'), _react2.default.createElement("span", { className: "flex" }), _react2.default.createElement("button", { className: "formulas-panel__close", onClick: props.hideFormulaList })), _react2.default.createElement("ul", { className: "formula-list flex" }, _formulas2.default.map(function (_ref) {
                var key = _ref.key,
                    description = _ref.description;
                return _react2.default.createElement("li", { key: key, className: "formula-item", onClick: function onClick() {
                        return _this2.onClickFormula(key);
                    } }, _react2.default.createElement("div", { className: "formula-name" }, key), _react2.default.createElement("div", { className: "formula-description" }, description));
            }))));
        }
    }]);
    return FormulaList;
}(_react.PureComponent);

exports.default = (0, _reactRedux.connect)(function (state) {
    return {
        visible: state.sheet.formula.visible
    };
}, function (dispatch) {
    return (0, _redux.bindActionCreators)({
        hideFormulaList: _sheet.hideFormulaList
    }, dispatch);
})(FormulaList);
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 3082:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _i18nHelper = __webpack_require__(240);

var _sr_en = __webpack_require__(1975);

var _calcengine = __webpack_require__(2013);

var _calcengine2 = _interopRequireDefault(_calcengine);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

_sr_en.SR.zh = _calcengine2.default;
var locale = (0, _i18nHelper.getLocale)();
var languagePack = {};
var getLanguagePackageFromSR = function getLanguagePackageFromSR(SR, language) {
    var pack = SR[language]._builtInFunctionsResource;
    var retPack = [];
    var keys = Object.keys(pack).sort();
    keys.forEach(function (key) {
        retPack.push({
            key: key,
            description: pack[key].description
        });
    });
    return retPack;
};
languagePack['en-US'] = getLanguagePackageFromSR(_sr_en.SR, 'en');
languagePack['zh-CN'] = getLanguagePackageFromSR(_sr_en.SR, 'zh');
exports.default = languagePack[locale];

/***/ }),

/***/ 3083:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3084:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _findbar = __webpack_require__(3085);

var _findbar2 = _interopRequireDefault(_findbar);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.default = _findbar2.default;

/***/ }),

/***/ 3085:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _typeof2 = __webpack_require__(76);

var _typeof3 = _interopRequireDefault(_typeof2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _reactRedux = __webpack_require__(238);

var _classnames = __webpack_require__(29);

var _classnames2 = _interopRequireDefault(_classnames);

var _reactDraggable = __webpack_require__(2048);

var _reactDraggable2 = _interopRequireDefault(_reactDraggable);

var _lodashDecorators = __webpack_require__(724);

var _sheet = __webpack_require__(713);

var _modal = __webpack_require__(1623);

var _sheet_context = __webpack_require__(1578);

var _sheet2 = __webpack_require__(715);

var _sheet3 = __webpack_require__(1597);

var _left = __webpack_require__(3086);

var _left2 = _interopRequireDefault(_left);

var _right = __webpack_require__(3087);

var _right2 = _interopRequireDefault(_right);

var _close = __webpack_require__(3088);

var _close2 = _interopRequireDefault(_close);

var _more = __webpack_require__(3089);

var _more2 = _interopRequireDefault(_more);

__webpack_require__(3090);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var __decorate = undefined && undefined.__decorate || function (decorators, target, key, desc) {
    var c = arguments.length,
        r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc,
        d;
    if ((typeof Reflect === "undefined" ? "undefined" : (0, _typeof3.default)(Reflect)) === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);else for (var i = decorators.length - 1; i >= 0; i--) {
        if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    }return c > 3 && r && Object.defineProperty(target, key, r), r;
};

var FINDBAR_PADDING_TOP = 9;
var FINDBAR_WIDTH = 360;
var PADDING_RIGHT = 20;
var initState = {
    findText: '',
    searching: false,
    replaceText: '',
    replaceFocus: false,
    total: 0,
    current: 0,
    position: {
        x: 0,
        y: 0
    }
};

var Findbar = function (_React$Component) {
    (0, _inherits3.default)(Findbar, _React$Component);

    function Findbar() {
        (0, _classCallCheck3.default)(this, Findbar);

        var _this = (0, _possibleConstructorReturn3.default)(this, (Findbar.__proto__ || Object.getPrototypeOf(Findbar)).apply(this, arguments));

        _this.state = initState;
        return _this;
    }

    (0, _createClass3.default)(Findbar, [{
        key: "componentWillReceiveProps",
        value: function componentWillReceiveProps(nextProps) {
            if (!this.props.visible && nextProps.visible) {
                // when show init position
                var position = this.getPosition();
                this.setState({
                    position: position
                });
                this.bindEvents();
            } else if (this.props.visible && !nextProps.visible) {
                // when hide, clear data
                this.setState(initState);
                this.unbindEvents();
                var sheets = this.props.spread.sheets;
                sheets.forEach(function (sheet) {
                    return sheet.clearSearchResult();
                });
            }
        }
    }, {
        key: "componentDidUpdate",
        value: function componentDidUpdate(prevProps) {
            // when show, focus input
            if (!prevProps.findFocus && this.props.findFocus && this.findInput) {
                var ignoreRepaintSelection = true;
                this.props.spread.focus(false, ignoreRepaintSelection);
                this.findInput.focus();
            }
        }
    }, {
        key: "componentWillUnmount",
        value: function componentWillUnmount() {
            this.props.hideFindbar();
        }
    }, {
        key: "bindEvents",
        value: function bindEvents() {
            var spread = this.props.spread;
            var context = spread._context;
            context.bind(_sheet_context.CollaborativeEvents.PRODUCE_ACTIONS, this.updateSearch);
            context.bind(_sheet_context.CollaborativeEvents.APPLY_ACTIONS, this.updateSearch);
            spread.bind(_sheet.Events.ActiveSheetChanged, this.search);
        }
    }, {
        key: "unbindEvents",
        value: function unbindEvents() {
            var spread = this.props.spread;
            var context = spread._context;
            context.unbind(_sheet_context.CollaborativeEvents.PRODUCE_ACTIONS, this.updateSearch);
            context.unbind(_sheet_context.CollaborativeEvents.APPLY_ACTIONS, this.updateSearch);
            spread.unbind(_sheet.Events.ActiveSheetChanged, this.search);
        }
    }, {
        key: "getPosition",
        value: function getPosition() {
            var findBtn = document.getElementById('sheet-find');
            var folderTrigger = document.getElementById('sheet-toolbar-folder-trigger');
            var anchorDom = folderTrigger || findBtn;
            if (!anchorDom) {
                return {
                    x: 0,
                    y: 0
                };
            }
            var rect = anchorDom.getBoundingClientRect();
            var screenWidth = window.innerWidth;
            var top = rect.top + rect.height + FINDBAR_PADDING_TOP;
            var left = rect.left + rect.width / 2 - FINDBAR_WIDTH / 2;
            if (left + FINDBAR_WIDTH > screenWidth) {
                left = screenWidth - FINDBAR_WIDTH - PADDING_RIGHT;
            }
            if (left < 0) {
                left = PADDING_RIGHT;
            }
            return {
                x: Math.round(left),
                y: Math.round(top)
            };
        }
    }, {
        key: "updateSearch",
        value: function updateSearch() {
            var sheet = this.props.spread.getActiveSheet();
            var result = sheet.search(this.state.findText);
            var total = result.length;
            var current = this.state.current;
            if (current >= total) {
                current = total > 0 ? total - 1 : 0;
            }
            this.setState({
                total: total,
                current: current
            });
            sheet.highlighSearchResult();
        }
    }, {
        key: "search",
        value: function search() {
            var sheet = this.props.spread.getActiveSheet();
            var result = sheet.search(this.state.findText);
            var first = 0;
            this.setState({
                total: result.length,
                current: first,
                searching: false
            });
            if (result.length > 0) {
                sheet.searchLocateTo(first);
            }
            sheet.highlighSearchResult();
        }
    }, {
        key: "debounceSearch",
        value: function debounceSearch() {
            this.search();
        }
    }, {
        key: "handleFindTextChange",
        value: function handleFindTextChange(e) {
            this.setState({
                findText: e.currentTarget.value,
                searching: true
            });
            this.debounceSearch();
        }
    }, {
        key: "handleReplaceTextChange",
        value: function handleReplaceTextChange(e) {
            this.setState({
                replaceText: e.target.value
            });
        }
    }, {
        key: "handleFindKeyDown",
        value: function handleFindKeyDown(e) {
            // enter key
            if (e.keyCode === 13) {
                this.nav(true);
                return;
            }
            this.handleEsc(e);
        }
    }, {
        key: "handleEsc",
        value: function handleEsc(e) {
            // Escape key
            if (e.keyCode === 27) {
                this.props.hideFindbar();
            }
        }
    }, {
        key: "handleDragStop",
        value: function handleDragStop(e, data) {
            this.setState({
                position: {
                    x: Math.round(data.x),
                    y: Math.round(data.y)
                }
            });
        }
    }, {
        key: "handleFindFocus",
        value: function handleFindFocus() {
            this.props.focusFindbar(true);
        }
    }, {
        key: "handleFindBlur",
        value: function handleFindBlur() {
            this.props.focusFindbar(false);
        }
    }, {
        key: "nav",
        value: function nav(isNext) {
            var sheet = this.props.spread.getActiveSheet();
            var current = this.state.current;

            var index = isNext ? sheet.searchNext(current) : sheet.searchPrev(current);
            if (index !== -1) {
                this.setState({
                    current: index
                });
                sheet.searchLocateTo(index);
            }
        }
    }, {
        key: "onNext",
        value: function onNext() {
            this.nav(true);
        }
    }, {
        key: "onPrev",
        value: function onPrev() {
            this.nav(false);
        }
    }, {
        key: "replace",
        value: function replace(index) {
            var sheet = this.props.spread.getActiveSheet();
            var commandManager = sheet.getParent().commandManager();
            var _state = this.state,
                findText = _state.findText,
                replaceText = _state.replaceText;

            commandManager.execute({
                cmd: 'replace',
                sheetName: sheet.name(),
                sheetId: sheet.id(),
                index: index,
                find: findText,
                replace: replaceText
            });
        }
    }, {
        key: "onReplace",
        value: function onReplace() {
            var sheet = this.props.spread.getActiveSheet();
            var _state2 = this.state,
                current = _state2.current,
                total = _state2.total;

            this.replace(current); // 替换掉一个后定位到下一个
            var next = current === total - 1 ? 0 : current;
            this.setState({
                current: next
            });
            sheet.searchLocateTo(next);
        }
    }, {
        key: "onReplaceAll",
        value: function onReplaceAll() {
            var _this2 = this;

            var _state3 = this.state,
                total = _state3.total,
                findText = _state3.findText,
                replaceText = _state3.replaceText;

            var formulaCount = this.countFormula();
            var note = t('sheet.find_bar.find_and_replace_tips', total - formulaCount, findText, replaceText);
            if (formulaCount > 0) {
                note += t('sheet.find_bar.find_and_replace__result_tips', formulaCount, findText);
            }
            (0, _modal.showModal)({
                title: t('common.prompt'),
                body: note,
                confirmText: t('common.confirm'),
                closable: true,
                cancelText: t('common.cancel'),
                maskClosable: false,
                onConfirm: function onConfirm() {
                    _this2.replace();
                }
            });
        }
    }, {
        key: "onShowReplace",
        value: function onShowReplace() {
            this.props.showFindbar(true);
        }
    }, {
        key: "onClose",
        value: function onClose() {
            this.props.hideFindbar();
        }
    }, {
        key: "countFormula",
        value: function countFormula() {
            var sheet = this.props.spread.getActiveSheet();
            var items = sheet.getSearchItems();
            var total = 0;
            for (var i = 0; i < items.length; i++) {
                if (items[i].hasFormula) {
                    total++;
                }
            }
            return total;
        }
    }, {
        key: "render",
        value: function render() {
            var _this3 = this;

            var _props = this.props,
                visible = _props.visible,
                replaceVisible = _props.replaceVisible,
                findFocus = _props.findFocus,
                editable = _props.editable;
            var _state4 = this.state,
                total = _state4.total,
                current = _state4.current,
                findText = _state4.findText,
                position = _state4.position,
                searching = _state4.searching;

            var sheet = this.props.spread.getActiveSheet();
            if (!sheet) {
                return null;
            }
            var currentItem = sheet.getSearchItem(current);
            var formulaCount = this.countFormula();
            var disabled = !editable || !findText || total === 0;
            var disabledReplace = disabled || currentItem && currentItem.hasFormula;
            var disabledReplaceAll = disabled || total === formulaCount;
            var sheetComponentName = 'sheet_findbar';
            var findbarClassName = (0, _classnames2.default)('findbar layout-column', {
                findbar_hidden: !visible,
                'findbar_replace-hidden': !replaceVisible
            });
            var findWrapClassName = (0, _classnames2.default)('findbar__input-wrap flex layout-row', {
                'findbar__input-wrap_focus': findFocus
            });
            var notfound = _react2.default.createElement("div", { className: "findbar__notfound" }, !searching && findText && total === 0 ? t('sheet.not_found') : '');
            var nav = _react2.default.createElement("div", { className: "findbar__nav" }, _react2.default.createElement("button", { className: "findbar__nav-button", onClick: this.onPrev, tabIndex: -1 }, _react2.default.createElement(_left2.default, null)), _react2.default.createElement("span", { className: "findbar__nav-content" }, current + 1, " / ", total), _react2.default.createElement("button", { className: "findbar__nav-button", onClick: this.onNext, tabIndex: -1 }, _react2.default.createElement(_right2.default, null)));
            return _react2.default.createElement(_reactDraggable2.default, { bounds: "body", cancel: ".no-move", position: position, onStop: this.handleDragStop, enableUserSelectHack: false }, _react2.default.createElement("div", { className: findbarClassName, "data-sheet-component": sheetComponentName }, _react2.default.createElement("div", { className: "no-move" }, _react2.default.createElement("button", { className: "findbar__close", onClick: this.onClose }, _react2.default.createElement(_close2.default, null)), _react2.default.createElement("div", { className: "findbar__find layout-row" }, _react2.default.createElement("label", { className: "findbar__label", htmlFor: "findbar__find-input" }, t('common.search')), _react2.default.createElement("div", { className: findWrapClassName }, _react2.default.createElement("input", { ref: function ref(input) {
                    _this3.findInput = input;
                }, id: "findbar__find-input", className: "findbar__find-input flex", type: "text", placeholder: t('sheet.search_in_sheet'), value: this.state.findText, onChange: this.handleFindTextChange, onKeyDown: this.handleFindKeyDown, onFocus: this.handleFindFocus, onBlur: this.handleFindBlur }), total > 0 ? nav : notfound), _react2.default.createElement("button", { className: "findbar__more", onClick: this.onShowReplace }, _react2.default.createElement(_more2.default, null))), _react2.default.createElement("div", { className: "findbar__replace layout-row" }, _react2.default.createElement("label", { className: "findbar__label", htmlFor: "findbar__replace-input" }, t('sheet.find_bar.replace_with')), _react2.default.createElement("input", { id: "findbar__replace-input", className: "findbar__replace-input flex", type: "text", disabled: !editable, value: this.state.replaceText, onChange: this.handleReplaceTextChange, onKeyDown: this.handleEsc })), _react2.default.createElement("div", { className: "findbar__buttons" }, _react2.default.createElement("button", { className: "findbar__button", disabled: !findText, onClick: this.onNext, tabIndex: -1 }, t('common.search')), _react2.default.createElement("button", { className: "findbar__button", disabled: disabledReplace, onClick: this.onReplace, tabIndex: -1 }, t('sheet.replace')), _react2.default.createElement("button", { className: "findbar__button findbar__button_replace-all", disabled: disabledReplaceAll, onClick: this.onReplaceAll, tabIndex: -1 }, t('sheet.replace_all'))))));
        }
    }]);
    return Findbar;
}(_react2.default.Component);

__decorate([(0, _lodashDecorators.Bind)()], Findbar.prototype, "updateSearch", null);
__decorate([(0, _lodashDecorators.Bind)()], Findbar.prototype, "search", null);
__decorate([(0, _lodashDecorators.Debounce)(200)], Findbar.prototype, "debounceSearch", null);
__decorate([(0, _lodashDecorators.Bind)()], Findbar.prototype, "handleFindTextChange", null);
__decorate([(0, _lodashDecorators.Bind)()], Findbar.prototype, "handleReplaceTextChange", null);
__decorate([(0, _lodashDecorators.Bind)()], Findbar.prototype, "handleFindKeyDown", null);
__decorate([(0, _lodashDecorators.Bind)()], Findbar.prototype, "handleEsc", null);
__decorate([(0, _lodashDecorators.Bind)()], Findbar.prototype, "handleDragStop", null);
__decorate([(0, _lodashDecorators.Bind)()], Findbar.prototype, "handleFindFocus", null);
__decorate([(0, _lodashDecorators.Bind)()], Findbar.prototype, "handleFindBlur", null);
__decorate([(0, _lodashDecorators.Bind)()], Findbar.prototype, "onNext", null);
__decorate([(0, _lodashDecorators.Bind)()], Findbar.prototype, "onPrev", null);
__decorate([(0, _lodashDecorators.Bind)()], Findbar.prototype, "onReplace", null);
__decorate([(0, _lodashDecorators.Bind)()], Findbar.prototype, "onReplaceAll", null);
__decorate([(0, _lodashDecorators.Bind)()], Findbar.prototype, "onShowReplace", null);
__decorate([(0, _lodashDecorators.Bind)()], Findbar.prototype, "onClose", null);
exports.default = (0, _reactRedux.connect)(function (state) {
    return {
        // activeSpread: state.sheet.activeSpread,
        visible: state.sheet.findbar.visible,
        replaceVisible: state.sheet.findbar.replaceVisible,
        findFocus: state.sheet.findbar.findFocus,
        editable: (0, _sheet3.editableSelector)(state)
    };
}, function (dispatch, props) {
    return {
        showFindbar: function showFindbar(replaceVisible) {
            return dispatch((0, _sheet2.showFindbar)(replaceVisible));
        },
        hideFindbar: function hideFindbar() {
            return dispatch((0, _sheet2.hideFindbar)());
        },
        focusFindbar: function focusFindbar(isFocus) {
            return dispatch((0, _sheet2.focusFindbar)(isFocus));
        }
    };
})(Findbar);
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 3086:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ xmlns: "http://www.w3.org/2000/svg", width: "12", height: "12", viewBox: "0 0 12 12", fill: "#424E5D" }, props),
    _react2.default.createElement("path", { d: "M3.7 6l4.65-4.65a.5.5 0 1 0-.7-.7L2.29 6l5.36 5.35a.5.5 0 0 0 .7-.7L3.71 6z" })
  );
};

/***/ }),

/***/ 3087:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ xmlns: "http://www.w3.org/2000/svg", width: "12", height: "12", viewBox: "0 0 12 12", fill: "#424E5D" }, props),
    _react2.default.createElement("path", { d: "M8.09 6L3.44 1.35a.5.5 0 1 1 .7-.7L9.5 6l-5.35 5.35a.5.5 0 0 1-.71-.7L8.09 6z" })
  );
};

/***/ }),

/***/ 3088:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 12 12", fill: "#424E5D" }, props),
    _react2.default.createElement("path", { d: "M6 5L3 2 2 3l3 3-3 3 1 1 3-3 3 3 1-1-3-3 3-3-1-1" })
  );
};

/***/ }),

/***/ 3089:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement(
      "g",
      { fill: "none", fillRule: "evenodd" },
      _react2.default.createElement("path", { d: "M0 0h24v24H0z" }),
      _react2.default.createElement("path", { d: "M14 6a2 2 0 0 0-2-2 2 2 0 0 0-2 2c0 1.1.9 2 2 2a2 2 0 0 0 2-2zm0 12a2 2 0 0 0-2-2 2 2 0 0 0-2 2c0 1.1.9 2 2 2a2 2 0 0 0 2-2zm0-6a2 2 0 0 0-2-2 2 2 0 0 0-2 2c0 1.1.9 2 2 2a2 2 0 0 0 2-2z", fill: "#BFC3C8" })
    )
  );
};

/***/ }),

/***/ 3090:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3091:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.DropdownPop = exports.DropdownList = undefined;

var _DropdownMenu = __webpack_require__(3092);

var _DropdownMenu2 = _interopRequireDefault(_DropdownMenu);

var _DropdownList = __webpack_require__(3102);

var _DropdownList2 = _interopRequireDefault(_DropdownList);

var _DropdownPop = __webpack_require__(3104);

var _DropdownPop2 = _interopRequireDefault(_DropdownPop);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.default = _DropdownMenu2.default;
exports.DropdownList = _DropdownList2.default;
exports.DropdownPop = _DropdownPop2.default;

/***/ }),

/***/ 3092:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});

var _button = __webpack_require__(2049);

var _button2 = _interopRequireDefault(_button);

var _toConsumableArray2 = __webpack_require__(135);

var _toConsumableArray3 = _interopRequireDefault(_toConsumableArray2);

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _reactDraggable = __webpack_require__(2048);

var _reactDraggable2 = _interopRequireDefault(_reactDraggable);

var _DragBar = __webpack_require__(3097);

var _DragBar2 = _interopRequireDefault(_DragBar);

var _sortablejs = __webpack_require__(3100);

var _sortablejs2 = _interopRequireDefault(_sortablejs);

__webpack_require__(1817);

var _dragnew = __webpack_require__(3101);

var _dragnew2 = _interopRequireDefault(_dragnew);

var _reactRedux = __webpack_require__(238);

var _sheet = __webpack_require__(715);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var Events = GC.Spread.Sheets.Events;

var DROPDOWNMENU_PADDING_TOP = 9;
var DROPDOWNMENU_WIDTH = 338;
var PADDING_RIGHT = 20;

var DropdownMenu = function (_Component) {
    (0, _inherits3.default)(DropdownMenu, _Component);

    function DropdownMenu(props) {
        (0, _classCallCheck3.default)(this, DropdownMenu);

        var _this = (0, _possibleConstructorReturn3.default)(this, (DropdownMenu.__proto__ || Object.getPrototypeOf(DropdownMenu)).call(this, props));

        _this.makeSort = function (div) {
            _this.dragMiddle = div;
        };
        _this.getDragList = function (dragListCollection) {
            var outputDragList = [].concat((0, _toConsumableArray3.default)(dragListCollection)).map(function (dragBar) {
                var inputDom = dragBar.querySelector('input');
                if (!inputDom) return null;
                return inputDom.value;
            }).filter(function (inputValue) {
                return inputValue !== null;
            });
            return outputDragList;
        };
        _this.addDragBar = function () {
            _this.setState(function (prevState) {
                var dragList = [].concat((0, _toConsumableArray3.default)(prevState.dragList));
                dragList.push('');
                return {
                    dragList: dragList
                };
            });
            setTimeout(function () {
                var dragBarLength = _this.dragMiddle.children.length;
                _this.dragMiddle.children[dragBarLength - 1].querySelector('input').focus();
            }, 0);
        };
        _this.changeValue = function (idx, value, input) {
            _this.setState(function (prevState) {
                var dragList = [].concat((0, _toConsumableArray3.default)(prevState.dragList));
                dragList[idx] = value;
                return {
                    dragList: dragList
                };
            });
            _this.activeInput = input;
        };
        _this.deleteBar = function (idx) {
            // 删除bar
            _this.setState(function (prevState) {
                var dragList = [].concat((0, _toConsumableArray3.default)(prevState.dragList));
                dragList.splice(idx, 1);
                return {
                    dragList: dragList
                };
            });
        };
        _this.close = function () {
            _this.props.hideDropdownMenu();
            _this.props.spread.focus();
        };
        _this.handleOK = function () {
            var dragList = _this.state.dragList;

            var clonedDragList = [].concat((0, _toConsumableArray3.default)(dragList));
            clonedDragList = clonedDragList.map(function (content) {
                return content.trim();
            });
            var hasNullContent = clonedDragList.some(function (content) {
                return content === '';
            });
            var allNullContent = clonedDragList.every(function (content) {
                return content === '';
            });
            if (allNullContent && hasNullContent) {
                var nullIndex = clonedDragList.indexOf('');
                var dragBar = _this.dragMiddle.children[nullIndex];
                if (dragBar) {
                    var input = dragBar.querySelector('input');
                    input && input.focus();
                }
                return;
            }
            _this.props.hideDropdownMenu();
            var sheet = _this.sheet;
            var value = _this.state.dragList;
            value = Array.from(new Set(value)).filter(function (content) {
                return content !== '';
            });
            _this.setState({
                dragList: value
            });
            _this.props.spread.commandManager().execute({
                cmd: 'setDropdown',
                sheetId: sheet.id(),
                sheetName: sheet.name(),
                selections: sheet.getSelections(),
                value: value
            });
            _this.props.spread.focus();
        };
        _this.handleDragStop = function (e, data) {
            _this.setState({
                position: {
                    x: Math.round(data.x),
                    y: Math.round(data.y)
                }
            });
        };
        _this._bindEvents = function () {
            var spread = _this.props.spread;

            [Events.SelectionChanged].forEach(function (event) {
                spread.bind(event, _this._hideMenu);
            });
            window.addEventListener('keydown', _this._onKeydown);
        };
        _this._unbindEvents = function () {
            var spread = _this.props.spread;

            [Events.SelectionChanged].forEach(function (event) {
                spread.unbind(event, _this._hideMenu);
            });
            window.removeEventListener('keydown', _this._onKeydown);
        };
        _this._onKeydown = function (e) {
            if (!_this.props.visible) return;
            // key Enter
            if (e.keyCode === 13) {
                var input = document.activeElement;
                var childs = [].concat((0, _toConsumableArray3.default)(_this.dragMiddle.children));
                childs = childs.map(function (child) {
                    return child.querySelector('input');
                });
                var idx = childs.indexOf(input);
                if (idx === -1) {
                    childs[0].focus();
                    return;
                }
                if (idx === childs.length - 1) {
                    _this.addDragBar();
                    return;
                }
                childs[idx + 1].focus();
            }
        };
        _this._hideMenu = function () {
            if (_this.props.visible) {
                _this.props.hideDropdownMenu();
            }
        };
        _this.removeDropdown = function () {
            var sheet = _this.props.spread.getActiveSheet();
            _this.props.spread.commandManager().execute({
                cmd: 'setDropdown',
                sheetId: sheet.id(),
                sheetName: sheet.name(),
                selections: sheet.getSelections(),
                value: []
            });
            _this.props.hideDropdownMenu();
            _this.props.spread.focus();
        };
        _this.state = {
            dragList: ['', '', ''],
            position: {
                x: 0,
                y: 0
            }
        };
        return _this;
    }

    (0, _createClass3.default)(DropdownMenu, [{
        key: 'getPosition',
        value: function getPosition() {
            var dropdownBtn = document.getElementById('sheet-dropdown');
            // 浮动工具栏中，可能会因为工具栏未显示而找不到这个按钮
            if (!dropdownBtn) {
                return {
                    x: 0,
                    y: 0
                };
            }
            var rect = dropdownBtn.getBoundingClientRect();
            var screenWidth = window.innerWidth;
            var top = rect.top + rect.height + DROPDOWNMENU_PADDING_TOP;
            var left = rect.left + rect.width / 2 - DROPDOWNMENU_WIDTH / 2;
            if (left + DROPDOWNMENU_WIDTH > screenWidth) {
                left = screenWidth - DROPDOWNMENU_WIDTH - PADDING_RIGHT;
            }
            if (left < 0) {
                left = PADDING_RIGHT;
            }
            return { x: left, y: top };
        }
    }, {
        key: 'componentWillReceiveProps',
        value: function componentWillReceiveProps(nextProps) {
            var _this2 = this;

            if (!this.props.visible && nextProps.visible === true) {
                this.sheet = this.props.spread.getActiveSheet();
                var row = this.sheet.getActiveRowIndex();
                var col = this.sheet.getActiveColumnIndex();
                var style = this.sheet.getStyle(row, col);
                var dropdown = ['', '', ''];
                if (style && style.dropdown) {
                    dropdown = style.dropdown.list;
                }
                var position = this.getPosition();
                if (position.x === 0 && position.y === 0) {
                    return;
                }
                this.setState({ position: position });
                this.setState({ dragList: dropdown });
                setTimeout(function () {
                    var ignoreRepaintSelection = true;
                    _this2.props.spread.focus(false, ignoreRepaintSelection);
                    _this2.dragMiddle.children[0].querySelector('input').focus();
                }, 10);
            }
        }
    }, {
        key: 'componentDidMount',
        value: function componentDidMount() {
            this.setState({
                dragList: this.getDragList(this.dragMiddle.children)
            });
            var prefixCls = this.props.prefixCls;
            var getDragList = this.getDragList;
            var setState = this.setState.bind(this);
            this.sortable = _sortablejs2.default.create(this.dragMiddle, {
                animation: 150,
                handle: '.' + prefixCls + '__menu-dragbar-left',
                // chosenClass: `${this.props.prefixCls}__menu-dragbar-chosen`,
                ghostClass: prefixCls + '__menu-dragbar-ghost',
                dataIdAttr: 'data-id',
                onEnd: function onEnd(ev) {
                    setState({
                        dragList: getDragList(ev.to.children)
                    });
                }
            });
            this._bindEvents();
        }
    }, {
        key: 'shouldComponentUpdate',
        value: function shouldComponentUpdate(nextProps) {
            if (this.props.visible === false && nextProps.visible === false) {
                return false;
            }
            return true;
        }
    }, {
        key: 'componentDidUpdate',
        value: function componentDidUpdate() {
            var _this3 = this;

            if (!this.activeInput) {
                var sortLength = this.getDragList(this.dragMiddle.children).length;
                var sortArray = [];
                for (var i = 0; i < sortLength; i++) {
                    sortArray.push('' + i);
                }
                this.sortable.sort(sortArray);
                this.dragMiddle.style.overflowY = 'hidden';
                setTimeout(function () {
                    _this3.dragMiddle.style.overflowY = 'scroll';
                }, 0);
                return;
            }
            this.activeInput = null;
        }
    }, {
        key: 'componentWillUnmount',
        value: function componentWillUnmount() {
            this._unbindEvents();
        }
    }, {
        key: 'render',
        value: function render() {
            var _this4 = this;

            var prefixCls = this.props.prefixCls;
            var MyButton = _button2.default;
            var dragList = this.state.dragList;
            var sheetComponentName = 'sheet_dropdown_menu';
            var isVisible = this.props.visible;
            if (this.state.position.x === 0 && this.state.position.y === 0) {
                isVisible = false;
            }
            return _react2.default.createElement(_reactDraggable2.default, { bounds: "body", handle: '.' + prefixCls + '__menu-top', position: this.state.position, onStop: this.handleDragStop, enableUserSelectHack: false }, _react2.default.createElement("div", { className: prefixCls + '__menu', style: { display: isVisible ? 'block' : 'none' }, "data-sheet-component": sheetComponentName }, _react2.default.createElement("div", { className: prefixCls + '__menu-top' }, _react2.default.createElement("div", null, t('sheet.dropdown')), _react2.default.createElement("div", { className: prefixCls + '__menu-top-close', onClick: this.close }, _react2.default.createElement("span", { className: "n-icon-close" }))), _react2.default.createElement("div", { className: prefixCls + '__menu-middle', ref: this.makeSort }, dragList.map(function (content, idx) {
                return _react2.default.createElement(_DragBar2.default, { prefixCls: prefixCls, key: 'dragbar-' + idx, changeValue: _this4.changeValue, deleteBar: _this4.deleteBar, dataId: idx }, content);
            })), _react2.default.createElement("div", { className: prefixCls + '__menu-bottom' }, _react2.default.createElement("div", { className: prefixCls + '__menu-dragbar-add', onClick: this.addDragBar, id: prefixCls + '__menu-dragbar-add' }, t('sheet.new_option'), '\xA0', _react2.default.createElement(_dragnew2.default, null)), _react2.default.createElement(MyButton, { prefixCls: "cp-btn", className: prefixCls + '__menu-btn ' + prefixCls + '__menu-btn-remove', onClick: this.removeDropdown }, t('sheet.remove_dropdown')), _react2.default.createElement(MyButton, { prefixCls: "cp-btn", className: prefixCls + '__menu-btn ' + prefixCls + '__menu-btn-cancel', onClick: this.close }, t('common.cancel')), _react2.default.createElement(MyButton, { prefixCls: "cp-btn", className: prefixCls + '__menu-btn', type: "primary", onClick: this.handleOK }, t('common.confirm')))));
        }
    }]);
    return DropdownMenu;
}(_react.Component);

DropdownMenu.defaultProps = {
    prefixCls: 'sheet-dropdown'
};
exports.default = (0, _reactRedux.connect)(function (state) {
    return {
        visible: state.sheet.dropdownMenu.visible
    };
}, function (dispatch, props) {
    return {
        showDropdownMenu: function showDropdownMenu() {
            return dispatch((0, _sheet.showDropdownMenu)());
        },
        hideDropdownMenu: function hideDropdownMenu() {
            return dispatch((0, _sheet.hideDropdownMenu)());
        }
    };
})(DropdownMenu);
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 3093:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _defineProperty2 = __webpack_require__(11);

var _defineProperty3 = _interopRequireDefault(_defineProperty2);

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var React = _interopRequireWildcard(_react);

var _reactDom = __webpack_require__(21);

var _propTypes = __webpack_require__(0);

var _propTypes2 = _interopRequireDefault(_propTypes);

var _classnames = __webpack_require__(29);

var _classnames2 = _interopRequireDefault(_classnames);

var _icon = __webpack_require__(3094);

var _icon2 = _interopRequireDefault(_icon);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj['default'] = obj; return newObj; } }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

var __rest = undefined && undefined.__rest || function (s, e) {
    var t = {};
    for (var p in s) {
        if (Object.prototype.hasOwnProperty.call(s, p) && e.indexOf(p) < 0) t[p] = s[p];
    }if (s != null && typeof Object.getOwnPropertySymbols === "function") for (var i = 0, p = Object.getOwnPropertySymbols(s); i < p.length; i++) {
        if (e.indexOf(p[i]) < 0) t[p[i]] = s[p[i]];
    }return t;
};

var rxTwoCNChar = /^[\u4e00-\u9fa5]{2}$/;
var isTwoCNChar = rxTwoCNChar.test.bind(rxTwoCNChar);
function isString(str) {
    return typeof str === 'string';
}
// Insert one space between two chinese characters automatically.
function insertSpace(child, needInserted) {
    // Check the child if is undefined or null.
    if (child == null) {
        return;
    }
    var SPACE = needInserted ? ' ' : '';
    // strictNullChecks oops.
    if (typeof child !== 'string' && typeof child !== 'number' && isString(child.type) && isTwoCNChar(child.props.children)) {
        return React.cloneElement(child, {}, child.props.children.split('').join(SPACE));
    }
    if (typeof child === 'string') {
        if (isTwoCNChar(child)) {
            child = child.split('').join(SPACE);
        }
        return React.createElement(
            'span',
            null,
            child
        );
    }
    return child;
}

var Button = function (_React$Component) {
    (0, _inherits3['default'])(Button, _React$Component);

    function Button(props) {
        (0, _classCallCheck3['default'])(this, Button);

        var _this = (0, _possibleConstructorReturn3['default'])(this, (Button.__proto__ || Object.getPrototypeOf(Button)).call(this, props));

        _this.handleClick = function (e) {
            // Add click effect
            _this.setState({ clicked: true });
            clearTimeout(_this.timeout);
            _this.timeout = window.setTimeout(function () {
                return _this.setState({ clicked: false });
            }, 500);
            var onClick = _this.props.onClick;
            if (onClick) {
                onClick(e);
            }
        };
        _this.state = {
            loading: props.loading,
            clicked: false,
            hasTwoCNChar: false
        };
        return _this;
    }

    (0, _createClass3['default'])(Button, [{
        key: 'componentDidMount',
        value: function componentDidMount() {
            this.fixTwoCNChar();
        }
    }, {
        key: 'componentWillReceiveProps',
        value: function componentWillReceiveProps(nextProps) {
            var _this2 = this;

            var currentLoading = this.props.loading;
            var loading = nextProps.loading;
            if (currentLoading) {
                clearTimeout(this.delayTimeout);
            }
            if (typeof loading !== 'boolean' && loading && loading.delay) {
                this.delayTimeout = window.setTimeout(function () {
                    return _this2.setState({ loading: loading });
                }, loading.delay);
            } else {
                this.setState({ loading: loading });
            }
        }
    }, {
        key: 'componentDidUpdate',
        value: function componentDidUpdate() {
            this.fixTwoCNChar();
        }
    }, {
        key: 'componentWillUnmount',
        value: function componentWillUnmount() {
            if (this.timeout) {
                clearTimeout(this.timeout);
            }
            if (this.delayTimeout) {
                clearTimeout(this.delayTimeout);
            }
        }
    }, {
        key: 'fixTwoCNChar',
        value: function fixTwoCNChar() {
            // Fix for HOC usage like <FormatMessage />
            var node = (0, _reactDom.findDOMNode)(this);
            var buttonText = node.textContent || node.innerText;
            if (this.isNeedInserted() && isTwoCNChar(buttonText)) {
                if (!this.state.hasTwoCNChar) {
                    this.setState({
                        hasTwoCNChar: true
                    });
                }
            } else if (this.state.hasTwoCNChar) {
                this.setState({
                    hasTwoCNChar: false
                });
            }
        }
    }, {
        key: 'isNeedInserted',
        value: function isNeedInserted() {
            var _props = this.props,
                icon = _props.icon,
                children = _props.children;

            return React.Children.count(children) === 1 && !icon;
        }
    }, {
        key: 'render',
        value: function render() {
            var _classNames,
                _this3 = this;

            var _a = this.props,
                type = _a.type,
                shape = _a.shape,
                size = _a.size,
                className = _a.className,
                children = _a.children,
                icon = _a.icon,
                prefixCls = _a.prefixCls,
                ghost = _a.ghost,
                _loadingProp = _a.loading,
                rest = __rest(_a, ["type", "shape", "size", "className", "children", "icon", "prefixCls", "ghost", "loading"]);var _state = this.state,
                loading = _state.loading,
                clicked = _state.clicked,
                hasTwoCNChar = _state.hasTwoCNChar;
            // large => lg
            // small => sm

            var sizeCls = '';
            switch (size) {
                case 'large':
                    sizeCls = 'lg';
                    break;
                case 'small':
                    sizeCls = 'sm';
                default:
                    break;
            }
            var classes = (0, _classnames2['default'])(prefixCls, className, (_classNames = {}, (0, _defineProperty3['default'])(_classNames, prefixCls + '-' + type, type), (0, _defineProperty3['default'])(_classNames, prefixCls + '-' + shape, shape), (0, _defineProperty3['default'])(_classNames, prefixCls + '-' + sizeCls, sizeCls), (0, _defineProperty3['default'])(_classNames, prefixCls + '-icon-only', !children && icon), (0, _defineProperty3['default'])(_classNames, prefixCls + '-loading', loading), (0, _defineProperty3['default'])(_classNames, prefixCls + '-clicked', clicked), (0, _defineProperty3['default'])(_classNames, prefixCls + '-background-ghost', ghost), (0, _defineProperty3['default'])(_classNames, prefixCls + '-two-chinese-chars', hasTwoCNChar), _classNames));
            var iconType = loading ? 'loading' : icon;
            var iconNode = iconType ? React.createElement(_icon2['default'], { type: iconType }) : null;
            var kids = children || children === 0 ? React.Children.map(children, function (child) {
                return insertSpace(child, _this3.isNeedInserted());
            }) : null;
            if ('href' in rest) {
                return React.createElement(
                    'a',
                    (0, _extends3['default'])({}, rest, { className: classes, onClick: this.handleClick }),
                    iconNode,
                    kids
                );
            } else {
                // React does not recognize the `htmlType` prop on a DOM element. Here we pick it out of `rest`.
                var htmlType = rest.htmlType,
                    otherProps = __rest(rest, ["htmlType"]);
                return React.createElement(
                    'button',
                    (0, _extends3['default'])({}, otherProps, { type: htmlType || 'button', className: classes, onClick: this.handleClick }),
                    iconNode,
                    kids
                );
            }
        }
    }]);
    return Button;
}(React.Component);

exports['default'] = Button;

Button.__ANT_BUTTON = true;
Button.defaultProps = {
    prefixCls: 'ant-btn',
    loading: false,
    ghost: false
};
Button.propTypes = {
    type: _propTypes2['default'].string,
    shape: _propTypes2['default'].oneOf(['circle', 'circle-outline']),
    size: _propTypes2['default'].oneOf(['large', 'default', 'small']),
    htmlType: _propTypes2['default'].oneOf(['submit', 'button', 'reset']),
    onClick: _propTypes2['default'].func,
    loading: _propTypes2['default'].oneOfType([_propTypes2['default'].bool, _propTypes2['default'].object]),
    className: _propTypes2['default'].string,
    icon: _propTypes2['default'].string
};
module.exports = exports['default'];

/***/ }),

/***/ 3094:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _defineProperty2 = __webpack_require__(11);

var _defineProperty3 = _interopRequireDefault(_defineProperty2);

var _react = __webpack_require__(1);

var React = _interopRequireWildcard(_react);

var _classnames = __webpack_require__(29);

var _classnames2 = _interopRequireDefault(_classnames);

var _omit = __webpack_require__(3095);

var _omit2 = _interopRequireDefault(_omit);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj['default'] = obj; return newObj; } }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

var Icon = function Icon(props) {
    var type = props.type,
        _props$className = props.className,
        className = _props$className === undefined ? '' : _props$className,
        spin = props.spin;

    var classString = (0, _classnames2['default'])((0, _defineProperty3['default'])({
        anticon: true,
        'anticon-spin': !!spin || type === 'loading'
    }, 'anticon-' + type, true), className);
    return React.createElement('i', (0, _extends3['default'])({}, (0, _omit2['default'])(props, ['type', 'spin']), { className: classString }));
};
exports['default'] = Icon;
module.exports = exports['default'];

/***/ }),

/***/ 3095:
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var babel_runtime_helpers_extends__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(10);
/* harmony import */ var babel_runtime_helpers_extends__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(babel_runtime_helpers_extends__WEBPACK_IMPORTED_MODULE_0__);

function omit(obj, fields) {
  var shallowCopy = babel_runtime_helpers_extends__WEBPACK_IMPORTED_MODULE_0___default()({}, obj);
  for (var i = 0; i < fields.length; i++) {
    var key = fields[i];
    delete shallowCopy[key];
  }
  return shallowCopy;
}

/* harmony default export */ __webpack_exports__["default"] = (omit);

/***/ }),

/***/ 3096:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _defineProperty2 = __webpack_require__(11);

var _defineProperty3 = _interopRequireDefault(_defineProperty2);

var _react = __webpack_require__(1);

var React = _interopRequireWildcard(_react);

var _classnames = __webpack_require__(29);

var _classnames2 = _interopRequireDefault(_classnames);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj['default'] = obj; return newObj; } }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

var __rest = undefined && undefined.__rest || function (s, e) {
    var t = {};
    for (var p in s) {
        if (Object.prototype.hasOwnProperty.call(s, p) && e.indexOf(p) < 0) t[p] = s[p];
    }if (s != null && typeof Object.getOwnPropertySymbols === "function") for (var i = 0, p = Object.getOwnPropertySymbols(s); i < p.length; i++) {
        if (e.indexOf(p[i]) < 0) t[p[i]] = s[p[i]];
    }return t;
};

var ButtonGroup = function ButtonGroup(props) {
    var _props$prefixCls = props.prefixCls,
        prefixCls = _props$prefixCls === undefined ? 'ant-btn-group' : _props$prefixCls,
        size = props.size,
        className = props.className,
        others = __rest(props, ["prefixCls", "size", "className"]);
    // large => lg
    // small => sm


    var sizeCls = '';
    switch (size) {
        case 'large':
            sizeCls = 'lg';
            break;
        case 'small':
            sizeCls = 'sm';
        default:
            break;
    }
    var classes = (0, _classnames2['default'])(prefixCls, (0, _defineProperty3['default'])({}, prefixCls + '-' + sizeCls, sizeCls), className);
    return React.createElement('div', (0, _extends3['default'])({}, others, { className: classes }));
};
exports['default'] = ButtonGroup;
module.exports = exports['default'];

/***/ }),

/***/ 3097:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.default = undefined;

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _dragmove = __webpack_require__(3098);

var _dragmove2 = _interopRequireDefault(_dragmove);

var _dragdelete = __webpack_require__(3099);

var _dragdelete2 = _interopRequireDefault(_dragdelete);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var DragBar = function (_Component) {
    (0, _inherits3.default)(DragBar, _Component);

    function DragBar(props) {
        (0, _classCallCheck3.default)(this, DragBar);

        var _this = (0, _possibleConstructorReturn3.default)(this, (DragBar.__proto__ || Object.getPrototypeOf(DragBar)).call(this, props));

        _this.handleInputChange = function (e) {
            _this.setState({
                inputValue: e.target.value
            });
            _this.props.changeValue(_this.getBarIndex(), e.target.value, _this.dragBarInput);
        };
        _this.handleDelete = function (e) {
            _this.props.deleteBar(_this.getBarIndex());
        };
        _this.getBarIndex = function () {
            var idx = 0;
            var ele = _this.dragBar.previousElementSibling;
            while (ele) {
                ele = ele.previousElementSibling;
                idx += 1;
            }
            return idx;
        };
        _this.bindDragBar = function (div) {
            _this.dragBar = div;
        };
        _this.bindDragBarInput = function (input) {
            _this.dragBarInput = input;
        };
        _this.state = {
            inputValue: props.children
        };
        return _this;
    }

    (0, _createClass3.default)(DragBar, [{
        key: 'componentWillReceiveProps',
        value: function componentWillReceiveProps(nextProps) {
            this.setState({
                inputValue: nextProps.children
            });
        }
    }, {
        key: 'render',
        value: function render() {
            var prefixCls = this.props.prefixCls;

            return _react2.default.createElement("div", { className: prefixCls + '__menu-dragbar', ref: this.bindDragBar, "data-id": this.props.dataId }, _react2.default.createElement("div", { className: prefixCls + '__menu-dragbar-left' }, _react2.default.createElement(_dragmove2.default, null)), _react2.default.createElement("div", { className: prefixCls + '__menu-dragbar-middle' }, _react2.default.createElement("input", { placeholder: t('sheet.input'), className: prefixCls + '__menu-dragbar-input', value: this.state.inputValue, onChange: this.handleInputChange, ref: this.bindDragBarInput })), _react2.default.createElement("div", { className: prefixCls + '__menu-dragbar-right', onClick: this.handleDelete }, _react2.default.createElement(_dragdelete2.default, null)));
        }
    }]);
    return DragBar;
}(_react.Component);

exports.default = DragBar;
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 3098:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ xmlns: "http://www.w3.org/2000/svg", width: "8", height: "18", viewBox: "0 0 8 18" }, props),
    _react2.default.createElement("path", { fill: "#BFC3C8", fillRule: "evenodd", d: "M1 4a1 1 0 1 1 0-2 1 1 0 0 1 0 2zm0 6a1 1 0 1 1 0-2 1 1 0 0 1 0 2zm0 6a1 1 0 1 1 0-2 1 1 0 0 1 0 2zM7 4a1 1 0 1 1 0-2 1 1 0 0 1 0 2zm0 6a1 1 0 1 1 0-2 1 1 0 0 1 0 2zm0 6a1 1 0 1 1 0-2 1 1 0 0 1 0 2z" })
  );
};

/***/ }),

/***/ 3099:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ xmlns: "http://www.w3.org/2000/svg", width: "16", height: "16", viewBox: "0 0 16 16" }, props),
    _react2.default.createElement("path", { fill: "#BFC4C8", d: "M8 16A8 8 0 1 1 8 0a8 8 0 0 1 0 16zm0-1A7 7 0 1 0 8 1a7 7 0 0 0 0 14zM6 7h4a1 1 0 0 1 0 2H6a1 1 0 1 1 0-2z" })
  );
};

/***/ }),

/***/ 3100:
/***/ (function(module, exports, __webpack_require__) {

var __WEBPACK_AMD_DEFINE_FACTORY__, __WEBPACK_AMD_DEFINE_RESULT__;/**!
 * Sortable
 * @author	RubaXa   <trash@rubaxa.org>
 * @license MIT
 */

(function sortableModule(factory) {
	"use strict";

	if (true) {
		!(__WEBPACK_AMD_DEFINE_FACTORY__ = (factory),
				__WEBPACK_AMD_DEFINE_RESULT__ = (typeof __WEBPACK_AMD_DEFINE_FACTORY__ === 'function' ?
				(__WEBPACK_AMD_DEFINE_FACTORY__.call(exports, __webpack_require__, exports, module)) :
				__WEBPACK_AMD_DEFINE_FACTORY__),
				__WEBPACK_AMD_DEFINE_RESULT__ !== undefined && (module.exports = __WEBPACK_AMD_DEFINE_RESULT__));
	}
	else {}
})(function sortableFactory() {
	"use strict";

	if (typeof window === "undefined" || !window.document) {
		return function sortableError() {
			throw new Error("Sortable.js requires a window with a document");
		};
	}

	var dragEl,
		parentEl,
		ghostEl,
		cloneEl,
		rootEl,
		nextEl,
		lastDownEl,

		scrollEl,
		scrollParentEl,
		scrollCustomFn,

		lastEl,
		lastCSS,
		lastParentCSS,

		oldIndex,
		newIndex,

		activeGroup,
		putSortable,

		autoScroll = {},

		tapEvt,
		touchEvt,

		moved,

		/** @const */
		R_SPACE = /\s+/g,
		R_FLOAT = /left|right|inline/,

		expando = 'Sortable' + (new Date).getTime(),

		win = window,
		document = win.document,
		parseInt = win.parseInt,
		setTimeout = win.setTimeout,

		$ = win.jQuery || win.Zepto,
		Polymer = win.Polymer,

		captureMode = false,
		passiveMode = false,

		supportDraggable = ('draggable' in document.createElement('div')),
		supportCssPointerEvents = (function (el) {
			// false when IE11
			if (!!navigator.userAgent.match(/(?:Trident.*rv[ :]?11\.|msie)/i)) {
				return false;
			}
			el = document.createElement('x');
			el.style.cssText = 'pointer-events:auto';
			return el.style.pointerEvents === 'auto';
		})(),

		_silent = false,

		abs = Math.abs,
		min = Math.min,

		savedInputChecked = [],
		touchDragOverListeners = [],

		_autoScroll = _throttle(function (/**Event*/evt, /**Object*/options, /**HTMLElement*/rootEl) {
			// Bug: https://bugzilla.mozilla.org/show_bug.cgi?id=505521
			if (rootEl && options.scroll) {
				var _this = rootEl[expando],
					el,
					rect,
					sens = options.scrollSensitivity,
					speed = options.scrollSpeed,

					x = evt.clientX,
					y = evt.clientY,

					winWidth = window.innerWidth,
					winHeight = window.innerHeight,

					vx,
					vy,

					scrollOffsetX,
					scrollOffsetY
				;

				// Delect scrollEl
				if (scrollParentEl !== rootEl) {
					scrollEl = options.scroll;
					scrollParentEl = rootEl;
					scrollCustomFn = options.scrollFn;

					if (scrollEl === true) {
						scrollEl = rootEl;

						do {
							if ((scrollEl.offsetWidth < scrollEl.scrollWidth) ||
								(scrollEl.offsetHeight < scrollEl.scrollHeight)
							) {
								break;
							}
							/* jshint boss:true */
						} while (scrollEl = scrollEl.parentNode);
					}
				}

				if (scrollEl) {
					el = scrollEl;
					rect = scrollEl.getBoundingClientRect();
					vx = (abs(rect.right - x) <= sens) - (abs(rect.left - x) <= sens);
					vy = (abs(rect.bottom - y) <= sens) - (abs(rect.top - y) <= sens);
				}


				if (!(vx || vy)) {
					vx = (winWidth - x <= sens) - (x <= sens);
					vy = (winHeight - y <= sens) - (y <= sens);

					/* jshint expr:true */
					(vx || vy) && (el = win);
				}


				if (autoScroll.vx !== vx || autoScroll.vy !== vy || autoScroll.el !== el) {
					autoScroll.el = el;
					autoScroll.vx = vx;
					autoScroll.vy = vy;

					clearInterval(autoScroll.pid);

					if (el) {
						autoScroll.pid = setInterval(function () {
							scrollOffsetY = vy ? vy * speed : 0;
							scrollOffsetX = vx ? vx * speed : 0;

							if ('function' === typeof(scrollCustomFn)) {
								return scrollCustomFn.call(_this, scrollOffsetX, scrollOffsetY, evt);
							}

							if (el === win) {
								win.scrollTo(win.pageXOffset + scrollOffsetX, win.pageYOffset + scrollOffsetY);
							} else {
								el.scrollTop += scrollOffsetY;
								el.scrollLeft += scrollOffsetX;
							}
						}, 24);
					}
				}
			}
		}, 30),

		_prepareGroup = function (options) {
			function toFn(value, pull) {
				if (value === void 0 || value === true) {
					value = group.name;
				}

				if (typeof value === 'function') {
					return value;
				} else {
					return function (to, from) {
						var fromGroup = from.options.group.name;

						return pull
							? value
							: value && (value.join
								? value.indexOf(fromGroup) > -1
								: (fromGroup == value)
							);
					};
				}
			}

			var group = {};
			var originalGroup = options.group;

			if (!originalGroup || typeof originalGroup != 'object') {
				originalGroup = {name: originalGroup};
			}

			group.name = originalGroup.name;
			group.checkPull = toFn(originalGroup.pull, true);
			group.checkPut = toFn(originalGroup.put);
			group.revertClone = originalGroup.revertClone;

			options.group = group;
		}
	;

	// Detect support a passive mode
	try {
		window.addEventListener('test', null, Object.defineProperty({}, 'passive', {
			get: function () {
				// `false`, because everything starts to work incorrectly and instead of d'n'd,
				// begins the page has scrolled.
				passiveMode = false;
				captureMode = {
					capture: false,
					passive: passiveMode
				};
			}
		}));
	} catch (err) {}

	/**
	 * @class  Sortable
	 * @param  {HTMLElement}  el
	 * @param  {Object}       [options]
	 */
	function Sortable(el, options) {
		if (!(el && el.nodeType && el.nodeType === 1)) {
			throw 'Sortable: `el` must be HTMLElement, and not ' + {}.toString.call(el);
		}

		this.el = el; // root element
		this.options = options = _extend({}, options);


		// Export instance
		el[expando] = this;

		// Default options
		var defaults = {
			group: Math.random(),
			sort: true,
			disabled: false,
			store: null,
			handle: null,
			scroll: true,
			scrollSensitivity: 30,
			scrollSpeed: 10,
			draggable: /[uo]l/i.test(el.nodeName) ? 'li' : '>*',
			ghostClass: 'sortable-ghost',
			chosenClass: 'sortable-chosen',
			dragClass: 'sortable-drag',
			ignore: 'a, img',
			filter: null,
			preventOnFilter: true,
			animation: 0,
			setData: function (dataTransfer, dragEl) {
				dataTransfer.setData('Text', dragEl.textContent);
			},
			dropBubble: false,
			dragoverBubble: false,
			dataIdAttr: 'data-id',
			delay: 0,
			forceFallback: false,
			fallbackClass: 'sortable-fallback',
			fallbackOnBody: false,
			fallbackTolerance: 0,
			fallbackOffset: {x: 0, y: 0},
			supportPointer: Sortable.supportPointer !== false
		};


		// Set default options
		for (var name in defaults) {
			!(name in options) && (options[name] = defaults[name]);
		}

		_prepareGroup(options);

		// Bind all private methods
		for (var fn in this) {
			if (fn.charAt(0) === '_' && typeof this[fn] === 'function') {
				this[fn] = this[fn].bind(this);
			}
		}

		// Setup drag mode
		this.nativeDraggable = options.forceFallback ? false : supportDraggable;

		// Bind events
		_on(el, 'mousedown', this._onTapStart);
		_on(el, 'touchstart', this._onTapStart);
		options.supportPointer && _on(el, 'pointerdown', this._onTapStart);

		if (this.nativeDraggable) {
			_on(el, 'dragover', this);
			_on(el, 'dragenter', this);
		}

		touchDragOverListeners.push(this._onDragOver);

		// Restore sorting
		options.store && this.sort(options.store.get(this));
	}


	Sortable.prototype = /** @lends Sortable.prototype */ {
		constructor: Sortable,

		_onTapStart: function (/** Event|TouchEvent */evt) {
			var _this = this,
				el = this.el,
				options = this.options,
				preventOnFilter = options.preventOnFilter,
				type = evt.type,
				touch = evt.touches && evt.touches[0],
				target = (touch || evt).target,
				originalTarget = evt.target.shadowRoot && (evt.path && evt.path[0]) || target,
				filter = options.filter,
				startIndex;

			_saveInputCheckedState(el);


			// Don't trigger start event when an element is been dragged, otherwise the evt.oldindex always wrong when set option.group.
			if (dragEl) {
				return;
			}

			if (/mousedown|pointerdown/.test(type) && evt.button !== 0 || options.disabled) {
				return; // only left button or enabled
			}

			// cancel dnd if original target is content editable
			if (originalTarget.isContentEditable) {
				return;
			}

			target = _closest(target, options.draggable, el);

			if (!target) {
				return;
			}

			if (lastDownEl === target) {
				// Ignoring duplicate `down`
				return;
			}

			// Get the index of the dragged element within its parent
			startIndex = _index(target, options.draggable);

			// Check filter
			if (typeof filter === 'function') {
				if (filter.call(this, evt, target, this)) {
					_dispatchEvent(_this, originalTarget, 'filter', target, el, el, startIndex);
					preventOnFilter && evt.preventDefault();
					return; // cancel dnd
				}
			}
			else if (filter) {
				filter = filter.split(',').some(function (criteria) {
					criteria = _closest(originalTarget, criteria.trim(), el);

					if (criteria) {
						_dispatchEvent(_this, criteria, 'filter', target, el, el, startIndex);
						return true;
					}
				});

				if (filter) {
					preventOnFilter && evt.preventDefault();
					return; // cancel dnd
				}
			}

			if (options.handle && !_closest(originalTarget, options.handle, el)) {
				return;
			}

			// Prepare `dragstart`
			this._prepareDragStart(evt, touch, target, startIndex);
		},

		_prepareDragStart: function (/** Event */evt, /** Touch */touch, /** HTMLElement */target, /** Number */startIndex) {
			var _this = this,
				el = _this.el,
				options = _this.options,
				ownerDocument = el.ownerDocument,
				dragStartFn;

			if (target && !dragEl && (target.parentNode === el)) {
				tapEvt = evt;

				rootEl = el;
				dragEl = target;
				parentEl = dragEl.parentNode;
				nextEl = dragEl.nextSibling;
				lastDownEl = target;
				activeGroup = options.group;
				oldIndex = startIndex;

				this._lastX = (touch || evt).clientX;
				this._lastY = (touch || evt).clientY;

				dragEl.style['will-change'] = 'all';

				dragStartFn = function () {
					// Delayed drag has been triggered
					// we can re-enable the events: touchmove/mousemove
					_this._disableDelayedDrag();

					// Make the element draggable
					dragEl.draggable = _this.nativeDraggable;

					// Chosen item
					_toggleClass(dragEl, options.chosenClass, true);

					// Bind the events: dragstart/dragend
					_this._triggerDragStart(evt, touch);

					// Drag start event
					_dispatchEvent(_this, rootEl, 'choose', dragEl, rootEl, rootEl, oldIndex);
				};

				// Disable "draggable"
				options.ignore.split(',').forEach(function (criteria) {
					_find(dragEl, criteria.trim(), _disableDraggable);
				});

				_on(ownerDocument, 'mouseup', _this._onDrop);
				_on(ownerDocument, 'touchend', _this._onDrop);
				_on(ownerDocument, 'touchcancel', _this._onDrop);
				_on(ownerDocument, 'selectstart', _this);
				options.supportPointer && _on(ownerDocument, 'pointercancel', _this._onDrop);

				if (options.delay) {
					// If the user moves the pointer or let go the click or touch
					// before the delay has been reached:
					// disable the delayed drag
					_on(ownerDocument, 'mouseup', _this._disableDelayedDrag);
					_on(ownerDocument, 'touchend', _this._disableDelayedDrag);
					_on(ownerDocument, 'touchcancel', _this._disableDelayedDrag);
					_on(ownerDocument, 'mousemove', _this._disableDelayedDrag);
					_on(ownerDocument, 'touchmove', _this._disableDelayedDrag);
					options.supportPointer && _on(ownerDocument, 'pointermove', _this._disableDelayedDrag);

					_this._dragStartTimer = setTimeout(dragStartFn, options.delay);
				} else {
					dragStartFn();
				}


			}
		},

		_disableDelayedDrag: function () {
			var ownerDocument = this.el.ownerDocument;

			clearTimeout(this._dragStartTimer);
			_off(ownerDocument, 'mouseup', this._disableDelayedDrag);
			_off(ownerDocument, 'touchend', this._disableDelayedDrag);
			_off(ownerDocument, 'touchcancel', this._disableDelayedDrag);
			_off(ownerDocument, 'mousemove', this._disableDelayedDrag);
			_off(ownerDocument, 'touchmove', this._disableDelayedDrag);
			_off(ownerDocument, 'pointermove', this._disableDelayedDrag);
		},

		_triggerDragStart: function (/** Event */evt, /** Touch */touch) {
			touch = touch || (evt.pointerType == 'touch' ? evt : null);

			if (touch) {
				// Touch device support
				tapEvt = {
					target: dragEl,
					clientX: touch.clientX,
					clientY: touch.clientY
				};

				this._onDragStart(tapEvt, 'touch');
			}
			else if (!this.nativeDraggable) {
				this._onDragStart(tapEvt, true);
			}
			else {
				_on(dragEl, 'dragend', this);
				_on(rootEl, 'dragstart', this._onDragStart);
			}

			try {
				if (document.selection) {
					// Timeout neccessary for IE9
					_nextTick(function () {
						document.selection.empty();
					});
				} else {
					window.getSelection().removeAllRanges();
				}
			} catch (err) {
			}
		},

		_dragStarted: function () {
			if (rootEl && dragEl) {
				var options = this.options;

				// Apply effect
				_toggleClass(dragEl, options.ghostClass, true);
				_toggleClass(dragEl, options.dragClass, false);

				Sortable.active = this;

				// Drag start event
				_dispatchEvent(this, rootEl, 'start', dragEl, rootEl, rootEl, oldIndex);
			} else {
				this._nulling();
			}
		},

		_emulateDragOver: function () {
			if (touchEvt) {
				if (this._lastX === touchEvt.clientX && this._lastY === touchEvt.clientY) {
					return;
				}

				this._lastX = touchEvt.clientX;
				this._lastY = touchEvt.clientY;

				if (!supportCssPointerEvents) {
					_css(ghostEl, 'display', 'none');
				}

				var target = document.elementFromPoint(touchEvt.clientX, touchEvt.clientY);
				var parent = target;
				var i = touchDragOverListeners.length;

				if (target && target.shadowRoot) {
					target = target.shadowRoot.elementFromPoint(touchEvt.clientX, touchEvt.clientY);
					parent = target;
				}

				if (parent) {
					do {
						if (parent[expando]) {
							while (i--) {
								touchDragOverListeners[i]({
									clientX: touchEvt.clientX,
									clientY: touchEvt.clientY,
									target: target,
									rootEl: parent
								});
							}

							break;
						}

						target = parent; // store last element
					}
					/* jshint boss:true */
					while (parent = parent.parentNode);
				}

				if (!supportCssPointerEvents) {
					_css(ghostEl, 'display', '');
				}
			}
		},


		_onTouchMove: function (/**TouchEvent*/evt) {
			if (tapEvt) {
				var	options = this.options,
					fallbackTolerance = options.fallbackTolerance,
					fallbackOffset = options.fallbackOffset,
					touch = evt.touches ? evt.touches[0] : evt,
					dx = (touch.clientX - tapEvt.clientX) + fallbackOffset.x,
					dy = (touch.clientY - tapEvt.clientY) + fallbackOffset.y,
					translate3d = evt.touches ? 'translate3d(' + dx + 'px,' + dy + 'px,0)' : 'translate(' + dx + 'px,' + dy + 'px)';

				// only set the status to dragging, when we are actually dragging
				if (!Sortable.active) {
					if (fallbackTolerance &&
						min(abs(touch.clientX - this._lastX), abs(touch.clientY - this._lastY)) < fallbackTolerance
					) {
						return;
					}

					this._dragStarted();
				}

				// as well as creating the ghost element on the document body
				this._appendGhost();

				moved = true;
				touchEvt = touch;

				_css(ghostEl, 'webkitTransform', translate3d);
				_css(ghostEl, 'mozTransform', translate3d);
				_css(ghostEl, 'msTransform', translate3d);
				_css(ghostEl, 'transform', translate3d);

				evt.preventDefault();
			}
		},

		_appendGhost: function () {
			if (!ghostEl) {
				var rect = dragEl.getBoundingClientRect(),
					css = _css(dragEl),
					options = this.options,
					ghostRect;

				ghostEl = dragEl.cloneNode(true);

				_toggleClass(ghostEl, options.ghostClass, false);
				_toggleClass(ghostEl, options.fallbackClass, true);
				_toggleClass(ghostEl, options.dragClass, true);

				_css(ghostEl, 'top', rect.top - parseInt(css.marginTop, 10));
				_css(ghostEl, 'left', rect.left - parseInt(css.marginLeft, 10));
				_css(ghostEl, 'width', rect.width);
				_css(ghostEl, 'height', rect.height);
				_css(ghostEl, 'opacity', '0.8');
				_css(ghostEl, 'position', 'fixed');
				_css(ghostEl, 'zIndex', '100000');
				_css(ghostEl, 'pointerEvents', 'none');

				options.fallbackOnBody && document.body.appendChild(ghostEl) || rootEl.appendChild(ghostEl);

				// Fixing dimensions.
				ghostRect = ghostEl.getBoundingClientRect();
				_css(ghostEl, 'width', rect.width * 2 - ghostRect.width);
				_css(ghostEl, 'height', rect.height * 2 - ghostRect.height);
			}
		},

		_onDragStart: function (/**Event*/evt, /**boolean*/useFallback) {
			var _this = this;
			var dataTransfer = evt.dataTransfer;
			var options = _this.options;

			_this._offUpEvents();

			if (activeGroup.checkPull(_this, _this, dragEl, evt)) {
				cloneEl = _clone(dragEl);

				cloneEl.draggable = false;
				cloneEl.style['will-change'] = '';

				_css(cloneEl, 'display', 'none');
				_toggleClass(cloneEl, _this.options.chosenClass, false);

				// #1143: IFrame support workaround
				_this._cloneId = _nextTick(function () {
					rootEl.insertBefore(cloneEl, dragEl);
					_dispatchEvent(_this, rootEl, 'clone', dragEl);
				});
			}

			_toggleClass(dragEl, options.dragClass, true);

			if (useFallback) {
				if (useFallback === 'touch') {
					// Bind touch events
					_on(document, 'touchmove', _this._onTouchMove);
					_on(document, 'touchend', _this._onDrop);
					_on(document, 'touchcancel', _this._onDrop);

					if (options.supportPointer) {
						_on(document, 'pointermove', _this._onTouchMove);
						_on(document, 'pointerup', _this._onDrop);
					}
				} else {
					// Old brwoser
					_on(document, 'mousemove', _this._onTouchMove);
					_on(document, 'mouseup', _this._onDrop);
				}

				_this._loopId = setInterval(_this._emulateDragOver, 50);
			}
			else {
				if (dataTransfer) {
					dataTransfer.effectAllowed = 'move';
					options.setData && options.setData.call(_this, dataTransfer, dragEl);
				}

				_on(document, 'drop', _this);

				// #1143: Бывает элемент с IFrame внутри блокирует `drop`,
				// поэтому если вызвался `mouseover`, значит надо отменять весь d'n'd.
				// Breaking Chrome 62+
				// _on(document, 'mouseover', _this);

				_this._dragStartId = _nextTick(_this._dragStarted);
			}
		},

		_onDragOver: function (/**Event*/evt) {
			var el = this.el,
				target,
				dragRect,
				targetRect,
				revert,
				options = this.options,
				group = options.group,
				activeSortable = Sortable.active,
				isOwner = (activeGroup === group),
				isMovingBetweenSortable = false,
				canSort = options.sort;

			if (evt.preventDefault !== void 0) {
				evt.preventDefault();
				!options.dragoverBubble && evt.stopPropagation();
			}

			if (dragEl.animated) {
				return;
			}

			moved = true;

			if (activeSortable && !options.disabled &&
				(isOwner
					? canSort || (revert = !rootEl.contains(dragEl)) // Reverting item into the original list
					: (
						putSortable === this ||
						(
							(activeSortable.lastPullMode = activeGroup.checkPull(this, activeSortable, dragEl, evt)) &&
							group.checkPut(this, activeSortable, dragEl, evt)
						)
					)
				) &&
				(evt.rootEl === void 0 || evt.rootEl === this.el) // touch fallback
			) {
				// Smart auto-scrolling
				_autoScroll(evt, options, this.el);

				if (_silent) {
					return;
				}

				target = _closest(evt.target, options.draggable, el);
				dragRect = dragEl.getBoundingClientRect();

				if (putSortable !== this) {
					putSortable = this;
					isMovingBetweenSortable = true;
				}

				if (revert) {
					_cloneHide(activeSortable, true);
					parentEl = rootEl; // actualization

					if (cloneEl || nextEl) {
						rootEl.insertBefore(dragEl, cloneEl || nextEl);
					}
					else if (!canSort) {
						rootEl.appendChild(dragEl);
					}

					return;
				}


				if ((el.children.length === 0) || (el.children[0] === ghostEl) ||
					(el === evt.target) && (_ghostIsLast(el, evt))
				) {
					//assign target only if condition is true
					if (el.children.length !== 0 && el.children[0] !== ghostEl && el === evt.target) {
						target = el.lastElementChild;
					}

					if (target) {
						if (target.animated) {
							return;
						}

						targetRect = target.getBoundingClientRect();
					}

					_cloneHide(activeSortable, isOwner);

					if (_onMove(rootEl, el, dragEl, dragRect, target, targetRect, evt) !== false) {
						if (!dragEl.contains(el)) {
							el.appendChild(dragEl);
							parentEl = el; // actualization
						}

						this._animate(dragRect, dragEl);
						target && this._animate(targetRect, target);
					}
				}
				else if (target && !target.animated && target !== dragEl && (target.parentNode[expando] !== void 0)) {
					if (lastEl !== target) {
						lastEl = target;
						lastCSS = _css(target);
						lastParentCSS = _css(target.parentNode);
					}

					targetRect = target.getBoundingClientRect();

					var width = targetRect.right - targetRect.left,
						height = targetRect.bottom - targetRect.top,
						floating = R_FLOAT.test(lastCSS.cssFloat + lastCSS.display)
							|| (lastParentCSS.display == 'flex' && lastParentCSS['flex-direction'].indexOf('row') === 0),
						isWide = (target.offsetWidth > dragEl.offsetWidth),
						isLong = (target.offsetHeight > dragEl.offsetHeight),
						halfway = (floating ? (evt.clientX - targetRect.left) / width : (evt.clientY - targetRect.top) / height) > 0.5,
						nextSibling = target.nextElementSibling,
						after = false
					;

					if (floating) {
						var elTop = dragEl.offsetTop,
							tgTop = target.offsetTop;

						if (elTop === tgTop) {
							after = (target.previousElementSibling === dragEl) && !isWide || halfway && isWide;
						}
						else if (target.previousElementSibling === dragEl || dragEl.previousElementSibling === target) {
							after = (evt.clientY - targetRect.top) / height > 0.5;
						} else {
							after = tgTop > elTop;
						}
						} else if (!isMovingBetweenSortable) {
						after = (nextSibling !== dragEl) && !isLong || halfway && isLong;
					}

					var moveVector = _onMove(rootEl, el, dragEl, dragRect, target, targetRect, evt, after);

					if (moveVector !== false) {
						if (moveVector === 1 || moveVector === -1) {
							after = (moveVector === 1);
						}

						_silent = true;
						setTimeout(_unsilent, 30);

						_cloneHide(activeSortable, isOwner);

						if (!dragEl.contains(el)) {
							if (after && !nextSibling) {
								el.appendChild(dragEl);
							} else {
								target.parentNode.insertBefore(dragEl, after ? nextSibling : target);
							}
						}

						parentEl = dragEl.parentNode; // actualization

						this._animate(dragRect, dragEl);
						this._animate(targetRect, target);
					}
				}
			}
		},

		_animate: function (prevRect, target) {
			var ms = this.options.animation;

			if (ms) {
				var currentRect = target.getBoundingClientRect();

				if (prevRect.nodeType === 1) {
					prevRect = prevRect.getBoundingClientRect();
				}

				_css(target, 'transition', 'none');
				_css(target, 'transform', 'translate3d('
					+ (prevRect.left - currentRect.left) + 'px,'
					+ (prevRect.top - currentRect.top) + 'px,0)'
				);

				target.offsetWidth; // repaint

				_css(target, 'transition', 'all ' + ms + 'ms');
				_css(target, 'transform', 'translate3d(0,0,0)');

				clearTimeout(target.animated);
				target.animated = setTimeout(function () {
					_css(target, 'transition', '');
					_css(target, 'transform', '');
					target.animated = false;
				}, ms);
			}
		},

		_offUpEvents: function () {
			var ownerDocument = this.el.ownerDocument;

			_off(document, 'touchmove', this._onTouchMove);
			_off(document, 'pointermove', this._onTouchMove);
			_off(ownerDocument, 'mouseup', this._onDrop);
			_off(ownerDocument, 'touchend', this._onDrop);
			_off(ownerDocument, 'pointerup', this._onDrop);
			_off(ownerDocument, 'touchcancel', this._onDrop);
			_off(ownerDocument, 'pointercancel', this._onDrop);
			_off(ownerDocument, 'selectstart', this);
		},

		_onDrop: function (/**Event*/evt) {
			var el = this.el,
				options = this.options;

			clearInterval(this._loopId);
			clearInterval(autoScroll.pid);
			clearTimeout(this._dragStartTimer);

			_cancelNextTick(this._cloneId);
			_cancelNextTick(this._dragStartId);

			// Unbind events
			_off(document, 'mouseover', this);
			_off(document, 'mousemove', this._onTouchMove);

			if (this.nativeDraggable) {
				_off(document, 'drop', this);
				_off(el, 'dragstart', this._onDragStart);
			}

			this._offUpEvents();

			if (evt) {
				if (moved) {
					evt.preventDefault();
					!options.dropBubble && evt.stopPropagation();
				}

				ghostEl && ghostEl.parentNode && ghostEl.parentNode.removeChild(ghostEl);

				if (rootEl === parentEl || Sortable.active.lastPullMode !== 'clone') {
					// Remove clone
					cloneEl && cloneEl.parentNode && cloneEl.parentNode.removeChild(cloneEl);
				}

				if (dragEl) {
					if (this.nativeDraggable) {
						_off(dragEl, 'dragend', this);
					}

					_disableDraggable(dragEl);
					dragEl.style['will-change'] = '';

					// Remove class's
					_toggleClass(dragEl, this.options.ghostClass, false);
					_toggleClass(dragEl, this.options.chosenClass, false);

					// Drag stop event
					_dispatchEvent(this, rootEl, 'unchoose', dragEl, parentEl, rootEl, oldIndex);

					if (rootEl !== parentEl) {
						newIndex = _index(dragEl, options.draggable);

						if (newIndex >= 0) {
							// Add event
							_dispatchEvent(null, parentEl, 'add', dragEl, parentEl, rootEl, oldIndex, newIndex);

							// Remove event
							_dispatchEvent(this, rootEl, 'remove', dragEl, parentEl, rootEl, oldIndex, newIndex);

							// drag from one list and drop into another
							_dispatchEvent(null, parentEl, 'sort', dragEl, parentEl, rootEl, oldIndex, newIndex);
							_dispatchEvent(this, rootEl, 'sort', dragEl, parentEl, rootEl, oldIndex, newIndex);
						}
					}
					else {
						if (dragEl.nextSibling !== nextEl) {
							// Get the index of the dragged element within its parent
							newIndex = _index(dragEl, options.draggable);

							if (newIndex >= 0) {
								// drag & drop within the same list
								_dispatchEvent(this, rootEl, 'update', dragEl, parentEl, rootEl, oldIndex, newIndex);
								_dispatchEvent(this, rootEl, 'sort', dragEl, parentEl, rootEl, oldIndex, newIndex);
							}
						}
					}

					if (Sortable.active) {
						/* jshint eqnull:true */
						if (newIndex == null || newIndex === -1) {
							newIndex = oldIndex;
						}

						_dispatchEvent(this, rootEl, 'end', dragEl, parentEl, rootEl, oldIndex, newIndex);

						// Save sorting
						this.save();
					}
				}

			}

			this._nulling();
		},

		_nulling: function() {
			rootEl =
			dragEl =
			parentEl =
			ghostEl =
			nextEl =
			cloneEl =
			lastDownEl =

			scrollEl =
			scrollParentEl =

			tapEvt =
			touchEvt =

			moved =
			newIndex =

			lastEl =
			lastCSS =

			putSortable =
			activeGroup =
			Sortable.active = null;

			savedInputChecked.forEach(function (el) {
				el.checked = true;
			});
			savedInputChecked.length = 0;
		},

		handleEvent: function (/**Event*/evt) {
			switch (evt.type) {
				case 'drop':
				case 'dragend':
					this._onDrop(evt);
					break;

				case 'dragover':
				case 'dragenter':
					if (dragEl) {
						this._onDragOver(evt);
						_globalDragOver(evt);
					}
					break;

				case 'mouseover':
					this._onDrop(evt);
					break;

				case 'selectstart':
					evt.preventDefault();
					break;
			}
		},


		/**
		 * Serializes the item into an array of string.
		 * @returns {String[]}
		 */
		toArray: function () {
			var order = [],
				el,
				children = this.el.children,
				i = 0,
				n = children.length,
				options = this.options;

			for (; i < n; i++) {
				el = children[i];
				if (_closest(el, options.draggable, this.el)) {
					order.push(el.getAttribute(options.dataIdAttr) || _generateId(el));
				}
			}

			return order;
		},


		/**
		 * Sorts the elements according to the array.
		 * @param  {String[]}  order  order of the items
		 */
		sort: function (order) {
			var items = {}, rootEl = this.el;

			this.toArray().forEach(function (id, i) {
				var el = rootEl.children[i];

				if (_closest(el, this.options.draggable, rootEl)) {
					items[id] = el;
				}
			}, this);

			order.forEach(function (id) {
				if (items[id]) {
					rootEl.removeChild(items[id]);
					rootEl.appendChild(items[id]);
				}
			});
		},


		/**
		 * Save the current sorting
		 */
		save: function () {
			var store = this.options.store;
			store && store.set(this);
		},


		/**
		 * For each element in the set, get the first element that matches the selector by testing the element itself and traversing up through its ancestors in the DOM tree.
		 * @param   {HTMLElement}  el
		 * @param   {String}       [selector]  default: `options.draggable`
		 * @returns {HTMLElement|null}
		 */
		closest: function (el, selector) {
			return _closest(el, selector || this.options.draggable, this.el);
		},


		/**
		 * Set/get option
		 * @param   {string} name
		 * @param   {*}      [value]
		 * @returns {*}
		 */
		option: function (name, value) {
			var options = this.options;

			if (value === void 0) {
				return options[name];
			} else {
				options[name] = value;

				if (name === 'group') {
					_prepareGroup(options);
				}
			}
		},


		/**
		 * Destroy
		 */
		destroy: function () {
			var el = this.el;

			el[expando] = null;

			_off(el, 'mousedown', this._onTapStart);
			_off(el, 'touchstart', this._onTapStart);
			_off(el, 'pointerdown', this._onTapStart);

			if (this.nativeDraggable) {
				_off(el, 'dragover', this);
				_off(el, 'dragenter', this);
			}

			// Remove draggable attributes
			Array.prototype.forEach.call(el.querySelectorAll('[draggable]'), function (el) {
				el.removeAttribute('draggable');
			});

			touchDragOverListeners.splice(touchDragOverListeners.indexOf(this._onDragOver), 1);

			this._onDrop();

			this.el = el = null;
		}
	};


	function _cloneHide(sortable, state) {
		if (sortable.lastPullMode !== 'clone') {
			state = true;
		}

		if (cloneEl && (cloneEl.state !== state)) {
			_css(cloneEl, 'display', state ? 'none' : '');

			if (!state) {
				if (cloneEl.state) {
					if (sortable.options.group.revertClone) {
						rootEl.insertBefore(cloneEl, nextEl);
						sortable._animate(dragEl, cloneEl);
					} else {
						rootEl.insertBefore(cloneEl, dragEl);
					}
				}
			}

			cloneEl.state = state;
		}
	}


	function _closest(/**HTMLElement*/el, /**String*/selector, /**HTMLElement*/ctx) {
		if (el) {
			ctx = ctx || document;

			do {
				if ((selector === '>*' && el.parentNode === ctx) || _matches(el, selector)) {
					return el;
				}
				/* jshint boss:true */
			} while (el = _getParentOrHost(el));
		}

		return null;
	}


	function _getParentOrHost(el) {
		var parent = el.host;

		return (parent && parent.nodeType) ? parent : el.parentNode;
	}


	function _globalDragOver(/**Event*/evt) {
		if (evt.dataTransfer) {
			evt.dataTransfer.dropEffect = 'move';
		}
		evt.preventDefault();
	}


	function _on(el, event, fn) {
		el.addEventListener(event, fn, captureMode);
	}


	function _off(el, event, fn) {
		el.removeEventListener(event, fn, captureMode);
	}


	function _toggleClass(el, name, state) {
		if (el) {
			if (el.classList) {
				el.classList[state ? 'add' : 'remove'](name);
			}
			else {
				var className = (' ' + el.className + ' ').replace(R_SPACE, ' ').replace(' ' + name + ' ', ' ');
				el.className = (className + (state ? ' ' + name : '')).replace(R_SPACE, ' ');
			}
		}
	}


	function _css(el, prop, val) {
		var style = el && el.style;

		if (style) {
			if (val === void 0) {
				if (document.defaultView && document.defaultView.getComputedStyle) {
					val = document.defaultView.getComputedStyle(el, '');
				}
				else if (el.currentStyle) {
					val = el.currentStyle;
				}

				return prop === void 0 ? val : val[prop];
			}
			else {
				if (!(prop in style)) {
					prop = '-webkit-' + prop;
				}

				style[prop] = val + (typeof val === 'string' ? '' : 'px');
			}
		}
	}


	function _find(ctx, tagName, iterator) {
		if (ctx) {
			var list = ctx.getElementsByTagName(tagName), i = 0, n = list.length;

			if (iterator) {
				for (; i < n; i++) {
					iterator(list[i], i);
				}
			}

			return list;
		}

		return [];
	}



	function _dispatchEvent(sortable, rootEl, name, targetEl, toEl, fromEl, startIndex, newIndex) {
		sortable = (sortable || rootEl[expando]);

		var evt = document.createEvent('Event'),
			options = sortable.options,
			onName = 'on' + name.charAt(0).toUpperCase() + name.substr(1);

		evt.initEvent(name, true, true);

		evt.to = toEl || rootEl;
		evt.from = fromEl || rootEl;
		evt.item = targetEl || rootEl;
		evt.clone = cloneEl;

		evt.oldIndex = startIndex;
		evt.newIndex = newIndex;

		rootEl.dispatchEvent(evt);

		if (options[onName]) {
			options[onName].call(sortable, evt);
		}
	}


	function _onMove(fromEl, toEl, dragEl, dragRect, targetEl, targetRect, originalEvt, willInsertAfter) {
		var evt,
			sortable = fromEl[expando],
			onMoveFn = sortable.options.onMove,
			retVal;

		evt = document.createEvent('Event');
		evt.initEvent('move', true, true);

		evt.to = toEl;
		evt.from = fromEl;
		evt.dragged = dragEl;
		evt.draggedRect = dragRect;
		evt.related = targetEl || toEl;
		evt.relatedRect = targetRect || toEl.getBoundingClientRect();
		evt.willInsertAfter = willInsertAfter;

		fromEl.dispatchEvent(evt);

		if (onMoveFn) {
			retVal = onMoveFn.call(sortable, evt, originalEvt);
		}

		return retVal;
	}


	function _disableDraggable(el) {
		el.draggable = false;
	}


	function _unsilent() {
		_silent = false;
	}


	/** @returns {HTMLElement|false} */
	function _ghostIsLast(el, evt) {
		var lastEl = el.lastElementChild,
			rect = lastEl.getBoundingClientRect();

		// 5 — min delta
		// abs — нельзя добавлять, а то глюки при наведении сверху
		return (evt.clientY - (rect.top + rect.height) > 5) ||
			(evt.clientX - (rect.left + rect.width) > 5);
	}


	/**
	 * Generate id
	 * @param   {HTMLElement} el
	 * @returns {String}
	 * @private
	 */
	function _generateId(el) {
		var str = el.tagName + el.className + el.src + el.href + el.textContent,
			i = str.length,
			sum = 0;

		while (i--) {
			sum += str.charCodeAt(i);
		}

		return sum.toString(36);
	}

	/**
	 * Returns the index of an element within its parent for a selected set of
	 * elements
	 * @param  {HTMLElement} el
	 * @param  {selector} selector
	 * @return {number}
	 */
	function _index(el, selector) {
		var index = 0;

		if (!el || !el.parentNode) {
			return -1;
		}

		while (el && (el = el.previousElementSibling)) {
			if ((el.nodeName.toUpperCase() !== 'TEMPLATE') && (selector === '>*' || _matches(el, selector))) {
				index++;
			}
		}

		return index;
	}

	function _matches(/**HTMLElement*/el, /**String*/selector) {
		if (el) {
			selector = selector.split('.');

			var tag = selector.shift().toUpperCase(),
				re = new RegExp('\\s(' + selector.join('|') + ')(?=\\s)', 'g');

			return (
				(tag === '' || el.nodeName.toUpperCase() == tag) &&
				(!selector.length || ((' ' + el.className + ' ').match(re) || []).length == selector.length)
			);
		}

		return false;
	}

	function _throttle(callback, ms) {
		var args, _this;

		return function () {
			if (args === void 0) {
				args = arguments;
				_this = this;

				setTimeout(function () {
					if (args.length === 1) {
						callback.call(_this, args[0]);
					} else {
						callback.apply(_this, args);
					}

					args = void 0;
				}, ms);
			}
		};
	}

	function _extend(dst, src) {
		if (dst && src) {
			for (var key in src) {
				if (src.hasOwnProperty(key)) {
					dst[key] = src[key];
				}
			}
		}

		return dst;
	}

	function _clone(el) {
		if (Polymer && Polymer.dom) {
			return Polymer.dom(el).cloneNode(true);
		}
		else if ($) {
			return $(el).clone(true)[0];
		}
		else {
			return el.cloneNode(true);
		}
	}

	function _saveInputCheckedState(root) {
		var inputs = root.getElementsByTagName('input');
		var idx = inputs.length;

		while (idx--) {
			var el = inputs[idx];
			el.checked && savedInputChecked.push(el);
		}
	}

	function _nextTick(fn) {
		return setTimeout(fn, 0);
	}

	function _cancelNextTick(id) {
		return clearTimeout(id);
	}

	// Fixed #973:
	_on(document, 'touchmove', function (evt) {
		if (Sortable.active) {
			evt.preventDefault();
		}
	});

	// Export utils
	Sortable.utils = {
		on: _on,
		off: _off,
		css: _css,
		find: _find,
		is: function (el, selector) {
			return !!_closest(el, selector, el);
		},
		extend: _extend,
		throttle: _throttle,
		closest: _closest,
		toggleClass: _toggleClass,
		clone: _clone,
		index: _index,
		nextTick: _nextTick,
		cancelNextTick: _cancelNextTick
	};


	/**
	 * Create sortable instance
	 * @param {HTMLElement}  el
	 * @param {Object}      [options]
	 */
	Sortable.create = function (el, options) {
		return new Sortable(el, options);
	};


	// Export
	Sortable.version = '1.7.0';
	return Sortable;
});


/***/ }),

/***/ 3101:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ xmlns: "http://www.w3.org/2000/svg", width: "12", height: "12", viewBox: "0 0 12 12" }, props),
    _react2.default.createElement("path", { fill: "#1A84EE", fillRule: "evenodd", d: "M5 5H1a1 1 0 1 0 0 2h4v4a1 1 0 0 0 2 0V7h4a1 1 0 0 0 0-2H7V1a1 1 0 1 0-2 0v4z" })
  );
};

/***/ }),

/***/ 3102:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.default = undefined;

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

__webpack_require__(1817);

var _dropdownSelected = __webpack_require__(3103);

var _dropdownSelected2 = _interopRequireDefault(_dropdownSelected);

var _classnames = __webpack_require__(29);

var _classnames2 = _interopRequireDefault(_classnames);

var _sheet = __webpack_require__(713);

var _sheet_context = __webpack_require__(1578);

var _dropdownHelper = __webpack_require__(1625);

var _shellNotify = __webpack_require__(1576);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var Direction;
(function (Direction) {
    Direction[Direction["UP"] = 0] = "UP";
    Direction[Direction["DOWN"] = 1] = "DOWN";
})(Direction || (Direction = {}));
var sheetArea = GC.Spread.Sheets.SheetArea;
var DROPDOWN_ITEM_HEIGHT = 28;

var DropdownList = function (_Component) {
    (0, _inherits3.default)(DropdownList, _Component);

    function DropdownList(props) {
        (0, _classCallCheck3.default)(this, DropdownList);

        var _this = (0, _possibleConstructorReturn3.default)(this, (DropdownList.__proto__ || Object.getPrototypeOf(DropdownList)).call(this, props));

        _this.handleSelect = function (content) {
            var sheet = _this.props.spread.getActiveSheet();
            var row = _this.state.row;
            var col = _this.state.col;
            _this.props.spread.commandManager().execute({
                cmd: 'setDropdownValid',
                sheetId: sheet.id(),
                sheetName: sheet.name(),
                row: row,
                col: col,
                text: content
            });
            _this.setState({
                visible: false
            });
            _this.props.spread.focus();
        };
        _this._bindEvents = function () {
            var spread = _this.props.spread;

            var context = spread._context;
            [_sheet.Events.EditChange].forEach(function (event) {
                spread.bind(event, _this._filterDropdown);
            });
            [_sheet.Events.CellDoubleClick, _sheet.Events.ShowDropdown].forEach(function (event) {
                spread.bind(event, _this._openDropdown);
            });
            [_sheet.Events.ActiveCellChanged, _sheet.Events.ActiveSheetChanged, _sheet.Events.ShowFilter, _sheet.Events.HideDropdown].forEach(function (event) {
                spread.bind(event, _this._closeDropdown);
            });
            [_sheet.Events.ColumnWidthChanged, _sheet.Events.RowHeightChanged].forEach(function (event) {
                spread.bind(event, _this._adjustDropdown);
            });
            context.bind(_sheet_context.CollaborativeEvents.NEW_CHANGES, _this._closeDropdown);
            context.bind(_sheet_context.CollaborativeEvents.CELL_COORD_CHANGE, _this._adjustDropdown);
        };
        _this._unbindEvents = function () {
            var spread = _this.props.spread;

            var context = spread._context;
            [_sheet.Events.EditChange].forEach(function (event) {
                spread.unbind(event, _this._filterDropdown);
            });
            [_sheet.Events.CellDoubleClick, _sheet.Events.ShowDropdown].forEach(function (event) {
                spread.unbind(event, _this._openDropdown);
            });
            [_sheet.Events.ActiveCellChanged, _sheet.Events.ActiveSheetChanged, _sheet.Events.ShowFilter, _sheet.Events.HideDropdown].forEach(function (event) {
                spread.unbind(event, _this._closeDropdown);
            });
            [_sheet.Events.ColumnWidthChanged, _sheet.Events.RowHeightChanged].forEach(function (event) {
                spread.unbind(event, _this._adjustDropdown);
            });
            context.unbind(_sheet_context.CollaborativeEvents.NEW_CHANGES, _this._closeDropdown);
            context.unbind(_sheet_context.CollaborativeEvents.CELL_COORD_CHANGE, _this._adjustDropdown);
        };
        _this._adjustDropdown = function (params) {
            if (!_this.state.visible) {
                return;
            }
            // const sheet = this.props.spread.getActiveSheet();
            var target = params.target,
                type = params.type;
            var _this$state = _this.state,
                row = _this$state.row,
                col = _this$state.col;

            if (target) {
                switch (type) {
                    case 'del':
                        if (target.row !== undefined) {
                            // 行被删除
                            if (target.row <= row && row <= target.row + target.rowCount - 1) {
                                _this.setState({
                                    visible: false
                                });
                            }
                            if (target.row < row && target.row + target.rowCount - 1 < row) {
                                row -= target.rowCount;
                            }
                        }
                        if (target.col !== undefined) {
                            // 列被删除
                            if (target.col <= col && col <= target.col + target.colCount - 1) {
                                _this.setState({
                                    visible: false
                                });
                            }
                            if (target.col < col && target.col + target.colCount - 1 < col) {
                                col -= target.colCount;
                            }
                        }
                        break;
                    case 'add':
                        if (target.row !== undefined) {
                            if (row >= target.row) row += target.rowCount;
                        }
                        if (target.col !== undefined) {
                            if (col >= target.col) col += target.colCount;
                        }
                        break;
                }
            }
            _this.setState(function (prevState) {
                return Object.assign({}, _this.getRefreshedPos(row, col), {
                    row: row,
                    col: col
                });
            });
        };
        _this._filterDropdown = function (event, params) {
            var row = params.row,
                col = params.col,
                editingText = params.editingText;

            if (!(0, _dropdownHelper.cellHasDropdown)(_this.props.spread.getActiveSheet(), row, col)) return;
            _this.setState(function (prevState) {
                var newDropdownList = _this._getDropdownList(row, col);
                if (editingText && editingText.length !== 0) {
                    newDropdownList = newDropdownList.filter(function (text) {
                        return text.indexOf(editingText) !== -1;
                    });
                }
                var visible = true;
                if (newDropdownList.length === 0) {
                    visible = false;
                }

                var _this$_getCellWidth = _this._getCellWidth(row, col),
                    width = _this$_getCellWidth.width,
                    maxWidth = _this$_getCellWidth.maxWidth;

                return {
                    visible: visible,
                    dropdownList: newDropdownList,
                    cellText: editingText,
                    row: row,
                    col: col,
                    minWidth: width,
                    maxWidth: maxWidth - 50,
                    inFilter: true
                };
            });
        };
        _this._openDropdown = function (event, params) {
            var _this$props = _this.props,
                editable = _this$props.editable,
                spread = _this$props.spread;

            if (!editable) return;
            var sheet = spread.getActiveSheet();
            sheet.endEdit();
            _this.updateDomBoundsInfo();
            var row = params.row,
                col = params.col;

            if (event.type === _sheet.Events.ShowDropdown && _this.state.visible === true && _this.state.row === row && _this.state.col === col) {
                _this.setState({
                    visible: false
                });
                return;
            }
            if (event.type === _sheet.Events.ShowDropdown) {
                sheet._setFocus();
                sheet.setSelection(row, col, 1, 1);
            }
            if (!(0, _dropdownHelper.cellHasDropdown)(sheet, row, col)) {
                return;
            }

            var _this$_getCellWidth2 = _this._getCellWidth(row, col),
                width = _this$_getCellWidth2.width,
                maxWidth = _this$_getCellWidth2.maxWidth;

            _this.setState(Object.assign({
                visible: true,
                dropdownList: _this._getDropdownList(row, col),
                cellText: _this._getCellText(row, col),
                row: row,
                col: col,
                minWidth: width,
                maxWidth: maxWidth - 50,
                prevCell: { row: _this.state.row, col: _this.state.col }
            }, _this.getRefreshedPos(row, col)));
            // 设置标志位以防止后续的Click事件关闭下拉框
            _this.ignoreWindowClick = true;
            window.addEventListener('click', _this._closeDropdown);
            window.addEventListener('keydown', _this._closeDropdown);
            _this.props.spread.getActiveSheet().notifyShell(_shellNotify.ShellNotifyType.BindCellPosition, {
                key: 'dropdownList',
                col: _this.state.col,
                row: _this.state.row,
                cb: function cb() {
                    _this._adjustDropdown({});
                }
            });
        };
        _this._getCellWidth = function (row, col) {
            var sheet = _this.props.spread.getActiveSheet();

            var _sheet$getCellRect = sheet.getCellRect(row, col),
                x = _sheet$getCellRect.x,
                width = _sheet$getCellRect.width;

            var _this$props$getCanvas = _this.props.getCanvasBoundingRect(),
                realHostWidth = _this$props$getCanvas.width;

            return { width: width, maxWidth: realHostWidth - x };
        };
        _this.getRefreshedPos = function (row, col) {
            var spread = _this.props.spread;

            var sheet = spread.getActiveSheet();
            var isEmbed = spread.options.embed;

            var _sheet$getCellRect2 = sheet.getCellRect(row, col),
                cellX = _sheet$getCellRect2.x,
                cellY = _sheet$getCellRect2.y,
                cellHeight = _sheet$getCellRect2.height;

            var colHeaderHeight = sheet.getRowHeight(-1, sheetArea.colHeader);
            var offsetRect = _this.props.getCanvasBoundingRect();
            var tableBounds = isEmbed ? document.body.getBoundingClientRect() : sheet.sheetViewRect(row, col);
            var left = cellX + (isEmbed ? offsetRect.left : 0);
            var top = cellY + cellHeight + (isEmbed ? offsetRect.top : 0);
            var topBound = isEmbed ? 0 : tableBounds.y || colHeaderHeight;
            var bottomBound = tableBounds.y + tableBounds.height;
            var height = _this.state.dropdownList.length * DROPDOWN_ITEM_HEIGHT + 16;
            var bottom = top + height;
            var realY = top;
            // 如果TOP在区域下半部分，则向上展示
            height = Math.min(height, (bottomBound - topBound) / 2);
            if (top > bottomBound / 2) {
                bottom = top - cellHeight;
                realY = bottom - height;
            }
            return {
                x: Math.round(left),
                y: Math.round(realY),
                bottom: Math.round(bottom),
                listHeight: Math.round(height),
                direction: Direction.DOWN
            };
        };
        _this._closeDropdown = function (e) {
            if (e instanceof MouseEvent && _this.ignoreWindowClick) {
                _this.ignoreWindowClick = false;
                return;
            }
            if (_this.state.visible === false) {
                return;
            }
            _this.setState({
                visible: false
            });
            window.removeEventListener('click', _this._closeDropdown);
            window.removeEventListener('keydown', _this._closeDropdown);
            _this.props.spread.getActiveSheet().notifyShell(_shellNotify.ShellNotifyType.UnbindCellPosition, {
                key: 'dropdownList'
            });
        };
        _this._getCellText = function (row, col) {
            return _this.props.spread.getActiveSheet().getText(row, col);
        };
        _this._getDropdownList = function (row, col) {
            var sheet = _this.props.spread.getActiveSheet();
            if (!(0, _dropdownHelper.cellHasDropdown)(sheet, row, col)) return [];
            return sheet.getStyle(row, col).dropdown.list;
        };
        _this.state = {
            visible: false,
            x: 0,
            y: 0,
            cellY: 0,
            bottom: 0,
            direction: Direction.DOWN,
            listHeight: 0,
            dropdownList: [],
            cellText: '',
            row: -1,
            col: -1,
            prevCell: { row: -1, col: -1 },
            inFilter: false,
            minWidth: 0,
            maxWidth: 0
        };
        _this.ignoreWindowClick = false;
        return _this;
    }

    (0, _createClass3.default)(DropdownList, [{
        key: 'componentDidMount',
        value: function componentDidMount() {
            this._bindEvents();
        }
    }, {
        key: 'componentWillUnmount',
        value: function componentWillUnmount() {
            this._unbindEvents();
        }
    }, {
        key: 'shouldComponentUpdate',
        value: function shouldComponentUpdate(nextProps, nextState) {
            if (this.state.visible === false && nextState.visible === false) {
                return false;
            }
            return true;
        }
    }, {
        key: 'componentDidUpdate',
        value: function componentDidUpdate(prevProps, prevState) {
            var _state$prevCell = this.state.prevCell,
                prevRow = _state$prevCell.row,
                prevCol = _state$prevCell.col;
            var spread = this.props.spread;

            if (this.state.visible !== prevState.visible && this.state.visible === true) {
                this.updateDomBoundsInfo();
                this._adjustDropdown({});
                if (spread && spread._context.embed) {
                    spread.focus(false);
                }
            }
            if ((this.state.row !== prevRow || this.state.col !== prevCol || this.state.inFilter) && this.state.visible !== false) {
                this.setState(Object.assign({}, this.getRefreshedPos(this.state.row, this.state.col), {
                    prevCell: {
                        row: this.state.row,
                        col: this.state.col
                    },
                    inFilter: false
                }));
            }
        }
    }, {
        key: 'updateDomBoundsInfo',
        value: function updateDomBoundsInfo() {
            this.hostBoundingRect = this.props.getCanvasBoundingRect();
        }
    }, {
        key: 'render',
        value: function render() {
            var _this2 = this;

            var prefixCls = 'sheet-dropdown__list';
            var sheetComponentName = 'sheet-dropdown__list';
            var directionClass = {};
            var _state = this.state,
                direction = _state.direction,
                x = _state.x,
                y = _state.y,
                bottom = _state.bottom,
                visible = _state.visible,
                minWidth = _state.minWidth,
                dropdownList = _state.dropdownList,
                listHeight = _state.listHeight,
                cellText = _state.cellText,
                maxWidth = _state.maxWidth;

            if (direction === Direction.DOWN) {
                directionClass.top = y;
            } else {
                directionClass.bottom = bottom;
            }
            return _react2.default.createElement("div", { className: (0, _classnames2.default)(prefixCls, visible ? '' : prefixCls + '--hidden'), style: Object.assign({
                    left: x,
                    minWidth: minWidth,
                    maxHeight: listHeight
                }, directionClass), "data-sheet-component": sheetComponentName }, dropdownList.map(function (content, idx) {
                return _react2.default.createElement("div", { key: prefixCls + '-' + idx, className: (0, _classnames2.default)(prefixCls + '-single', content === cellText ? prefixCls + '-single-active' : ''), onClick: _this2.handleSelect.bind(_this2, content) }, _react2.default.createElement("div", { className: prefixCls + '-single-left' }, content === cellText ? _react2.default.createElement(_dropdownSelected2.default, null) : ''), _react2.default.createElement("div", { className: prefixCls + '-single-content', style: {
                        maxWidth: maxWidth
                    } }, content));
            }));
        }
    }]);
    return DropdownList;
}(_react.Component);

exports.default = DropdownList;

/***/ }),

/***/ 3103:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ xmlns: "http://www.w3.org/2000/svg", width: "12", height: "12", viewBox: "0 0 12 12" }, props),
    _react2.default.createElement(
      "g",
      { fill: "none", fillRule: "evenodd" },
      _react2.default.createElement("path", { d: "M0 0h12v12H0z" }),
      _react2.default.createElement("path", { fill: "#3799FF", fillRule: "nonzero", d: "M9.3 2.3a1 1 0 0 1 1.4 1.4l-6.86 6.87-2.67-4.02a1 1 0 1 1 1.66-1.1l1.33 1.98 5.13-5.14z" })
    )
  );
};

/***/ }),

/***/ 3104:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.default = undefined;

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _typeof2 = __webpack_require__(76);

var _typeof3 = _interopRequireDefault(_typeof2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

__webpack_require__(1817);

var _error = __webpack_require__(3105);

var _error2 = _interopRequireDefault(_error);

var _debounce = __webpack_require__(767);

var _dropdownHelper = __webpack_require__(1625);

var _sheet = __webpack_require__(713);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var __decorate = undefined && undefined.__decorate || function (decorators, target, key, desc) {
    var c = arguments.length,
        r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc,
        d;
    if ((typeof Reflect === "undefined" ? "undefined" : (0, _typeof3.default)(Reflect)) === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);else for (var i = decorators.length - 1; i >= 0; i--) {
        if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    }return c > 3 && r && Object.defineProperty(target, key, r), r;
};

var Events = GC.Spread.Sheets.Events;
var prefixCls = 'sheet-dropdown__pop';

var DropdownPop = function (_Component) {
    (0, _inherits3.default)(DropdownPop, _Component);

    function DropdownPop(props) {
        (0, _classCallCheck3.default)(this, DropdownPop);

        var _this = (0, _possibleConstructorReturn3.default)(this, (DropdownPop.__proto__ || Object.getPrototypeOf(DropdownPop)).call(this, props));

        _this.onScroll = function () {
            if (_this.state.visible) {
                _this.setState({ visible: false });
            }
        };
        _this.onHoverCellChanged = function (e, params) {
            var sheet = params.sheet,
                row = params.row,
                col = params.col;

            _this.locateDropdownPop(sheet, row, col);
        };
        _this.onEditEnded = function (e, params) {
            var row = params.row,
                col = params.col,
                sheet = params.sheet;

            _this.handleDropdownPop(sheet, row, col);
        };
        _this.onCellChanged = function (e, params) {
            var row = params.row,
                col = params.col,
                sheet = params.sheet;

            _this.handleDropdownPop(sheet, row, col);
        };
        _this.clearDropdownPop = function (e, params) {
            var row = params.row,
                col = params.col;

            if (_this.isSamePosition(row, col)) {
                _this.setState({ visible: false });
            }
        };
        _this.handleDropdownPop = function (sheet, row, col) {
            if (_this.isSamePosition(row, col)) {
                _this.locateDropdownPop(sheet, row, col);
            }
        };
        _this.isSamePosition = function (row, col) {
            return row === _this.state.currentRow && col === _this.state.currentCol;
        };
        _this.state = {
            visible: false,
            x: 0,
            y: 0,
            currentRow: 0,
            currentCol: 0
        };
        return _this;
    }

    (0, _createClass3.default)(DropdownPop, [{
        key: "bindEvents",
        value: function bindEvents(spread) {
            if (!spread) return;
            spread.bind(_sheet.Events.TopPosChanged, this.onScroll);
            spread.bind(_sheet.Events.LeftPosChagned, this.onScroll);
            spread.bind(_sheet.Events.FCellHover, this.onHoverCellChanged);
            spread.bind(Events.CellChanged, this.onCellChanged);
            spread.bind(Events.EditEnded, this.onEditEnded);
            spread.bind(Events.EditStarting, this.clearDropdownPop);
            spread.bind(Events.ShowDropdown, this.clearDropdownPop);
        }
    }, {
        key: "unbindEvents",
        value: function unbindEvents(spread) {
            if (!spread) return;
            spread.unbind(_sheet.Events.TopPosChanged, this.onScroll);
            spread.unbind(_sheet.Events.LeftPosChagned, this.onScroll);
            spread.unbind(_sheet.Events.FCellHover, this.onHoverCellChanged);
            spread.unbind(Events.CellChanged, this.onCellChanged);
            spread.unbind(Events.EditEnded, this.onEditEnded);
            spread.unbind(Events.EditStarting, this.clearDropdownPop);
            spread.unbind(Events.ShowDropdown, this.clearDropdownPop);
        }
    }, {
        key: "locateDropdownPop",
        value: function locateDropdownPop(sheet, row, col) {
            if (!this.props.editable) return;
            if (!(0, _dropdownHelper.cellHasDropdown)(sheet, row, col)) {
                this.setState({ visible: false });
                return;
            }

            var _sheet$getCellRect = sheet.getCellRect(row, col),
                x = _sheet$getCellRect.x,
                y = _sheet$getCellRect.y,
                width = _sheet$getCellRect.width,
                height = _sheet$getCellRect.height;

            var offset = sheet.getCanvasOffset();
            var topOffset = y + height / 2 - 16;
            this.setState({
                visible: !sheet.getStyle(row, col).dropdown.isValid,
                x: offset.left + x + width + 6,
                y: offset.top + topOffset,
                currentRow: row,
                currentCol: col
            });
        }
    }, {
        key: "componentDidMount",
        value: function componentDidMount() {
            this.bindEvents(this.props.spread);
        }
    }, {
        key: "shouldComponentUpdate",
        value: function shouldComponentUpdate(nextProps, nextState) {
            if (this.state.visible === false && nextState.visible === false) return false;
            return true;
        }
    }, {
        key: "componentWillUnmount",
        value: function componentWillUnmount() {
            this.unbindEvents(this.props.spread);
        }
    }, {
        key: "render",
        value: function render() {
            return _react2.default.createElement("div", { className: prefixCls, style: {
                    display: this.state.visible ? 'flex' : 'none',
                    left: this.state.x,
                    top: this.state.y
                } }, _react2.default.createElement("div", { className: prefixCls + "_left" }, _react2.default.createElement(_error2.default, null)), _react2.default.createElement("div", { className: prefixCls + "_right" }, t('sheet.invalid_dropdown')));
        }
    }]);
    return DropdownPop;
}(_react.Component);

exports.default = DropdownPop;

__decorate([(0, _debounce.Debounce)(17)], DropdownPop.prototype, "locateDropdownPop", null);
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 3105:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "16", height: "16", viewBox: "0 0 16 16", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement(
      "g",
      { fill: "none", fillRule: "evenodd" },
      _react2.default.createElement("path", { d: "M8 16A8 8 0 1 1 8 0a8 8 0 0 1 0 16z", fill: "#EE5050", fillRule: "nonzero" }),
      _react2.default.createElement("path", { d: "M7 4l.48 6H8.5L9 4s.28-1-1-1-1 1-1 1z", fill: "#FFF" }),
      _react2.default.createElement("circle", { fill: "#FFF", cx: "8", cy: "12", r: "1" })
    )
  );
};

/***/ }),

/***/ 3106:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.HyperlinkEditor = undefined;

var _hyperlinkEditor = __webpack_require__(3107);

var _hyperlinkEditor2 = _interopRequireDefault(_hyperlinkEditor);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.HyperlinkEditor = _hyperlinkEditor2.default;

/***/ }),

/***/ 3107:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _redux = __webpack_require__(65);

var _reactRedux = __webpack_require__(238);

var _classnames = __webpack_require__(29);

var _classnames2 = _interopRequireDefault(_classnames);

var _string = __webpack_require__(158);

var _sheet = __webpack_require__(1597);

var _tea = __webpack_require__(47);

var _toolbarHelper = __webpack_require__(1606);

var _utils = __webpack_require__(1575);

var _segmentValue = __webpack_require__(1635);

var _segmentValue2 = _interopRequireDefault(_segmentValue);

var _sheet2 = __webpack_require__(715);

var _sheet_context = __webpack_require__(1578);

var _bytedSpark = __webpack_require__(1680);

var _positionHelper = __webpack_require__(2050);

var _i18nHelper = __webpack_require__(240);

__webpack_require__(3108);

var _sheet3 = __webpack_require__(713);

var _hyperlinkMiniEditor = __webpack_require__(3109);

var _hyperlinkMiniEditor2 = _interopRequireDefault(_hyperlinkMiniEditor);

var _linkHelper = __webpack_require__(388);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var Events = GC.Spread.Sheets.Events;
// const Range = GC.Spread.Sheets.Range;
var FocusHelper = GC.Spread.Sheets._FocusHelper;
var BOX_WIDTH = _i18nHelper.LANG_MAP.zh ? 342 : 410;
var BOX_HEIGHT = 104;
var Arrow = function Arrow(props) {
    var position = props.position,
        left = props.left;

    return _react2.default.createElement("div", { className: position === 'bottom' ? 'hyperlink-editor-arrow--bottom-array' : '' }, _react2.default.createElement("div", { className: "hyperlink-editor-arrow-border", style: {
            left: left
        } }), _react2.default.createElement("div", { className: "hyperlink-editor-arrow", style: {
            left: left
        } }));
};

var HyperlinkEditor = function (_React$Component) {
    (0, _inherits3.default)(HyperlinkEditor, _React$Component);

    function HyperlinkEditor() {
        (0, _classCallCheck3.default)(this, HyperlinkEditor);

        var _this = (0, _possibleConstructorReturn3.default)(this, (HyperlinkEditor.__proto__ || Object.getPrototypeOf(HyperlinkEditor)).apply(this, arguments));

        _this._enterMiniEditor = false;
        _this._isEmbed = _this.props.context.isEmbed();
        _this._embedSheetId = '';
        _this.state = {
            text: '',
            link: '',
            sheetId: '',
            miniEditor: null
        };
        _this.hideMiniEditor = function () {
            _this.setState({
                miniEditor: null
            });
            _this._enterMiniEditor = false;
        };
        _this.hideEditor = function () {
            if (_this.isLinkEditorShow()) {
                _this.props.hideHyperlinkEditor();
            }
            if (_this.isLinkMiniEditorShow()) {
                _this.hideMiniEditor();
            }
        };
        _this.handleCellChange = function (_ref) {
            var type = _ref.type,
                target = _ref.target,
                sheet = _ref.sheet;

            if (!_this.isLinkEditorShow()) {
                return;
            }
            var _this$props$hyperlink = _this.props.hyperlinkEditor,
                row = _this$props$hyperlink.row,
                col = _this$props$hyperlink.col;

            if (target.row != null && target.row <= row) {
                if (type === 'add') {
                    row += target.rowCount;
                }
                if (type === 'del') {
                    row -= target.rowCount;
                }
            }
            if (target.col != null && target.col <= col) {
                if (type === 'add') {
                    col += target.colCount;
                }
                if (type === 'del') {
                    col -= target.colCount;
                }
            }
            _this.props.showHyperlinkEditor(row, col, sheet.id(), _this.props.hyperlinkEditor.from);
        };
        _this.handleSpansChange = function (_ref2) {
            var spans = _ref2.spans,
                sheet = _ref2.sheet;

            if (!_this.isLinkEditorShow() || spans.length === 0) {
                return;
            }
            var _this$props$hyperlink2 = _this.props.hyperlinkEditor,
                row = _this$props$hyperlink2.row,
                col = _this$props$hyperlink2.col;

            var isIntersect = spans.some(function (span) {
                span = span.target;
                var rowInvolve = row >= span.row && row < span.row + span.rowCount;
                var colInvolve = col >= span.col && col < span.col + span.colCount;
                if (rowInvolve && colInvolve) {
                    return true;
                }
                return false;
            });
            if (isIntersect) {
                _this.hideEditor();
            }
        };
        _this.handleHyperlinkClick = function (type, event) {
            var seg = event.info.seg;
            if (!seg || seg.type() !== 'url') return;
            var spread = _this.props.spread;

            var sheet = spread.getActiveSheet();

            var _this$getHyperLinkInf = _this.getHyperLinkInfo(seg.seg),
                link = _this$getHyperLinkInf.link;

            if ((0, _utils.shouldOpenLink)(event.info.fEvent)) {
                !(0, _utils.openLink)(link) && sheet._raiseInvalidOperation(1, t('sheet.invalid_link'));
            }
        };
        _this.handleSegHoverChange = function (type, event) {
            var seg = event.info.seg;
            if (!seg || seg.type() !== 'url') {
                _this.handleHyperlinkLeave();
            } else {
                _this.handleHyperlinkEnter(type, event);
            }
        };
        _this.handleHyperlinkEnter = function (type, event) {
            var sheet = event.sheet,
                info = event.info;
            var row = info.row,
                col = info.col;

            if (_this.isLinkEditorShow()) {
                return;
            }
            var colViewportIndex = sheet._getRowViewportIndex(row);
            var rowViewportIndex = sheet._getColumnViewportIndex(col);
            _this.showMiniEditor(row, col, rowViewportIndex, colViewportIndex, info);
        };
        _this.handleHyperlinkLeave = function () {
            if (_this._enterMiniEditor) return;
            _this._hideEditorTimer = window.setTimeout(function () {
                clearTimeout(_this._showEditorTimer);
                _this.hideMiniEditor();
            }, 100);
        };
        _this.handleMiniEditorMouseEnter = function () {
            _this._enterMiniEditor = true;
            clearTimeout(_this._hideEditorTimer);
        };
        _this.handleMiniEditorMouseLeave = function () {
            _this._enterMiniEditor = false;
            _this.hideMiniEditor();
        };
        _this.getBindList = function () {
            return {
                spread: [{ key: _sheet3.Events.SegClick, handler: _this.handleHyperlinkClick }, { key: _sheet3.Events.SegHover, handler: _this.handleSegHoverChange }, { key: Events.ActiveSheetChanged, handler: _this.hideEditor }, { key: Events.CellClick, handler: _this.handleCellClick }, { key: Events.ShowDropdown, handler: _this.hideEditor }, { key: _sheet3.Events.LeftPosChagned, handler: _this.hideEditor }, { key: _sheet3.Events.TopPosChanged, handler: _this.hideEditor }],
                context: [{ key: _sheet_context.CollaborativeEvents.CELL_COORD_CHANGE, handler: _this.handleCellChange }, { key: _sheet_context.CollaborativeEvents.SPANS_CHANGE, handler: _this.handleSpansChange }]
            };
        };
        _this.clickOnSelf = function (dom) {
            var currentTarget = dom;
            while (currentTarget) {
                if (currentTarget.classList.contains('hyperlink-editor-container')) {
                    return true;
                } else {
                    currentTarget = currentTarget.parentElement;
                }
            }
            return false;
        };
        _this.bindWindowClick = function (event) {
            var sheet = _this.props.spread && _this.props.spread.getActiveSheet();
            var container = sheet && sheet._host;
            container = container && container.parentElement && container.parentElement.parentElement;
            if (!container || !event.target) return;
            if (!_this._isEmbed || event.fromSheetToolbar === true) return;
            if (!_this.clickOnSelf(event.srcElement)) {
                if (_this.isLinkEditorShow() || _this.isLinkMiniEditorShow()) {
                    _this.hideEditor();
                }
            }
        };
        _this.submit = function (row, col) {
            var spread = _this.props.spread;

            var value = _this.getNewHtsSegLink(row, col);
            (0, _toolbarHelper.setHyperlink)(spread, {
                row: row,
                col: col,
                newValue: value
            });
            _this.hideEditor();
            (0, _tea.collectSuiteEvent)('click_sheet_url_edit_confirm');
        };
        _this.handleTextChange = function (event) {
            _this.setState({
                text: event.target.value
            });
        };
        _this.handleLinkChange = function (event) {
            _this.setState({
                link: event.target.value
            });
        };
        _this.collectInfoFromMiniEditor = function (text, link, hyperlinkEditorParams) {
            _this.hideMiniEditor();
            _this.setState({ text: text, link: link });
            var row = hyperlinkEditorParams.row,
                col = hyperlinkEditorParams.col,
                sheetId = hyperlinkEditorParams.sheetId,
                from = hyperlinkEditorParams.from;

            _this.props.showHyperlinkEditor(row, col, sheetId, from);
        };
        _this.handleKeyDown = function (event, row, col) {
            if (event.keyCode === 13) {
                _this.submit(row, col);
            }
        };
        _this.handleCellClick = function (e, params) {
            var targetRow = params.row,
                targetCol = params.col;
            var miniEditor = _this.state.miniEditor;
            var _this$props = _this.props,
                hyperlinkEditor = _this$props.hyperlinkEditor,
                spread = _this$props.spread;

            if (miniEditor) {
                var row = miniEditor.row,
                    col = miniEditor.col;

                if (targetRow !== row || targetCol !== col) {
                    _this.hideEditor();
                }
            }
            if (hyperlinkEditor) {
                var _row = hyperlinkEditor.row,
                    _col = hyperlinkEditor.col;

                if (targetRow !== _row || targetCol !== _col) {
                    _this.hideEditor();
                }
            }
            if (_this._isEmbed) {
                // doc插sheet内，多个sheet之间切换，this.state.sheetId会为空
                _this._embedSheetId = spread.getActiveSheet().id();
            }
        };
        _this.isLinkEditorShow = function () {
            var _this$props2 = _this.props,
                hyperlinkEditor = _this$props2.hyperlinkEditor,
                editable = _this$props2.editable;

            return editable && hyperlinkEditor && (hyperlinkEditor.sheetId === _this.state.sheetId || hyperlinkEditor.sheetId === _this._embedSheetId);
        };
        _this.isLinkMiniEditorShow = function () {
            var miniEditor = _this.state.miniEditor;

            return !!miniEditor;
        };
        return _this;
    }

    (0, _createClass3.default)(HyperlinkEditor, [{
        key: 'showMiniEditor',
        value: function showMiniEditor(row, col, rowViewportIndex, colViewportIndex, info) {
            var _this2 = this;

            clearTimeout(this._showEditorTimer);
            clearTimeout(this._hideEditorTimer);
            this._showEditorTimer = window.setTimeout(function () {
                _this2.setState({
                    info: info,
                    miniEditor: {
                        row: row,
                        col: col,
                        rowViewportIndex: rowViewportIndex,
                        colViewportIndex: colViewportIndex,
                        info: info
                    }
                });
            }, 500);
        }
    }, {
        key: 'getHyperLinkInfo',
        value: function getHyperLinkInfo(seg) {
            if (!seg) {
                return {
                    text: '',
                    link: ''
                };
            }
            /**
             * 在 seg 中， text 是用来渲染的字段，在纯链接的情况下，不存在 link 字段，text 就是链接
             * 在带文本的链接情况下，text 就是渲染的文本，link 才是真实链接
             */
            var link = seg.link,
                text = seg.text;

            var realLink = link ? link : text;
            var realText = link ? text : '';
            return {
                text: realText,
                link: realLink
            };
        }
    }, {
        key: 'bindEvents',
        value: function bindEvents(spread) {
            var _this3 = this;

            if (!spread) return;
            var bindList = this.getBindList();
            window.addEventListener('click', this.bindWindowClick);
            bindList.spread.forEach(function (event) {
                spread.bind(event.key, event.handler);
            });
            bindList.context.forEach(function (event) {
                _this3.props.context.bind(event.key, event.handler);
            });
        }
    }, {
        key: 'unbindEvents',
        value: function unbindEvents(spread) {
            var _this4 = this;

            if (!spread) return;
            this.getBindList().spread.map(function (event) {
                spread.unbind(event.key, event.handler);
            });
            this.getBindList().context.map(function (event) {
                _this4.props.context.unbind(event.key, event.handler);
            });
            window.removeEventListener('click', this.bindWindowClick);
        }
    }, {
        key: 'componentWillReceiveProps',
        value: function componentWillReceiveProps(nextProps) {
            if (this.props.spread !== nextProps.spread) {
                this.unbindEvents(this.props.spread);
                this.bindEvents(nextProps.spread);
            }
            if (nextProps.hyperlinkEditor && this.props.hyperlinkEditor !== nextProps.hyperlinkEditor) {
                var sheetId = nextProps.spread.getActiveSheet().id();
                if (nextProps.hyperlinkEditor.from === 'cell') {
                    var sheet = nextProps.spread.getActiveSheet();
                    var row = sheet.getActiveRowIndex();
                    var col = sheet.getActiveColumnIndex();

                    var _getHpyerlinkInfoByCe = this.getHpyerlinkInfoByCell(row, col),
                        text = _getHpyerlinkInfoByCe.text,
                        link = _getHpyerlinkInfoByCe.link;

                    this.setState({
                        sheetId: sheetId,
                        text: text,
                        link: link
                    });
                } else {
                    this.setState({
                        sheetId: sheetId
                    });
                }
            }
        }
    }, {
        key: 'componentDidUpdate',
        value: function componentDidUpdate(prevProps) {
            var _this5 = this;

            if (prevProps.hyperlinkEditor !== this.props.hyperlinkEditor) {
                if (this.defaultFocusInput) {
                    setTimeout(function () {
                        return _this5.defaultFocusInput && _this5.defaultFocusInput.focus();
                    }, 0);
                    FocusHelper._setActiveElement(null, true);
                }
            }
        }
    }, {
        key: 'componentDidMount',
        value: function componentDidMount() {
            this.bindEvents(this.props.spread);
            if (this.defaultFocusInput) {
                this.defaultFocusInput.focus();
                FocusHelper._setActiveElement(null, true);
            }
        }
    }, {
        key: 'componentWillUnmount',
        value: function componentWillUnmount() {
            this.unbindEvents(this.props.spread);
        }
    }, {
        key: 'getNewHtsSegLink',
        value: function getNewHtsSegLink(row, col) {
            var _state = this.state,
                text = _state.text,
                link = _state.link;
            // a标签不支持 data url

            if ((0, _linkHelper.isDataURL)(link)) {
                link = '';
            }
            if (!text) {
                text = link;
            }
            if (link && !(0, _string.hasUrlProtocol)(link)) {
                link = (0, _linkHelper.completeURLProtocol)(link);
            }
            var from = this.props.hyperlinkEditor.from;
            var sheet = this.props.spread.getActiveSheet();
            var segmentArray = sheet.getSegmentArray(row, col);
            if (Array.isArray(segmentArray) && from === 'seg') {
                var info = this.state.info;
                var iseg = info && info.seg && info.seg.seg;
                var newSegmentArray = segmentArray.map(function (seg) {
                    if (seg === iseg) {
                        if (!link) {
                            return {
                                type: 'text',
                                text: text
                            };
                        }
                        return Object.assign({}, seg, {
                            text: text,
                            link: link
                        });
                    }
                    return seg;
                });
                return newSegmentArray;
            }
            if (!link) {
                return text;
            }
            return [{
                type: 'url',
                text: text,
                link: link
            }];
        }
    }, {
        key: 'getHpyerlinkInfoByCell',
        value: function getHpyerlinkInfoByCell(row, col) {
            var sheet = this.props.spread.getActiveSheet();
            if (sheet.isEditing()) {
                sheet.endEdit();
            }
            var segmentArray = sheet.getSegmentArray(row, col);
            var text = sheet.getText(row, col);
            if (Array.isArray(segmentArray)) {
                var segmentValue = new _segmentValue2.default(segmentArray);
                var urlSeg = segmentArray.find(function (seg) {
                    return seg.type === 'url';
                });
                var _text = segmentValue.getText();
                var link = '';
                if (urlSeg) {
                    link = urlSeg.link || urlSeg.text || '';
                    var realLink = link ? link : _text;
                    var realText = link ? _text : '';
                    return {
                        text: realText,
                        link: realLink
                    };
                }
                return {
                    text: _text,
                    link: ''
                };
            }
            return {
                text: segmentArray || text || '',
                link: ''
            };
        }
    }, {
        key: 'linkMiniEditor',
        value: function linkMiniEditor() {
            var _this6 = this;

            if (!this.state.miniEditor) {
                return null;
            }
            var info = this.state.info;
            var _props = this.props,
                spread = _props.spread,
                editable = _props.editable,
                embed = _props.embed;
            var _state$miniEditor = this.state.miniEditor,
                row = _state$miniEditor.row,
                col = _state$miniEditor.col;

            if (!editable) return null;
            return _react2.default.createElement(_hyperlinkMiniEditor2.default, { handleMiniEditorMouseEnter: this.handleMiniEditorMouseEnter, handleMiniEditorMouseLeave: this.handleMiniEditorMouseLeave, collectInfoFromMiniEditor: this.collectInfoFromMiniEditor, hideMiniEditor: this.hideMiniEditor, getHyperLinkInfo: this.getHyperLinkInfo, Arrow: Arrow, info: info, row: row, col: col, spread: spread, ref: function ref(ele) {
                    return _this6.editorDom = ele;
                }, embed: embed, getCanvasBoundingRect: this.props.getCanvasBoundingRect });
        }
    }, {
        key: 'linkEditor',
        value: function linkEditor() {
            var _this7 = this;

            var _props2 = this.props,
                spread = _props2.spread,
                embed = _props2.embed;
            var _props$hyperlinkEdito = this.props.hyperlinkEditor,
                row = _props$hyperlinkEdito.row,
                col = _props$hyperlinkEdito.col,
                from = _props$hyperlinkEdito.from;

            var info = this.state.info;
            var sheet = spread.getActiveSheet();
            var offset = sheet.getCanvasOffset();
            var sheetComponentName = 'sheet_hyperlink_editor';
            var rect = from === 'cell' ? sheet.getCellRect(row, col) : info.rect;
            rect.x += offset.left;
            rect.y += offset.top;
            var boundingRect = this.props.getCanvasBoundingRect();

            var _getLinkBoxPosition = (0, _positionHelper.getLinkBoxPosition)(boundingRect, rect, {
                width: BOX_WIDTH,
                height: BOX_HEIGHT
            }, false, embed),
                top = _getLinkBoxPosition.top,
                left = _getLinkBoxPosition.left;

            var languageStyle = _i18nHelper.LANG_MAP.zh ? 'hyperlink-editor__input-block__zh' : 'hyperlink-editor__input-block__en';
            return _react2.default.createElement("div", { className: "hyperlink-editor-container", style: {
                    top: top,
                    left: left
                }, "data-sheet-component": sheetComponentName }, _react2.default.createElement("table", { className: "hyperlink-editor multi-line" }, _react2.default.createElement("tbody", null, _react2.default.createElement("tr", { className: (0, _classnames2.default)('hyperlink-editor__input-block', languageStyle) }, _react2.default.createElement("td", null, _react2.default.createElement("span", null, t('sheet.text'), ":")), _react2.default.createElement("td", null, _react2.default.createElement("input", { className: "hyperlink-editor__text-input", type: "text", placeholder: t('sheet.enter_text'), value: this.state.text, onChange: this.handleTextChange, onKeyDown: function onKeyDown(event) {
                    return _this7.handleKeyDown(event, row, col);
                } }))), _react2.default.createElement("tr", { className: (0, _classnames2.default)('hyperlink-editor__input-block', languageStyle) }, _react2.default.createElement("td", null, _react2.default.createElement("span", null, t('common.link'), ":")), _react2.default.createElement("td", null, _react2.default.createElement("input", { className: "hyperlink-editor__text-input", type: "text", placeholder: t('sheet.input_link'), value: this.state.link, onChange: this.handleLinkChange, onKeyDown: function onKeyDown(event) {
                    return _this7.handleKeyDown(event, row, col);
                }, ref: function ref(ele) {
                    return _this7.defaultFocusInput = ele;
                } })), _react2.default.createElement("td", null, _react2.default.createElement(_bytedSpark.Button, { type: "primary", onClick: function onClick() {
                    return _this7.submit(row, col);
                } }, t('common.determine')))))));
        }
    }, {
        key: 'render',
        value: function render() {
            var editor = null;
            // 处理 doc 插 sheet 多实例存在的情况
            if (this.isLinkEditorShow()) {
                editor = this.linkEditor();
            }
            if (this.isLinkMiniEditorShow()) {
                editor = this.linkMiniEditor();
            }
            return editor;
        }
    }]);
    return HyperlinkEditor;
}(_react2.default.Component);

exports.default = (0, _reactRedux.connect)(function (state, props) {
    return {
        hyperlinkEditor: (0, _sheet.hyperlinkEditorSelector)(state),
        editable: (0, _sheet.editableSelector)(state)
    };
}, function (dispatch) {
    return (0, _redux.bindActionCreators)({
        showHyperlinkEditor: _sheet2.showHyperlinkEditor,
        hideHyperlinkEditor: _sheet2.hideHyperlinkEditor
    }, dispatch);
})(HyperlinkEditor);
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 3108:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3109:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.default = undefined;

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _positionHelper = __webpack_require__(2050);

var _miniEditorOperation = __webpack_require__(3110);

var _miniEditorOperation2 = _interopRequireDefault(_miniEditorOperation);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var HyperlinkMiniEditor = function (_Component) {
    (0, _inherits3.default)(HyperlinkMiniEditor, _Component);

    function HyperlinkMiniEditor(props) {
        (0, _classCallCheck3.default)(this, HyperlinkMiniEditor);

        var _this = (0, _possibleConstructorReturn3.default)(this, (HyperlinkMiniEditor.__proto__ || Object.getPrototypeOf(HyperlinkMiniEditor)).call(this, props));

        _this.BOX_MINI_WIDTH = 300;
        _this.BOX_MINI_HEIGHT = 40;
        _this.submitMiniEditor = function (row, col) {
            var _this$props = _this.props,
                spread = _this$props.spread,
                info = _this$props.info,
                collectInfoFromMiniEditor = _this$props.collectInfoFromMiniEditor,
                hideMiniEditor = _this$props.hideMiniEditor,
                getHyperLinkInfo = _this$props.getHyperLinkInfo;

            hideMiniEditor();
            var sheet = spread.getActiveSheet();

            var _getHyperLinkInfo = getHyperLinkInfo(info.seg.seg),
                link = _getHyperLinkInfo.link,
                text = _getHyperLinkInfo.text;

            var hyperlinkEditorParams = {
                row: row,
                col: col,
                sheetId: sheet.id(),
                from: 'seg'
            };
            collectInfoFromMiniEditor(text, link, hyperlinkEditorParams);
        };
        return _this;
    }

    (0, _createClass3.default)(HyperlinkMiniEditor, [{
        key: 'componentDidMount',
        value: function componentDidMount() {
            var ignoreRepaintSelection = true;
            this.props.spread.focus(false, ignoreRepaintSelection);
        }
    }, {
        key: 'render',
        value: function render() {
            var _props = this.props,
                handleMiniEditorMouseEnter = _props.handleMiniEditorMouseEnter,
                handleMiniEditorMouseLeave = _props.handleMiniEditorMouseLeave,
                info = _props.info,
                spread = _props.spread,
                row = _props.row,
                col = _props.col,
                hideMiniEditor = _props.hideMiniEditor,
                getHyperLinkInfo = _props.getHyperLinkInfo,
                embed = _props.embed;

            var _getHyperLinkInfo2 = getHyperLinkInfo(info.seg.seg),
                link = _getHyperLinkInfo2.link;

            var sheet = spread.getActiveSheet();
            var offset = sheet.getCanvasOffset();
            var sheetComponentName = 'sheet_hyperlink_minieditor';
            // 补上 doc 插 sheet 是去焦点的时候，行头列头变化产生的 offset
            var rect = info.rect.move(offset.left, offset.top);

            var _getLinkBoxPosition = (0, _positionHelper.getLinkBoxPosition)(this.props.getCanvasBoundingRect(), rect, {
                width: this.BOX_MINI_WIDTH,
                height: this.BOX_MINI_HEIGHT
            }, true, embed),
                top = _getLinkBoxPosition.top,
                left = _getLinkBoxPosition.left;

            return _react2.default.createElement("div", { className: "hyperlink-editor-container", onMouseEnter: handleMiniEditorMouseEnter, onMouseLeave: handleMiniEditorMouseLeave, style: {
                    top: top,
                    left: left,
                    minWidth: this.BOX_MINI_WIDTH + 'px',
                    minHeight: this.BOX_MINI_HEIGHT + 'px'
                }, "data-sheet-component": sheetComponentName }, _react2.default.createElement("div", { className: "hyperlink-editor hyperlink-editor--mini" }, _react2.default.createElement("div", { className: "hyperlink-editor__input-Mini" }, _react2.default.createElement("div", { className: "hyperlink-editor__text-display" }, _react2.default.createElement("span", null, link)), _react2.default.createElement(_miniEditorOperation2.default, { spread: spread, info: info, row: row, col: col, hideMiniEditor: hideMiniEditor, submitMiniEditor: this.submitMiniEditor }))));
        }
    }]);
    return HyperlinkMiniEditor;
}(_react.Component);

exports.default = HyperlinkMiniEditor;

/***/ }),

/***/ 3110:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.default = undefined;

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _tooltip = __webpack_require__(1818);

var _tooltip2 = _interopRequireDefault(_tooltip);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _linkcancel = __webpack_require__(3113);

var _linkcancel2 = _interopRequireDefault(_linkcancel);

var _linkedit = __webpack_require__(3114);

var _linkedit2 = _interopRequireDefault(_linkedit);

var _toolbarHelper = __webpack_require__(1606);

var _tea = __webpack_require__(47);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var ATooltip = _tooltip2.default;

var MiniEditorOperation = function (_Component) {
    (0, _inherits3.default)(MiniEditorOperation, _Component);

    function MiniEditorOperation(props) {
        (0, _classCallCheck3.default)(this, MiniEditorOperation);

        var _this = (0, _possibleConstructorReturn3.default)(this, (MiniEditorOperation.__proto__ || Object.getPrototypeOf(MiniEditorOperation)).call(this, props));

        _this.clearHyperlink = function (row, col) {
            var _this$props = _this.props,
                spread = _this$props.spread,
                info = _this$props.info,
                hideMiniEditor = _this$props.hideMiniEditor;

            var sheet = spread.getActiveSheet();
            var segment = info && info.seg && info.seg.seg;
            var segmentArray = sheet.getSegmentArray(row, col);
            var text = sheet.getText(row, col);
            var value = segmentArray || text;
            if (Array.isArray(value)) {
                if (value.length === 1) {
                    value = value[0].text;
                } else {
                    value = value.map(function (seg) {
                        if (seg === segment) {
                            return {
                                type: 'text',
                                text: seg.text
                            };
                        }
                        return seg;
                    });
                }
            }
            (0, _toolbarHelper.setHyperlink)(spread, {
                row: row,
                col: col,
                newValue: value
            });
            hideMiniEditor();
            (0, _tea.collectSuiteEvent)('click_sheet_url_delete');
        };
        _this.onSubmit = function (e, row, col) {
            e.stopPropagation();
            var submitMiniEditor = _this.props.submitMiniEditor;

            submitMiniEditor(row, col);
            (0, _tea.collectSuiteEvent)('click_sheet_url_edit');
        };
        return _this;
    }

    (0, _createClass3.default)(MiniEditorOperation, [{
        key: 'render',
        value: function render() {
            var _this2 = this;

            var _props = this.props,
                row = _props.row,
                col = _props.col;

            var cancelLink = _react2.default.createElement("button", { onClick: function onClick() {
                    return _this2.clearHyperlink(row, col);
                } }, _react2.default.createElement(_linkcancel2.default, null));
            var editLink = _react2.default.createElement("button", { onClick: function onClick(e) {
                    return _this2.onSubmit(e, row, col);
                } }, _react2.default.createElement(_linkedit2.default, null));
            return _react2.default.createElement("div", { className: "hyperlink-editor--mini__handler" }, _react2.default.createElement(ATooltip, { prefixCls: "cp-tooltip", placement: "top", title: t('sheet.edit_hyperlink'), trigger: "hover" }, editLink), _react2.default.createElement(ATooltip, { prefixCls: "cp-tooltip", placement: "top", title: t('sheet.cancel_hyperlink'), trigger: "hover" }, cancelLink));
        }
    }]);
    return MiniEditorOperation;
}(_react.Component);

exports.default = MiniEditorOperation;
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 3111:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

exports.getOverflowOptions = getOverflowOptions;
exports['default'] = getPlacements;

var _placements = __webpack_require__(3112);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

var autoAdjustOverflowEnabled = {
    adjustX: 1,
    adjustY: 1
};
var autoAdjustOverflowDisabled = {
    adjustX: 0,
    adjustY: 0
};
var targetOffset = [0, 0];
function getOverflowOptions(autoAdjustOverflow) {
    if (typeof autoAdjustOverflow === 'boolean') {
        return autoAdjustOverflow ? autoAdjustOverflowEnabled : autoAdjustOverflowDisabled;
    }
    return (0, _extends3['default'])({}, autoAdjustOverflowDisabled, autoAdjustOverflow);
}
function getPlacements() {
    var config = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};
    var _config$arrowWidth = config.arrowWidth,
        arrowWidth = _config$arrowWidth === undefined ? 5 : _config$arrowWidth,
        _config$horizontalArr = config.horizontalArrowShift,
        horizontalArrowShift = _config$horizontalArr === undefined ? 16 : _config$horizontalArr,
        _config$verticalArrow = config.verticalArrowShift,
        verticalArrowShift = _config$verticalArrow === undefined ? 12 : _config$verticalArrow,
        _config$autoAdjustOve = config.autoAdjustOverflow,
        autoAdjustOverflow = _config$autoAdjustOve === undefined ? true : _config$autoAdjustOve;

    var placementMap = {
        left: {
            points: ['cr', 'cl'],
            offset: [-4, 0]
        },
        right: {
            points: ['cl', 'cr'],
            offset: [4, 0]
        },
        top: {
            points: ['bc', 'tc'],
            offset: [0, -4]
        },
        bottom: {
            points: ['tc', 'bc'],
            offset: [0, 4]
        },
        topLeft: {
            points: ['bl', 'tc'],
            offset: [-(horizontalArrowShift + arrowWidth), -4]
        },
        leftTop: {
            points: ['tr', 'cl'],
            offset: [-4, -(verticalArrowShift + arrowWidth)]
        },
        topRight: {
            points: ['br', 'tc'],
            offset: [horizontalArrowShift + arrowWidth, -4]
        },
        rightTop: {
            points: ['tl', 'cr'],
            offset: [4, -(verticalArrowShift + arrowWidth)]
        },
        bottomRight: {
            points: ['tr', 'bc'],
            offset: [horizontalArrowShift + arrowWidth, 4]
        },
        rightBottom: {
            points: ['bl', 'cr'],
            offset: [4, verticalArrowShift + arrowWidth]
        },
        bottomLeft: {
            points: ['tl', 'bc'],
            offset: [-(horizontalArrowShift + arrowWidth), 4]
        },
        leftBottom: {
            points: ['br', 'cl'],
            offset: [-4, verticalArrowShift + arrowWidth]
        }
    };
    Object.keys(placementMap).forEach(function (key) {
        placementMap[key] = config.arrowPointAtCenter ? (0, _extends3['default'])({}, placementMap[key], { overflow: getOverflowOptions(autoAdjustOverflow), targetOffset: targetOffset }) : (0, _extends3['default'])({}, _placements.placements[key], { overflow: getOverflowOptions(autoAdjustOverflow) });
    });
    return placementMap;
}

/***/ }),

/***/ 3112:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


exports.__esModule = true;
var autoAdjustOverflow = {
  adjustX: 1,
  adjustY: 1
};

var targetOffset = [0, 0];

var placements = exports.placements = {
  left: {
    points: ['cr', 'cl'],
    overflow: autoAdjustOverflow,
    offset: [-4, 0],
    targetOffset: targetOffset
  },
  right: {
    points: ['cl', 'cr'],
    overflow: autoAdjustOverflow,
    offset: [4, 0],
    targetOffset: targetOffset
  },
  top: {
    points: ['bc', 'tc'],
    overflow: autoAdjustOverflow,
    offset: [0, -4],
    targetOffset: targetOffset
  },
  bottom: {
    points: ['tc', 'bc'],
    overflow: autoAdjustOverflow,
    offset: [0, 4],
    targetOffset: targetOffset
  },
  topLeft: {
    points: ['bl', 'tl'],
    overflow: autoAdjustOverflow,
    offset: [0, -4],
    targetOffset: targetOffset
  },
  leftTop: {
    points: ['tr', 'tl'],
    overflow: autoAdjustOverflow,
    offset: [-4, 0],
    targetOffset: targetOffset
  },
  topRight: {
    points: ['br', 'tr'],
    overflow: autoAdjustOverflow,
    offset: [0, -4],
    targetOffset: targetOffset
  },
  rightTop: {
    points: ['tl', 'tr'],
    overflow: autoAdjustOverflow,
    offset: [4, 0],
    targetOffset: targetOffset
  },
  bottomRight: {
    points: ['tr', 'br'],
    overflow: autoAdjustOverflow,
    offset: [0, 4],
    targetOffset: targetOffset
  },
  rightBottom: {
    points: ['bl', 'br'],
    overflow: autoAdjustOverflow,
    offset: [4, 0],
    targetOffset: targetOffset
  },
  bottomLeft: {
    points: ['tl', 'bl'],
    overflow: autoAdjustOverflow,
    offset: [0, 4],
    targetOffset: targetOffset
  },
  leftBottom: {
    points: ['br', 'bl'],
    overflow: autoAdjustOverflow,
    offset: [-4, 0],
    targetOffset: targetOffset
  }
};

exports['default'] = placements;

/***/ }),

/***/ 3113:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M16.5 7H19a1 1 0 0 1 0 2h-1v8.95c0 1.13-1 2.05-2.25 2.05h-7.5C7.01 20 6 19.08 6 17.95V9H5a1 1 0 1 1 0-2h11.5zM16 9H8v8.79c0 .03.17.21.5.21h7c.33 0 .5-.18.5-.21V9zM9 4h6a1 1 0 0 1 0 2H9a1 1 0 1 1 0-2zm1.25 7c.41 0 .75.34.75.75v3.5a.75.75 0 1 1-1.5 0v-3.5c0-.41.34-.75.75-.75zm3.5 0c.41 0 .75.34.75.75v3.5a.75.75 0 1 1-1.5 0v-3.5c0-.41.34-.75.75-.75z", fill: "#424E5D", fillRule: "nonzero" })
  );
};

/***/ }),

/***/ 3114:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M8.87 18.98h9.43a1 1 0 1 1 0 2H4.77a1 1 0 0 1-.88-.54 1.5 1.5 0 0 1-.75-1.88l1.33-3.45c.07-.2.19-.38.34-.52L15.34 4.05a1.5 1.5 0 0 1 2.12 0l2.12 2.13a1.5 1.5 0 0 1 0 2.12L9.05 18.83l-.18.15zm4-9.62L6.3 15.92l-.89 2.3 2.3-.88 6.57-6.57-1.42-1.41zm1.4-1.42l1.42 1.42 2.12-2.12-1.41-1.42-2.12 2.12z", fill: "#424E5D", fillRule: "nonzero" })
  );
};

/***/ }),

/***/ 3115:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.ImageUploader = undefined;

var _imageUploader = __webpack_require__(3116);

var _imageUploader2 = _interopRequireDefault(_imageUploader);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.ImageUploader = _imageUploader2.default;

/***/ }),

/***/ 3116:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _get2 = __webpack_require__(182);

var _get3 = _interopRequireDefault(_get2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _uploader = __webpack_require__(3117);

var _uploader2 = _interopRequireDefault(_uploader);

var _toolbarHelper = __webpack_require__(1606);

var _sheet = __webpack_require__(713);

var _sheet_context = __webpack_require__(1578);

var _shellNotify = __webpack_require__(1576);

__webpack_require__(3118);

var _toast = __webpack_require__(500);

var _toast2 = _interopRequireDefault(_toast);

var _util = __webpack_require__(3119);

__webpack_require__(3120);

var _tea = __webpack_require__(47);

var _browserHelper = __webpack_require__(34);

var _browserHelper2 = _interopRequireDefault(_browserHelper);

var _viewer = __webpack_require__(1816);

var _common = __webpack_require__(19);

var _routeHelper = __webpack_require__(57);

var _suiteHelper = __webpack_require__(60);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var SHEET_OPRATION = 'sheet_opration'; /**
                                        * sheet图片插入功能
                                        * 技术文档：https://docs.bytedance.net/doc/HU0zbTsm0C1R4em2RuJrnf
                                        * 需求文档：https://docs.bytedance.net/doc/pOMQV5K4fVSgp0HekoCwOc
                                        */

var markProperty = 'embed-image-uploading';
var FILE_SIZE = 1024 * 1024 * 20; // 图片上传大小限制
var pcImageViewer = void 0;

var ImageUploader = function (_React$Component) {
    (0, _inherits3.default)(ImageUploader, _React$Component);

    function ImageUploader(props) {
        (0, _classCallCheck3.default)(this, ImageUploader);

        // 维护一个插入图片的对象，其属性值为file.id
        var _this = (0, _possibleConstructorReturn3.default)(this, (ImageUploader.__proto__ || Object.getPrototypeOf(ImageUploader)).call(this, props));

        _this.insertImgsObj = {};
        _this.bIsUploadingImage = false;
        // 用来存储点击图片后的行列位置
        _this.tempCol = null;
        _this.tempRow = null;
        _this.getBindList = function () {
            return {
                spread: [{ key: _sheet.Events.ShowImageUploader, handler: _this.handleShowImageUploader }, { key: _sheet.Events.OpenImgFullScreen, handler: _this.handleShowImageFullScreen }, { key: _sheet.Events.StartPaste, handler: _this.fnRecordCurrentPos }],
                context: [{ key: _sheet_context.CollaborativeEvents.CELL_COORD_CHANGE, handler: _this.handleCellCoordChange }, { key: _sheet_context.CollaborativeEvents.DELETE_CELL, handler: _this.handleDeleteCell }, { key: _sheet_context.CollaborativeEvents.SPANS_CHANGE, handler: _this.handleSpansChange }]
            };
        };
        // 图片全屏点击事件
        _this.handleShowImageFullScreen = function (type, imgInfo) {
            var openLarkImageViewer = (0, _get3.default)(window, 'lark_to_bear_bridge.openImgViewer');
            if (_browserHelper2.default.isLark && openLarkImageViewer) {
                var images = [{
                    key: 0,
                    url: imgInfo.link
                }];
                openLarkImageViewer({ images: images });
            } else {
                var img = document.createElement('img');
                img.setAttribute('data-src', imgInfo.link);
                pcImageViewer = (0, _viewer.createViewer)(img, {
                    container: '#editorcontainerbox',
                    hidden: function hidden() {
                        pcImageViewer.destroy();
                        pcImageViewer = null;
                    }
                }, _viewer.MODULE_TYPE.SHEET);
                pcImageViewer.show();
            }
            // 打点
            (0, _tea.collectSuiteEvent)(SHEET_OPRATION, {
                action: 'embed_img_fullscreen',
                source: 'body',
                eventType: 'click'
            });
        };
        // ===== webuploader event handle ==== //
        _this.initUploader = function () {
            _this.uploader = new _uploader2.default('<div style="width:0;overflow:hidden;" id="uploader0"></div>');
            _this.uploaderInstance = _this.uploader.createUploader();
            var events = ['beforeFileQueued', 'uploadStart', 'uploadProgress', 'uploadSuccess', 'uploadError', 'filesQueued', 'uploadBeforeSend'];
            events.forEach(function (evtName) {
                _this.uploaderInstance.on(evtName, _this[evtName]);
            });
        };
        _this.beforeFileQueued = function (file) {
            if (file.size > FILE_SIZE) {
                _toast2.default.show({
                    type: 'error',
                    closable: true,
                    content: '\u300C' + (0, _util.fileNameCut)(file.name) + '\u300D' + t('sheet.image_size_limit')
                });
                return false;
            }
            return true;
        };
        _this.uploadStart = function (file) {
            var activeSheet = _this.props.spread.getActiveSheet();
            if (!activeSheet || !activeSheet.id() === undefined) return;
            var sheetId = _this.props.spread.getActiveSheet().id();
            var sheet = _this.props.spread.getSheetFromId(sheetId);
            _this.bIsUploadingImage = true;
            console.log('上传前图片id ' + file.id);
            var col = sheet.getActiveColumnIndex();
            var row = sheet.getActiveRowIndex();
            // 通过点击图标上传，有光标移动过快的问题
            if (_this.tempCol !== null && _this.tempRow !== null) {
                col = _this.tempCol;
                row = _this.tempRow;
                _this.tempCol = null;
                _this.tempRow = null;
            }
            // 以file.id为key保存当前的图片插入信息
            _this.insertImgsObj[file.id] = {
                row: row,
                col: col,
                sheetId: sheetId
            };
            // 通知cell绘制loading
            sheet.notifyShell(_shellNotify.ShellNotifyType.BindImageLoading, {
                imageId: file.id,
                row: row, col: col,
                percentage: 0,
                isCellChange: true
            });
            var model = sheet._getModel();
            model.setValueForKey(row, col, markProperty, true);
            var token = (0, _suiteHelper.getToken)();
            // 如果是doc内的sheet上传图片，要去取sheet的token.
            if ((0, _routeHelper.locateRoute)().isDoc) {
                token = _this.props.context && _this.props.context.token;
            }
            _this.uploaderInstance.option('formData', { token: token,
                obj_type: _common.NUM_SUITE_TYPE.SHEET });
        };
        _this.uploadProgress = function (file, percentage) {
            console.log(percentage);
            var insertImgInfo = _this.insertImgsObj[file.id];
            var row = insertImgInfo.row,
                col = insertImgInfo.col,
                sheetId = insertImgInfo.sheetId;

            var sheet = _this.props.spread.getSheetFromId(sheetId);
            _this.insertImgsObj[file.id].percentage = percentage;
            var isCellDelete = false;
            // 结束情况2：终止上传，移除图片，清除loading状态
            if (_this.insertImgsObj[file.id].isCellDelete) {
                isCellDelete = true;
                _this.uploaderInstance.cancelFile(file);
                delete _this.insertImgsObj[file.id];
                _this.closeUploadingImage();
            }
            sheet.notifyShell(_shellNotify.ShellNotifyType.BindImageLoading, {
                imageId: file.id,
                row: row,
                col: col,
                percentage: percentage,
                isCellChange: false,
                isCellDelete: isCellDelete
            });
        };
        _this.uploadSuccess = function (file, response) {
            var insertImgInfo = _this.insertImgsObj[file.id];
            // 上传后获得最新的行列位置，查看该单元格的标记变量是否还在
            var row = insertImgInfo.row,
                col = insertImgInfo.col,
                sheetId = insertImgInfo.sheetId;
            var spread = _this.props.spread;

            var sheet = _this.props.spread.getSheetFromId(sheetId);
            var model = sheet._getModel();
            if (response && response.data && response.data.url) {
                var imgUrl = response.data.url;
                _this.getImageWidthAndRow(imgUrl).then(function (_ref) {
                    var imgWidth = _ref.imgWidth,
                        imgHeight = _ref.imgHeight;

                    var value = [{
                        type: 'embed-image',
                        text: '',
                        link: response.data.url,
                        width: imgWidth,
                        height: imgHeight
                    }];
                    // 找到标记的地方
                    if (model.dataTable[row][col] && model.dataTable[row][col][markProperty]) {
                        delete model.dataTable[row][col][markProperty];
                        (0, _toolbarHelper.setCellInnerImage)(spread, sheetId, {
                            row: row,
                            col: col,
                            newValue: value
                        });
                    }
                });
                // 上传出错 -- 删除变量
            } else {
                if (model.dataTable[row][col] && model.dataTable[row][col][markProperty]) {
                    delete model.dataTable[row][col][markProperty];
                }
                _this.teaImageUploaderFail('upload_fail');
            }
            // 结束情况1：上传成功，移除图片，清除loading状态
            delete _this.insertImgsObj[file.id];
            _this.closeUploadingImage();
            _this.uploaderInstance.removeFile(file);
        };
        _this.uploadError = function (file) {
            // 如果是最后一个上传图片了。设置正在上传为false
            _this.closeUploadingImage();
            _this.uploaderInstance.removeFile(file);
            _this.teaImageUploaderFail('upload_fail');
        };
        _this.closeUploadingImage = function () {
            if (Object.getOwnPropertyNames(_this.insertImgsObj).length === 0) {
                _this.bIsUploadingImage = false;
            }
        };
        // 通过click页面元素展示图片上传框
        _this.handleShowImageUploader = function () {
            _this.fnRecordCurrentPos();
            _this.uploader.showImageUploader();
        };
        // 复制 / 点击上传前提前记录位置
        _this.fnRecordCurrentPos = function () {
            var sheet = _this.props.spread.getActiveSheet();
            _this.tempCol = sheet.getActiveColumnIndex();
            _this.tempRow = sheet.getActiveRowIndex();
        };
        // 协同带来的行列变化
        _this.handleCellCoordChange = function (_ref2) {
            var target = _ref2.target,
                sheet = _ref2.sheet,
                type = _ref2.type;

            if (!_this.bIsUploadingImage) return;
            for (var fileId in _this.insertImgsObj) {
                var insertImgObj = _this.insertImgsObj[fileId];
                var row = insertImgObj.row,
                    col = insertImgObj.col;
                var sheetId = insertImgObj.sheetId;

                if (sheet.id() === sheetId) {
                    // 判断该单元格是否被删除
                    var isCellDelete = _this.insertImgsObj[fileId].isCellDelete;
                    if (isCellDelete) continue;
                    // 如果是删除行列的话
                    if (type === 'del') {
                        if (target.row !== undefined) {
                            // 行被删除
                            if (target.row <= row && row <= target.row + target.rowCount - 1) {
                                isCellDelete = true;
                            }
                            if (target.row < row && target.row + target.rowCount - 1 < row) {
                                row -= target.rowCount;
                            }
                        }
                        if (target.col !== undefined) {
                            // 列被删除
                            if (target.col <= col && col <= target.col + target.colCount - 1) {
                                isCellDelete = true;
                            }
                            if (target.col < col && target.col + target.colCount - 1 < col) {
                                col -= target.colCount;
                            }
                        }
                    }
                    // 如果是增加行列的话
                    if (type === 'add') {
                        if (target.row !== undefined) {
                            if (row >= target.row) row += target.rowCount;
                        }
                        if (target.col !== undefined) {
                            if (col >= target.col) col += target.colCount;
                        }
                    }
                    // 更新对应的每个插入图片的位置
                    _this.insertImgsObj[fileId].row = row;
                    _this.insertImgsObj[fileId].col = col;
                    if (isCellDelete) {
                        _this.insertImgsObj[fileId].isCellDelete = true;
                    }
                    // 此时更新loading的状态
                    sheet.notifyShell(_shellNotify.ShellNotifyType.BindImageLoading, {
                        imageId: fileId,
                        row: row, col: col,
                        percentage: insertImgObj.percentage,
                        isCellChange: true,
                        isCellDelete: isCellDelete
                    });
                }
            }
        };
        // 单元格被删除的时候要阻断loading
        _this.handleDeleteCell = function (range) {
            if (!_this.bIsUploadingImage) return;
            var activeSheet = _this.props.spread.getActiveSheet();
            for (var fileId in _this.insertImgsObj) {
                var insertImgObj = _this.insertImgsObj[fileId];
                var row = insertImgObj.row,
                    col = insertImgObj.col,
                    sheetId = insertImgObj.sheetId;

                if (activeSheet.id() === sheetId) {
                    var _iteratorNormalCompletion = true;
                    var _didIteratorError = false;
                    var _iteratorError = undefined;

                    try {
                        for (var _iterator = range[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {
                            var item = _step.value;

                            // 如果在被操作的区域内
                            if (item.row <= row && row < item.row + item.rowCount && item.col <= col && col < item.col + item.colCount) {
                                _this.insertImgsObj[fileId].isCellDelete = true;
                                var model = activeSheet._getModel();
                                if (model.dataTable[row][col] && model.dataTable[row][col][markProperty]) {
                                    delete model.dataTable[row][col][markProperty];
                                }
                                break;
                            }
                        }
                    } catch (err) {
                        _didIteratorError = true;
                        _iteratorError = err;
                    } finally {
                        try {
                            if (!_iteratorNormalCompletion && _iterator.return) {
                                _iterator.return();
                            }
                        } finally {
                            if (_didIteratorError) {
                                throw _iteratorError;
                            }
                        }
                    }
                }
            }
        };
        // 合并单元格的时候，如果loading不在第一个单元格，就要移除它（们）
        _this.handleSpansChange = function (_ref3) {
            var spans = _ref3.spans,
                sheet = _ref3.sheet;

            if (!_this.bIsUploadingImage) return;
            for (var fileId in _this.insertImgsObj) {
                var insertImgObj = _this.insertImgsObj[fileId];
                var row = insertImgObj.row,
                    col = insertImgObj.col,
                    sheetId = insertImgObj.sheetId;

                if (sheetId === sheet.id()) {
                    var _iteratorNormalCompletion2 = true;
                    var _didIteratorError2 = false;
                    var _iteratorError2 = undefined;

                    try {
                        for (var _iterator2 = spans[Symbol.iterator](), _step2; !(_iteratorNormalCompletion2 = (_step2 = _iterator2.next()).done); _iteratorNormalCompletion2 = true) {
                            var span = _step2.value;

                            var item = span.target;
                            // 如果在被操作的区域内 && 不是左上角的单元格
                            if (item.row <= row && row < item.row + item.rowCount && item.col <= col && col < item.col + item.colCount && item.col !== col && item.row !== row) {
                                _this.insertImgsObj[fileId].isCellDelete = true;
                            }
                        }
                    } catch (err) {
                        _didIteratorError2 = true;
                        _iteratorError2 = err;
                    } finally {
                        try {
                            if (!_iteratorNormalCompletion2 && _iterator2.return) {
                                _iterator2.return();
                            }
                        } finally {
                            if (_didIteratorError2) {
                                throw _iteratorError2;
                            }
                        }
                    }
                }
            }
        };
        // load_fail or upload_fail
        _this.teaImageUploaderFail = function (type) {
            (0, _tea.collectSuiteEvent)(SHEET_OPRATION, {
                action: 'embed_img_' + type,
                source: 'body',
                eventType: 'click'
            });
        };
        return _this;
    }

    (0, _createClass3.default)(ImageUploader, [{
        key: 'componentDidMount',
        value: function componentDidMount() {
            this.bindEvents(this.props.spread);
            this.initUploader();
        }
    }, {
        key: 'componentWillUnmount',
        value: function componentWillUnmount() {
            this.unbindEvents(this.props.spread);
            this.uploader.destroyUploader();
        }
    }, {
        key: 'bindEvents',
        value: function bindEvents(spread) {
            var _this2 = this;

            if (!spread) return;
            var bindList = this.getBindList();
            bindList.spread.forEach(function (event) {
                _this2.props.spread.bind(event.key, event.handler);
            });
            bindList.context.forEach(function (event) {
                _this2.props.context.bind(event.key, event.handler);
            });
        }
    }, {
        key: 'unbindEvents',
        value: function unbindEvents(spread) {
            var _this3 = this;

            if (!spread) return;
            var bindList = this.getBindList();
            bindList.spread.forEach(function (event) {
                _this3.props.spread.unbind(event.key, event.handler);
            });
            bindList.context.forEach(function (event) {
                _this3.props.context.unbind(event.key, event.handler);
            });
        }
    }, {
        key: 'getImageWidthAndRow',
        value: function getImageWidthAndRow(url) {
            var _this4 = this;

            return new Promise(function (resolve) {
                var img = new Image();
                img.onload = function () {
                    var imgWidth = img.width;
                    var imgHeight = img.height;
                    resolve({ imgWidth: imgWidth, imgHeight: imgHeight });
                };
                img.onerror = function () {
                    console.log('插入图片返回链接加载出错');
                    _this4.teaImageUploaderFail('load_fail');
                    resolve({ imgWidth: 0, imgHeight: 0 });
                };
                img.src = url;
            });
        }
    }, {
        key: 'render',
        value: function render() {
            return null;
        }
    }]);
    return ImageUploader;
}(_react2.default.Component);

exports.default = ImageUploader;
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 3117:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = undefined;

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _webuploader = __webpack_require__(1938);

var WebUploader = _interopRequireWildcard(_webuploader);

var _$rjquery = __webpack_require__(499);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * 封装 webloader by镇佳
 */
var Uploader = function () {
  function Uploader(triggerBtnDom) {
    (0, _classCallCheck3.default)(this, Uploader);

    this.triggerBtnDom = triggerBtnDom;
    this.instance = null;
    this.triggerBtn = null;
  }

  (0, _createClass3.default)(Uploader, [{
    key: 'destroyUploader',
    value: function destroyUploader() {
      if (this.instance) {
        try {
          this.instance.destroy();
          this.instance = null;
        } catch (e) {
          // Raven上报
          window.Raven && window.Raven.captureException(e);
          // ConsoleError
          console.error(e);
        };
      }
    }
  }, {
    key: 'showImageUploader',
    value: function showImageUploader() {
      if (this.triggerBtn) {
        // 通过editorBar中的按钮触发trigger，设置上传格式过滤
        var input = (0, _$rjquery.$)(this.triggerBtn).find('input[name=file]');
        input.attr('accept', 'image/jpg, image/jpeg, image/png');
        (0, _$rjquery.$)(this.triggerBtn).find('label').trigger('click');
        input.attr('accept', '*');
      }
    }
  }, {
    key: 'createUploader',
    value: function createUploader() {
      var _this = this;

      if (!this.instance) {
        this.triggerBtn = (0, _$rjquery.$)(this.triggerBtnDom);
        (0, _$rjquery.$)('body').append(this.triggerBtn);
        this.instance = WebUploader.create({
          auto: true,
          server: '/api/file/upload/',
          method: 'POST',
          pick: this.triggerBtn,
          paste: document.body,
          multiple: false,
          threads: 1,
          fileNumLimit: 1,
          duplicate: true,
          ignorePasteElement: ['.innerdocbody'],
          // 只允许选择图片文件
          accept: {
            title: 'Images',
            extensions: 'jpg,jpeg,png',
            mimeTypes: 'image/*'
          }
        });
        this.instance.open = function () {
          return _this.showImageUploader();
        };
      }
      return this.instance;
    }
  }]);
  return Uploader;
}();

exports.default = Uploader;

/***/ }),

/***/ 3118:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3119:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.fileNameCut = fileNameCut;
function fileNameCut(name) {
    var len = 0;
    for (var i = 0; i < name.length; i++) {
        if (name.charCodeAt(i) > 127 || name.charCodeAt(i) === 94) {
            len += 2;
        } else {
            len += 1;
        }
    }
    if (len > 20) {
        return name.substring(0, 10) + "...";
    } else {
        return name;
    }
}

/***/ }),

/***/ 3120:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3121:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.OptionPasteDialog = undefined;

var _optionPasteDialog = __webpack_require__(3122);

var _optionPasteDialog2 = _interopRequireDefault(_optionPasteDialog);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.OptionPasteDialog = _optionPasteDialog2.default;

/***/ }),

/***/ 3122:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _sheet = __webpack_require__(713);

var _sheet_context = __webpack_require__(1578);

__webpack_require__(3123);

var _optionalImg = __webpack_require__(3124);

var _optionalImg2 = _interopRequireDefault(_optionalImg);

var _shellNotify = __webpack_require__(1576);

var _tea = __webpack_require__(47);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var sheetArea = GC.Spread.Sheets.SheetArea; /**
                                             * 选择性粘贴右下角弹窗
                                             * @author 王镇佳
                                             */

var SHEET_OPRATION = 'sheet_opration';
var directionType;
(function (directionType) {
    directionType["down"] = "down";
    directionType["up"] = "up";
})(directionType || (directionType = {}));

var OptionPasteDialog = function (_React$Component) {
    (0, _inherits3.default)(OptionPasteDialog, _React$Component);

    function OptionPasteDialog(props) {
        (0, _classCallCheck3.default)(this, OptionPasteDialog);

        var _this = (0, _possibleConstructorReturn3.default)(this, (OptionPasteDialog.__proto__ || Object.getPrototypeOf(OptionPasteDialog)).call(this, props));

        _this.direction = directionType.down;
        _this.getBindList = function () {
            return {
                spread: [{ key: _sheet.Events.ToggleOptionalPasteIcon, handler: _this.handleToggleOptionalPasteIcon }],
                context: [{ key: _sheet_context.CollaborativeEvents.CELL_COORD_CHANGE, handler: _this.handleCellCoordChange }]
            };
        };
        // 显示/隐藏 dialog icon
        _this.handleToggleOptionalPasteIcon = function (e, param) {
            var isShowIcon = param.isShowIcon,
                pastedRange = param.pastedRange;

            if (!pastedRange) return;
            var pasteLastRow = pastedRange.row + pastedRange.rowCount - 1;
            var pasteLastCol = pastedRange.col + pastedRange.colCount - 1;
            // icon 在最后一个单元格的右下角

            var _this$getRefreshedPos = _this.getRefreshedPos(pasteLastRow + 1, pasteLastCol + 1),
                x = _this$getRefreshedPos.x,
                y = _this$getRefreshedPos.y;

            _this.setState({
                bShowIcon: isShowIcon,
                bShowDialog: false,
                posTop: y + 'px',
                posLeft: x + 'px',
                pasteLastRow: pasteLastRow,
                pasteLastCol: pasteLastCol
            });
            if (isShowIcon) {
                _this.bindDialogEvent(pasteLastRow, pasteLastCol);
            } else {
                _this.unbindDialogEvent();
            }
        };
        // 打开dialog init相关内容 => 事件监听
        _this.bindDialogEvent = function (row, col) {
            _this.props.spread.getActiveSheet().notifyShell(_shellNotify.ShellNotifyType.BindCellPosition, {
                key: 'optionalPasteDialog',
                row: row,
                col: col,
                cb: function cb() {
                    _this.updateIconPos();
                }
            });
            window.addEventListener('click', _this._closeDialog);
            // 事件捕获的时候处理，因为canvas会特殊处理很多快捷键，不会冒泡出来
            window.addEventListener('keydown', _this._closeDialog, true);
            window.addEventListener('contextmenu', _this._closeDialog); // 右键菜单
        };
        // 关闭后重置相关内容 => faster监听移除 / window事件移除
        _this.unbindDialogEvent = function () {
            window.removeEventListener('click', _this._closeDialog);
            window.removeEventListener('keydown', _this._closeDialog);
            window.removeEventListener('contextmenu', _this._closeDialog);
            var sheet = _this.props.spread.getActiveSheet();
            if (!sheet) return;
            sheet.notifyShell(_shellNotify.ShellNotifyType.UnbindCellPosition, {
                key: 'optionalPasteDialog'
            });
        };
        // 禁用双指左滑 右滑
        _this.preventWheel = function (e) {
            e.preventDefault();
        };
        /**
         * 协同的时候要调整icon的位置
         */
        _this.handleCellCoordChange = function (params) {
            if (!_this.state.bShowIcon) return;
            var target = params.target,
                type = params.type;
            var _this$state = _this.state,
                pasteLastRow = _this$state.pasteLastRow,
                pasteLastCol = _this$state.pasteLastCol;

            switch (type) {
                case 'del':
                    if (target.row !== undefined) {
                        // 选择性粘贴的左上角行列 的行被删除
                        if (target.row <= pasteLastRow && pasteLastRow <= target.row + target.rowCount - 1) {
                            _this.setState({
                                bShowDialog: false,
                                bShowIcon: false
                            });
                            return;
                        }
                        // 选择性粘贴的左上角行列 以上的行被删除
                        if (target.row < pasteLastRow && target.row + target.rowCount - 1 < pasteLastRow) {
                            pasteLastRow -= target.rowCount;
                        }
                    }
                    if (target.col !== undefined) {
                        // 选择性粘贴的左上角行列 的列被删除
                        if (target.col <= pasteLastCol && pasteLastCol <= target.col + target.colCount - 1) {
                            _this.setState({
                                bShowDialog: false,
                                bShowIcon: false
                            });
                            return;
                        }
                        // 选择性粘贴的左上角行列 以左的列被删除
                        if (target.col < pasteLastCol && target.col + target.colCount - 1 < pasteLastCol) {
                            pasteLastCol -= target.colCount;
                        }
                    }
                    break;
                case 'add':
                    if (target.row !== undefined) {
                        if (pasteLastRow >= target.row && target.rowCount) pasteLastRow += target.rowCount;
                    }
                    if (target.col !== undefined) {
                        if (pasteLastCol >= target.col && target.colCount) pasteLastCol += target.colCount;
                    }
                    break;
                default:
                    break;
            }

            var _this$getRefreshedPos2 = _this.getRefreshedPos(pasteLastRow + 1, pasteLastCol + 1),
                x = _this$getRefreshedPos2.x,
                y = _this$getRefreshedPos2.y;

            _this.setState({
                posTop: y + 'px',
                posLeft: x + 'px',
                pasteLastRow: pasteLastRow,
                pasteLastCol: pasteLastCol
            });
        };
        _this._closeDialog = function (e) {
            if (e instanceof MouseEvent) {
                // 如果点击事件包含 option-paste
                var target = e.target;
                while (target) {
                    var classList = target.classList && target.classList.toString();
                    if (classList === 'option-paste-img' || classList === 'option-paste-list') return;
                    target = target.parentNode;
                }
            }
            var _this$state2 = _this.state,
                bShowIcon = _this$state2.bShowIcon,
                bShowDialog = _this$state2.bShowDialog;

            if (e instanceof KeyboardEvent) {
                // 如果dialog是打开的，并且按了tab键和esc键, 则收起下拉列表
                if (bShowDialog && (e.keyCode === 9 || e.keyCode === 27)) {
                    _this.setState({
                        bShowDialog: false
                    });
                    return;
                } else if (bShowDialog) {
                    return;
                }
            }
            // 如果没有打开 dialog ，不响应
            if (!bShowIcon) return;
            // 否则关闭 dialog
            _this.setState({
                bShowIcon: false,
                bShowDialog: false
            });
            _this.unbindDialogEvent();
        };
        // faster 渲染更新时修改 icon的位置
        _this.updateIconPos = function () {
            var _this$state3 = _this.state,
                pasteLastRow = _this$state3.pasteLastRow,
                pasteLastCol = _this$state3.pasteLastCol;

            var _this$getRefreshedPos3 = _this.getRefreshedPos(pasteLastRow + 1, pasteLastCol + 1),
                x = _this$getRefreshedPos3.x,
                y = _this$getRefreshedPos3.y;

            _this.setState({
                posTop: y + 'px',
                posLeft: x + 'px'
            });
        };
        // 显示/隐藏 列表
        _this.toggleOptionalPasteDialog = function () {
            _this.setState({
                bShowDialog: !_this.state.bShowDialog
            }, function () {
                if (_this.state.bShowDialog === true) {
                    (0, _tea.collectSuiteEvent)(SHEET_OPRATION, {
                        action: 'optional-paste-open',
                        source: 'body',
                        eventType: 'click'
                    });
                }
            });
        };
        _this.handleOptionPaste = function (type) {
            var sheet = _this.props.spread.getActiveSheet();
            switch (type) {
                case 'values':
                    sheet._doClipboardOptionalPaste(_sheet.ClipboardPasteOptions.values);
                    break;
                case 'formatting':
                    sheet._doClipboardOptionalPaste(_sheet.ClipboardPasteOptions.formatting);
                    break;
                case 'formulas':
                    sheet._doClipboardOptionalPaste(_sheet.ClipboardPasteOptions.formulas);
                    break;
                default:
                    break;
            }
            _this.setState({
                bShowDialog: false
            });
            // 打点
            (0, _tea.collectSuiteEvent)(SHEET_OPRATION, {
                action: 'optional-paste-' + type,
                source: 'body',
                eventType: 'click'
            });
        };
        // 获取更新完为止后的icon应该显示的位置
        _this.getRefreshedPos = function (row, col) {
            var spread = _this.props.spread;

            var sheet = spread.getActiveSheet();
            var divWidth = 80;
            var divHeight = 110;
            var pasteLastCol = _this.state.pasteLastCol;

            var tableBounds = sheet.sheetViewRect();

            var _sheet$getCellRect = sheet.getCellRect(row, col),
                x = _sheet$getCellRect.x,
                y = _sheet$getCellRect.y;

            var rowHeaderWidth = sheet.getColumnWidth(-1, sheetArea.rowHeader);
            var colHeaderHeight = sheet.getRowHeight(-1, sheetArea.colHeader);
            var left = x;
            var top = y;
            var leftBound = tableBounds.x || rowHeaderWidth;
            var rightBound = tableBounds.x + tableBounds.width;
            var topBound = tableBounds.y || colHeaderHeight;
            var bottomBound = tableBounds.y + tableBounds.height;
            _this.direction = directionType.down; // 默认向下展示
            var realX = x;
            var realY = y; // 经过处理返回的x, y的值
            // 1. 如果 单元格 top < topBound 消失
            if (top < topBound) realY = -10000;
            // 2. 如果 单元格 left < leftBound 消失
            if (left < leftBound) realX = -10000;
            // 3. 如果 单元格 left > rightBound 消失
            if (left > rightBound) realX = -10000;
            // 4. 如果 单元格 bottom 到 bottomBound 的距离不够展示list.且，向上的空间是够的。 向上展示
            if (bottomBound - y < divHeight && bottomBound - topBound > divHeight) {
                _this.direction = directionType.up;
            }
            // 5. 如果 单元格 left 到 rightBound 的距离不够展示list. 向左展示, 但是只最左不能超过该列
            if (rightBound - left < divWidth && col > pasteLastCol) {
                return _this.getRefreshedPos(row, col - 1);
            }
            return { x: realX, y: realY };
        };
        _this.state = {
            bShowIcon: false,
            bShowDialog: false,
            posTop: '0px',
            posLeft: '0px',
            pasteLastRow: 0,
            pasteLastCol: 0
        };
        return _this;
    }

    (0, _createClass3.default)(OptionPasteDialog, [{
        key: 'componentDidMount',
        value: function componentDidMount() {
            this.bindEvents(this.props.spread);
        }
    }, {
        key: 'componentWillUnmount',
        value: function componentWillUnmount() {
            this.unbindEvents(this.props.spread);
        }
    }, {
        key: 'bindEvents',
        value: function bindEvents(spread) {
            var _this2 = this;

            if (!spread) return;
            var bindList = this.getBindList();
            bindList.spread.forEach(function (event) {
                _this2.props.spread.bind(event.key, event.handler);
            });
            bindList.context.forEach(function (event) {
                _this2.props.context.bind(event.key, event.handler);
            });
        }
    }, {
        key: 'unbindEvents',
        value: function unbindEvents(spread) {
            var _this3 = this;

            if (!spread) return;
            var bindList = this.getBindList();
            bindList.spread.forEach(function (event) {
                _this3.props.spread.unbind(event.key, event.handler);
            });
            bindList.context.forEach(function (event) {
                _this3.props.context.unbind(event.key, event.handler);
            });
        }
    }, {
        key: 'render',
        value: function render() {
            var _this4 = this;

            var _state = this.state,
                bShowIcon = _state.bShowIcon,
                bShowDialog = _state.bShowDialog,
                posTop = _state.posTop,
                posLeft = _state.posLeft;

            if (!bShowIcon) return null;
            var listStyle = { top: '0px' };
            if (this.direction === directionType.up) {
                listStyle.top = '-140px';
            }
            return _react2.default.createElement("div", { className: "option-paste", onWheel: this.preventWheel, style: { top: posTop, left: posLeft }, "data-sheet-component": true }, _react2.default.createElement(_optionalImg2.default, { width: "40", className: "option-paste-img", onClick: this.toggleOptionalPasteDialog }), bShowDialog ? _react2.default.createElement("div", { className: "option-paste-list", style: listStyle, "data-sheet-component": true }, _react2.default.createElement("li", { onClick: function onClick() {
                    return _this4.handleOptionPaste('values');
                } }, t('sheet.optional_paste_values')), _react2.default.createElement("li", { onClick: function onClick() {
                    return _this4.handleOptionPaste('formatting');
                } }, t('sheet.optional_paste_formatting')), _react2.default.createElement("li", { onClick: function onClick() {
                    return _this4.handleOptionPaste('formulas');
                } }, t('sheet.optional_paste_formulas'))) : null);
        }
    }]);
    return OptionPasteDialog;
}(_react2.default.Component);

exports.default = OptionPasteDialog;
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 3123:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3124:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement(
      "g",
      { fill: "#424E5D", fillRule: "nonzero" },
      _react2.default.createElement("path", { d: "M11 11h2a1 1 0 0 1 1 1v6a1 1 0 0 1-1 1H7a1 1 0 0 1-1-1H.92a.92.92 0 0 1-.92-.92V7.92C0 7.4.41 7 .92 7H3V6a1 1 0 0 1 1-1h3a1 1 0 0 1 1 1v1h2.08c.51 0 .92.41.92.92V11zm-1 0V8H9v1H2V8H1v9h5v-5a1 1 0 0 1 1-1h3zM7 7V6H4v1h3zm0 5v6h6v-6H7zm1 1h4v1H8v-1zm0 2h4v1H8v-1zM20.5 12.8l2.65-2.65a.5.5 0 0 1 .7.7l-3.35 3.36-3.35-3.36a.5.5 0 0 1 .7-.7l2.65 2.64z" })
    )
  );
};

/***/ }),

/***/ 3125:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.setEmbedStyle = exports.FullScreen = exports.IgnoreFocus = exports.StateComponent = exports.Comment = exports.Filter = exports.Dropdown = exports.FindAndReplace = exports.Link = exports.Formula = exports.Freeze = exports.Sort = exports.WordWrap = exports.VAlign = exports.HAlign = exports.SplitMerge = exports.BorderLine = exports.BackColor = exports.ForeColor = exports.Strikethrough = exports.Underline = exports.Italic = exports.Bold = exports.FontSize = exports.Formatter = exports.Divider = exports.ClearFormat = exports.FormatPainterWidget = exports.Redo = exports.Undo = exports.SheetToolbar = exports.SheetToolbarBaseState = exports.SheetToolbarBaseProps = exports.SheetToolbarBase = undefined;

var _SheetToolbar = __webpack_require__(3126);

var _SheetToolbar2 = _interopRequireDefault(_SheetToolbar);

var _SheetToolbarBase = __webpack_require__(2060);

var _SheetToolbarItemHelper = __webpack_require__(1678);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.SheetToolbarBase = _SheetToolbarBase.SheetToolbarBase;
exports.SheetToolbarBaseProps = _SheetToolbarBase.SheetToolbarBaseProps;
exports.SheetToolbarBaseState = _SheetToolbarBase.SheetToolbarBaseState;
exports.SheetToolbar = _SheetToolbar2.default;
exports.Undo = _SheetToolbarItemHelper.Undo;
exports.Redo = _SheetToolbarItemHelper.Redo;
exports.FormatPainterWidget = _SheetToolbarItemHelper.FormatPainterWidget;
exports.ClearFormat = _SheetToolbarItemHelper.ClearFormat;
exports.Divider = _SheetToolbarItemHelper.Divider;
exports.Formatter = _SheetToolbarItemHelper.Formatter;
exports.FontSize = _SheetToolbarItemHelper.FontSize;
exports.Bold = _SheetToolbarItemHelper.Bold;
exports.Italic = _SheetToolbarItemHelper.Italic;
exports.Underline = _SheetToolbarItemHelper.Underline;
exports.Strikethrough = _SheetToolbarItemHelper.Strikethrough;
exports.ForeColor = _SheetToolbarItemHelper.ForeColor;
exports.BackColor = _SheetToolbarItemHelper.BackColor;
exports.BorderLine = _SheetToolbarItemHelper.BorderLine;
exports.SplitMerge = _SheetToolbarItemHelper.SplitMerge;
exports.HAlign = _SheetToolbarItemHelper.HAlign;
exports.VAlign = _SheetToolbarItemHelper.VAlign;
exports.WordWrap = _SheetToolbarItemHelper.WordWrap;
exports.Sort = _SheetToolbarItemHelper.Sort;
exports.Freeze = _SheetToolbarItemHelper.Freeze;
exports.Formula = _SheetToolbarItemHelper.Formula;
exports.Link = _SheetToolbarItemHelper.Link;
exports.FindAndReplace = _SheetToolbarItemHelper.FindAndReplace;
exports.Dropdown = _SheetToolbarItemHelper.Dropdown;
exports.Filter = _SheetToolbarItemHelper.Filter;
exports.Comment = _SheetToolbarItemHelper.Comment;
exports.StateComponent = _SheetToolbarItemHelper.StateComponent;
exports.IgnoreFocus = _SheetToolbarItemHelper.IgnoreFocus;
exports.FullScreen = _SheetToolbarItemHelper.FullScreen;
exports.setEmbedStyle = _SheetToolbarItemHelper.setEmbedStyle;

/***/ }),

/***/ 3126:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _isUndefined2 = __webpack_require__(287);

var _isUndefined3 = _interopRequireDefault(_isUndefined2);

var _findIndex2 = __webpack_require__(1837);

var _findIndex3 = _interopRequireDefault(_findIndex2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _reactDom = __webpack_require__(21);

var _reactDom2 = _interopRequireDefault(_reactDom);

var _reactRedux = __webpack_require__(238);

var _redux = __webpack_require__(65);

var _utils = __webpack_require__(1575);

var _tea = __webpack_require__(47);

var _SheetToolbarItemHelper = __webpack_require__(1678);

var _sheet = __webpack_require__(1597);

var _sheet2 = __webpack_require__(715);

var _toolbar = __webpack_require__(1714);

var _SheetToolbarBase2 = __webpack_require__(2060);

var _FoldPlate = __webpack_require__(3220);

var _sheet3 = __webpack_require__(713);

__webpack_require__(3221);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var SHEET_HEAD_TOOLBAR = 'sheet_head_toolbar';
var SHEET_OPRATION = 'sheet_opration';
var foldPlateInstance = null;
var refreshFoldPlate = function refreshFoldPlate(groupBoxList, anchorDom, disabled) {
    if (!anchorDom || groupBoxList.length === 0) {
        if (foldPlateInstance && foldPlateInstance.style.display !== 'none') {
            foldPlateInstance.style.display = 'none';
        }
        return;
    }
    var clientRect = anchorDom.getBoundingClientRect();
    foldPlateInstance = foldPlateInstance || (0, _FoldPlate.createFoldPlate)();
    foldPlateInstance.style.top = clientRect.bottom + 8 + 'px';
    var clonedGroupBoxList = _react.Children.map(groupBoxList, function (item, index) {
        if (_react2.default.isValidElement(item)) {
            return (0, _react.cloneElement)(item, {
                showDivider: index !== 0
            });
        } else {
            return null;
        }
    });
    var dom = _react2.default.createElement("div", { className: "toolbar-plate" }, _react2.default.createElement(_toolbar.Toolbar, { disabled: disabled, className: "" }, clonedGroupBoxList));
    _reactDom2.default.render(dom, foldPlateInstance);
};

var GroupBox = function (_React$PureComponent) {
    (0, _inherits3.default)(GroupBox, _React$PureComponent);

    function GroupBox(props) {
        (0, _classCallCheck3.default)(this, GroupBox);

        var _this = (0, _possibleConstructorReturn3.default)(this, (GroupBox.__proto__ || Object.getPrototypeOf(GroupBox)).call(this, props));

        _this.state = {};
        return _this;
    }

    (0, _createClass3.default)(GroupBox, [{
        key: 'render',
        value: function render() {
            var props = this.props;
            var disabled = props.disabled,
                children = props.children,
                doNotAssignPermission = props.doNotAssignPermission,
                _props$showDivider = props.showDivider,
                showDivider = _props$showDivider === undefined ? true : _props$showDivider,
                className = props.className;

            return _react2.default.createElement("div", { id: props.id, className: className + ' toolbar-groupbox' }, showDivider && children && (0, _SheetToolbarItemHelper.Divider)(), disabled ? _react.Children.map(children, function (child) {
                if (_react2.default.isValidElement(child)) {
                    return _react2.default.cloneElement(child, { disabled: doNotAssignPermission === true ? false : true });
                }
                return child;
            }) : children);
        }
    }]);
    return GroupBox;
}(_react2.default.PureComponent);

var SheetToolbar = function (_SheetToolbarBase) {
    (0, _inherits3.default)(SheetToolbar, _SheetToolbarBase);

    function SheetToolbar(props) {
        (0, _classCallCheck3.default)(this, SheetToolbar);

        var _this2 = (0, _possibleConstructorReturn3.default)(this, (SheetToolbar.__proto__ || Object.getPrototypeOf(SheetToolbar)).call(this, props));

        _this2._triggerDom = null;
        _this2._groupBoxList = [];
        _this2._groupBoxRightPos = [];
        _this2._spreadToken = '';
        _this2._handleFoldTriggerClick = function (e) {
            e.stopPropagation();
            if (foldPlateInstance) {
                if (foldPlateInstance.style.display === 'none') {
                    foldPlateInstance.style.display = 'flex';
                    var data = {
                        action: 'more_func',
                        source: SHEET_HEAD_TOOLBAR,
                        eventType: 'click',
                        file_id: _this2._spreadToken,
                        file_type: 'sheet'
                    };
                    (0, _tea.collectSuiteEvent)(SHEET_OPRATION, data);
                } else {
                    foldPlateInstance.style.display = 'none';
                }
            }
        };
        _this2._handleExpandClick = function (e) {
            e.stopPropagation();
            var isPickUp = _this2.state.isPickUp;
            // 如果要收缩上去

            if (!isPickUp) {
                _this2._teaHandleButtonClick('pickupToolbar');
                _this2.props.toggleNavBar(true, true);
            } else {
                _this2._teaHandleButtonClick('expandToolbar');
                _this2.props.toggleNavBar(false, true);
            }
            // 处理因为收缩和展开带来的一些问题
            if (foldPlateInstance) foldPlateInstance.style.display = 'none';
            // settimeout是因为做了动画 延迟计算页面高度 动画时间.2s
            setTimeout(function () {
                _this2.setState({
                    isPickUp: !isPickUp
                });
                _this2.props.doResize();
                if (foldPlateInstance) {
                    var anchorDom = _reactDom2.default.findDOMNode(_this2._triggerDom);
                    var clientRect = anchorDom.getBoundingClientRect();
                    foldPlateInstance.style.top = clientRect.bottom + 8 + 'px';
                }
            }, 200);
            var sPickUp = !isPickUp ? '1' : '0';
            try {
                localStorage.setItem(location.pathname + '-pickup', sPickUp);
            } catch (e) {
                // Raven上报
                window.Raven && window.Raven.captureException(e);
                // ConsoleError
                console.error(e);
            }
        };
        _this2._getTriggerRef = function (groupBox) {
            _this2._triggerDom = groupBox;
        };
        _this2._onWindowResize = function () {
            var props = _this2.props,
                state = _this2.state;

            var clientWidth = document.documentElement.clientWidth;
            // 24 + 16 是最后一个收起icon len + margin
            var pickupLength = _this2.mode === 'default' ? 24 + 16 : 0;
            var preserveWidth = props.showComment !== false ? 64 + pickupLength : 12;
            if (state.displayIndex !== -1) {
                preserveWidth += 36;
            }
            var displayIndex = (0, _findIndex3.default)(_this2._groupBoxRightPos, function (item) {
                return item + preserveWidth > clientWidth;
            });
            if (displayIndex !== _this2.state.displayIndex) {
                _this2.setState({
                    displayIndex: displayIndex
                });
            }
        };
        _this2.mode = props.mode;
        // 根据token 获取是否收起 | 默认false
        var sPickup = localStorage.getItem(location.pathname + '-pickup');
        var isPickUp = sPickup === '1';
        _this2.state = {
            isPickUp: isPickUp,
            displayIndex: -1
        };
        window.removeEventListener('resize', _this2._onWindowResize);
        window.addEventListener('resize', _this2._onWindowResize);
        return _this2;
    }

    (0, _createClass3.default)(SheetToolbar, [{
        key: 'componentWillReceiveProps',
        value: function componentWillReceiveProps(nextProps) {
            var spread = nextProps.spread;

            if (spread) {
                this._spreadToken = spread._context.token || '';
            }
        }
    }, {
        key: 'componentDidMount',
        value: function componentDidMount() {
            var _this3 = this;

            this._groupBoxList.forEach(function (item, index) {
                var domNode = document.querySelector('#' + item.props.id);
                if (item.props.freeze !== true && domNode) {
                    var clientRect = domNode.getBoundingClientRect();
                    _this3._groupBoxRightPos[index] = clientRect.right;
                } else {
                    _this3._groupBoxRightPos[index] = 0;
                }
            });
            this._onWindowResize();
        }
    }, {
        key: 'componentDidUpdate',
        value: function componentDidUpdate() {
            var state = this.state,
                props = this.props;

            refreshFoldPlate(this._groupBoxList.slice(state.displayIndex).filter(function (item) {
                return item.props.freeze !== true;
            }), _reactDom2.default.findDOMNode(this._triggerDom), props.disabled);
        }
        // 在组件要卸载的时候 要把标题栏展开，更新全局状态，保证标题栏不会影响别的文档

    }, {
        key: 'componentWillUnmount',
        value: function componentWillUnmount() {
            this.props.toggleNavBar(false, false);
        }
    }, {
        key: 'render',
        value: function render() {
            var _this4 = this;

            var state = this.state,
                props = this.props;
            var _state$foreColor = state.foreColor,
                foreColor = _state$foreColor === undefined ? '#000000' : _state$foreColor,
                _state$backColor = state.backColor,
                backColor = _state$backColor === undefined ? '#ffffff' : _state$backColor,
                _state$borderLine = state.borderLine,
                borderLine = _state$borderLine === undefined ? { border: _sheet3.SHEET_BORDER.FULL_BORDER, color: '#000000', selected: 'border' } : _state$borderLine,
                isPickUp = state.isPickUp;
            var cellStatus = props.cellStatus,
                rangeStatus = props.rangeStatus,
                findbar = props.findbar,
                isFiltered = props.isFiltered,
                commentable = props.commentable,
                dropdownMenu = props.dropdownMenu,
                spread = props.spread;
            var _cellStatus$formatter = cellStatus.formatter,
                formatter = _cellStatus$formatter === undefined ? 'normal' : _cellStatus$formatter,
                bold = cellStatus.bold,
                italic = cellStatus.italic,
                underline = cellStatus.underline,
                lineThrough = cellStatus.lineThrough;
            var splitable = rangeStatus.splitable,
                mergable = rangeStatus.mergable,
                sortable = rangeStatus.sortable,
                painterFormatable = rangeStatus.painterFormatable;
            var hAlign = cellStatus.hAlign,
                vAlign = cellStatus.vAlign,
                wordWrap = cellStatus.wordWrap,
                fontSize = cellStatus.fontSize;

            (0, _SheetToolbarItemHelper.setEmbedStyle)(false);
            hAlign = hAlign + '';
            vAlign = vAlign + '';
            // 旧数据兼容
            wordWrap = (0, _utils.compatibleOldWordWrapData)(wordWrap);
            wordWrap = ((0, _isUndefined3.default)(wordWrap) ? _sheet3.WORD_WRAP_TYPE.OVERFLOW : wordWrap) + '';
            fontSize = parseInt(fontSize, 10) + '';
            this._groupBoxList = [_react2.default.createElement(GroupBox, { key: 1, freeze: true, id: "sheet-toolbar-g1", showDivider: false }, (0, _SheetToolbarItemHelper.Undo)(function () {
                return _this4._handleButtonClick('undo');
            }), (0, _SheetToolbarItemHelper.Redo)(function () {
                return _this4._handleButtonClick('redo');
            }), (0, _SheetToolbarItemHelper.FormatPainterWidget)(props, painterFormatable), (0, _SheetToolbarItemHelper.ClearFormat)(function () {
                return _this4._handleButtonClick('clear');
            })), _react2.default.createElement(GroupBox, { key: 2, freeze: true, id: "sheet-toolbar-g2" }, (0, _SheetToolbarItemHelper.Formatter)(formatter, function (visible) {
                return _this4._handleMenuVisible('formatter', visible);
            }, function (val) {
                return _this4._handleButtonClick('formatter', val);
            })), _react2.default.createElement(GroupBox, { key: 3, freeze: true, id: "sheet-toolbar-g3" }, (0, _SheetToolbarItemHelper.FontSize)(fontSize, function (visible) {
                return _this4._handleMenuVisible('fontSize', visible);
            }, function (val) {
                return _this4._handleButtonClick('fontSize', val);
            })), _react2.default.createElement(GroupBox, { key: 4, freeze: true, id: "sheet-toolbar-g4" }, (0, _SheetToolbarItemHelper.Bold)(bold, function () {
                return _this4._handleButtonClick('bold', !bold);
            }), (0, _SheetToolbarItemHelper.Italic)(italic, function () {
                return _this4._handleButtonClick('italic', !italic);
            }), (0, _SheetToolbarItemHelper.Underline)(underline, function () {
                return _this4._handleButtonClick('underline', !underline);
            }), (0, _SheetToolbarItemHelper.Strikethrough)(lineThrough, function () {
                return _this4._handleButtonClick('lineThrough', !lineThrough);
            })), _react2.default.createElement(GroupBox, { key: 5, id: "sheet-toolbar-g5" }, (0, _SheetToolbarItemHelper.ForeColor)(foreColor, function (visible) {
                return _this4._handleMenuVisible('foreColor', visible);
            }, function (val, isDefault) {
                return _this4._handleButtonClick('foreColor', val, isDefault);
            }), (0, _SheetToolbarItemHelper.BackColor)(backColor, function (visible) {
                return _this4._handleMenuVisible('backColor', visible);
            }, function (val, isDefault) {
                return _this4._handleButtonClick('backColor', val, isDefault);
            }), (0, _SheetToolbarItemHelper.BorderLine)(borderLine, function (visible) {
                return _this4._handleMenuVisible('frame', visible);
            }, function (val, isDefault) {
                return _this4._handleButtonClick('frame', val, isDefault);
            })), _react2.default.createElement(GroupBox, { key: 6, id: "sheet-toolbar-g6" }, (0, _SheetToolbarItemHelper.SplitMerge)(splitable, mergable, function () {
                return _this4._handleButtonClick('merge', {
                    splitable: splitable,
                    mergable: mergable
                });
            }), (0, _SheetToolbarItemHelper.HAlign)(hAlign, function (visible) {
                return _this4._handleMenuVisible('hAlign', visible);
            }, function (val) {
                return _this4._handleButtonClick('hAlign', val);
            }), (0, _SheetToolbarItemHelper.VAlign)(vAlign, function (visible) {
                return _this4._handleMenuVisible('vAlign', visible);
            }, function (val) {
                return _this4._handleButtonClick('vAlign', val);
            }), (0, _SheetToolbarItemHelper.WordWrap)(wordWrap, function (visible) {
                return _this4._handleMenuVisible('wordWrap', visible);
            }, function (val) {
                return _this4._handleButtonClick('wordWrap', val);
            })), _react2.default.createElement(GroupBox, { key: 7, id: "sheet-toolbar-g7" }, (0, _SheetToolbarItemHelper.Sort)(sortable, function (visible) {
                return _this4._handleMenuVisible('sort', visible);
            }, function (val) {
                return _this4._handleButtonClick('sort', val);
            }), (0, _SheetToolbarItemHelper.Filter)(isFiltered, function () {
                return _this4._handleButtonClick('filter', !isFiltered);
            }), (0, _SheetToolbarItemHelper.Dropdown)(dropdownMenu.visible, function () {
                return _this4._handleButtonClick('dropdownMenu');
            })), _react2.default.createElement(GroupBox, { key: 8, id: "sheet-toolbar-g8" }, (0, _SheetToolbarItemHelper.Img)(function () {
                return _this4._handleButtonClick('img', 'embed');
            }), (0, _SheetToolbarItemHelper.Link)(this._isHyperlinkActive(), function (e) {
                return _this4._handleButtonClick('hyperlink', null, false, e);
            }, !this._isHyperlinkDisable()), (0, _SheetToolbarItemHelper.Formula)(function (visible) {
                return _this4._handleMenuVisible('formula', visible);
            }, function (val, isDefault) {
                return _this4._handleButtonClick('formula', val, isDefault);
            })), _react2.default.createElement(GroupBox, { key: 9, id: "sheet-toolbar-g9" }, (0, _SheetToolbarItemHelper.Freeze)(spread), (0, _SheetToolbarItemHelper.FindAndReplace)(findbar.visible, function () {
                return _this4._handleButtonClick('find');
            }, true))];
            if (props.showComment !== false) {
                this._groupBoxList.push(_react2.default.createElement(GroupBox, { key: 10, freeze: true, id: "sheet-toolbar-g10" }, (0, _SheetToolbarItemHelper.Comment)(function () {
                    return _this4._handleButtonClick('comment');
                }, commentable)));
            }
            var groupBoxList = [];
            if (state.displayIndex === -1) {
                groupBoxList = this._groupBoxList;
            } else {
                groupBoxList = this._groupBoxList.slice(0, state.displayIndex);
                groupBoxList = groupBoxList.concat(this._groupBoxList.slice(state.displayIndex).filter(function (item) {
                    return item.props.freeze === true;
                }));
                groupBoxList.push(_react2.default.createElement(GroupBox, { key: 11, freeze: true, doNotAssignPermission: true, ref: this._getTriggerRef, id: "sheet-toolbar-folder-trigger" }, (0, _SheetToolbarItemHelper.FoldTrigger)(this._handleFoldTriggerClick)));
            }
            // 放入收起的图标 如果是展开就旋转180
            if (this.mode === 'default') {
                groupBoxList.push(_react2.default.createElement(GroupBox, { id: "sheet-toolbar-g12", key: 12, className: isPickUp ? 'sheet_toolbar_rotate' : '', freeze: true, showDivider: false }, (0, _SheetToolbarItemHelper.Pickup)(this._handleExpandClick, isPickUp)));
            }
            return _react2.default.createElement(_toolbar.Toolbar, { className: props.className, disabled: props.disabled }, groupBoxList);
        }
    }]);
    return SheetToolbar;
}(_SheetToolbarBase2.SheetToolbarBase);

exports.default = (0, _reactRedux.connect)(function (state, props) {
    return {
        cellStatus: (0, _sheet.cellStatusSelector)(state),
        coord: (0, _sheet.coordSelector)(state),
        rangeStatus: (0, _sheet.rangeStatusSelector)(state),
        disabled: (0, _sheet.toolbarDisableSelector)(state),
        editable: !(0, _sheet.toolbarDisableSelector)(state),
        hyperlinkEditor: (0, _sheet.hyperlinkEditorSelector)(state),
        formatPainter: (0, _sheet.formatPainterSelector)(state),
        findbar: (0, _sheet.findbarSelector)(state),
        dropdownMenu: (0, _sheet.dropdownMenuSelector)(state),
        isFiltered: (0, _sheet.isFilteredSelector)(state),
        commentable: (0, _sheet.commentableSelector)(state)
    };
}, function (dispatch) {
    return (0, _redux.bindActionCreators)({
        showFormulaList: _sheet2.showFormulaList,
        showHyperlinkEditor: _sheet2.showHyperlinkEditor,
        hideHyperlinkEditor: _sheet2.hideHyperlinkEditor,
        formatPainterToggle: _sheet2.formatPainterToggle,
        showFindbar: _sheet2.showFindbar,
        hideFindbar: _sheet2.hideFindbar,
        showDropdownMenu: _sheet2.showDropdownMenu,
        hideDropdownMenu: _sheet2.hideDropdownMenu,
        toggleCommentPanel: _sheet2.toggleCommentPanel,
        toggleNavBar: _sheet2.toggleNavBar
    }, dispatch);
})(SheetToolbar);

/***/ }),

/***/ 3127:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.Toolbar = undefined;

var _objectWithoutProperties2 = __webpack_require__(26);

var _objectWithoutProperties3 = _interopRequireDefault(_objectWithoutProperties2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _classnames = __webpack_require__(29);

var _classnames2 = _interopRequireDefault(_classnames);

__webpack_require__(3128);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var Toolbar = function Toolbar(_ref) {
    var className = _ref.className,
        disabled = _ref.disabled,
        children = _ref.children,
        other = (0, _objectWithoutProperties3.default)(_ref, ['className', 'disabled', 'children']);

    if (!children) {
        return null;
    }
    return _react2.default.createElement("div", Object.assign({ className: (0, _classnames2.default)(className, 'toolbar'), role: "toolbar" }, other), disabled ? _react.Children.map(children, function (child) {
        if (_react2.default.isValidElement(child)) {
            return _react2.default.cloneElement(child, { disabled: true });
        }
        return child;
    }) : children);
};
exports.Toolbar = Toolbar;

/***/ }),

/***/ 3128:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3129:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3130:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3131:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _dropdown = __webpack_require__(2052);

var _dropdown2 = _interopRequireDefault(_dropdown);

var _dropdownButton = __webpack_require__(3132);

var _dropdownButton2 = _interopRequireDefault(_dropdownButton);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

_dropdown2['default'].Button = _dropdownButton2['default'];
exports['default'] = _dropdown2['default'];
module.exports = exports['default'];

/***/ }),

/***/ 3132:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var React = _interopRequireWildcard(_react);

var _button = __webpack_require__(2049);

var _button2 = _interopRequireDefault(_button);

var _dropdown = __webpack_require__(2052);

var _dropdown2 = _interopRequireDefault(_dropdown);

var _classnames = __webpack_require__(29);

var _classnames2 = _interopRequireDefault(_classnames);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj['default'] = obj; return newObj; } }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

var __rest = undefined && undefined.__rest || function (s, e) {
    var t = {};
    for (var p in s) {
        if (Object.prototype.hasOwnProperty.call(s, p) && e.indexOf(p) < 0) t[p] = s[p];
    }if (s != null && typeof Object.getOwnPropertySymbols === "function") for (var i = 0, p = Object.getOwnPropertySymbols(s); i < p.length; i++) {
        if (e.indexOf(p[i]) < 0) t[p[i]] = s[p[i]];
    }return t;
};

var ButtonGroup = _button2['default'].Group;

var DropdownButton = function (_React$Component) {
    (0, _inherits3['default'])(DropdownButton, _React$Component);

    function DropdownButton() {
        (0, _classCallCheck3['default'])(this, DropdownButton);
        return (0, _possibleConstructorReturn3['default'])(this, (DropdownButton.__proto__ || Object.getPrototypeOf(DropdownButton)).apply(this, arguments));
    }

    (0, _createClass3['default'])(DropdownButton, [{
        key: 'render',
        value: function render() {
            var _a = this.props,
                type = _a.type,
                disabled = _a.disabled,
                onClick = _a.onClick,
                children = _a.children,
                prefixCls = _a.prefixCls,
                className = _a.className,
                overlay = _a.overlay,
                trigger = _a.trigger,
                align = _a.align,
                visible = _a.visible,
                onVisibleChange = _a.onVisibleChange,
                placement = _a.placement,
                getPopupContainer = _a.getPopupContainer,
                restProps = __rest(_a, ["type", "disabled", "onClick", "children", "prefixCls", "className", "overlay", "trigger", "align", "visible", "onVisibleChange", "placement", "getPopupContainer"]);
            var dropdownProps = {
                align: align,
                overlay: overlay,
                disabled: disabled,
                trigger: disabled ? [] : trigger,
                onVisibleChange: onVisibleChange,
                placement: placement,
                getPopupContainer: getPopupContainer
            };
            if ('visible' in this.props) {
                dropdownProps.visible = visible;
            }
            return React.createElement(
                ButtonGroup,
                (0, _extends3['default'])({}, restProps, { className: (0, _classnames2['default'])(prefixCls, className) }),
                React.createElement(
                    _button2['default'],
                    { type: type, disabled: disabled, onClick: onClick },
                    children
                ),
                React.createElement(
                    _dropdown2['default'],
                    dropdownProps,
                    React.createElement(_button2['default'], { type: type, icon: 'ellipsis' })
                )
            );
        }
    }]);
    return DropdownButton;
}(React.Component);

exports['default'] = DropdownButton;

DropdownButton.defaultProps = {
    placement: 'bottomRight',
    type: 'default',
    prefixCls: 'ant-dropdown-button'
};
module.exports = exports['default'];

/***/ }),

/***/ 3133:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3134:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3135:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.ToolbarMenu = undefined;

var _defineProperty2 = __webpack_require__(11);

var _defineProperty3 = _interopRequireDefault(_defineProperty2);

var _menu = __webpack_require__(3136);

var _menu2 = _interopRequireDefault(_menu);

var _objectWithoutProperties2 = __webpack_require__(26);

var _objectWithoutProperties3 = _interopRequireDefault(_objectWithoutProperties2);

var _isFunction2 = __webpack_require__(100);

var _isFunction3 = _interopRequireDefault(_isFunction2);

var _isObject2 = __webpack_require__(48);

var _isObject3 = _interopRequireDefault(_isObject2);

var _map2 = __webpack_require__(504);

var _map3 = _interopRequireDefault(_map2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _classnames2 = __webpack_require__(29);

var _classnames3 = _interopRequireDefault(_classnames2);

__webpack_require__(3140);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var ToolbarMenu = function ToolbarMenu(_ref) {
    var items = _ref.items,
        menuVisible = _ref.menuVisible,
        other = (0, _objectWithoutProperties3.default)(_ref, ['items', 'menuVisible']);

    if (!menuVisible) {
        return null;
    }
    return _react2.default.createElement(_menu2.default, Object.assign({}, other), (0, _map3.default)(items, function (item, index) {
        if (!(0, _isObject3.default)(item)) {
            return _react2.default.createElement(_menu2.default.Item, { key: item, className: "toolbar-menu-item toolbar-menu-item_text" }, item);
        }
        if (item.divider) {
            return _react2.default.createElement(_menu2.default.Divider, { key: index });
        }
        var Icon = item.icon,
            _item$key = item.key,
            key = _item$key === undefined ? index : _item$key;
        var _item$name = item.name,
            name = _item$name === undefined ? key : _item$name;

        var className = (0, _classnames3.default)('toolbar-menu-item', (0, _defineProperty3.default)({}, 'toolbar-menu-item_text', !Icon));
        return _react2.default.createElement(_menu2.default.Item, { key: key, className: className }, Icon && _react2.default.createElement(Icon, { className: "toolbar-menu-item__icon" }), (0, _isFunction3.default)(name) ? name() : name);
    }));
};
exports.ToolbarMenu = ToolbarMenu;

/***/ }),

/***/ 3136:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _defineProperty2 = __webpack_require__(11);

var _defineProperty3 = _interopRequireDefault(_defineProperty2);

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var React = _interopRequireWildcard(_react);

var _reactDom = __webpack_require__(21);

var _rcMenu = __webpack_require__(744);

var _rcMenu2 = _interopRequireDefault(_rcMenu);

var _propTypes = __webpack_require__(0);

var _propTypes2 = _interopRequireDefault(_propTypes);

var _classnames = __webpack_require__(29);

var _classnames2 = _interopRequireDefault(_classnames);

var _openAnimation = __webpack_require__(3137);

var _openAnimation2 = _interopRequireDefault(_openAnimation);

var _warning = __webpack_require__(1819);

var _warning2 = _interopRequireDefault(_warning);

var _SubMenu = __webpack_require__(3138);

var _SubMenu2 = _interopRequireDefault(_SubMenu);

var _MenuItem = __webpack_require__(3139);

var _MenuItem2 = _interopRequireDefault(_MenuItem);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj['default'] = obj; return newObj; } }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

var Menu = function (_React$Component) {
    (0, _inherits3['default'])(Menu, _React$Component);

    function Menu(props) {
        (0, _classCallCheck3['default'])(this, Menu);

        var _this = (0, _possibleConstructorReturn3['default'])(this, (Menu.__proto__ || Object.getPrototypeOf(Menu)).call(this, props));

        _this.inlineOpenKeys = [];
        _this.handleClick = function (e) {
            _this.handleOpenChange([]);
            var onClick = _this.props.onClick;

            if (onClick) {
                onClick(e);
            }
        };
        _this.handleOpenChange = function (openKeys) {
            _this.setOpenKeys(openKeys);
            var onOpenChange = _this.props.onOpenChange;

            if (onOpenChange) {
                onOpenChange(openKeys);
            }
        };
        (0, _warning2['default'])(!('onOpen' in props || 'onClose' in props), '`onOpen` and `onClose` are removed, please use `onOpenChange` instead, ' + 'see: https://u.ant.design/menu-on-open-change.');
        (0, _warning2['default'])(!('inlineCollapsed' in props && props.mode !== 'inline'), '`inlineCollapsed` should only be used when Menu\'s `mode` is inline.');
        var openKeys = void 0;
        if ('defaultOpenKeys' in props) {
            openKeys = props.defaultOpenKeys;
        } else if ('openKeys' in props) {
            openKeys = props.openKeys;
        }
        _this.state = {
            openKeys: openKeys || []
        };
        return _this;
    }

    (0, _createClass3['default'])(Menu, [{
        key: 'getChildContext',
        value: function getChildContext() {
            return {
                inlineCollapsed: this.getInlineCollapsed(),
                antdMenuTheme: this.props.theme
            };
        }
    }, {
        key: 'componentWillReceiveProps',
        value: function componentWillReceiveProps(nextProps, nextContext) {
            var prefixCls = this.props.prefixCls;

            if (this.props.mode === 'inline' && nextProps.mode !== 'inline') {
                this.switchModeFromInline = true;
            }
            if ('openKeys' in nextProps) {
                this.setState({ openKeys: nextProps.openKeys });
                return;
            }
            if (nextProps.inlineCollapsed && !this.props.inlineCollapsed || nextContext.siderCollapsed && !this.context.siderCollapsed) {
                var menuNode = (0, _reactDom.findDOMNode)(this);
                this.switchModeFromInline = !!this.state.openKeys.length && !!menuNode.querySelectorAll('.' + prefixCls + '-submenu-open').length;
                this.inlineOpenKeys = this.state.openKeys;
                this.setState({ openKeys: [] });
            }
            if (!nextProps.inlineCollapsed && this.props.inlineCollapsed || !nextContext.siderCollapsed && this.context.siderCollapsed) {
                this.setState({ openKeys: this.inlineOpenKeys });
                this.inlineOpenKeys = [];
            }
        }
    }, {
        key: 'setOpenKeys',
        value: function setOpenKeys(openKeys) {
            if (!('openKeys' in this.props)) {
                this.setState({ openKeys: openKeys });
            }
        }
    }, {
        key: 'getRealMenuMode',
        value: function getRealMenuMode() {
            var inlineCollapsed = this.getInlineCollapsed();
            if (this.switchModeFromInline && inlineCollapsed) {
                return 'inline';
            }
            var mode = this.props.mode;

            return inlineCollapsed ? 'vertical' : mode;
        }
    }, {
        key: 'getInlineCollapsed',
        value: function getInlineCollapsed() {
            var inlineCollapsed = this.props.inlineCollapsed;

            if (this.context.siderCollapsed !== undefined) {
                return this.context.siderCollapsed;
            }
            return inlineCollapsed;
        }
    }, {
        key: 'getMenuOpenAnimation',
        value: function getMenuOpenAnimation(menuMode) {
            var _this2 = this;

            var _props = this.props,
                openAnimation = _props.openAnimation,
                openTransitionName = _props.openTransitionName;

            var menuOpenAnimation = openAnimation || openTransitionName;
            if (openAnimation === undefined && openTransitionName === undefined) {
                switch (menuMode) {
                    case 'horizontal':
                        menuOpenAnimation = 'slide-up';
                        break;
                    case 'vertical':
                    case 'vertical-left':
                    case 'vertical-right':
                        // When mode switch from inline
                        // submenu should hide without animation
                        if (this.switchModeFromInline) {
                            menuOpenAnimation = '';
                            this.switchModeFromInline = false;
                        } else {
                            menuOpenAnimation = 'zoom-big';
                        }
                        break;
                    case 'inline':
                        menuOpenAnimation = (0, _extends3['default'])({}, _openAnimation2['default'], { leave: function leave(node, done) {
                                return _openAnimation2['default'].leave(node, function () {
                                    // Make sure inline menu leave animation finished before mode is switched
                                    _this2.switchModeFromInline = false;
                                    _this2.setState({});
                                    // when inlineCollapsed change false to true, all submenu will be unmounted,
                                    // so that we don't need handle animation leaving.
                                    if (_this2.getRealMenuMode() === 'vertical') {
                                        return;
                                    }
                                    done();
                                });
                            } });
                        break;
                    default:
                }
            }
            return menuOpenAnimation;
        }
    }, {
        key: 'render',
        value: function render() {
            var _props2 = this.props,
                prefixCls = _props2.prefixCls,
                className = _props2.className,
                theme = _props2.theme;

            var menuMode = this.getRealMenuMode();
            var menuOpenAnimation = this.getMenuOpenAnimation(menuMode);
            var menuClassName = (0, _classnames2['default'])(className, prefixCls + '-' + theme, (0, _defineProperty3['default'])({}, prefixCls + '-inline-collapsed', this.getInlineCollapsed()));
            var menuProps = {
                openKeys: this.state.openKeys,
                onOpenChange: this.handleOpenChange,
                className: menuClassName,
                mode: menuMode
            };
            if (menuMode !== 'inline') {
                // closing vertical popup submenu after click it
                menuProps.onClick = this.handleClick;
                menuProps.openTransitionName = menuOpenAnimation;
            } else {
                menuProps.openAnimation = menuOpenAnimation;
            }
            // https://github.com/ant-design/ant-design/issues/8587
            var collapsedWidth = this.context.collapsedWidth;

            if (this.getInlineCollapsed() && (collapsedWidth === 0 || collapsedWidth === '0' || collapsedWidth === '0px')) {
                return null;
            }
            return React.createElement(_rcMenu2['default'], (0, _extends3['default'])({}, this.props, menuProps));
        }
    }]);
    return Menu;
}(React.Component);

exports['default'] = Menu;

Menu.Divider = _rcMenu.Divider;
Menu.Item = _MenuItem2['default'];
Menu.SubMenu = _SubMenu2['default'];
Menu.ItemGroup = _rcMenu.ItemGroup;
Menu.defaultProps = {
    prefixCls: 'ant-menu',
    className: '',
    theme: 'light',
    focusable: false
};
Menu.childContextTypes = {
    inlineCollapsed: _propTypes2['default'].bool,
    antdMenuTheme: _propTypes2['default'].string
};
Menu.contextTypes = {
    siderCollapsed: _propTypes2['default'].bool,
    collapsedWidth: _propTypes2['default'].oneOfType([_propTypes2['default'].number, _propTypes2['default'].string])
};
module.exports = exports['default'];

/***/ }),

/***/ 3137:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _cssAnimation = __webpack_require__(497);

var _cssAnimation2 = _interopRequireDefault(_cssAnimation);

var _raf = __webpack_require__(397);

var _raf2 = _interopRequireDefault(_raf);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

function animate(node, show, done) {
    var height = void 0;
    var requestAnimationFrameId = void 0;
    return (0, _cssAnimation2['default'])(node, 'ant-motion-collapse', {
        start: function start() {
            if (!show) {
                node.style.height = node.offsetHeight + 'px';
                node.style.opacity = '1';
            } else {
                height = node.offsetHeight;
                node.style.height = '0px';
                node.style.opacity = '0';
            }
        },
        active: function active() {
            if (requestAnimationFrameId) {
                _raf2['default'].cancel(requestAnimationFrameId);
            }
            requestAnimationFrameId = (0, _raf2['default'])(function () {
                node.style.height = (show ? height : 0) + 'px';
                node.style.opacity = show ? '1' : '0';
            });
        },
        end: function end() {
            if (requestAnimationFrameId) {
                _raf2['default'].cancel(requestAnimationFrameId);
            }
            node.style.height = '';
            node.style.opacity = '';
            done();
        }
    });
}
var animation = {
    enter: function enter(node, done) {
        return animate(node, true, done);
    },
    leave: function leave(node, done) {
        return animate(node, false, done);
    },
    appear: function appear(node, done) {
        return animate(node, true, done);
    }
};
exports['default'] = animation;
module.exports = exports['default'];

/***/ }),

/***/ 3138:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var React = _interopRequireWildcard(_react);

var _propTypes = __webpack_require__(0);

var _propTypes2 = _interopRequireDefault(_propTypes);

var _rcMenu = __webpack_require__(744);

var _classnames = __webpack_require__(29);

var _classnames2 = _interopRequireDefault(_classnames);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj['default'] = obj; return newObj; } }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

var SubMenu = function (_React$Component) {
    (0, _inherits3['default'])(SubMenu, _React$Component);

    function SubMenu() {
        (0, _classCallCheck3['default'])(this, SubMenu);

        var _this = (0, _possibleConstructorReturn3['default'])(this, (SubMenu.__proto__ || Object.getPrototypeOf(SubMenu)).apply(this, arguments));

        _this.onKeyDown = function (e) {
            _this.subMenu.onKeyDown(e);
        };
        _this.saveSubMenu = function (subMenu) {
            _this.subMenu = subMenu;
        };
        return _this;
    }

    (0, _createClass3['default'])(SubMenu, [{
        key: 'render',
        value: function render() {
            var _props = this.props,
                rootPrefixCls = _props.rootPrefixCls,
                className = _props.className;

            var theme = this.context.antdMenuTheme;
            return React.createElement(_rcMenu.SubMenu, (0, _extends3['default'])({}, this.props, { ref: this.saveSubMenu, popupClassName: (0, _classnames2['default'])(rootPrefixCls + '-' + theme, className) }));
        }
    }]);
    return SubMenu;
}(React.Component);

SubMenu.contextTypes = {
    antdMenuTheme: _propTypes2['default'].string
};
// fix issue:https://github.com/ant-design/ant-design/issues/8666
SubMenu.isSubMenu = 1;
exports['default'] = SubMenu;
module.exports = exports['default'];

/***/ }),

/***/ 3139:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var React = _interopRequireWildcard(_react);

var _rcMenu = __webpack_require__(744);

var _propTypes = __webpack_require__(0);

var _propTypes2 = _interopRequireDefault(_propTypes);

var _tooltip = __webpack_require__(1818);

var _tooltip2 = _interopRequireDefault(_tooltip);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj['default'] = obj; return newObj; } }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

var MenuItem = function (_React$Component) {
    (0, _inherits3['default'])(MenuItem, _React$Component);

    function MenuItem() {
        (0, _classCallCheck3['default'])(this, MenuItem);

        var _this = (0, _possibleConstructorReturn3['default'])(this, (MenuItem.__proto__ || Object.getPrototypeOf(MenuItem)).apply(this, arguments));

        _this.onKeyDown = function (e) {
            _this.menuItem.onKeyDown(e);
        };
        _this.saveMenuItem = function (menuItem) {
            _this.menuItem = menuItem;
        };
        return _this;
    }

    (0, _createClass3['default'])(MenuItem, [{
        key: 'render',
        value: function render() {
            var inlineCollapsed = this.context.inlineCollapsed;

            var props = this.props;
            return React.createElement(
                _tooltip2['default'],
                { title: inlineCollapsed && props.level === 1 ? props.children : '', placement: 'right', overlayClassName: props.rootPrefixCls + '-inline-collapsed-tooltip' },
                React.createElement(_rcMenu.Item, (0, _extends3['default'])({}, props, { ref: this.saveMenuItem }))
            );
        }
    }]);
    return MenuItem;
}(React.Component);

MenuItem.contextTypes = {
    inlineCollapsed: _propTypes2['default'].bool
};
MenuItem.isMenuItem = 1;
exports['default'] = MenuItem;
module.exports = exports['default'];

/***/ }),

/***/ 3140:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3141:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.ToolbarComboButton = undefined;

var _objectWithoutProperties2 = __webpack_require__(26);

var _objectWithoutProperties3 = _interopRequireDefault(_objectWithoutProperties2);

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _pickBy2 = __webpack_require__(2054);

var _pickBy3 = _interopRequireDefault(_pickBy2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _ToolbarMenuButton = __webpack_require__(2051);

var _ToolbarButton = __webpack_require__(1679);

__webpack_require__(2055);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var ToolbarComboButton = exports.ToolbarComboButton = function (_React$Component) {
    (0, _inherits3.default)(ToolbarComboButton, _React$Component);

    function ToolbarComboButton() {
        (0, _classCallCheck3.default)(this, ToolbarComboButton);

        var _this = (0, _possibleConstructorReturn3.default)(this, (ToolbarComboButton.__proto__ || Object.getPrototypeOf(ToolbarComboButton)).apply(this, arguments));

        _this.state = {
            menuVisible: false
        };
        _this.onMenuVisibleChange = function (visible) {
            _this.setState({
                menuVisible: visible
            });
            var onMenuVisibleChange = _this.props.onMenuVisibleChange;

            if (onMenuVisibleChange) {
                onMenuVisibleChange(visible);
            }
        };
        return _this;
    }

    (0, _createClass3.default)(ToolbarComboButton, [{
        key: 'render',
        value: function render() {
            var _props = this.props,
                id = _props.id,
                title = _props.title,
                children = _props.children,
                menu = _props.menu,
                buttonProps = _props.buttonProps,
                menuButtonProps = _props.menuButtonProps,
                onMenuVisibleChange = _props.onMenuVisibleChange,
                other = (0, _objectWithoutProperties3.default)(_props, ['id', 'title', 'children', 'menu', 'buttonProps', 'menuButtonProps', 'onMenuVisibleChange']);
            var menuVisible = this.state.menuVisible;

            var childProps = (0, _pickBy3.default)(other, function (value, key) {
                return !/^on[A-Z]/.test(key);
            });
            return _react2.default.createElement(_ToolbarButton.ToolbarButton, Object.assign({ id: id, blockClass: "toolbar-combo-button", title: title, tipHidden: menuVisible }, other), _react2.default.createElement(_ToolbarButton.ToolbarButton, Object.assign({}, childProps, buttonProps), children), _react2.default.createElement(_ToolbarMenuButton.ToolbarMenuButton, Object.assign({ menu: menu }, childProps, menuButtonProps, { onMenuVisibleChange: this.onMenuVisibleChange })));
        }
    }]);
    return ToolbarComboButton;
}(_react2.default.Component);

/***/ }),

/***/ 3142:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.ToolbarDivider = undefined;

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

__webpack_require__(3143);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var ToolbarDivider = exports.ToolbarDivider = function ToolbarDivider() {
  return _react2.default.createElement("div", { className: "toolbar-divider" });
};

/***/ }),

/***/ 3143:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3144:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.ToolbarComplexComboButton = undefined;

var _typeof2 = __webpack_require__(76);

var _typeof3 = _interopRequireDefault(_typeof2);

var _objectWithoutProperties2 = __webpack_require__(26);

var _objectWithoutProperties3 = _interopRequireDefault(_objectWithoutProperties2);

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _pickBy2 = __webpack_require__(2054);

var _pickBy3 = _interopRequireDefault(_pickBy2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _ToolbarButton = __webpack_require__(1679);

var _caret = __webpack_require__(2053);

var _caret2 = _interopRequireDefault(_caret);

__webpack_require__(2055);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var ToolbarComplexComboButton = exports.ToolbarComplexComboButton = function (_React$Component) {
    (0, _inherits3.default)(ToolbarComplexComboButton, _React$Component);

    function ToolbarComplexComboButton() {
        (0, _classCallCheck3.default)(this, ToolbarComplexComboButton);

        var _this = (0, _possibleConstructorReturn3.default)(this, (ToolbarComplexComboButton.__proto__ || Object.getPrototypeOf(ToolbarComplexComboButton)).apply(this, arguments));

        _this.state = {
            menuVisible: false
        };
        _this.onMenuVisibleChange = function (visible) {
            _this.setState({
                menuVisible: visible
            });
            var onMenuVisibleChange = _this.props.onMenuVisibleChange;

            if (onMenuVisibleChange) {
                onMenuVisibleChange(visible);
            }
        };
        return _this;
    }

    (0, _createClass3.default)(ToolbarComplexComboButton, [{
        key: 'render',
        value: function render() {
            var _props = this.props,
                id = _props.id,
                title = _props.title,
                children = _props.children,
                buttonProps = _props.buttonProps,
                menuButtonProps = _props.menuButtonProps,
                onMenuVisibleChange = _props.onMenuVisibleChange,
                tipHidden = _props.tipHidden,
                other = (0, _objectWithoutProperties3.default)(_props, ['id', 'title', 'children', 'buttonProps', 'menuButtonProps', 'onMenuVisibleChange', 'tipHidden']);

            var childProps = (0, _pickBy3.default)(other, function (value, key) {
                return !/^on[A-Z]/.test(key);
            });
            var isHidden = (typeof tipHidden === 'undefined' ? 'undefined' : (0, _typeof3.default)(tipHidden)) !== undefined ? tipHidden : this.state.menuVisible;
            return _react2.default.createElement(_ToolbarButton.ToolbarButton, Object.assign({ id: id, blockClass: "toolbar-combo-button", title: title, tipHidden: isHidden }, other), _react2.default.createElement(_ToolbarButton.ToolbarButton, Object.assign({}, childProps, buttonProps), children), _react2.default.createElement("span", null, title), _react2.default.createElement(_caret2.default, { key: "caret", className: "toolbar-menu-button__caret" }));
        }
    }]);
    return ToolbarComplexComboButton;
}(_react2.default.Component);

/***/ }),

/***/ 3145:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});

var _slicedToArray2 = __webpack_require__(136);

var _slicedToArray3 = _interopRequireDefault(_slicedToArray2);

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _typeof2 = __webpack_require__(76);

var _typeof3 = _interopRequireDefault(_typeof2);

var _toolbar = __webpack_require__(1714);

var _sheet = __webpack_require__(713);

var _teaCollector = __webpack_require__(517);

var _teaCollector2 = _interopRequireDefault(_teaCollector);

var _bind = __webpack_require__(503);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _formatPainter = __webpack_require__(3146);

var _formatPainter2 = _interopRequireDefault(_formatPainter);

var _SheetToolbarItemHelper = __webpack_require__(1678);

var _shellNotify = __webpack_require__(1576);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var __decorate = undefined && undefined.__decorate || function (decorators, target, key, desc) {
    var c = arguments.length,
        r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc,
        d;
    if ((typeof Reflect === "undefined" ? "undefined" : (0, _typeof3.default)(Reflect)) === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);else for (var i = decorators.length - 1; i >= 0; i--) {
        if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    }return c > 3 && r && Object.defineProperty(target, key, r), r;
};

var SHEET_HEAD_TOOLBAR = 'sheet_head_toolbar';
var SHEET_OPRATION = 'sheet_opration';

var FormatPainter = function (_React$Component) {
    (0, _inherits3.default)(FormatPainter, _React$Component);

    function FormatPainter() {
        (0, _classCallCheck3.default)(this, FormatPainter);

        var _this = (0, _possibleConstructorReturn3.default)(this, (FormatPainter.__proto__ || Object.getPrototypeOf(FormatPainter)).apply(this, arguments));

        _this.formatPainterClickCount = 0;
        _this.formatPainterTimeout = null;
        return _this;
    }

    (0, _createClass3.default)(FormatPainter, [{
        key: "componentDidMount",
        value: function componentDidMount() {
            window.addEventListener('keydown', this._onKeyDown);
            this.bindEvents(this.props.spread);
        }
    }, {
        key: "componentWillUpdate",
        value: function componentWillUpdate(nextProps) {
            if (this.props.spread !== nextProps.spread) {
                this.unbindEvents(this.props.spread);
            }
        }
    }, {
        key: "componentDidUpdate",
        value: function componentDidUpdate(prevProps) {
            var spread = this.props.spread;

            if (spread !== prevProps.spread) {
                this.bindEvents(spread);
            }
        }
    }, {
        key: "componentWillUnmount",
        value: function componentWillUnmount() {
            window.removeEventListener('keydown', this._onKeyDown);
            this.unbindEvents(this.props.spread);
            this.exit();
        }
    }, {
        key: "bindEvents",
        value: function bindEvents(spread) {
            if (spread == null) return;
            spread.bind(_sheet.Events.CellClick, this.formatNewRange);
            spread.bind('CommandExecuting', this.handleOtherCommands);
        }
    }, {
        key: "unbindEvents",
        value: function unbindEvents(spread) {
            if (spread == null) return;
            spread.unbind(_sheet.Events.CellClick, this.formatNewRange);
            spread.unbind('CommandExecuting', this.handleOtherCommands);
        }
    }, {
        key: "handleFormatPainterClick",
        value: function handleFormatPainterClick() {
            var _this2 = this;

            this.props.spread.focus();
            // 记录点击次数
            this.formatPainterClickCount += 1; // 每次点击都清除上次点击设置的定时器
            if (this.formatPainterTimeout) {
                clearTimeout(this.formatPainterTimeout);
                this.formatPainterTimeout = null;
            }
            // 如果 200ms 内点击超过两次，则为双击
            if (this.formatPainterClickCount >= 2) {
                this.formatPainterClickCount = 0;
                this.formatOnce = false;
                this.props.formatPainterToggle(true);
                this.setFormatPainter();
            } else {
                // 如果已经在使用格式刷，那么退出
                if (this.props.formatPainter.painterFormatting) {
                    this.formatPainterClickCount = 0;
                    this.exit();
                    return;
                }
                // 设置定时器判断是单击还是双击
                // 超时则为单击
                this.formatPainterTimeout = window.setTimeout(function () {
                    _this2.formatPainterTimeout = null;
                    _this2.formatPainterClickCount = 0;
                    _this2.formatOnce = true;
                    _this2.props.formatPainterToggle(true);
                    _this2.setFormatPainter();
                }, 200);
            }
        }
    }, {
        key: "formatNewRange",
        value: function formatNewRange(result) {
            // 不是使用格式刷，则不做任何事情
            if (!this.props.formatPainter.painterFormatting) return;
            var spread = this.props.spread;

            var sheet = spread.getActiveSheet();
            var newSelections = sheet.getSelections();

            var _newSelections = (0, _slicedToArray3.default)(newSelections, 1),
                toRange = _newSelections[0];

            var actualToRange = sheet._getActualRange(toRange);
            var toRangeRowCount = actualToRange.rowCount,
                toRangeColCount = actualToRange.colCount; // 计算需要重复多少次行和列，以及剩下多少行和列

            var rows = Math.floor(toRangeRowCount / this.rowCount);
            var cols = Math.floor(toRangeColCount / this.colCount); // 至少要应用一次
            if (rows === 0) {
                actualToRange.rowCount = this.rowCount;
            }
            if (cols === 0) {
                actualToRange.colCount = this.colCount;
            }
            if (this.rowHeight.length > 0 || this.colWidth.length > 0) {
                var toRangeSpans = sheet.getSpans(actualToRange);
                var isInvalid = false;
                for (var i = 0; i < toRangeSpans.length; i++) {
                    var span = sheet._getActualRange(toRangeSpans[i]);
                    if (!actualToRange.containsRange(span)) {
                        isInvalid = true;
                    }
                }
                if (isInvalid) {
                    if (this.formatOnce) {
                        this.exit();
                    }
                    sheet._raiseInvalidOperation(1, t('sheet.no_change_partof_cell'));
                    return;
                }
            }
            var commandManager = spread.commandManager();
            commandManager.execute({
                cmd: _sheet.Commands.FORMAT_PAINTER,
                sheetId: sheet.id(),
                fromRangeRowCount: this.rowCount,
                fromRangeColCount: this.colCount,
                toRangeRow: actualToRange.row,
                toRangeCol: actualToRange.col,
                toRangeRowCount: actualToRange.rowCount,
                toRangeColCount: actualToRange.colCount,
                rowHeight: this.rowHeight,
                colWidth: this.colWidth,
                styles: this.styles,
                spans: this.spans
            });
            var row = actualToRange.row,
                col = actualToRange.col,
                rowCount = actualToRange.rowCount,
                colCount = actualToRange.colCount;

            if (this.formatOnce) {
                this.exit();
            }
            var _rowCount = rowCount < this.rowCount ? this.rowCount : rowCount;
            var _colCount = colCount < this.colCount ? this.colCount : colCount;
            sheet.setSelection(row, col, _rowCount, _colCount);
        }
    }, {
        key: "exit",
        value: function exit() {
            if (!this.props.formatPainter.painterFormatting) {
                return;
            }
            this.props.formatPainterToggle(false);
            var sheet = this.props.spread.getActiveSheet();
            if (sheet) {
                sheet.notifyShell(_shellNotify.ShellNotifyType.UnSelectFormateFloatingObjs);
            }
        }
    }, {
        key: "handleOtherCommands",
        value: function handleOtherCommands(result, _ref) {
            var commandName = _ref.commandName,
                isUndo = _ref.isUndo;

            if (commandName !== _sheet.Commands.FORMAT_PAINTER || isUndo) {
                this.exit();
            }
        }
        /**
         * 1. 设置格式刷选中样式
         * 2. 储存选区的样式和选区中已有的合并单元格
         * @param {GC.Spread.Sheets.Workbook} spread
         * @param {boolean} formatOnce 是否使用一次
         */

    }, {
        key: "setFormatPainter",
        value: function setFormatPainter() {
            var spread = this.props.spread;

            var sheet = spread.getActiveSheet();
            var selections = sheet.getSelections();
            if (selections.length > 0) {
                sheet.notifyShell(_shellNotify.ShellNotifyType.SetFormatPainter);
            }
            if (selections.length === 1) {
                var _selections = (0, _slicedToArray3.default)(selections, 1),
                    range = _selections[0];

                range = sheet._getActualRange(range);
                this.rowCount = range.rowCount;
                this.colCount = range.colCount; // 储存样式，二维数组
                this.styles = []; // 储存列宽
                this.colWidth = [];
                if (range.row === 0 && range.rowCount === sheet.getRowCount()) {
                    for (var i = 0; i < range.colCount; i++) {
                        this.colWidth.push(sheet.getColumnWidth(range.col + i));
                    }
                } // 储存行高
                this.rowHeight = [];
                if (range.col === 0 && range.colCount === sheet.getColumnCount()) {
                    for (var _i = 0; _i < range.rowCount; _i++) {
                        this.rowHeight.push(sheet.getRowHeight(range.row + _i));
                    }
                }
                for (var _i2 = 0; _i2 < range.rowCount; _i2++) {
                    var ss = [];
                    for (var j = 0; j < range.colCount; j++) {
                        var cellRow = range.row + _i2;
                        var cellCol = range.col + j;
                        var cellStyle = sheet.getStyle(cellRow, cellCol);
                        var newStyle = cellStyle ? cellStyle.clone() : null;
                        if (newStyle && newStyle.cellType) {
                            delete newStyle.cellType;
                        }
                        ss.push(newStyle);
                    }
                    this.styles.push(ss);
                } // 储存合并单元格的相对位置
                this.spans = [];
                var spans = sheet.getSpans(range);
                var Range = GC.Spread.Sheets.Range;

                for (var _i3 = 0; _i3 < spans.length; _i3++) {
                    var span = spans[_i3];
                    if (range.containsRange(span)) {
                        this.spans.push(new Range(span.row - range.row, span.col - range.col, span.rowCount, span.colCount));
                    }
                }
            }
        }
    }, {
        key: "_onKeyDown",
        value: function _onKeyDown(e) {
            // esc 退出
            if (e.keyCode === 27) {
                this.exit();
            }
        }
    }, {
        key: "render",
        value: function render() {
            var _props = this.props,
                disabled = _props.disabled,
                active = _props.active,
                spread = _props.spread;

            var isEmbed = spread._context.embed;
            return _react2.default.createElement(_toolbar.ToolbarButton, { id: "sheet-format-painter", title: t('sheet.double_click_painter'), active: active, disabled: disabled, onClick: this.handleFormatPainterClick, tipTop: isEmbed }, (0, _SheetToolbarItemHelper.StateComponent)(_formatPainter2.default, 'svg'));
        }
    }]);
    return FormatPainter;
}(_react2.default.Component);

__decorate([(0, _bind.Bind)()], FormatPainter.prototype, "bindEvents", null);
__decorate([(0, _bind.Bind)()], FormatPainter.prototype, "unbindEvents", null);
__decorate([(0, _bind.Bind)(), (0, _teaCollector2.default)(SHEET_OPRATION, 'click', SHEET_HEAD_TOOLBAR, 'format_painter')], FormatPainter.prototype, "handleFormatPainterClick", null);
__decorate([(0, _bind.Bind)()], FormatPainter.prototype, "formatNewRange", null);
__decorate([(0, _bind.Bind)()], FormatPainter.prototype, "exit", null);
__decorate([(0, _bind.Bind)()], FormatPainter.prototype, "handleOtherCommands", null);
__decorate([(0, _bind.Bind)()], FormatPainter.prototype, "setFormatPainter", null);
__decorate([(0, _bind.Bind)()], FormatPainter.prototype, "_onKeyDown", null);
exports.default = FormatPainter;
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 3146:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M16 7h1a2 2 0 0 1 2 2v3.02a2 2 0 0 1-2 2h-5a1 1 0 0 0-1 1V19a1 1 0 0 1-2 0v-3.98a3 3 0 0 1 3-3h5V9h-1v1.5a.5.5 0 0 1-.5.5h-10a.5.5 0 0 1-.5-.5v-5c0-.28.22-.5.5-.5h10c.28 0 .5.22.5.5V7zM7 7v2h7V7H7z", fillRule: "nonzero" })
  );
};

/***/ }),

/***/ 3147:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.FreezeItem = undefined;

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _isEqual2 = __webpack_require__(501);

var _isEqual3 = _interopRequireDefault(_isEqual2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _toolbar = __webpack_require__(1714);

var _toolbarHelper = __webpack_require__(1606);

var _tea = __webpack_require__(47);

var _freezeRow = __webpack_require__(3148);

var _freezeRow2 = _interopRequireDefault(_freezeRow);

var _freezeCol = __webpack_require__(3149);

var _freezeCol2 = _interopRequireDefault(_freezeCol);

var _freezeCell = __webpack_require__(3150);

var _freezeCell2 = _interopRequireDefault(_freezeCell);

var _unfreeze = __webpack_require__(3151);

var _unfreeze2 = _interopRequireDefault(_unfreeze);

var _string = __webpack_require__(158);

var _SheetToolbarItemHelper = __webpack_require__(1678);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var SHEET_HEAD_TOOLBAR = 'sheet_head_toolbar';
var SHEET_OPRATION = 'sheet_opration';

var FreezeItem = exports.FreezeItem = function (_React$Component) {
    (0, _inherits3.default)(FreezeItem, _React$Component);

    function FreezeItem(props) {
        (0, _classCallCheck3.default)(this, FreezeItem);

        var _this = (0, _possibleConstructorReturn3.default)(this, (FreezeItem.__proto__ || Object.getPrototypeOf(FreezeItem)).call(this, props));

        _this.handleMenuVisible = function (visible) {
            if (visible) {
                (0, _tea.collectSuiteEvent)(SHEET_OPRATION, {
                    action: 'freeze_open',
                    source: SHEET_HEAD_TOOLBAR,
                    eventType: 'click'
                });
            }
        };
        _this.handleFreezeClick = function (key) {
            (0, _tea.collectSuiteEvent)(SHEET_OPRATION, {
                action: 'freeze',
                op_item: key,
                source: SHEET_HEAD_TOOLBAR,
                eventType: 'click'
            });
            var items = _this.state.items;
            var item = items.find(function (it) {
                return it.key === key;
            });
            if (!item) return;
            var fzItem = item;
            (0, _toolbarHelper.freezeSheet)(_this.props.spread, fzItem.row, fzItem.col);
            _this.props.spread.focus();
        };
        _this.state = {
            items: []
        };
        return _this;
    }

    (0, _createClass3.default)(FreezeItem, [{
        key: 'shouldComponentUpdate',
        value: function shouldComponentUpdate(nextProps, nextState) {
            var currProps = this.props;
            var currState = this.state;
            return !(0, _isEqual3.default)(nextProps, currProps) || !(0, _isEqual3.default)(nextState, currState);
        }
    }, {
        key: '_refreshItems',
        value: function _refreshItems() {
            var ws = this.props.spread.getActiveSheet();
            var rgs = ws.getSelections();
            var rg = rgs.pop();
            if (!rg) {
                this.setState({
                    items: []
                });
                return;
            }
            var fzRow = ws.frozenRowCount();
            var fzCol = ws.frozenColumnCount();
            var acRow = Math.max(rg.row, 0) + rg.rowCount;
            var acCol = Math.max(rg.col, 0) + rg.colCount;
            if (acRow === ws.getRowCount()) acRow = 1;
            if (acCol === ws.getColumnCount()) acCol = 1;
            var items = [];
            var addItem = function addItem(icon, name, key, row, col) {
                return items.push({
                    icon: icon,
                    name: name,
                    key: key,
                    row: row,
                    col: col
                });
            };
            if (fzRow !== acRow) {
                var fzRowName = acRow > 1 ? t('sheet.freeze_row', acRow) : t('sheet.freeze_first_row', acRow);
                addItem(_freezeRow2.default, fzRowName, 'fz-row', acRow, -1);
            }
            if (fzCol !== acCol) {
                var fzColName = acCol > 1 ? t('sheet.freeze_col', (0, _string.intToAZ)(acCol - 1)) : t('sheet.freeze_first_col', (0, _string.intToAZ)(acCol - 1));
                addItem(_freezeCol2.default, fzColName, 'fz-col', -1, acCol);
            }
            if (acRow && acCol && (acRow !== fzRow || acCol !== fzCol)) {
                addItem(_freezeCell2.default, t('sheet.freeze_to_row_col', acRow, (0, _string.intToAZ)(acCol - 1)), 'fz-row-col', acRow, acCol);
            }
            if (fzRow || fzCol) {
                if (items.length) {
                    items.push({
                        divider: true
                    });
                }
                addItem(_unfreeze2.default, t('sheet.cancel_freeze'), 'unfreeze', 0, 0);
            }
            this.setState({
                items: items
            });
        }
    }, {
        key: 'render',
        value: function render() {
            var _this2 = this;

            return _react2.default.createElement(_toolbar.ToolbarMenuButton, { id: "sheet-freeze", title: t('sheet.freeze_row_col'), disabled: this.props.disabled, onClick: function onClick(e) {
                    return _this2._refreshItems();
                }, onMenuVisibleChange: this.handleMenuVisible, menu: _react2.default.createElement(_toolbar.ToolbarMenu, { id: "freeze-menu", selectable: false, onClick: function onClick(e) {
                        return _this2.handleFreezeClick(e.key);
                    }, items: this.state.items }) }, (0, _SheetToolbarItemHelper.StateComponent)(_freezeRow2.default, 'svg'));
        }
    }]);
    return FreezeItem;
}(_react2.default.Component);
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 3148:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M15.96 7h-2.3l-1.74 3h2.31l1.73-3zm1.04.2L15.39 10H17V7.2zM12.5 7h-2.3l-1.74 3h2.3l1.74-3zM9.04 7H7v3h.3l1.74-3zM17 12H7v5h10v-5zM5.5 5h13c.28 0 .5.22.5.5v13a.5.5 0 0 1-.5.5h-13a.5.5 0 0 1-.5-.5v-13c0-.28.22-.5.5-.5z", fillRule: "nonzero" })
  );
};

/***/ }),

/***/ 3149:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M7 8.04v2.3l3 1.74V9.77L7 8.04zM7.2 7L10 8.61V7H7.2zM7 11.5v2.3l3 1.74v-2.3L7 11.5zm0 3.46V17h3v-.3l-3-1.74zM12 7v10h5V7h-5zM5 18.5v-13c0-.28.22-.5.5-.5h13c.28 0 .5.22.5.5v13a.5.5 0 0 1-.5.5h-13a.5.5 0 0 1-.5-.5z", fillRule: "nonzero" })
  );
};

/***/ }),

/***/ 3150:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M12 16.65V17h5v-5h-5v4.65zM19 5.5v13a.5.5 0 0 1-.5.5h-13a.5.5 0 0 1-.5-.5v-13c0-.28.22-.5.5-.5h13c.28 0 .5.22.5.5zm-2 1.9V7h-2.42l-3 3h2.83L17 7.4zm0 1.42L15.82 10H17V8.82zm-7 5.59v-2.83l-3 3V17h.4l2.6-2.6zm0 1.41L8.82 17H10v-1.18zM13.17 7h-2.83L7 10.34v2.83L13.17 7zM8.92 7H7v1.92L8.92 7z", fillRule: "nonzero" })
  );
};

/***/ }),

/***/ 3151:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M10 18v-2h2v2h5.5a.5.5 0 0 0 .5-.5V12h-2v-2h2V6.5a.5.5 0 0 0-.5-.5h-11a.5.5 0 0 0-.5.5v11c0 .28.22.5.5.5H10zM6 4h12a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6c0-1.1.9-2 2-2zm7 6h2v2h-2v-2zm-3 0h2v2h-2v-2zm0 3h2v2h-2v-2z", fillRule: "nonzero" })
  );
};

/***/ }),

/***/ 3152:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.ColorPicker = undefined;

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _more_color = __webpack_require__(3153);

var _more_color2 = _interopRequireDefault(_more_color);

var _chromePicker = __webpack_require__(3154);

var _swatchesPicker = __webpack_require__(3166);

__webpack_require__(3172);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var ColorPicker = exports.ColorPicker = function (_React$Component) {
    (0, _inherits3.default)(ColorPicker, _React$Component);

    function ColorPicker() {
        (0, _classCallCheck3.default)(this, ColorPicker);

        var _this = (0, _possibleConstructorReturn3.default)(this, (ColorPicker.__proto__ || Object.getPrototypeOf(ColorPicker)).apply(this, arguments));

        _this.state = {
            currPicker: 'swatchPicker'
        };
        _this.togglePicker = function () {
            _this.setState({
                currPicker: 'chromePicker'
            });
        };
        return _this;
    }

    (0, _createClass3.default)(ColorPicker, [{
        key: 'componentDidUpdate',
        value: function componentDidUpdate(nextProps) {
            if (!nextProps.menuVisible) {
                this.setState({
                    currPicker: 'swatchPicker'
                });
            }
        }
    }, {
        key: 'render',
        value: function render() {
            var currPicker = this.state.currPicker;

            return _react2.default.createElement("div", { className: "color-picker sheet-color-picker", "data-sheet-component": true }, currPicker === 'chromePicker' ? _react2.default.createElement(_chromePicker.ChromePicker, Object.assign({}, this.props, { onClick: this.props.onClick })) : _react2.default.createElement(_react.Fragment, null, _react2.default.createElement(_swatchesPicker.SwatchesPicker, Object.assign({}, this.props, { onClick: this.props.onClick })), _react2.default.createElement("div", { className: "color-picker__more layout-row layout-main-cross-center", onClick: this.togglePicker }, _react2.default.createElement("img", { src: _more_color2.default, width: "16", height: "16" }), _react2.default.createElement("span", { style: {
                    verticalAlign: 'top',
                    marginLeft: 8
                } }, t('sheet.more_color')))));
        }
    }]);
    return ColorPicker;
}(_react2.default.Component);
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 3153:
/***/ (function(module, exports, __webpack_require__) {

module.exports = __webpack_require__.p + "images/more_color.png";

/***/ }),

/***/ 3154:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.ChromePicker = undefined;

var _ChromePicker = __webpack_require__(3155);

var _ChromePicker2 = _interopRequireDefault(_ChromePicker);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.ChromePicker = _ChromePicker2.default;

/***/ }),

/***/ 3155:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _ColorWrap = __webpack_require__(2057);

var _Hue = __webpack_require__(3158);

var _Checkboard = __webpack_require__(3161);

var _Saturation = __webpack_require__(3163);

__webpack_require__(3165);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var ChromePicker = function (_React$PureComponent) {
    (0, _inherits3.default)(ChromePicker, _React$PureComponent);

    function ChromePicker() {
        (0, _classCallCheck3.default)(this, ChromePicker);
        return (0, _possibleConstructorReturn3.default)(this, (ChromePicker.__proto__ || Object.getPrototypeOf(ChromePicker)).apply(this, arguments));
    }

    (0, _createClass3.default)(ChromePicker, [{
        key: 'render',
        value: function render() {
            var _props = this.props,
                hsl = _props.hsl,
                hsv = _props.hsv,
                onChange = _props.onChange,
                hex = _props.hex;

            return _react2.default.createElement("div", { className: "chrome-picker" }, _react2.default.createElement(_Saturation.Saturation, { className: "chrome-picker__saturation", hsl: hsl, hsv: hsv, onChange: onChange }), _react2.default.createElement(_Hue.Hue, { className: "chrome-picker__hue", hsl: hsl, onChange: onChange }), _react2.default.createElement(_Checkboard.Checkboard, { backgroundColor: hex }));
        }
    }]);
    return ChromePicker;
}(_react2.default.PureComponent);

function Wrapper(Picker) {
    return function (_React$PureComponent2) {
        (0, _inherits3.default)(ColorPicker, _React$PureComponent2);

        function ColorPicker() {
            (0, _classCallCheck3.default)(this, ColorPicker);

            var _this2 = (0, _possibleConstructorReturn3.default)(this, (ColorPicker.__proto__ || Object.getPrototypeOf(ColorPicker)).apply(this, arguments));

            _this2.handleChange = function (color) {
                _this2.color = color;
            };
            _this2.handleClick = function () {
                _this2.props.onClick && _this2.props.onClick(_this2.color);
            };
            return _this2;
        }

        (0, _createClass3.default)(ColorPicker, [{
            key: 'render',
            value: function render() {
                return _react2.default.createElement(_react.Fragment, null, _react2.default.createElement(Picker, { color: this.props.color, onChangeComplete: this.handleChange }), _react2.default.createElement("button", { className: "chrome-picker__button", onClick: this.handleClick }, t('common.determine')));
            }
        }]);
        return ColorPicker;
    }(_react2.default.PureComponent);
}
exports.default = Wrapper((0, _ColorWrap.ColorWrap)(ChromePicker));
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 3156:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.toState = toState;

var _tinycolor = __webpack_require__(3157);

var _tinycolor2 = _interopRequireDefault(_tinycolor);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function toState(data, oldHue) {
    var color = data.hex ? (0, _tinycolor2.default)(data.hex) : (0, _tinycolor2.default)(data);
    var hsl = color.toHsl();
    var hsv = color.toHsv();
    var rgb = color.toRgb();
    var hex = color.toHex();
    if (hsl.s === 0) {
        hsl.h = oldHue || 0;
        hsv.h = oldHue || 0;
    }
    var transparent = hex === '000000' && rgb.a === 0;
    return {
        hsl: hsl,
        hex: transparent ? 'transparent' : '#' + hex,
        rgb: rgb,
        hsv: hsv,
        oldHue: data.h || oldHue || hsl.h
    };
}

/***/ }),

/***/ 3157:
/***/ (function(module, exports, __webpack_require__) {

var __WEBPACK_AMD_DEFINE_RESULT__;// TinyColor v1.4.1
// https://github.com/bgrins/TinyColor
// Brian Grinstead, MIT License

(function(Math) {

var trimLeft = /^\s+/,
    trimRight = /\s+$/,
    tinyCounter = 0,
    mathRound = Math.round,
    mathMin = Math.min,
    mathMax = Math.max,
    mathRandom = Math.random;

function tinycolor (color, opts) {

    color = (color) ? color : '';
    opts = opts || { };

    // If input is already a tinycolor, return itself
    if (color instanceof tinycolor) {
       return color;
    }
    // If we are called as a function, call using new instead
    if (!(this instanceof tinycolor)) {
        return new tinycolor(color, opts);
    }

    var rgb = inputToRGB(color);
    this._originalInput = color,
    this._r = rgb.r,
    this._g = rgb.g,
    this._b = rgb.b,
    this._a = rgb.a,
    this._roundA = mathRound(100*this._a) / 100,
    this._format = opts.format || rgb.format;
    this._gradientType = opts.gradientType;

    // Don't let the range of [0,255] come back in [0,1].
    // Potentially lose a little bit of precision here, but will fix issues where
    // .5 gets interpreted as half of the total, instead of half of 1
    // If it was supposed to be 128, this was already taken care of by `inputToRgb`
    if (this._r < 1) { this._r = mathRound(this._r); }
    if (this._g < 1) { this._g = mathRound(this._g); }
    if (this._b < 1) { this._b = mathRound(this._b); }

    this._ok = rgb.ok;
    this._tc_id = tinyCounter++;
}

tinycolor.prototype = {
    isDark: function() {
        return this.getBrightness() < 128;
    },
    isLight: function() {
        return !this.isDark();
    },
    isValid: function() {
        return this._ok;
    },
    getOriginalInput: function() {
      return this._originalInput;
    },
    getFormat: function() {
        return this._format;
    },
    getAlpha: function() {
        return this._a;
    },
    getBrightness: function() {
        //http://www.w3.org/TR/AERT#color-contrast
        var rgb = this.toRgb();
        return (rgb.r * 299 + rgb.g * 587 + rgb.b * 114) / 1000;
    },
    getLuminance: function() {
        //http://www.w3.org/TR/2008/REC-WCAG20-20081211/#relativeluminancedef
        var rgb = this.toRgb();
        var RsRGB, GsRGB, BsRGB, R, G, B;
        RsRGB = rgb.r/255;
        GsRGB = rgb.g/255;
        BsRGB = rgb.b/255;

        if (RsRGB <= 0.03928) {R = RsRGB / 12.92;} else {R = Math.pow(((RsRGB + 0.055) / 1.055), 2.4);}
        if (GsRGB <= 0.03928) {G = GsRGB / 12.92;} else {G = Math.pow(((GsRGB + 0.055) / 1.055), 2.4);}
        if (BsRGB <= 0.03928) {B = BsRGB / 12.92;} else {B = Math.pow(((BsRGB + 0.055) / 1.055), 2.4);}
        return (0.2126 * R) + (0.7152 * G) + (0.0722 * B);
    },
    setAlpha: function(value) {
        this._a = boundAlpha(value);
        this._roundA = mathRound(100*this._a) / 100;
        return this;
    },
    toHsv: function() {
        var hsv = rgbToHsv(this._r, this._g, this._b);
        return { h: hsv.h * 360, s: hsv.s, v: hsv.v, a: this._a };
    },
    toHsvString: function() {
        var hsv = rgbToHsv(this._r, this._g, this._b);
        var h = mathRound(hsv.h * 360), s = mathRound(hsv.s * 100), v = mathRound(hsv.v * 100);
        return (this._a == 1) ?
          "hsv("  + h + ", " + s + "%, " + v + "%)" :
          "hsva(" + h + ", " + s + "%, " + v + "%, "+ this._roundA + ")";
    },
    toHsl: function() {
        var hsl = rgbToHsl(this._r, this._g, this._b);
        return { h: hsl.h * 360, s: hsl.s, l: hsl.l, a: this._a };
    },
    toHslString: function() {
        var hsl = rgbToHsl(this._r, this._g, this._b);
        var h = mathRound(hsl.h * 360), s = mathRound(hsl.s * 100), l = mathRound(hsl.l * 100);
        return (this._a == 1) ?
          "hsl("  + h + ", " + s + "%, " + l + "%)" :
          "hsla(" + h + ", " + s + "%, " + l + "%, "+ this._roundA + ")";
    },
    toHex: function(allow3Char) {
        return rgbToHex(this._r, this._g, this._b, allow3Char);
    },
    toHexString: function(allow3Char) {
        return '#' + this.toHex(allow3Char);
    },
    toHex8: function(allow4Char) {
        return rgbaToHex(this._r, this._g, this._b, this._a, allow4Char);
    },
    toHex8String: function(allow4Char) {
        return '#' + this.toHex8(allow4Char);
    },
    toRgb: function() {
        return { r: mathRound(this._r), g: mathRound(this._g), b: mathRound(this._b), a: this._a };
    },
    toRgbString: function() {
        return (this._a == 1) ?
          "rgb("  + mathRound(this._r) + ", " + mathRound(this._g) + ", " + mathRound(this._b) + ")" :
          "rgba(" + mathRound(this._r) + ", " + mathRound(this._g) + ", " + mathRound(this._b) + ", " + this._roundA + ")";
    },
    toPercentageRgb: function() {
        return { r: mathRound(bound01(this._r, 255) * 100) + "%", g: mathRound(bound01(this._g, 255) * 100) + "%", b: mathRound(bound01(this._b, 255) * 100) + "%", a: this._a };
    },
    toPercentageRgbString: function() {
        return (this._a == 1) ?
          "rgb("  + mathRound(bound01(this._r, 255) * 100) + "%, " + mathRound(bound01(this._g, 255) * 100) + "%, " + mathRound(bound01(this._b, 255) * 100) + "%)" :
          "rgba(" + mathRound(bound01(this._r, 255) * 100) + "%, " + mathRound(bound01(this._g, 255) * 100) + "%, " + mathRound(bound01(this._b, 255) * 100) + "%, " + this._roundA + ")";
    },
    toName: function() {
        if (this._a === 0) {
            return "transparent";
        }

        if (this._a < 1) {
            return false;
        }

        return hexNames[rgbToHex(this._r, this._g, this._b, true)] || false;
    },
    toFilter: function(secondColor) {
        var hex8String = '#' + rgbaToArgbHex(this._r, this._g, this._b, this._a);
        var secondHex8String = hex8String;
        var gradientType = this._gradientType ? "GradientType = 1, " : "";

        if (secondColor) {
            var s = tinycolor(secondColor);
            secondHex8String = '#' + rgbaToArgbHex(s._r, s._g, s._b, s._a);
        }

        return "progid:DXImageTransform.Microsoft.gradient("+gradientType+"startColorstr="+hex8String+",endColorstr="+secondHex8String+")";
    },
    toString: function(format) {
        var formatSet = !!format;
        format = format || this._format;

        var formattedString = false;
        var hasAlpha = this._a < 1 && this._a >= 0;
        var needsAlphaFormat = !formatSet && hasAlpha && (format === "hex" || format === "hex6" || format === "hex3" || format === "hex4" || format === "hex8" || format === "name");

        if (needsAlphaFormat) {
            // Special case for "transparent", all other non-alpha formats
            // will return rgba when there is transparency.
            if (format === "name" && this._a === 0) {
                return this.toName();
            }
            return this.toRgbString();
        }
        if (format === "rgb") {
            formattedString = this.toRgbString();
        }
        if (format === "prgb") {
            formattedString = this.toPercentageRgbString();
        }
        if (format === "hex" || format === "hex6") {
            formattedString = this.toHexString();
        }
        if (format === "hex3") {
            formattedString = this.toHexString(true);
        }
        if (format === "hex4") {
            formattedString = this.toHex8String(true);
        }
        if (format === "hex8") {
            formattedString = this.toHex8String();
        }
        if (format === "name") {
            formattedString = this.toName();
        }
        if (format === "hsl") {
            formattedString = this.toHslString();
        }
        if (format === "hsv") {
            formattedString = this.toHsvString();
        }

        return formattedString || this.toHexString();
    },
    clone: function() {
        return tinycolor(this.toString());
    },

    _applyModification: function(fn, args) {
        var color = fn.apply(null, [this].concat([].slice.call(args)));
        this._r = color._r;
        this._g = color._g;
        this._b = color._b;
        this.setAlpha(color._a);
        return this;
    },
    lighten: function() {
        return this._applyModification(lighten, arguments);
    },
    brighten: function() {
        return this._applyModification(brighten, arguments);
    },
    darken: function() {
        return this._applyModification(darken, arguments);
    },
    desaturate: function() {
        return this._applyModification(desaturate, arguments);
    },
    saturate: function() {
        return this._applyModification(saturate, arguments);
    },
    greyscale: function() {
        return this._applyModification(greyscale, arguments);
    },
    spin: function() {
        return this._applyModification(spin, arguments);
    },

    _applyCombination: function(fn, args) {
        return fn.apply(null, [this].concat([].slice.call(args)));
    },
    analogous: function() {
        return this._applyCombination(analogous, arguments);
    },
    complement: function() {
        return this._applyCombination(complement, arguments);
    },
    monochromatic: function() {
        return this._applyCombination(monochromatic, arguments);
    },
    splitcomplement: function() {
        return this._applyCombination(splitcomplement, arguments);
    },
    triad: function() {
        return this._applyCombination(triad, arguments);
    },
    tetrad: function() {
        return this._applyCombination(tetrad, arguments);
    }
};

// If input is an object, force 1 into "1.0" to handle ratios properly
// String input requires "1.0" as input, so 1 will be treated as 1
tinycolor.fromRatio = function(color, opts) {
    if (typeof color == "object") {
        var newColor = {};
        for (var i in color) {
            if (color.hasOwnProperty(i)) {
                if (i === "a") {
                    newColor[i] = color[i];
                }
                else {
                    newColor[i] = convertToPercentage(color[i]);
                }
            }
        }
        color = newColor;
    }

    return tinycolor(color, opts);
};

// Given a string or object, convert that input to RGB
// Possible string inputs:
//
//     "red"
//     "#f00" or "f00"
//     "#ff0000" or "ff0000"
//     "#ff000000" or "ff000000"
//     "rgb 255 0 0" or "rgb (255, 0, 0)"
//     "rgb 1.0 0 0" or "rgb (1, 0, 0)"
//     "rgba (255, 0, 0, 1)" or "rgba 255, 0, 0, 1"
//     "rgba (1.0, 0, 0, 1)" or "rgba 1.0, 0, 0, 1"
//     "hsl(0, 100%, 50%)" or "hsl 0 100% 50%"
//     "hsla(0, 100%, 50%, 1)" or "hsla 0 100% 50%, 1"
//     "hsv(0, 100%, 100%)" or "hsv 0 100% 100%"
//
function inputToRGB(color) {

    var rgb = { r: 0, g: 0, b: 0 };
    var a = 1;
    var s = null;
    var v = null;
    var l = null;
    var ok = false;
    var format = false;

    if (typeof color == "string") {
        color = stringInputToObject(color);
    }

    if (typeof color == "object") {
        if (isValidCSSUnit(color.r) && isValidCSSUnit(color.g) && isValidCSSUnit(color.b)) {
            rgb = rgbToRgb(color.r, color.g, color.b);
            ok = true;
            format = String(color.r).substr(-1) === "%" ? "prgb" : "rgb";
        }
        else if (isValidCSSUnit(color.h) && isValidCSSUnit(color.s) && isValidCSSUnit(color.v)) {
            s = convertToPercentage(color.s);
            v = convertToPercentage(color.v);
            rgb = hsvToRgb(color.h, s, v);
            ok = true;
            format = "hsv";
        }
        else if (isValidCSSUnit(color.h) && isValidCSSUnit(color.s) && isValidCSSUnit(color.l)) {
            s = convertToPercentage(color.s);
            l = convertToPercentage(color.l);
            rgb = hslToRgb(color.h, s, l);
            ok = true;
            format = "hsl";
        }

        if (color.hasOwnProperty("a")) {
            a = color.a;
        }
    }

    a = boundAlpha(a);

    return {
        ok: ok,
        format: color.format || format,
        r: mathMin(255, mathMax(rgb.r, 0)),
        g: mathMin(255, mathMax(rgb.g, 0)),
        b: mathMin(255, mathMax(rgb.b, 0)),
        a: a
    };
}


// Conversion Functions
// --------------------

// `rgbToHsl`, `rgbToHsv`, `hslToRgb`, `hsvToRgb` modified from:
// <http://mjijackson.com/2008/02/rgb-to-hsl-and-rgb-to-hsv-color-model-conversion-algorithms-in-javascript>

// `rgbToRgb`
// Handle bounds / percentage checking to conform to CSS color spec
// <http://www.w3.org/TR/css3-color/>
// *Assumes:* r, g, b in [0, 255] or [0, 1]
// *Returns:* { r, g, b } in [0, 255]
function rgbToRgb(r, g, b){
    return {
        r: bound01(r, 255) * 255,
        g: bound01(g, 255) * 255,
        b: bound01(b, 255) * 255
    };
}

// `rgbToHsl`
// Converts an RGB color value to HSL.
// *Assumes:* r, g, and b are contained in [0, 255] or [0, 1]
// *Returns:* { h, s, l } in [0,1]
function rgbToHsl(r, g, b) {

    r = bound01(r, 255);
    g = bound01(g, 255);
    b = bound01(b, 255);

    var max = mathMax(r, g, b), min = mathMin(r, g, b);
    var h, s, l = (max + min) / 2;

    if(max == min) {
        h = s = 0; // achromatic
    }
    else {
        var d = max - min;
        s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
        switch(max) {
            case r: h = (g - b) / d + (g < b ? 6 : 0); break;
            case g: h = (b - r) / d + 2; break;
            case b: h = (r - g) / d + 4; break;
        }

        h /= 6;
    }

    return { h: h, s: s, l: l };
}

// `hslToRgb`
// Converts an HSL color value to RGB.
// *Assumes:* h is contained in [0, 1] or [0, 360] and s and l are contained [0, 1] or [0, 100]
// *Returns:* { r, g, b } in the set [0, 255]
function hslToRgb(h, s, l) {
    var r, g, b;

    h = bound01(h, 360);
    s = bound01(s, 100);
    l = bound01(l, 100);

    function hue2rgb(p, q, t) {
        if(t < 0) t += 1;
        if(t > 1) t -= 1;
        if(t < 1/6) return p + (q - p) * 6 * t;
        if(t < 1/2) return q;
        if(t < 2/3) return p + (q - p) * (2/3 - t) * 6;
        return p;
    }

    if(s === 0) {
        r = g = b = l; // achromatic
    }
    else {
        var q = l < 0.5 ? l * (1 + s) : l + s - l * s;
        var p = 2 * l - q;
        r = hue2rgb(p, q, h + 1/3);
        g = hue2rgb(p, q, h);
        b = hue2rgb(p, q, h - 1/3);
    }

    return { r: r * 255, g: g * 255, b: b * 255 };
}

// `rgbToHsv`
// Converts an RGB color value to HSV
// *Assumes:* r, g, and b are contained in the set [0, 255] or [0, 1]
// *Returns:* { h, s, v } in [0,1]
function rgbToHsv(r, g, b) {

    r = bound01(r, 255);
    g = bound01(g, 255);
    b = bound01(b, 255);

    var max = mathMax(r, g, b), min = mathMin(r, g, b);
    var h, s, v = max;

    var d = max - min;
    s = max === 0 ? 0 : d / max;

    if(max == min) {
        h = 0; // achromatic
    }
    else {
        switch(max) {
            case r: h = (g - b) / d + (g < b ? 6 : 0); break;
            case g: h = (b - r) / d + 2; break;
            case b: h = (r - g) / d + 4; break;
        }
        h /= 6;
    }
    return { h: h, s: s, v: v };
}

// `hsvToRgb`
// Converts an HSV color value to RGB.
// *Assumes:* h is contained in [0, 1] or [0, 360] and s and v are contained in [0, 1] or [0, 100]
// *Returns:* { r, g, b } in the set [0, 255]
 function hsvToRgb(h, s, v) {

    h = bound01(h, 360) * 6;
    s = bound01(s, 100);
    v = bound01(v, 100);

    var i = Math.floor(h),
        f = h - i,
        p = v * (1 - s),
        q = v * (1 - f * s),
        t = v * (1 - (1 - f) * s),
        mod = i % 6,
        r = [v, q, p, p, t, v][mod],
        g = [t, v, v, q, p, p][mod],
        b = [p, p, t, v, v, q][mod];

    return { r: r * 255, g: g * 255, b: b * 255 };
}

// `rgbToHex`
// Converts an RGB color to hex
// Assumes r, g, and b are contained in the set [0, 255]
// Returns a 3 or 6 character hex
function rgbToHex(r, g, b, allow3Char) {

    var hex = [
        pad2(mathRound(r).toString(16)),
        pad2(mathRound(g).toString(16)),
        pad2(mathRound(b).toString(16))
    ];

    // Return a 3 character hex if possible
    if (allow3Char && hex[0].charAt(0) == hex[0].charAt(1) && hex[1].charAt(0) == hex[1].charAt(1) && hex[2].charAt(0) == hex[2].charAt(1)) {
        return hex[0].charAt(0) + hex[1].charAt(0) + hex[2].charAt(0);
    }

    return hex.join("");
}

// `rgbaToHex`
// Converts an RGBA color plus alpha transparency to hex
// Assumes r, g, b are contained in the set [0, 255] and
// a in [0, 1]. Returns a 4 or 8 character rgba hex
function rgbaToHex(r, g, b, a, allow4Char) {

    var hex = [
        pad2(mathRound(r).toString(16)),
        pad2(mathRound(g).toString(16)),
        pad2(mathRound(b).toString(16)),
        pad2(convertDecimalToHex(a))
    ];

    // Return a 4 character hex if possible
    if (allow4Char && hex[0].charAt(0) == hex[0].charAt(1) && hex[1].charAt(0) == hex[1].charAt(1) && hex[2].charAt(0) == hex[2].charAt(1) && hex[3].charAt(0) == hex[3].charAt(1)) {
        return hex[0].charAt(0) + hex[1].charAt(0) + hex[2].charAt(0) + hex[3].charAt(0);
    }

    return hex.join("");
}

// `rgbaToArgbHex`
// Converts an RGBA color to an ARGB Hex8 string
// Rarely used, but required for "toFilter()"
function rgbaToArgbHex(r, g, b, a) {

    var hex = [
        pad2(convertDecimalToHex(a)),
        pad2(mathRound(r).toString(16)),
        pad2(mathRound(g).toString(16)),
        pad2(mathRound(b).toString(16))
    ];

    return hex.join("");
}

// `equals`
// Can be called with any tinycolor input
tinycolor.equals = function (color1, color2) {
    if (!color1 || !color2) { return false; }
    return tinycolor(color1).toRgbString() == tinycolor(color2).toRgbString();
};

tinycolor.random = function() {
    return tinycolor.fromRatio({
        r: mathRandom(),
        g: mathRandom(),
        b: mathRandom()
    });
};


// Modification Functions
// ----------------------
// Thanks to less.js for some of the basics here
// <https://github.com/cloudhead/less.js/blob/master/lib/less/functions.js>

function desaturate(color, amount) {
    amount = (amount === 0) ? 0 : (amount || 10);
    var hsl = tinycolor(color).toHsl();
    hsl.s -= amount / 100;
    hsl.s = clamp01(hsl.s);
    return tinycolor(hsl);
}

function saturate(color, amount) {
    amount = (amount === 0) ? 0 : (amount || 10);
    var hsl = tinycolor(color).toHsl();
    hsl.s += amount / 100;
    hsl.s = clamp01(hsl.s);
    return tinycolor(hsl);
}

function greyscale(color) {
    return tinycolor(color).desaturate(100);
}

function lighten (color, amount) {
    amount = (amount === 0) ? 0 : (amount || 10);
    var hsl = tinycolor(color).toHsl();
    hsl.l += amount / 100;
    hsl.l = clamp01(hsl.l);
    return tinycolor(hsl);
}

function brighten(color, amount) {
    amount = (amount === 0) ? 0 : (amount || 10);
    var rgb = tinycolor(color).toRgb();
    rgb.r = mathMax(0, mathMin(255, rgb.r - mathRound(255 * - (amount / 100))));
    rgb.g = mathMax(0, mathMin(255, rgb.g - mathRound(255 * - (amount / 100))));
    rgb.b = mathMax(0, mathMin(255, rgb.b - mathRound(255 * - (amount / 100))));
    return tinycolor(rgb);
}

function darken (color, amount) {
    amount = (amount === 0) ? 0 : (amount || 10);
    var hsl = tinycolor(color).toHsl();
    hsl.l -= amount / 100;
    hsl.l = clamp01(hsl.l);
    return tinycolor(hsl);
}

// Spin takes a positive or negative amount within [-360, 360] indicating the change of hue.
// Values outside of this range will be wrapped into this range.
function spin(color, amount) {
    var hsl = tinycolor(color).toHsl();
    var hue = (hsl.h + amount) % 360;
    hsl.h = hue < 0 ? 360 + hue : hue;
    return tinycolor(hsl);
}

// Combination Functions
// ---------------------
// Thanks to jQuery xColor for some of the ideas behind these
// <https://github.com/infusion/jQuery-xcolor/blob/master/jquery.xcolor.js>

function complement(color) {
    var hsl = tinycolor(color).toHsl();
    hsl.h = (hsl.h + 180) % 360;
    return tinycolor(hsl);
}

function triad(color) {
    var hsl = tinycolor(color).toHsl();
    var h = hsl.h;
    return [
        tinycolor(color),
        tinycolor({ h: (h + 120) % 360, s: hsl.s, l: hsl.l }),
        tinycolor({ h: (h + 240) % 360, s: hsl.s, l: hsl.l })
    ];
}

function tetrad(color) {
    var hsl = tinycolor(color).toHsl();
    var h = hsl.h;
    return [
        tinycolor(color),
        tinycolor({ h: (h + 90) % 360, s: hsl.s, l: hsl.l }),
        tinycolor({ h: (h + 180) % 360, s: hsl.s, l: hsl.l }),
        tinycolor({ h: (h + 270) % 360, s: hsl.s, l: hsl.l })
    ];
}

function splitcomplement(color) {
    var hsl = tinycolor(color).toHsl();
    var h = hsl.h;
    return [
        tinycolor(color),
        tinycolor({ h: (h + 72) % 360, s: hsl.s, l: hsl.l}),
        tinycolor({ h: (h + 216) % 360, s: hsl.s, l: hsl.l})
    ];
}

function analogous(color, results, slices) {
    results = results || 6;
    slices = slices || 30;

    var hsl = tinycolor(color).toHsl();
    var part = 360 / slices;
    var ret = [tinycolor(color)];

    for (hsl.h = ((hsl.h - (part * results >> 1)) + 720) % 360; --results; ) {
        hsl.h = (hsl.h + part) % 360;
        ret.push(tinycolor(hsl));
    }
    return ret;
}

function monochromatic(color, results) {
    results = results || 6;
    var hsv = tinycolor(color).toHsv();
    var h = hsv.h, s = hsv.s, v = hsv.v;
    var ret = [];
    var modification = 1 / results;

    while (results--) {
        ret.push(tinycolor({ h: h, s: s, v: v}));
        v = (v + modification) % 1;
    }

    return ret;
}

// Utility Functions
// ---------------------

tinycolor.mix = function(color1, color2, amount) {
    amount = (amount === 0) ? 0 : (amount || 50);

    var rgb1 = tinycolor(color1).toRgb();
    var rgb2 = tinycolor(color2).toRgb();

    var p = amount / 100;

    var rgba = {
        r: ((rgb2.r - rgb1.r) * p) + rgb1.r,
        g: ((rgb2.g - rgb1.g) * p) + rgb1.g,
        b: ((rgb2.b - rgb1.b) * p) + rgb1.b,
        a: ((rgb2.a - rgb1.a) * p) + rgb1.a
    };

    return tinycolor(rgba);
};


// Readability Functions
// ---------------------
// <http://www.w3.org/TR/2008/REC-WCAG20-20081211/#contrast-ratiodef (WCAG Version 2)

// `contrast`
// Analyze the 2 colors and returns the color contrast defined by (WCAG Version 2)
tinycolor.readability = function(color1, color2) {
    var c1 = tinycolor(color1);
    var c2 = tinycolor(color2);
    return (Math.max(c1.getLuminance(),c2.getLuminance())+0.05) / (Math.min(c1.getLuminance(),c2.getLuminance())+0.05);
};

// `isReadable`
// Ensure that foreground and background color combinations meet WCAG2 guidelines.
// The third argument is an optional Object.
//      the 'level' property states 'AA' or 'AAA' - if missing or invalid, it defaults to 'AA';
//      the 'size' property states 'large' or 'small' - if missing or invalid, it defaults to 'small'.
// If the entire object is absent, isReadable defaults to {level:"AA",size:"small"}.

// *Example*
//    tinycolor.isReadable("#000", "#111") => false
//    tinycolor.isReadable("#000", "#111",{level:"AA",size:"large"}) => false
tinycolor.isReadable = function(color1, color2, wcag2) {
    var readability = tinycolor.readability(color1, color2);
    var wcag2Parms, out;

    out = false;

    wcag2Parms = validateWCAG2Parms(wcag2);
    switch (wcag2Parms.level + wcag2Parms.size) {
        case "AAsmall":
        case "AAAlarge":
            out = readability >= 4.5;
            break;
        case "AAlarge":
            out = readability >= 3;
            break;
        case "AAAsmall":
            out = readability >= 7;
            break;
    }
    return out;

};

// `mostReadable`
// Given a base color and a list of possible foreground or background
// colors for that base, returns the most readable color.
// Optionally returns Black or White if the most readable color is unreadable.
// *Example*
//    tinycolor.mostReadable(tinycolor.mostReadable("#123", ["#124", "#125"],{includeFallbackColors:false}).toHexString(); // "#112255"
//    tinycolor.mostReadable(tinycolor.mostReadable("#123", ["#124", "#125"],{includeFallbackColors:true}).toHexString();  // "#ffffff"
//    tinycolor.mostReadable("#a8015a", ["#faf3f3"],{includeFallbackColors:true,level:"AAA",size:"large"}).toHexString(); // "#faf3f3"
//    tinycolor.mostReadable("#a8015a", ["#faf3f3"],{includeFallbackColors:true,level:"AAA",size:"small"}).toHexString(); // "#ffffff"
tinycolor.mostReadable = function(baseColor, colorList, args) {
    var bestColor = null;
    var bestScore = 0;
    var readability;
    var includeFallbackColors, level, size ;
    args = args || {};
    includeFallbackColors = args.includeFallbackColors ;
    level = args.level;
    size = args.size;

    for (var i= 0; i < colorList.length ; i++) {
        readability = tinycolor.readability(baseColor, colorList[i]);
        if (readability > bestScore) {
            bestScore = readability;
            bestColor = tinycolor(colorList[i]);
        }
    }

    if (tinycolor.isReadable(baseColor, bestColor, {"level":level,"size":size}) || !includeFallbackColors) {
        return bestColor;
    }
    else {
        args.includeFallbackColors=false;
        return tinycolor.mostReadable(baseColor,["#fff", "#000"],args);
    }
};


// Big List of Colors
// ------------------
// <http://www.w3.org/TR/css3-color/#svg-color>
var names = tinycolor.names = {
    aliceblue: "f0f8ff",
    antiquewhite: "faebd7",
    aqua: "0ff",
    aquamarine: "7fffd4",
    azure: "f0ffff",
    beige: "f5f5dc",
    bisque: "ffe4c4",
    black: "000",
    blanchedalmond: "ffebcd",
    blue: "00f",
    blueviolet: "8a2be2",
    brown: "a52a2a",
    burlywood: "deb887",
    burntsienna: "ea7e5d",
    cadetblue: "5f9ea0",
    chartreuse: "7fff00",
    chocolate: "d2691e",
    coral: "ff7f50",
    cornflowerblue: "6495ed",
    cornsilk: "fff8dc",
    crimson: "dc143c",
    cyan: "0ff",
    darkblue: "00008b",
    darkcyan: "008b8b",
    darkgoldenrod: "b8860b",
    darkgray: "a9a9a9",
    darkgreen: "006400",
    darkgrey: "a9a9a9",
    darkkhaki: "bdb76b",
    darkmagenta: "8b008b",
    darkolivegreen: "556b2f",
    darkorange: "ff8c00",
    darkorchid: "9932cc",
    darkred: "8b0000",
    darksalmon: "e9967a",
    darkseagreen: "8fbc8f",
    darkslateblue: "483d8b",
    darkslategray: "2f4f4f",
    darkslategrey: "2f4f4f",
    darkturquoise: "00ced1",
    darkviolet: "9400d3",
    deeppink: "ff1493",
    deepskyblue: "00bfff",
    dimgray: "696969",
    dimgrey: "696969",
    dodgerblue: "1e90ff",
    firebrick: "b22222",
    floralwhite: "fffaf0",
    forestgreen: "228b22",
    fuchsia: "f0f",
    gainsboro: "dcdcdc",
    ghostwhite: "f8f8ff",
    gold: "ffd700",
    goldenrod: "daa520",
    gray: "808080",
    green: "008000",
    greenyellow: "adff2f",
    grey: "808080",
    honeydew: "f0fff0",
    hotpink: "ff69b4",
    indianred: "cd5c5c",
    indigo: "4b0082",
    ivory: "fffff0",
    khaki: "f0e68c",
    lavender: "e6e6fa",
    lavenderblush: "fff0f5",
    lawngreen: "7cfc00",
    lemonchiffon: "fffacd",
    lightblue: "add8e6",
    lightcoral: "f08080",
    lightcyan: "e0ffff",
    lightgoldenrodyellow: "fafad2",
    lightgray: "d3d3d3",
    lightgreen: "90ee90",
    lightgrey: "d3d3d3",
    lightpink: "ffb6c1",
    lightsalmon: "ffa07a",
    lightseagreen: "20b2aa",
    lightskyblue: "87cefa",
    lightslategray: "789",
    lightslategrey: "789",
    lightsteelblue: "b0c4de",
    lightyellow: "ffffe0",
    lime: "0f0",
    limegreen: "32cd32",
    linen: "faf0e6",
    magenta: "f0f",
    maroon: "800000",
    mediumaquamarine: "66cdaa",
    mediumblue: "0000cd",
    mediumorchid: "ba55d3",
    mediumpurple: "9370db",
    mediumseagreen: "3cb371",
    mediumslateblue: "7b68ee",
    mediumspringgreen: "00fa9a",
    mediumturquoise: "48d1cc",
    mediumvioletred: "c71585",
    midnightblue: "191970",
    mintcream: "f5fffa",
    mistyrose: "ffe4e1",
    moccasin: "ffe4b5",
    navajowhite: "ffdead",
    navy: "000080",
    oldlace: "fdf5e6",
    olive: "808000",
    olivedrab: "6b8e23",
    orange: "ffa500",
    orangered: "ff4500",
    orchid: "da70d6",
    palegoldenrod: "eee8aa",
    palegreen: "98fb98",
    paleturquoise: "afeeee",
    palevioletred: "db7093",
    papayawhip: "ffefd5",
    peachpuff: "ffdab9",
    peru: "cd853f",
    pink: "ffc0cb",
    plum: "dda0dd",
    powderblue: "b0e0e6",
    purple: "800080",
    rebeccapurple: "663399",
    red: "f00",
    rosybrown: "bc8f8f",
    royalblue: "4169e1",
    saddlebrown: "8b4513",
    salmon: "fa8072",
    sandybrown: "f4a460",
    seagreen: "2e8b57",
    seashell: "fff5ee",
    sienna: "a0522d",
    silver: "c0c0c0",
    skyblue: "87ceeb",
    slateblue: "6a5acd",
    slategray: "708090",
    slategrey: "708090",
    snow: "fffafa",
    springgreen: "00ff7f",
    steelblue: "4682b4",
    tan: "d2b48c",
    teal: "008080",
    thistle: "d8bfd8",
    tomato: "ff6347",
    turquoise: "40e0d0",
    violet: "ee82ee",
    wheat: "f5deb3",
    white: "fff",
    whitesmoke: "f5f5f5",
    yellow: "ff0",
    yellowgreen: "9acd32"
};

// Make it easy to access colors via `hexNames[hex]`
var hexNames = tinycolor.hexNames = flip(names);


// Utilities
// ---------

// `{ 'name1': 'val1' }` becomes `{ 'val1': 'name1' }`
function flip(o) {
    var flipped = { };
    for (var i in o) {
        if (o.hasOwnProperty(i)) {
            flipped[o[i]] = i;
        }
    }
    return flipped;
}

// Return a valid alpha value [0,1] with all invalid values being set to 1
function boundAlpha(a) {
    a = parseFloat(a);

    if (isNaN(a) || a < 0 || a > 1) {
        a = 1;
    }

    return a;
}

// Take input from [0, n] and return it as [0, 1]
function bound01(n, max) {
    if (isOnePointZero(n)) { n = "100%"; }

    var processPercent = isPercentage(n);
    n = mathMin(max, mathMax(0, parseFloat(n)));

    // Automatically convert percentage into number
    if (processPercent) {
        n = parseInt(n * max, 10) / 100;
    }

    // Handle floating point rounding errors
    if ((Math.abs(n - max) < 0.000001)) {
        return 1;
    }

    // Convert into [0, 1] range if it isn't already
    return (n % max) / parseFloat(max);
}

// Force a number between 0 and 1
function clamp01(val) {
    return mathMin(1, mathMax(0, val));
}

// Parse a base-16 hex value into a base-10 integer
function parseIntFromHex(val) {
    return parseInt(val, 16);
}

// Need to handle 1.0 as 100%, since once it is a number, there is no difference between it and 1
// <http://stackoverflow.com/questions/7422072/javascript-how-to-detect-number-as-a-decimal-including-1-0>
function isOnePointZero(n) {
    return typeof n == "string" && n.indexOf('.') != -1 && parseFloat(n) === 1;
}

// Check to see if string passed in is a percentage
function isPercentage(n) {
    return typeof n === "string" && n.indexOf('%') != -1;
}

// Force a hex value to have 2 characters
function pad2(c) {
    return c.length == 1 ? '0' + c : '' + c;
}

// Replace a decimal with it's percentage value
function convertToPercentage(n) {
    if (n <= 1) {
        n = (n * 100) + "%";
    }

    return n;
}

// Converts a decimal to a hex value
function convertDecimalToHex(d) {
    return Math.round(parseFloat(d) * 255).toString(16);
}
// Converts a hex value to a decimal
function convertHexToDecimal(h) {
    return (parseIntFromHex(h) / 255);
}

var matchers = (function() {

    // <http://www.w3.org/TR/css3-values/#integers>
    var CSS_INTEGER = "[-\\+]?\\d+%?";

    // <http://www.w3.org/TR/css3-values/#number-value>
    var CSS_NUMBER = "[-\\+]?\\d*\\.\\d+%?";

    // Allow positive/negative integer/number.  Don't capture the either/or, just the entire outcome.
    var CSS_UNIT = "(?:" + CSS_NUMBER + ")|(?:" + CSS_INTEGER + ")";

    // Actual matching.
    // Parentheses and commas are optional, but not required.
    // Whitespace can take the place of commas or opening paren
    var PERMISSIVE_MATCH3 = "[\\s|\\(]+(" + CSS_UNIT + ")[,|\\s]+(" + CSS_UNIT + ")[,|\\s]+(" + CSS_UNIT + ")\\s*\\)?";
    var PERMISSIVE_MATCH4 = "[\\s|\\(]+(" + CSS_UNIT + ")[,|\\s]+(" + CSS_UNIT + ")[,|\\s]+(" + CSS_UNIT + ")[,|\\s]+(" + CSS_UNIT + ")\\s*\\)?";

    return {
        CSS_UNIT: new RegExp(CSS_UNIT),
        rgb: new RegExp("rgb" + PERMISSIVE_MATCH3),
        rgba: new RegExp("rgba" + PERMISSIVE_MATCH4),
        hsl: new RegExp("hsl" + PERMISSIVE_MATCH3),
        hsla: new RegExp("hsla" + PERMISSIVE_MATCH4),
        hsv: new RegExp("hsv" + PERMISSIVE_MATCH3),
        hsva: new RegExp("hsva" + PERMISSIVE_MATCH4),
        hex3: /^#?([0-9a-fA-F]{1})([0-9a-fA-F]{1})([0-9a-fA-F]{1})$/,
        hex6: /^#?([0-9a-fA-F]{2})([0-9a-fA-F]{2})([0-9a-fA-F]{2})$/,
        hex4: /^#?([0-9a-fA-F]{1})([0-9a-fA-F]{1})([0-9a-fA-F]{1})([0-9a-fA-F]{1})$/,
        hex8: /^#?([0-9a-fA-F]{2})([0-9a-fA-F]{2})([0-9a-fA-F]{2})([0-9a-fA-F]{2})$/
    };
})();

// `isValidCSSUnit`
// Take in a single string / number and check to see if it looks like a CSS unit
// (see `matchers` above for definition).
function isValidCSSUnit(color) {
    return !!matchers.CSS_UNIT.exec(color);
}

// `stringInputToObject`
// Permissive string parsing.  Take in a number of formats, and output an object
// based on detected format.  Returns `{ r, g, b }` or `{ h, s, l }` or `{ h, s, v}`
function stringInputToObject(color) {

    color = color.replace(trimLeft,'').replace(trimRight, '').toLowerCase();
    var named = false;
    if (names[color]) {
        color = names[color];
        named = true;
    }
    else if (color == 'transparent') {
        return { r: 0, g: 0, b: 0, a: 0, format: "name" };
    }

    // Try to match string input using regular expressions.
    // Keep most of the number bounding out of this function - don't worry about [0,1] or [0,100] or [0,360]
    // Just return an object and let the conversion functions handle that.
    // This way the result will be the same whether the tinycolor is initialized with string or object.
    var match;
    if ((match = matchers.rgb.exec(color))) {
        return { r: match[1], g: match[2], b: match[3] };
    }
    if ((match = matchers.rgba.exec(color))) {
        return { r: match[1], g: match[2], b: match[3], a: match[4] };
    }
    if ((match = matchers.hsl.exec(color))) {
        return { h: match[1], s: match[2], l: match[3] };
    }
    if ((match = matchers.hsla.exec(color))) {
        return { h: match[1], s: match[2], l: match[3], a: match[4] };
    }
    if ((match = matchers.hsv.exec(color))) {
        return { h: match[1], s: match[2], v: match[3] };
    }
    if ((match = matchers.hsva.exec(color))) {
        return { h: match[1], s: match[2], v: match[3], a: match[4] };
    }
    if ((match = matchers.hex8.exec(color))) {
        return {
            r: parseIntFromHex(match[1]),
            g: parseIntFromHex(match[2]),
            b: parseIntFromHex(match[3]),
            a: convertHexToDecimal(match[4]),
            format: named ? "name" : "hex8"
        };
    }
    if ((match = matchers.hex6.exec(color))) {
        return {
            r: parseIntFromHex(match[1]),
            g: parseIntFromHex(match[2]),
            b: parseIntFromHex(match[3]),
            format: named ? "name" : "hex"
        };
    }
    if ((match = matchers.hex4.exec(color))) {
        return {
            r: parseIntFromHex(match[1] + '' + match[1]),
            g: parseIntFromHex(match[2] + '' + match[2]),
            b: parseIntFromHex(match[3] + '' + match[3]),
            a: convertHexToDecimal(match[4] + '' + match[4]),
            format: named ? "name" : "hex8"
        };
    }
    if ((match = matchers.hex3.exec(color))) {
        return {
            r: parseIntFromHex(match[1] + '' + match[1]),
            g: parseIntFromHex(match[2] + '' + match[2]),
            b: parseIntFromHex(match[3] + '' + match[3]),
            format: named ? "name" : "hex"
        };
    }

    return false;
}

function validateWCAG2Parms(parms) {
    // return valid WCAG2 parms for isReadable.
    // If input parms are invalid, return {"level":"AA", "size":"small"}
    var level, size;
    parms = parms || {"level":"AA", "size":"small"};
    level = (parms.level || "AA").toUpperCase();
    size = (parms.size || "small").toLowerCase();
    if (level !== "AA" && level !== "AAA") {
        level = "AA";
    }
    if (size !== "small" && size !== "large") {
        size = "small";
    }
    return {"level":level, "size":size};
}

// Node: Export function
if (typeof module !== "undefined" && module.exports) {
    module.exports = tinycolor;
}
// AMD/requirejs: Define the module
else if (true) {
    !(__WEBPACK_AMD_DEFINE_RESULT__ = (function () {return tinycolor;}).call(exports, __webpack_require__, exports, module),
				__WEBPACK_AMD_DEFINE_RESULT__ !== undefined && (module.exports = __WEBPACK_AMD_DEFINE_RESULT__));
}
// Browser: Expose to window
else {}

})(Math);


/***/ }),

/***/ 3158:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.Hue = undefined;

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _classnames = __webpack_require__(29);

var _classnames2 = _interopRequireDefault(_classnames);

var _constants = __webpack_require__(3159);

__webpack_require__(3160);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var calculateChange = function calculateChange(event, props, container) {
    var containerWidth = container.clientWidth;
    var containerHeight = container.clientHeight;
    var x = event.pageX;
    var y = event.pageY;
    var left = x - (container.getBoundingClientRect().left + window.pageXOffset);
    var top = y - (container.getBoundingClientRect().top + window.pageYOffset);
    var h = void 0;
    if (props.direction === 'vertical') {
        if (top < 0) {
            h = 359;
        } else if (top > containerHeight) {
            h = 0;
        } else {
            var percent = -(top * 100 / containerHeight) + 100;
            h = 360 * percent / 100;
        }
    } else {
        if (left < 0) {
            h = 0;
        } else if (left > containerWidth) {
            h = 359;
        } else {
            var _percent = left * 100 / containerWidth;
            h = 360 * _percent / 100;
        }
    }
    if (props.hsl.h !== h) {
        return {
            h: h,
            s: props.hsl.s,
            l: props.hsl.l,
            a: props.hsl.a
        };
    }
    return null;
};

var Hue = exports.Hue = function (_PureComponent) {
    (0, _inherits3.default)(Hue, _PureComponent);

    function Hue() {
        (0, _classCallCheck3.default)(this, Hue);

        var _this = (0, _possibleConstructorReturn3.default)(this, (Hue.__proto__ || Object.getPrototypeOf(Hue)).apply(this, arguments));

        _this.handleChange = function (event) {
            event.preventDefault();
            var change = calculateChange(event, _this.props, _this.container);
            if (change && _this.props.onChange) {
                _this.props.onChange(change, event);
            }
        };
        _this.handleMouseDown = function (event) {
            _this.handleChange(event);
            window.addEventListener('mousemove', _this.handleChange);
            window.addEventListener('mouseup', _this.handleMouseUp);
        };
        _this.handleMouseUp = function () {
            _this.unbindEventListeners();
        };
        _this.unbindEventListeners = function () {
            window.removeEventListener('mousemove', _this.handleChange);
            window.removeEventListener('mouseup', _this.handleMouseUp);
        };
        _this.setContainer = function (container) {
            _this.container = container;
        };
        return _this;
    }

    (0, _createClass3.default)(Hue, [{
        key: 'componentWillUnmount',
        value: function componentWillUnmount() {
            this.unbindEventListeners();
        }
    }, {
        key: 'render',
        value: function render() {
            var props = this.props;
            var _props$direction = props.direction,
                direction = _props$direction === undefined ? _constants.Direction.Horizontal : _props$direction;

            var pointerStyle = direction === _constants.Direction.Horizontal ? { left: props.hsl.h * 100 / 360 + '%' } : { top: -(props.hsl.h * 100 / 360) + 100 + '%' };
            var pointer = _react2.default.isValidElement(props.pointer) ? props.pointer : _react2.default.createElement("div", { className: "hue__slider" });
            return _react2.default.createElement("div", { ref: this.setContainer, className: (0, _classnames2.default)(props.className, 'hue', 'hue_' + direction), onMouseDown: this.handleMouseDown }, _react2.default.cloneElement(pointer, { style: pointerStyle }));
        }
    }]);
    return Hue;
}(_react.PureComponent);

/***/ }),

/***/ 3159:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
/**
 * 水平与竖直方向
 */
var Direction = exports.Direction = undefined;
(function (Direction) {
  Direction["Horizontal"] = "horizontal";
  Direction["Vertical"] = "vertical";
})(Direction || (exports.Direction = Direction = {}));

/***/ }),

/***/ 3160:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3161:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.Checkboard = undefined;

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _classnames = __webpack_require__(29);

var _classnames2 = _interopRequireDefault(_classnames);

__webpack_require__(3162);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var Checkboard = exports.Checkboard = function Checkboard(props) {
    var backgroundColor = props.backgroundColor;
    return _react2.default.createElement("div", { className: (0, _classnames2.default)(props.className, 'checkboard layout-row layout-cross-center') }, _react2.default.createElement("span", { className: "checkboard__color", style: { backgroundColor: backgroundColor } }), _react2.default.createElement("span", { className: "checkboard__text" }, backgroundColor && backgroundColor.toUpperCase()));
};

/***/ }),

/***/ 3162:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3163:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.Saturation = undefined;

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _throttle2 = __webpack_require__(502);

var _throttle3 = _interopRequireDefault(_throttle2);

var _isEqual2 = __webpack_require__(501);

var _isEqual3 = _interopRequireDefault(_isEqual2);

var _clamp2 = __webpack_require__(1948);

var _clamp3 = _interopRequireDefault(_clamp2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _classnames = __webpack_require__(29);

var _classnames2 = _interopRequireDefault(_classnames);

__webpack_require__(3164);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * 将 位置 转为 HSV
 * @param position 点的位置
 * @param props
 */
function positionToHSV(position, props) {
    return {
        h: props.hsl.h,
        s: position.left / 100,
        v: 1 - position.top / 100,
        a: props.hsl.a
    };
}
/**
 * 将 HSV 转为 位置
 * @param {HSV} hsv 颜色
 */
function HSVtoPosition(hsv) {
    return {
        top: 100 - hsv.v * 100,
        left: hsv.s * 100
    };
}

var Saturation = exports.Saturation = function (_React$PureComponent) {
    (0, _inherits3.default)(Saturation, _React$PureComponent);

    function Saturation(props) {
        (0, _classCallCheck3.default)(this, Saturation);

        var _this = (0, _possibleConstructorReturn3.default)(this, (Saturation.__proto__ || Object.getPrototypeOf(Saturation)).call(this, props));

        _this.getPosition = function (event) {
            var containerRect = _this.container.getBoundingClientRect();
            var containerWidth = containerRect.width,
                containerHeight = containerRect.height;

            var left = event.pageX - (containerRect.left + window.pageXOffset);
            var top = event.pageY - (containerRect.top + window.pageYOffset);
            left = (0, _clamp3.default)(left, 0, containerWidth);
            top = (0, _clamp3.default)(top, 0, containerHeight);
            return {
                left: left * 100 / containerWidth,
                top: top * 100 / containerHeight
            };
        };
        _this.handleChange = function (event) {
            event.preventDefault();
            // 获取位置
            var position = _this.getPosition(event);
            _this.setState({ position: position });
            // 将颜色传递给父组件
            _this.data = positionToHSV(position, _this.props);
            _this.props.onChange && _this.props.onChange(_this.data, event);
        };
        _this.handleMouseDown = function (event) {
            _this.handleChange(event);
            _this.bindEventListeners();
        };
        _this.handleMouseUp = function () {
            _this.unbindEventListeners();
        };
        _this.setContainer = function (container) {
            _this.container = container;
        };
        _this.data = _this.props.hsv;
        _this.state = {
            position: HSVtoPosition(_this.props.hsv)
        };
        return _this;
    }

    (0, _createClass3.default)(Saturation, [{
        key: 'componentWillReceiveProps',
        value: function componentWillReceiveProps(nextProps) {
            if (nextProps.hsv.v === 0 && this.data.v === 0) {
                return;
            }
            if (!(0, _isEqual3.default)(nextProps.hsv, this.data)) {
                this.setState({ position: HSVtoPosition(nextProps.hsv) });
            }
        }
    }, {
        key: 'componentWillUnmount',
        value: function componentWillUnmount() {
            this.unbindEventListeners();
        }
    }, {
        key: 'bindEventListeners',
        value: function bindEventListeners() {
            this.handleChangeThrottle = (0, _throttle3.default)(this.handleChange, 10);
            window.addEventListener('mousemove', this.handleChangeThrottle);
            window.addEventListener('mouseup', this.handleMouseUp);
        }
    }, {
        key: 'unbindEventListeners',
        value: function unbindEventListeners() {
            if (this.handleChangeThrottle) {
                this.handleChangeThrottle.cancel();
                window.removeEventListener('mousemove', this.handleChangeThrottle);
                this.handleChangeThrottle = undefined;
            }
            window.removeEventListener('mouseup', this.handleMouseUp);
        }
    }, {
        key: 'render',
        value: function render() {
            var props = this.props,
                state = this.state;

            var pointer = _react2.default.isValidElement(props.pointer) ? props.pointer : _react2.default.createElement("div", { className: "saturation__circle" });
            return _react2.default.createElement("div", { ref: this.setContainer, className: (0, _classnames2.default)(props.className, 'saturation'), style: { background: 'hsl(' + props.hsl.h + ', 100%, 50%)' }, onMouseDown: this.handleMouseDown }, _react2.default.createElement("div", { className: "saturation__white" }, _react2.default.createElement("div", { className: "saturation__black" }), _react2.default.cloneElement(pointer, {
                style: {
                    top: state.position.top + '%',
                    left: state.position.left + '%'
                }
            })));
        }
    }]);
    return Saturation;
}(_react2.default.PureComponent);

/***/ }),

/***/ 3164:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3165:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3166:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.SwatchesPicker = undefined;

var _SwatchesPicker = __webpack_require__(3167);

var _SwatchesPicker2 = _interopRequireDefault(_SwatchesPicker);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.SwatchesPicker = _SwatchesPicker2.default;

/***/ }),

/***/ 3167:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _ColorWrap = __webpack_require__(2057);

var _SwatchesColor = __webpack_require__(3168);

var _SwatchesColor2 = _interopRequireDefault(_SwatchesColor);

__webpack_require__(3171);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var SwatchesPicker = function (_React$PureComponent) {
    (0, _inherits3.default)(SwatchesPicker, _React$PureComponent);

    function SwatchesPicker() {
        (0, _classCallCheck3.default)(this, SwatchesPicker);

        var _this = (0, _possibleConstructorReturn3.default)(this, (SwatchesPicker.__proto__ || Object.getPrototypeOf(SwatchesPicker)).apply(this, arguments));

        _this.handleClick = function (color, event) {
            _this.props.onChange(color, event);
        };
        return _this;
    }

    (0, _createClass3.default)(SwatchesPicker, [{
        key: 'render',
        value: function render() {
            var _this2 = this;

            var _props = this.props,
                colorsGroup = _props.colorsGroup,
                hex = _props.hex;

            return _react2.default.createElement("div", { className: "swatches-picker layout-row" }, colorsGroup.map(function (colors, index) {
                return _react2.default.createElement("div", { key: index, className: "swatches-column layout-column" }, colors.map(function (color, index) {
                    return _react2.default.createElement(_SwatchesColor2.default, { key: color, color: color.toUpperCase(), active: color.toUpperCase() === hex.toUpperCase(), onClick: _this2.handleClick });
                }));
            }));
        }
    }]);
    return SwatchesPicker;
}(_react2.default.PureComponent);

SwatchesPicker.defaultProps = {
    colorsGroup: [['#FFFFFF', '#F5F5F5', '#E6E6E6', '#9E9E9E', '#424242', '#000000'], ['#4FA2F8', '#C9DAF8', '#A4C2F4', '#3B78D8', '#1355CD', '#1D4586'], ['#21D11F', '#D8EAD3', '#B6D7A7', '#6AA74F', '#38761E', '#284D13'], ['#9837FF', '#D8D1E8', '#B4A6D6', '#664EA8', '#341C74', '#20124D'], ['#FFFD00', '#FFF3CC', '#F4CE5B', '#F2C131', '#BF8F02', '#7F6001'], ['#FF2601', '#F4CCCC', '#E06666', '#CB1B00', '#991200', '#650800']]
};
exports.default = (0, _ColorWrap.ColorWrap)(SwatchesPicker);

/***/ }),

/***/ 3168:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _check = __webpack_require__(3169);

var _check2 = _interopRequireDefault(_check);

__webpack_require__(3170);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var SwatchesColor = function (_React$PureComponent) {
    (0, _inherits3.default)(SwatchesColor, _React$PureComponent);

    function SwatchesColor() {
        (0, _classCallCheck3.default)(this, SwatchesColor);

        var _this = (0, _possibleConstructorReturn3.default)(this, (SwatchesColor.__proto__ || Object.getPrototypeOf(SwatchesColor)).apply(this, arguments));

        _this.handleClick = function (event) {
            _this.props.onClick(_this.props.color, event);
        };
        return _this;
    }

    (0, _createClass3.default)(SwatchesColor, [{
        key: 'render',
        value: function render() {
            var _props = this.props,
                color = _props.color,
                active = _props.active;

            var swatchesStyle = {
                backgroundColor: color,
                borderColor: color
            };
            var iconStyle = {};
            // 白色的边框和 Icon 要变色
            if (color === '#FFFFFF') {
                swatchesStyle.borderColor = '#F1F2F3';
                iconStyle.fill = '#7B8591';
            }
            return _react2.default.createElement("div", { className: "swatches-color", style: swatchesStyle, onClick: this.handleClick }, active && _react2.default.createElement(_check2.default, { className: "swatches-color__icon", style: iconStyle }));
        }
    }]);
    return SwatchesColor;
}(_react2.default.PureComponent);

exports.default = SwatchesColor;

/***/ }),

/***/ 3169:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ viewBox: "0 0 12 12", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M2.7 4.95a1 1 0 1 0-1.4 1.42l3.37 3.37 6.04-6.03a1 1 0 1 0-1.42-1.42L4.67 6.92 2.71 4.95z" })
  );
};

/***/ }),

/***/ 3170:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3171:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3172:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3173:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _BorderLinePicker = __webpack_require__(3174);

Object.keys(_BorderLinePicker).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function get() {
      return _BorderLinePicker[key];
    }
  });
});

/***/ }),

/***/ 3174:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.BorderLinePicker = undefined;

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _boxPicker = __webpack_require__(3175);

var _borderColorPicker = __webpack_require__(3187);

__webpack_require__(3190);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var BorderLinePicker = exports.BorderLinePicker = function (_React$Component) {
    (0, _inherits3.default)(BorderLinePicker, _React$Component);

    function BorderLinePicker() {
        (0, _classCallCheck3.default)(this, BorderLinePicker);

        var _this = (0, _possibleConstructorReturn3.default)(this, (BorderLinePicker.__proto__ || Object.getPrototypeOf(BorderLinePicker)).apply(this, arguments));

        _this.state = {
            colorMenuVisible: false,
            color: '#000000',
            border: ''
        };
        _this.toggleColor = function () {
            _this.setState({
                colorMenuVisible: !_this.state.colorMenuVisible
            });
        };
        _this.onColorClick = function (color) {
            _this.setState({
                color: color
            });
            var border = _this.state.border;

            _this.props.onClick({
                border: border,
                color: color,
                menuVisible: true,
                selected: 'color'
            });
        };
        _this.onBorderClick = function (border) {
            _this.setState({
                border: border
            });
            var color = _this.state.color;

            _this.props.onClick({
                border: border,
                color: color,
                menuVisible: true,
                selected: 'border'
            });
        };
        return _this;
    }

    (0, _createClass3.default)(BorderLinePicker, [{
        key: 'componentDidUpdate',
        value: function componentDidUpdate(nextProps) {
            if (!nextProps.menuVisible) {
                this.setState({
                    colorMenuVisible: false,
                    color: '#000000',
                    border: ''
                });
            }
        }
    }, {
        key: 'render',
        value: function render() {
            var menuVisible = this.props.menuVisible;
            var color = this.state.color;

            return _react2.default.createElement("div", { className: "border-line-picker" }, _react2.default.createElement(_boxPicker.BoxPicker, { onClick: this.onBorderClick }), _react2.default.createElement(_borderColorPicker.BorderColorPicker, { menuVisible: menuVisible, color: color, onClick: this.onColorClick }));
        }
    }]);
    return BorderLinePicker;
}(_react2.default.Component);

/***/ }),

/***/ 3175:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.BoxPicker = undefined;

var _BoxPicker = __webpack_require__(3176);

var _BoxPicker2 = _interopRequireDefault(_BoxPicker);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.BoxPicker = _BoxPicker2.default;

/***/ }),

/***/ 3176:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _BoxLiner = __webpack_require__(3177);

var _BoxLiner2 = _interopRequireDefault(_BoxLiner);

var _sheet = __webpack_require__(713);

__webpack_require__(3186);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var BoxPicker = function (_React$PureComponent) {
    (0, _inherits3.default)(BoxPicker, _React$PureComponent);

    function BoxPicker() {
        (0, _classCallCheck3.default)(this, BoxPicker);
        return (0, _possibleConstructorReturn3.default)(this, (BoxPicker.__proto__ || Object.getPrototypeOf(BoxPicker)).apply(this, arguments));
    }

    (0, _createClass3.default)(BoxPicker, [{
        key: 'render',
        value: function render() {
            var _this2 = this;

            var borderGroups = this.props.borderGroups;

            return _react2.default.createElement("div", { className: "box-picker layout-row" }, borderGroups.map(function (borders, index) {
                return _react2.default.createElement("div", { key: index, className: "box-column layout-column" }, borders.map(function (border, index) {
                    return _react2.default.createElement(_BoxLiner2.default, { key: border, border: border, onClick: function onClick(picked) {
                            return _this2.props.onClick(picked);
                        } });
                }));
            }));
        }
    }]);
    return BoxPicker;
}(_react2.default.PureComponent);

BoxPicker.defaultProps = {
    borderGroups: [[_sheet.SHEET_BORDER.FULL_BORDER, _sheet.SHEET_BORDER.LEFT_BORDER], [_sheet.SHEET_BORDER.OUTER_BORDER, _sheet.SHEET_BORDER.RIGHT_BORDER], [_sheet.SHEET_BORDER.INNER_BORDER, _sheet.SHEET_BORDER.TOP_BORDER], [_sheet.SHEET_BORDER.NO_BORDER, _sheet.SHEET_BORDER.BOTTOM_BORDER]]
};
exports.default = BoxPicker;

/***/ }),

/***/ 3177:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _fullBorder = __webpack_require__(2058);

var _fullBorder2 = _interopRequireDefault(_fullBorder);

var _noBorder = __webpack_require__(3178);

var _noBorder2 = _interopRequireDefault(_noBorder);

var _topBorder = __webpack_require__(3179);

var _topBorder2 = _interopRequireDefault(_topBorder);

var _bottomBorder = __webpack_require__(3180);

var _bottomBorder2 = _interopRequireDefault(_bottomBorder);

var _leftBorder = __webpack_require__(3181);

var _leftBorder2 = _interopRequireDefault(_leftBorder);

var _rightBorder = __webpack_require__(3182);

var _rightBorder2 = _interopRequireDefault(_rightBorder);

var _innerBorder = __webpack_require__(3183);

var _innerBorder2 = _interopRequireDefault(_innerBorder);

var _outerBorder = __webpack_require__(3184);

var _outerBorder2 = _interopRequireDefault(_outerBorder);

var _ToolbarButton = __webpack_require__(1679);

var _sheet = __webpack_require__(713);

__webpack_require__(3185);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var BoxLiner = function (_React$PureComponent) {
    (0, _inherits3.default)(BoxLiner, _React$PureComponent);

    function BoxLiner() {
        (0, _classCallCheck3.default)(this, BoxLiner);

        var _this = (0, _possibleConstructorReturn3.default)(this, (BoxLiner.__proto__ || Object.getPrototypeOf(BoxLiner)).apply(this, arguments));

        _this.state = {
            tipHidden: true
        };
        _this.handleClick = function (event) {
            _this.props.onClick(_this.props.border, event);
        };
        _this.handletipShow = function () {
            _this.setState({
                tipHidden: false
            });
        };
        _this.handleTipHide = function () {
            _this.setState({
                tipHidden: true
            });
        };
        return _this;
    }

    (0, _createClass3.default)(BoxLiner, [{
        key: 'render',
        value: function render() {
            var border = this.props.border;

            var element = void 0;
            var title = void 0;
            var borderAttr = {
                className: 'box-liner__icon',
                onMouseLeave: this.handleTipHide
            };
            switch (border) {
                case _sheet.SHEET_BORDER.FULL_BORDER:
                    element = _react2.default.createElement(_fullBorder2.default, Object.assign({}, borderAttr));
                    title = t('sheet.full_borders');
                    break;
                case _sheet.SHEET_BORDER.NO_BORDER:
                    element = _react2.default.createElement(_noBorder2.default, Object.assign({}, borderAttr));
                    title = t('sheet.no_border');
                    break;
                case _sheet.SHEET_BORDER.TOP_BORDER:
                    element = _react2.default.createElement(_topBorder2.default, Object.assign({}, borderAttr));
                    title = t('sheet.top_border');
                    break;
                case _sheet.SHEET_BORDER.BOTTOM_BORDER:
                    element = _react2.default.createElement(_bottomBorder2.default, Object.assign({}, borderAttr));
                    title = t('sheet.bottom_border');
                    break;
                case _sheet.SHEET_BORDER.LEFT_BORDER:
                    element = _react2.default.createElement(_leftBorder2.default, Object.assign({}, borderAttr));
                    title = t('sheet.left_border');
                    break;
                case _sheet.SHEET_BORDER.RIGHT_BORDER:
                    element = _react2.default.createElement(_rightBorder2.default, Object.assign({}, borderAttr));
                    title = t('sheet.right_border');
                    break;
                case _sheet.SHEET_BORDER.INNER_BORDER:
                    element = _react2.default.createElement(_innerBorder2.default, Object.assign({}, borderAttr));
                    title = t('sheet.inner_borders');
                    break;
                case _sheet.SHEET_BORDER.OUTER_BORDER:
                    element = _react2.default.createElement(_outerBorder2.default, Object.assign({}, borderAttr));
                    title = t('sheet.outer_borders');
                    break;
            }
            return _react2.default.createElement("div", { className: "box-liner", onClick: this.handleClick, onMouseEnter: this.handletipShow }, _react2.default.createElement(_ToolbarButton.ToolbarButton, { className: "box-liner__tip", title: title, tipHidden: this.state.tipHidden }, element));
        }
    }]);
    return BoxLiner;
}(_react2.default.PureComponent);

exports.default = BoxLiner;
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 3178:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ xmlns: "http://www.w3.org/2000/svg", width: "24", height: "24", viewBox: "0 0 24 24", fill: "#424E5D" }, props),
    _react2.default.createElement("path", { d: "M5 5h2v2H5V5zm0 3h2v2H5V8zm0 3h2v2H5v-2zm0 3h2v2H5v-2zm0 3h2v2H5v-2zm3 0h2v2H8v-2zm3 0h2v2h-2v-2zm3 0h2v2h-2v-2zm3 0h2v2h-2v-2zm0-3h2v2h-2v-2zm0-3h2v2h-2v-2zm0-3h2v2h-2V8zM8 5h2v2H8V5zm3 0h2v2h-2V5zm0 3h2v2h-2V8zm0 3h2v2h-2v-2zm-3 0h2v2H8v-2zm6 0h2v2h-2v-2zm-3 3h2v2h-2v-2zm3-9h2v2h-2V5zm3 0h2v2h-2V5z", fillRule: "evenodd", opacity: ".6" })
  );
};

/***/ }),

/***/ 3179:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ xmlns: "http://www.w3.org/2000/svg", width: "24", height: "24", viewBox: "0 0 24 24", fill: "#424E5D" }, props),
    _react2.default.createElement(
      "g",
      { fillRule: "evenodd" },
      _react2.default.createElement("path", { d: "M5 5h2v2H5V5zm0 3h2v2H5V8zm0 3h2v2H5v-2zm0 3h2v2H5v-2zm0 3h2v2H5v-2zm3 0h2v2H8v-2zm3 0h2v2h-2v-2zm3 0h2v2h-2v-2zm3 0h2v2h-2v-2zm0-3h2v2h-2v-2zm0-3h2v2h-2v-2zm0-3h2v2h-2V8zM8 5h2v2H8V5zm3 0h2v2h-2V5zm0 3h2v2h-2V8zm0 3h2v2h-2v-2zm-3 0h2v2H8v-2zm6 0h2v2h-2v-2zm-3 3h2v2h-2v-2zm3-9h2v2h-2V5zm3 0h2v2h-2V5z", opacity: ".6" }),
      _react2.default.createElement("path", { d: "M5 5h14v2H5z" })
    )
  );
};

/***/ }),

/***/ 3180:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ xmlns: "http://www.w3.org/2000/svg", width: "24", height: "24", viewBox: "0 0 24 24", fill: "#424E5D" }, props),
    _react2.default.createElement(
      "g",
      { fillRule: "evenodd" },
      _react2.default.createElement("path", { d: "M5 5h2v2H5V5zm0 3h2v2H5V8zm0 3h2v2H5v-2zm0 3h2v2H5v-2zm0 3h2v2H5v-2zm3 0h2v2H8v-2zm3 0h2v2h-2v-2zm3 0h2v2h-2v-2zm3 0h2v2h-2v-2zm0-3h2v2h-2v-2zm0-3h2v2h-2v-2zm0-3h2v2h-2V8zM8 5h2v2H8V5zm3 0h2v2h-2V5zm0 3h2v2h-2V8zm0 3h2v2h-2v-2zm-3 0h2v2H8v-2zm6 0h2v2h-2v-2zm-3 3h2v2h-2v-2zm3-9h2v2h-2V5zm3 0h2v2h-2V5z", opacity: ".6" }),
      _react2.default.createElement("path", { d: "M5 17h14v2H5z" })
    )
  );
};

/***/ }),

/***/ 3181:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ xmlns: "http://www.w3.org/2000/svg", width: "24", height: "24", viewBox: "0 0 24 24", fill: "#424E5D" }, props),
    _react2.default.createElement(
      "g",
      { fillRule: "evenodd" },
      _react2.default.createElement("path", { d: "M5 5h2v2H5V5zm0 3h2v2H5V8zm0 3h2v2H5v-2zm0 3h2v2H5v-2zm0 3h2v2H5v-2zm3 0h2v2H8v-2zm3 0h2v2h-2v-2zm3 0h2v2h-2v-2zm3 0h2v2h-2v-2zm0-3h2v2h-2v-2zm0-3h2v2h-2v-2zm0-3h2v2h-2V8zM8 5h2v2H8V5zm3 0h2v2h-2V5zm0 3h2v2h-2V8zm0 3h2v2h-2v-2zm-3 0h2v2H8v-2zm6 0h2v2h-2v-2zm-3 3h2v2h-2v-2zm3-9h2v2h-2V5zm3 0h2v2h-2V5z", opacity: ".6" }),
      _react2.default.createElement("path", { d: "M5 5h2v14H5z" })
    )
  );
};

/***/ }),

/***/ 3182:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ xmlns: "http://www.w3.org/2000/svg", width: "24", height: "24", viewBox: "0 0 24 24", fill: "#424E5D" }, props),
    _react2.default.createElement(
      "g",
      { fillRule: "evenodd" },
      _react2.default.createElement("path", { d: "M5 5h2v2H5V5zm0 3h2v2H5V8zm0 3h2v2H5v-2zm0 3h2v2H5v-2zm0 3h2v2H5v-2zm3 0h2v2H8v-2zm3 0h2v2h-2v-2zm3 0h2v2h-2v-2zm3 0h2v2h-2v-2zm0-3h2v2h-2v-2zm0-3h2v2h-2v-2zm0-3h2v2h-2V8zM8 5h2v2H8V5zm3 0h2v2h-2V5zm0 3h2v2h-2V8zm0 3h2v2h-2v-2zm-3 0h2v2H8v-2zm6 0h2v2h-2v-2zm-3 3h2v2h-2v-2zm3-9h2v2h-2V5zm3 0h2v2h-2V5z", opacity: ".6" }),
      _react2.default.createElement("path", { d: "M17 5h2v14h-2z" })
    )
  );
};

/***/ }),

/***/ 3183:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ xmlns: "http://www.w3.org/2000/svg", width: "24", height: "24", viewBox: "0 0 24 24", fill: "#424E5D" }, props),
    _react2.default.createElement(
      "g",
      { fillRule: "evenodd" },
      _react2.default.createElement("path", { d: "M5 5h2v2H5V5zm0 3h2v2H5V8zm0 3h2v2H5v-2zm0 3h2v2H5v-2zm0 3h2v2H5v-2zm3 0h2v2H8v-2zm3 0h2v2h-2v-2zm3 0h2v2h-2v-2zm3 0h2v2h-2v-2zm0-3h2v2h-2v-2zm0-3h2v2h-2v-2zm0-3h2v2h-2V8zM8 5h2v2H8V5zm3 0h2v2h-2V5zm0 3h2v2h-2V8zm0 3h2v2h-2v-2zm-3 0h2v2H8v-2zm6 0h2v2h-2v-2zm-3 3h2v2h-2v-2zm3-9h2v2h-2V5zm3 0h2v2h-2V5z", opacity: ".6" }),
      _react2.default.createElement("path", { xmlns: "http://www.w3.org/2000/svg", d: "M11 11V5h2v6h6v2h-6v6h-2v-6H5v-2h6z" })
    )
  );
};

/***/ }),

/***/ 3184:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ xmlns: "http://www.w3.org/2000/svg", width: "24", height: "24", viewBox: "0 0 24 24", fill: "#424E5D" }, props),
    _react2.default.createElement(
      "g",
      { fillRule: "evenodd" },
      _react2.default.createElement("path", { d: "M5.5 5h13c.28 0 .5.22.5.5v13a.5.5 0 0 1-.5.5h-13a.5.5 0 0 1-.5-.5v-13c0-.28.22-.5.5-.5zM7 7v10h10V7H7z", fillRule: "nonzero" }),
      _react2.default.createElement("path", { d: "M8 11h2v2H8v-2zm6 0h2v2h-2v-2zm-3 3h2v2h-2v-2zm0-6h2v2h-2V8zm0 3h2v2h-2v-2z", opacity: ".6" })
    )
  );
};

/***/ }),

/***/ 3185:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3186:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3187:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.BorderColorPicker = undefined;

var _BorderColorPicker = __webpack_require__(3188);

var _BorderColorPicker2 = _interopRequireDefault(_BorderColorPicker);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.BorderColorPicker = _BorderColorPicker2.default;

/***/ }),

/***/ 3188:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _SheetToolbarItemHelper = __webpack_require__(1678);

var _colorPicker = __webpack_require__(2056);

var _tea = __webpack_require__(47);

__webpack_require__(3189);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var SHEET_OPRATION = 'sheet_opration';
var SHEET_HEAD_TOOLBAR = 'sheet_head_toolbar';

var BorderColorPicker = function (_React$PureComponent) {
    (0, _inherits3.default)(BorderColorPicker, _React$PureComponent);

    function BorderColorPicker() {
        (0, _classCallCheck3.default)(this, BorderColorPicker);

        var _this = (0, _possibleConstructorReturn3.default)(this, (BorderColorPicker.__proto__ || Object.getPrototypeOf(BorderColorPicker)).apply(this, arguments));

        _this.state = {
            colorMenuVisible: false
        };
        _this.toggleColor = function () {
            var colorMenuVisible = _this.state.colorMenuVisible;

            _this._handleColorMenuVisible(!colorMenuVisible);
            _this.setState({
                colorMenuVisible: !colorMenuVisible
            });
        };
        return _this;
    }

    (0, _createClass3.default)(BorderColorPicker, [{
        key: 'componentDidUpdate',
        value: function componentDidUpdate(nextProps) {
            if (!nextProps.menuVisible) {
                this.setState({
                    colorMenuVisible: false
                });
            }
        }
    }, {
        key: '_handleColorMenuVisible',
        value: function _handleColorMenuVisible(visible) {
            if (!visible) return;
            (0, _tea.collectSuiteEvent)(SHEET_OPRATION, {
                action: 'frame_color_open',
                source: SHEET_HEAD_TOOLBAR,
                eventType: 'click'
            });
        }
    }, {
        key: 'render',
        value: function render() {
            var _this2 = this;

            var colorMenuVisible = this.state.colorMenuVisible;
            var color = this.props.color;

            return _react2.default.createElement(_react.Fragment, null, _react2.default.createElement("div", { className: "border-color-picker layout-row layout-main-cross-center", onClick: this.toggleColor }, (0, _SheetToolbarItemHelper.BorderColor)(color)), colorMenuVisible && _react2.default.createElement(_colorPicker.ColorPicker, { color: color, menuVisible: colorMenuVisible, onClick: function onClick(picked) {
                    return _this2.props.onClick(picked && picked.hex);
                } }));
        }
    }]);
    return BorderColorPicker;
}(_react2.default.PureComponent);

exports.default = BorderColorPicker;

/***/ }),

/***/ 3189:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3190:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3191:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M9.41 8h4.09a5.5 5.5 0 0 1 0 11H9a1 1 0 0 1 0-2h4.5a3.5 3.5 0 1 0 0-7H9.41l1.3 1.3a1 1 0 0 1-1.42 1.4L5.6 9l3.7-3.7a1 1 0 0 1 1.42 1.4L9.4 8z", fillRule: "nonzero" })
  );
};

/***/ }),

/***/ 3192:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M14.6 8h-3.98A5.62 5.62 0 0 0 5 13.47 5.39 5.39 0 0 0 10.25 19h4.76a1 1 0 0 0 0-2H10.3A3.39 3.39 0 0 1 7 13.53 3.62 3.62 0 0 1 10.62 10h3.98l-1.28 1.3a1 1 0 0 0 1.42 1.4L18.41 9l-3.67-3.7a1 1 0 0 0-1.42 1.4L14.6 8z", fillRule: "nonzero" })
  );
};

/***/ }),

/***/ 3193:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M13.38 15.12a.5.5 0 0 1-.35.14H9.38a.5.5 0 0 1-.35-.15L5.82 11.9a.5.5 0 0 1 0-.7L12.5 4.5c.2-.2.5-.2.7 0l4.96 5.14c.19.2.19.51 0 .7l-4.78 4.78zm-3.5-5.17l-1.6 1.59L10 13.26h2.4l3.3-3.29-5.82-.02zM5.5 17h13c.28 0 .5.22.5.5v1a.5.5 0 0 1-.5.5h-13a.5.5 0 0 1-.5-.5v-1c0-.28.22-.5.5-.5z", fillRule: "nonzero" })
  );
};

/***/ }),

/***/ 3194:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M15.06 11.57A4 4 0 0 1 13 19H7V5h5a4 4 0 0 1 3.06 6.57zM9 13v4h4a2 2 0 1 0 0-4H9zm0-6v4h3a2 2 0 1 0 0-4H9z", fillRule: "nonzero" })
  );
};

/***/ }),

/***/ 3195:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M15.36 7h2.14a.5.5 0 0 0 .5-.5v-1a.5.5 0 0 0-.5-.5h-7a.5.5 0 0 0-.5.5v1c0 .28.22.5.5.5h1.8a.5.5 0 0 1 .48.66l-2.67 8a.5.5 0 0 1-.47.34H7.5a.5.5 0 0 0-.5.5v1c0 .28.22.5.5.5h7a.5.5 0 0 0 .5-.5v-1a.5.5 0 0 0-.5-.5h-1.8a.5.5 0 0 1-.48-.66l2.67-8a.5.5 0 0 1 .47-.34z", fillRule: "evenodd" })
  );
};

/***/ }),

/***/ 3196:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M15 5.5c0-.28.22-.5.5-.5h1c.28 0 .5.22.5.5V11a5 5 0 0 1-10 0V5.5c0-.28.22-.5.5-.5h1c.28 0 .5.22.5.5V11a3 3 0 0 0 6 0V5.5zm-8.5 12h11c.28 0 .5.22.5.5v.5a.5.5 0 0 1-.5.5h-11a.5.5 0 0 1-.5-.5V18c0-.28.22-.5.5-.5z", fillRule: "nonzero" })
  );
};

/***/ }),

/***/ 3197:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M17.46 13c.36.51.54 1.1.54 1.79 0 2.8-2 4.21-6 4.21-3.7 0-5.69-1.57-6-4.65h2.71c.16.9.5 1.54.97 1.9.47.34 1.2.52 2.24.52 2.14 0 3.24-.62 3.24-1.8 0-.65-.42-1.16-1.2-1.52a8.23 8.23 0 0 0-1.38-.45H4.5a.5.5 0 1 1 0-1h15a.5.5 0 1 1 0 1h-2.04zm-3.54-2h-6.7a2.89 2.89 0 0 1-.88-2.15c0-1.2.5-2.15 1.51-2.82A6.92 6.92 0 0 1 11.82 5c3.5 0 5.42 1.39 5.74 4.19h-2.69c-.2-.72-.52-1.21-.97-1.5a4 4 0 0 0-2.13-.46c-.84 0-1.47.1-1.88.36-.5.26-.73.67-.73 1.19 0 .46.36.84 1.1 1.18.46.2 1.35.46 2.7.8.34.07.66.15.96.24z", fillRule: "evenodd" })
  );
};

/***/ }),

/***/ 3198:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M9 11V9l1.94 2H11v.06l1 1.03L9 15v-2H5v-2h4zm6 2v2l-3-2.91 1-1.03V11h.06L15 9v2h4v2h-4zm2 1h2v4a1 1 0 0 1-1 1h-3.5a.5.5 0 0 1-.5-.5V16h2v1h1v-3zm0-4V7h-1v1h-2V5.5c0-.28.22-.5.5-.5H18a1 1 0 0 1 1 1v4h-2zM5 14h2v3h1v-1h2v2.5a.5.5 0 0 1-.5.5H6a1 1 0 0 1-1-1v-4zm0-4V6a1 1 0 0 1 1-1h3.5c.28 0 .5.22.5.5V8H8V7H7v3H5z", fillRule: "nonzero" })
  );
};

/***/ }),

/***/ 3199:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M5.5 6h13c.28 0 .5.22.5.5v1a.5.5 0 0 1-.5.5h-13a.5.5 0 0 1-.5-.5v-1c0-.28.22-.5.5-.5zm0 5h7c.28 0 .5.22.5.5v1a.5.5 0 0 1-.5.5h-7a.5.5 0 0 1-.5-.5v-1c0-.28.22-.5.5-.5zm0 5h13c.28 0 .5.22.5.5v1a.5.5 0 0 1-.5.5h-13a.5.5 0 0 1-.5-.5v-1c0-.28.22-.5.5-.5z", fillRule: "evenodd" })
  );
};

/***/ }),

/***/ 3200:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M5.5 6h13c.28 0 .5.22.5.5v1a.5.5 0 0 1-.5.5h-13a.5.5 0 0 1-.5-.5v-1c0-.28.22-.5.5-.5zm6 5h7c.28 0 .5.22.5.5v1a.5.5 0 0 1-.5.5h-7a.5.5 0 0 1-.5-.5v-1c0-.28.22-.5.5-.5zm-6 5h13c.28 0 .5.22.5.5v1a.5.5 0 0 1-.5.5h-13a.5.5 0 0 1-.5-.5v-1c0-.28.22-.5.5-.5z", fillRule: "evenodd" })
  );
};

/***/ }),

/***/ 3201:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M5.5 6h13c.28 0 .5.22.5.5v1a.5.5 0 0 1-.5.5h-13a.5.5 0 0 1-.5-.5v-1c0-.28.22-.5.5-.5zm3 5h7c.28 0 .5.22.5.5v1a.5.5 0 0 1-.5.5h-7a.5.5 0 0 1-.5-.5v-1c0-.28.22-.5.5-.5zm-3 5h13c.28 0 .5.22.5.5v1a.5.5 0 0 1-.5.5h-13a.5.5 0 0 1-.5-.5v-1c0-.28.22-.5.5-.5z", fillRule: "evenodd" })
  );
};

/***/ }),

/***/ 3202:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M11 10H9l2.91-3L15 10h-2v10h-2V10zM5.5 4h13c.28 0 .5.22.5.5v1a.5.5 0 0 1-.5.5h-13a.5.5 0 0 1-.5-.5v-1c0-.28.22-.5.5-.5z", fillRule: "evenodd" })
  );
};

/***/ }),

/***/ 3203:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M13 14h2l-2 1.94V16h-.06l-1.03 1L9 14h2V4h2v10zm-7.5 4h13c.28 0 .5.22.5.5v1a.5.5 0 0 1-.5.5h-13a.5.5 0 0 1-.5-.5v-1c0-.28.22-.5.5-.5z", fillRule: "evenodd" })
  );
};

/***/ }),

/***/ 3204:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M11 17H9l2.91-3L15 17h-2v3h-2v-3zm2-10h2l-3.09 3L9 7h2V4h2v3zm-7.5 4h13c.28 0 .5.22.5.5v1a.5.5 0 0 1-.5.5h-13a.5.5 0 0 1-.5-.5v-1c0-.28.22-.5.5-.5z", fillRule: "evenodd" })
  );
};

/***/ }),

/***/ 3205:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M11 16v2l-3-2.91L11 12v2h1a2 2 0 1 0 0-4H9V8h3a4 4 0 1 1 0 8h-1zM5.5 5h1c.28 0 .5.22.5.5v13a.5.5 0 0 1-.5.5h-1a.5.5 0 0 1-.5-.5v-13c0-.28.22-.5.5-.5zm12 0h1c.28 0 .5.22.5.5v13a.5.5 0 0 1-.5.5h-1a.5.5 0 0 1-.5-.5v-13c0-.28.22-.5.5-.5z", fillRule: "evenodd" })
  );
};

/***/ }),

/***/ 3206:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M16 11V9l3 3.09L16 15v-2h-5.5a.5.5 0 0 1-.5-.5v-1c0-.28.22-.5.5-.5H16zm-2-1h-2V4.5c0-.28.22-.5.5-.5h1c.28 0 .5.22.5.5V10zm0 4v5.5a.5.5 0 0 1-.5.5h-1a.5.5 0 0 1-.5-.5V14h2zM5.5 5h1c.28 0 .5.22.5.5v13a.5.5 0 0 1-.5.5h-1a.5.5 0 0 1-.5-.5v-13c0-.28.22-.5.5-.5z", fillRule: "evenodd" })
  );
};

/***/ }),

/***/ 3207:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M17 10.5h-3.02l-.44 1.25h-1.6l2.47-6.92a1 1 0 0 1 .92-.67h.3a1 1 0 0 1 .96.66l2.47 6.93h-1.61L17 10.5zM16.49 9l-.98-2.77L14.52 9h1.96zm2.51 5.5L14.47 18H19v1.5h-7V18h.02l4.52-3.5H12V13h7v1.5zM8 8v12H6V9H4l4-5v4z", fillRule: "nonzero" })
  );
};

/***/ }),

/***/ 3208:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M17 18.5h-3.02l-.44 1.25h-1.6l2.47-6.92a1 1 0 0 1 .92-.67h.3a1 1 0 0 1 .96.66l2.47 6.93h-1.61L17 18.5zm-.52-1.5l-.98-2.77-.98 2.77h1.96zm2.51-10.5L14.47 10H19v1.5h-7V10h.02l4.52-3.5H12V5h7v1.5zM8 17v3l-4-5h2V5h2v12z", fillRule: "nonzero" })
  );
};

/***/ }),

/***/ 3209:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M6.38 7.64A1.5 1.5 0 0 1 7.35 5H17v2H8.7l5.84 5-5.84 5H17v2H7.35a1.5 1.5 0 0 1-.97-2.64L11.46 12 6.38 7.64z", fillRule: "nonzero" })
  );
};

/***/ }),

/***/ 3210:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M5.97 5h13.06a.5.5 0 0 1 .4.8l-4.34 6.07a.5.5 0 0 0-.09.29v4.56a.5.5 0 0 1-.24.43l-4 2.4a.5.5 0 0 1-.76-.43v-6.96a.5.5 0 0 0-.1-.29L5.57 5.79A.5.5 0 0 1 5.97 5zM8.9 7l2.64 3.7c.3.43.47.94.47 1.46v4.3l1-.6v-3.7c0-.52.16-1.03.47-1.45L16.1 7H8.9z", fillRule: "nonzero" })
  );
};

/***/ }),

/***/ 3211:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M17.58 15.17l1.93 1.93c.2.2.2.5 0 .7l-.7.71a.5.5 0 0 1-.71 0l-1.93-1.93a3.5 3.5 0 1 1 1.41-1.41zM5.5 5h13c.28 0 .5.22.5.5v1a.5.5 0 0 1-.5.5h-13a.5.5 0 0 1-.5-.5v-1c0-.28.22-.5.5-.5zm0 6h4c.28 0 .5.22.5.5v1a.5.5 0 0 1-.5.5h-4a.5.5 0 0 1-.5-.5v-1c0-.28.22-.5.5-.5zm0 6h5c.28 0 .5.22.5.5v1a.5.5 0 0 1-.5.5h-5a.5.5 0 0 1-.5-.5v-1c0-.28.22-.5.5-.5zm9-2a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3z", fillRule: "evenodd" })
  );
};

/***/ }),

/***/ 3212:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M11 16v2H9A6 6 0 1 1 9 6h2v2H9a4 4 0 1 0 0 8h2zm2 0h2a4 4 0 1 0 0-8h-2V6h2a6 6 0 1 1 0 12h-2v-2zm-3-5h4a1 1 0 0 1 0 2h-4a1 1 0 0 1 0-2z", fillRule: "nonzero" })
  );
};

/***/ }),

/***/ 3213:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M5.6 5h12.8c.88 0 1.6.69 1.6 1.53V16.6c0 .85-.77 1.85-1.66 1.85h-3.6a.81.81 0 0 0-.64.3l-1.52 1.94a.82.82 0 0 1-1.28 0l-1.52-1.94a.81.81 0 0 0-.64-.3h-3.6c-.88 0-1.54-1-1.54-1.85V6.53C4 5.7 4.72 5 5.6 5zM6 7v9.28h3c1 0 1.94.45 2.56 1.24l.38.48.38-.48a3.26 3.26 0 0 1 2.56-1.24H18V7H6zm4 4h4a1 1 0 0 1 0 2h-4a1 1 0 0 1 0-2z", fillRule: "nonzero" })
  );
};

/***/ }),

/***/ 3214:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ xmlns: "http://www.w3.org/2000/svg", width: "24", height: "24", viewBox: "0 0 24 24" }, props),
    _react2.default.createElement("path", { d: "M6 4h12a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6c0-1.1.9-2 2-2zm0 2v12h12V6H6zm8.3 4.3a1 1 0 0 1 1.4 1.4L12 15.42l-3.7-3.7a1 1 0 0 1 1.4-1.42l2.3 2.3 2.3-2.3z" })
  );
};

/***/ }),

/***/ 3215:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M6 10a2 2 0 0 0-2 2c0 1.1.9 2 2 2a2 2 0 0 0 2-2 2 2 0 0 0-2-2zm12 0a2 2 0 0 0-2 2c0 1.1.9 2 2 2a2 2 0 0 0 2-2 2 2 0 0 0-2-2zm-6 0a2 2 0 0 0-2 2c0 1.1.9 2 2 2a2 2 0 0 0 2-2 2 2 0 0 0-2-2z", fillRule: "evenodd" })
  );
};

/***/ }),

/***/ 3216:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M17 11.76V7H7v6.26l.56-.6a2.63 2.63 0 0 1 3.37-.43c.3.2.68.16.94-.08l1.85-1.72a1.5 1.5 0 0 1 2.12.08L17 11.76zm0 2.95l-2.29-2.48-1.48 1.39c-.93.86-2.33.98-3.39.29a.63.63 0 0 0-.8.1L7 16.2V17h10v-2.29zM6 5h12a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1zm3 5a1 1 0 1 1 0-2 1 1 0 0 1 0 2z", fillRule: "nonzero" })
  );
};

/***/ }),

/***/ 3217:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M6.7 16.14a1 1 0 1 1-1.4-1.41L12.01 8l6.73 6.73a1 1 0 0 1-1.42 1.41l-5.31-5.31-5.31 5.31z", fillRule: "nonzero" })
  );
};

/***/ }),

/***/ 3218:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M17 13H9.5a.5.5 0 0 1-.5-.5v-1c0-.28.22-.5.5-.5H17V5.5c0-.28.22-.5.5-.5h1c.28 0 .5.22.5.5v13a.5.5 0 0 1-.5.5h-1a.5.5 0 0 1-.5-.5V13zM5.5 5h1c.28 0 .5.22.5.5v13a.5.5 0 0 1-.5.5h-1a.5.5 0 0 1-.5-.5v-13c0-.28.22-.5.5-.5z", fillRule: "evenodd" })
  );
};

/***/ }),

/***/ 3219:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ xmlns: "http://www.w3.org/2000/svg", width: "24", height: "24", viewBox: "0 0 24 24" }, props),
    _react2.default.createElement(
      "g",
      { xmlns: "http://www.w3.org/2000/svg", fillRule: "nonzero" },
      _react2.default.createElement("path", { xmlns: "http://www.w3.org/2000/svg", d: "M14.98 10.2l-2.44-2.52L7.3 13.2 7 16l2.73-.25 5.25-5.55zm-1.7-3.3l2.45 2.52L17 8.08c.67-.7.67-1.85 0-2.55-.67-.7-1.75-.7-2.41 0L13.28 6.9z", fill: "#424E5D" }),
      _react2.default.createElement("rect", { width: "16", height: "2", x: "4", y: "17", rx: "1" })
    )
  );
};

/***/ }),

/***/ 3220:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
var wrapperDom = null;
var createFoldPlate = exports.createFoldPlate = function createFoldPlate() {
    if (wrapperDom) {
        return wrapperDom;
    }
    wrapperDom = document.createElement('div');
    wrapperDom.className = 'toolbar-plate-wrapper';
    wrapperDom.style.position = 'fixed';
    wrapperDom.style.right = '12px';
    wrapperDom.style.display = 'none';
    wrapperDom.style.zIndex = '88';
    window.addEventListener('click', function (e) {
        var srcElement = e.srcElement;
        while (srcElement) {
            if (srcElement === wrapperDom) {
                return;
            }
            srcElement = srcElement.parentNode;
        }
        if (wrapperDom && wrapperDom.style.display !== 'none') {
            wrapperDom.style.display = 'none';
        }
    });
    document.body.appendChild(wrapperDom);
    return wrapperDom;
};

/***/ }),

/***/ 3221:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3222:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _reactRedux = __webpack_require__(238);

var _redux = __webpack_require__(65);

var _sheet = __webpack_require__(713);

var _sheet2 = __webpack_require__(715);

var _toolbarHelper = __webpack_require__(1606);

var toolbarHelper = _interopRequireWildcard(_toolbarHelper);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * 用来响应sheet的事件，更新其他组件需要的状态数据
 * 如：toolbar的Status, coord
 */
var SheetStatusCollector = function (_React$Component) {
    (0, _inherits3.default)(SheetStatusCollector, _React$Component);

    function SheetStatusCollector() {
        (0, _classCallCheck3.default)(this, SheetStatusCollector);

        var _this = (0, _possibleConstructorReturn3.default)(this, (SheetStatusCollector.__proto__ || Object.getPrototypeOf(SheetStatusCollector)).apply(this, arguments));

        _this._updateStatus = null;
        return _this;
    }

    (0, _createClass3.default)(SheetStatusCollector, [{
        key: 'componentWillMount',
        value: function componentWillMount() {
            var spread = this.props.spread;

            this.updateStatus(spread);
            this.bindEvents(spread);
        }
    }, {
        key: 'componentWillUpdate',
        value: function componentWillUpdate(nextProps) {
            if (this.props.spread !== nextProps.spread) {
                this.unbindEvents(this.props.spread);
            }
        }
    }, {
        key: 'componentDidUpdate',
        value: function componentDidUpdate(prevProps) {
            var spread = this.props.spread;

            if (spread !== prevProps.spread) {
                this.bindEvents(spread);
                this.updateStatus(spread);
            }
        }
    }, {
        key: 'componentWillUnmount',
        value: function componentWillUnmount() {
            this.unbindEvents(this.props.spread);
        }
    }, {
        key: 'getBindList',
        value: function getBindList() {
            return [_sheet.Events.CommandExecuted, _sheet.Events.SelectionChanged, _sheet.Events.DragDropBlockCompleted, _sheet.Events.ClipboardPasted, _sheet.Events.ActiveSheetChanged];
        }
    }, {
        key: 'bindEvents',
        value: function bindEvents(spread) {
            var _this2 = this;

            if (spread == null) return;
            this._updateStatus = this.updateStatus.bind(this, spread);
            this.getBindList().forEach(function (e) {
                spread.bind(e, _this2._updateStatus);
            });
        }
    }, {
        key: 'unbindEvents',
        value: function unbindEvents(spread) {
            var _this3 = this;

            if (spread == null || this._updateStatus == null) return;
            this.getBindList().forEach(function (e) {
                spread.unbind(e, _this3._updateStatus);
            });
            this._updateStatus = null;
        }
    }, {
        key: 'updateStatus',
        value: function updateStatus(spread) {
            if (this.checkEmptySheet(spread)) return;
            var cellStatus = toolbarHelper.cellStatus(spread);
            var rangeStatus = toolbarHelper.rangeStatus(spread);
            var sheet = spread.getActiveSheet();
            var col = sheet.getActiveColumnIndex();
            var row = sheet.getActiveRowIndex();
            var isFiltered = toolbarHelper.hasFilter(spread);
            this.props.updateSheetStatus({
                cellStatus: cellStatus,
                rangeStatus: rangeStatus,
                coord: { row: row, col: col },
                emptySheet: false,
                isFiltered: isFiltered
            });
        }
    }, {
        key: 'checkEmptySheet',
        value: function checkEmptySheet(spread) {
            var emptySheet = !spread || !spread.getActiveSheet();
            if (this.props.status.emptySheet !== emptySheet) {
                this.props.updateSheetStatus({ emptySheet: true });
            }
            return emptySheet;
        }
    }, {
        key: 'render',
        value: function render() {
            return null;
        }
    }]);
    return SheetStatusCollector;
}(_react2.default.Component);

exports.default = (0, _reactRedux.connect)(function (state) {
    return {
        status: state.sheet.status
    };
}, function (dispatch) {
    return (0, _redux.bindActionCreators)({
        updateSheetStatus: _sheet2.updateSheetStatus
    }, dispatch);
})(SheetStatusCollector);

/***/ }),

/***/ 3223:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _footerstatus = __webpack_require__(3224);

var _footerstatus2 = _interopRequireDefault(_footerstatus);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.default = _footerstatus2.default;

/***/ }),

/***/ 3224:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _reactRedux = __webpack_require__(238);

__webpack_require__(3225);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var FooterStatus = function (_React$PureComponent) {
    (0, _inherits3.default)(FooterStatus, _React$PureComponent);

    function FooterStatus() {
        (0, _classCallCheck3.default)(this, FooterStatus);

        var _this = (0, _possibleConstructorReturn3.default)(this, (FooterStatus.__proto__ || Object.getPrototypeOf(FooterStatus)).apply(this, arguments));

        _this.setRef = function (ref) {
            _this.ref = ref;
        };
        return _this;
    }

    (0, _createClass3.default)(FooterStatus, [{
        key: 'componentDidMount',
        value: function componentDidMount() {
            this.clientWidth = this.ref.clientWidth;
        }
    }, {
        key: 'componentDidUpdate',
        value: function componentDidUpdate() {
            var clientWidth = this.ref.clientWidth;
            if (this.clientWidth !== clientWidth) {
                this.clientWidth = clientWidth;
                this.props.onWidthChange && this.props.onWidthChange();
            }
        }
    }, {
        key: 'render',
        value: function render() {
            var rangeStatus = this.props.rangeStatus;
            var sum = rangeStatus.sum,
                average = rangeStatus.average,
                count = rangeStatus.count;

            return _react2.default.createElement("div", { className: "footer-status layout-row layout-cross-center", ref: this.setRef }, count !== 0 && _react2.default.createElement("div", { className: "footer-status__item" }, t('sheet.footer_status.count'), ": ", count), count > 1 && _react2.default.createElement("div", { className: "footer-status__item" }, t('sheet.footer_status.sum'), ": ", sum), count > 1 && _react2.default.createElement("div", { className: "footer-status__item" }, t('sheet.footer_status.average'), ": ", average));
        }
    }]);
    return FooterStatus;
}(_react2.default.PureComponent);

exports.default = (0, _reactRedux.connect)(function (state) {
    return {
        rangeStatus: state.sheet.toolbar.rangeStatus
    };
})(FooterStatus);
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 3225:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3226:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _SheetExportFile = __webpack_require__(3227);

var _SheetExportFile2 = _interopRequireDefault(_SheetExportFile);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.default = _SheetExportFile2.default;

/***/ }),

/***/ 3227:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t, Buffer) {

Object.defineProperty(exports, "__esModule", {
    value: true
});

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _reactRedux = __webpack_require__(238);

var _redux = __webpack_require__(65);

var _sheet = __webpack_require__(715);

var _sheet2 = __webpack_require__(713);

var _CSVHelper = __webpack_require__(3228);

var _common = __webpack_require__(19);

var _utils = __webpack_require__(1575);

var _sheet3 = __webpack_require__(1597);

var _tea = __webpack_require__(47);

var _workbook = __webpack_require__(1995);

var _toast = __webpack_require__(500);

var _toast2 = _interopRequireDefault(_toast);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var EXPORT_FILE_WHILE_LOADING = '__EXPORT_FILE_WHILE_LOADING__';
var EXPORT_FILE = '__SHEET_EXPORT_FILE__';

var SheetExportFile = function (_React$Component) {
    (0, _inherits3.default)(SheetExportFile, _React$Component);

    function SheetExportFile() {
        (0, _classCallCheck3.default)(this, SheetExportFile);

        var _this = (0, _possibleConstructorReturn3.default)(this, (SheetExportFile.__proto__ || Object.getPrototypeOf(SheetExportFile)).apply(this, arguments));

        _this.isExporting = false;
        return _this;
    }

    (0, _createClass3.default)(SheetExportFile, [{
        key: 'componentWillMount',
        value: function componentWillMount() {
            if (this.props.spread != null) {
                this.exportFile();
            }
        }
    }, {
        key: 'shouldComponentUpdate',
        value: function shouldComponentUpdate(nextProps) {
            if (!nextProps.fileExport.isExport) {
                return false;
            }
            return true;
        }
    }, {
        key: 'componentDidUpdate',
        value: function componentDidUpdate(prevProps) {
            if (this.props.spread != null) {
                this.exportFile();
            }
        }
    }, {
        key: 'exportFile',
        value: function exportFile() {
            var _this2 = this;

            var isExport = this.props.fileExport.isExport;

            if (isExport && !this.isExporting && this.props.loaded) {
                var beforeExport = function beforeExport() {
                    _this2.isExporting = true;
                    _this2.props.freezeSheet(true);
                    _utils.utils.addSyncToast(EXPORT_FILE, 'loading', t('sheet.exporting'));
                };
                var afterExport = function afterExport() {
                    _this2.isExporting = false;
                    setTimeout(function () {
                        return _this2.props.freezeSheet(false);
                    });
                    _utils.utils.removeSyncToast(EXPORT_FILE);
                };
                switch (this.props.fileExport.fileType) {
                    case _sheet2.EXPORT_FILE_TYPE.CSV:
                        this.exportCSV(beforeExport, afterExport);
                }
            }
            if (isExport && !this.props.loaded) {
                _toast2.default.show({
                    key: EXPORT_FILE_WHILE_LOADING,
                    type: 'error',
                    content: t('sheet.error.export_while_loading'),
                    duration: 3000,
                    closable: false
                });
            }
            isExport && this.props.exportFile({
                isExport: false
            });
        }
    }, {
        key: 'saveFile',
        value: function saveFile(data, fileName, mimeType) {
            var blob = new Blob([data], { type: mimeType });
            if (window.navigator.msSaveOrOpenBlob) {
                window.navigator.msSaveBlob(blob, fileName);
            } else {
                var element = window.document.createElement('a');
                var URL = window.URL.createObjectURL(blob);
                element.href = URL;
                element.download = fileName;
                document.body.appendChild(element);
                element.click();
                document.body.removeChild(element);
                window.URL.revokeObjectURL(URL);
            }
        }
    }, {
        key: 'exportCSV',
        value: function exportCSV(beforeCb, afterCb) {
            var _this3 = this;

            var sheet = this.props.spread.getActiveSheet();
            beforeCb();
            setTimeout(function () {
                try {
                    var data = (0, _CSVHelper.getSheetCSV)(sheet) || '';
                    var spreadName = _this3.props.title;
                    var name = spreadName + ' - ' + sheet.name() + '.' + _common.CSVSuffix;
                    // Excel 需要 BOM 头来说明它是 UTF-8
                    // https://www.zhihu.com/question/21869078/answer/350728339
                    var BOM = Buffer.from('\uFEFF');
                    var bomCSV = Buffer.concat([BOM, Buffer.from(data)]);
                    _this3.saveFile(bomCSV.toString(), name, _common.CSVMimeTypes);
                    (0, _tea.collectSuiteEvent)('click_export', {
                        module: 'sheet',
                        file_type: 'sheet',
                        export_file_type: 'csv',
                        status_name: 'success'
                    });
                } catch (e) {
                    // Raven上报
                    window.Raven && window.Raven.captureException(e);
                    // ConsoleError
                    console.error(e);
                    (0, _tea.collectSuiteEvent)('click_export', {
                        module: 'sheet',
                        file_type: 'sheet',
                        export_file_type: 'csv',
                        status_name: 'fail'
                    });
                    sheet._raiseInvalidOperation(_workbook.InvalidOperationType.exportFile, t('sheet.error.export_file'));
                    throw e;
                } finally {
                    afterCb();
                }
            });
        }
    }, {
        key: 'render',
        value: function render() {
            return null;
        }
    }]);
    return SheetExportFile;
}(_react2.default.Component);

exports.default = (0, _reactRedux.connect)(function (state) {
    return {
        fileExport: state.sheet.fileExport,
        title: (0, _sheet3.titleSelector)(state),
        loaded: state.sheet.fetchState.spreadState.loaded
    };
}, function (dispatch) {
    return (0, _redux.bindActionCreators)({
        exportFile: _sheet.exportFile
    }, dispatch);
})(SheetExportFile);
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28), __webpack_require__(714).Buffer))

/***/ }),

/***/ 3228:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.default = undefined;

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

exports.getRangeCSV = getRangeCSV;
exports.getSheetCSV = getSheetCSV;
exports.getNotEmptyRange = getNotEmptyRange;

var _csvSerializer = __webpack_require__(1785);

var _util = __webpack_require__(1568);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var CSVExportSerializer = function (_CsvSerializer) {
    (0, _inherits3.default)(CSVExportSerializer, _CsvSerializer);

    function CSVExportSerializer() {
        (0, _classCallCheck3.default)(this, CSVExportSerializer);

        var _this = (0, _possibleConstructorReturn3.default)(this, (CSVExportSerializer.__proto__ || Object.getPrototypeOf(CSVExportSerializer)).apply(this, arguments));

        _this.columnDelimiter = _csvSerializer.CsvDelimiter.commaDelimiter;
        return _this;
    }

    (0, _createClass3.default)(CSVExportSerializer, [{
        key: 'serializeCell',
        value: function serializeCell(row, col, sheetArea) {
            if (this.isHiddenInSpan(row, col, sheetArea)) {
                return '';
            }
            var forceCellDelimiter = this.forceCellDelimiter,
                columnDelimiter = this.columnDelimiter,
                cellDelimiter = this.cellDelimiter,
                sheet = this.sheet;

            var cellStr = sheet.getText(row, col, sheetArea) || '';
            // 对双引号进行转义
            var cellDelimiterReg = new RegExp(cellDelimiter, 'g');
            var rowDelimiter = '\n';
            var shouldAddCellDelimiter = forceCellDelimiter || cellStr.indexOf(columnDelimiter) > -1 || cellStr.indexOf(rowDelimiter) > -1;
            cellStr = cellStr.replace(cellDelimiterReg, cellDelimiter + cellDelimiter);
            if (shouldAddCellDelimiter) {
                cellStr = cellDelimiter + cellStr + cellDelimiter;
            }
            return cellStr;
        }
    }]);
    return CSVExportSerializer;
}(_csvSerializer.CsvSerializer);

exports.default = CSVExportSerializer;
function getRangeCSV(sheet, range) {
    // 筛选器
    var rowFilter = sheet.rowFilter();
    var ignoredRows = rowFilter && rowFilter.toJSON().filteredOutRows || [];
    var serializer = new CSVExportSerializer();
    serializer.sheet = sheet;
    serializer.range = range;
    serializer.ignoredRows = ignoredRows;
    serializer.ignoredCols = [];
    serializer.forceCellDelimiter = false;
    return serializer.serialize();
}
function getSheetCSV(sheet) {
    var range = getNotEmptyRange(sheet);
    if (range.rowCount === 0) return;
    return getRangeCSV(sheet, range);
}
function getNotEmptyRange(sheet) {
    var dataTable = sheet._dataModel.dataTable;
    var rows = Object.keys(dataTable).sort(function (a, b) {
        return parseInt(a, 10) - parseInt(b, 10);
    });
    var lastNonNullRow = -1;
    for (var i = rows.length - 1; i >= 0; i--) {
        var row = parseInt(rows[i], 10);
        var rowTable = dataTable[row] || {};
        var cells = Object.keys(rowTable);
        var isEmpty = true;
        for (var j = 0; j < cells.length; j++) {
            var cell = cells[j] && rowTable[cells[j]];
            if (cell && cell.value) {
                isEmpty = false;
                break;
            }
        }
        if (!isEmpty) {
            lastNonNullRow = row;
            break;
        }
    }
    return new _util.Range(0, 0, lastNonNullRow + 1, sheet.getColumnCount());
}

/***/ }),

/***/ 3229:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _AddRows = __webpack_require__(3230);

Object.keys(_AddRows).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function get() {
      return _AddRows[key];
    }
  });
});

/***/ }),

/***/ 3230:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.AddRows = undefined;

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _tea = __webpack_require__(47);

var _inputNumber = __webpack_require__(3231);

var _toolbarHelper = __webpack_require__(1606);

var toolbarHelper = _interopRequireWildcard(_toolbarHelper);

var _add = __webpack_require__(3234);

var _add2 = _interopRequireDefault(_add);

var _shellNotify = __webpack_require__(1576);

__webpack_require__(3235);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var AddRows = exports.AddRows = function (_React$PureComponent) {
    (0, _inherits3.default)(AddRows, _React$PureComponent);

    function AddRows() {
        (0, _classCallCheck3.default)(this, AddRows);

        var _this = (0, _possibleConstructorReturn3.default)(this, (AddRows.__proto__ || Object.getPrototypeOf(AddRows)).apply(this, arguments));

        _this.state = {
            rowCount: 200,
            visible: false,
            top: 0
        };
        _this.calcTop = function () {
            var sheet = _this.props.spread.getActiveSheet();
            if (sheet === null) return;
            var col = 0;
            var row = sheet.getRowCount() - 1;
            var lastRowLayout = sheet.getCellRect(row, col);
            if (!lastRowLayout) {
                return;
            }
            var top = lastRowLayout.y + lastRowLayout.height + 5;
            var viewRect = sheet.sheetContentRect();
            var visible = viewRect.y + viewRect.height > top + 20;
            _this.setState({ top: top, visible: visible });
        };
        _this.handleChange = function (val) {
            _this.setState({ rowCount: val });
        };
        _this.handleClick = function () {
            var count = _this.state.rowCount;
            if (!count) return;
            var rowCount = _this.props.spread.getActiveSheet().getRowCount();
            toolbarHelper.setRowColChange(_this.props.spread.getActiveSheet(), {
                type: 'row',
                method: 'add',
                target: rowCount,
                count: count,
                source: rowCount - 1
            });
            (0, _tea.collectSuiteEvent)('click_add_sheet_range', {
                add_range_direction: 'down',
                range_type: 'row',
                range_num: count,
                source: 'sheet_bottom_statusbar'
            });
        };
        return _this;
    }

    (0, _createClass3.default)(AddRows, [{
        key: 'componentDidMount',
        value: function componentDidMount() {
            var _this2 = this;

            this.setState({ visible: true });
            var sheet = this.props.spread.getActiveSheet();
            sheet.notifyShell(_shellNotify.ShellNotifyType.BindAddRowPosition, {
                key: 'addRow',
                col: 0,
                row: sheet.getRowCount(),
                cb: function cb(v) {
                    _this2.calcTop();
                }
            });
        }
    }, {
        key: 'componentWillReceiveProps',
        value: function componentWillReceiveProps(nextProps) {
            var _this3 = this;

            if (this.props.spread !== nextProps.spread) {
                // unbind
                var sheet = this.props.spread.getActiveSheet();
                sheet.notifyShell(_shellNotify.ShellNotifyType.UnbindAddRowPosition, { key: 'addRow' });
                // bind
                var nextSheet = nextProps.spread.getActiveSheet();
                nextSheet.notifyShell(_shellNotify.ShellNotifyType.BindAddRowPosition, {
                    key: 'addRow',
                    col: 0,
                    row: sheet.getRowCount(),
                    cb: function cb(v) {
                        _this3.calcTop();
                    }
                });
            }
        }
    }, {
        key: 'render',
        value: function render() {
            var props = this.props,
                state = this.state;

            if (!props.editable || !state.visible) return null;
            return _react2.default.createElement("div", { className: "sheet-add-rows layout-row", style: { top: state.top } }, _react2.default.createElement("span", { className: "sheet-add-rows__addon layout-row layout-main-cross-center" }, _react2.default.createElement("button", { className: "sheet-add-rows__button", onClick: this.handleClick }, _react2.default.createElement(_add2.default, { className: "sheet-add-rows__icon" }))), _react2.default.createElement(_inputNumber.InputNumber, { className: "sheet-add-rows__input-number", min: 1, max: 1000, value: this.state.rowCount, onChange: this.handleChange }), t('common.row'));
        }
    }]);
    return AddRows;
}(_react2.default.PureComponent);
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 3231:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _InputNumber = __webpack_require__(3232);

Object.keys(_InputNumber).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function get() {
      return _InputNumber[key];
    }
  });
});

/***/ }),

/***/ 3232:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.InputNumber = undefined;

var _objectWithoutProperties2 = __webpack_require__(26);

var _objectWithoutProperties3 = _interopRequireDefault(_objectWithoutProperties2);

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _isNumber2 = __webpack_require__(509);

var _isNumber3 = _interopRequireDefault(_isNumber2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _classnames = __webpack_require__(29);

var _classnames2 = _interopRequireDefault(_classnames);

__webpack_require__(3233);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var InputNumber = exports.InputNumber = function (_React$PureComponent) {
    (0, _inherits3.default)(InputNumber, _React$PureComponent);

    function InputNumber() {
        (0, _classCallCheck3.default)(this, InputNumber);

        var _this = (0, _possibleConstructorReturn3.default)(this, (InputNumber.__proto__ || Object.getPrototypeOf(InputNumber)).apply(this, arguments));

        _this.handleChange = function (e) {
            var props = _this.props;
            var max = props.max,
                min = props.min;

            var target = e.target;
            var value = target.value;
            // 仅能输入数字，其他字符都过滤掉
            value = value && value.replace(/([^0-9]+)/g, '');
            var val = parseInt(value, 10);
            // NaN 则设置为 undefined
            val = isNaN(val) ? undefined : val;
            if (val !== undefined) {
                if ((0, _isNumber3.default)(max) && val > max) {
                    val = max;
                }
                if ((0, _isNumber3.default)(min) && val < min) {
                    val = min;
                }
            }
            props.onChange && props.onChange(val);
        };
        return _this;
    }

    (0, _createClass3.default)(InputNumber, [{
        key: 'render',
        value: function render() {
            var _props = this.props,
                max = _props.max,
                min = _props.min,
                onChange = _props.onChange,
                className = _props.className,
                _props$value = _props.value,
                value = _props$value === undefined ? '' : _props$value,
                other = (0, _objectWithoutProperties3.default)(_props, ['max', 'min', 'onChange', 'className', 'value']);

            return _react2.default.createElement("input", Object.assign({}, other, { value: value, className: (0, _classnames2.default)('sheet-input-number', className), onChange: this.handleChange }));
        }
    }]);
    return InputNumber;
}(_react2.default.PureComponent);

/***/ }),

/***/ 3233:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3234:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "12", height: "12", viewBox: "0 0 12 12", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M5 5V2a1 1 0 1 1 2 0v3h3a1 1 0 0 1 0 2H7v3a1 1 0 0 1-2 0V7H2a1 1 0 1 1 0-2h3z", fillRule: "evenodd" })
  );
};

/***/ }),

/***/ 3235:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3236:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3237:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});

var _regenerator = __webpack_require__(13);

var _regenerator2 = _interopRequireDefault(_regenerator);

var _asyncToGenerator2 = __webpack_require__(99);

var _asyncToGenerator3 = _interopRequireDefault(_asyncToGenerator2);

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _typeof2 = __webpack_require__(76);

var _typeof3 = _interopRequireDefault(_typeof2);

var _findIndex2 = __webpack_require__(279);

var _findIndex3 = _interopRequireDefault(_findIndex2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _bind = __webpack_require__(503);

var _redux = __webpack_require__(65);

var _reactRedux = __webpack_require__(238);

var _sheet = __webpack_require__(713);

var _sheet2 = __webpack_require__(1597);

var _sheet3 = __webpack_require__(715);

var _tea = __webpack_require__(47);

var _collaborative = __webpack_require__(1607);

var _info = __webpack_require__(3238);

var _info2 = _interopRequireDefault(_info);

var _MentionNotificationQueue = __webpack_require__(2047);

var _MentionNotificationQueue2 = _interopRequireDefault(_MentionNotificationQueue);

var _const = __webpack_require__(1581);

var _hyperlink = __webpack_require__(2030);

var _hyperlink2 = _interopRequireDefault(_hyperlink);

var _Mention = __webpack_require__(1805);

var _Mention2 = _interopRequireDefault(_Mention);

var _headerSelectionBubble = __webpack_require__(2033);

var _headerSelectionBubble2 = _interopRequireDefault(_headerSelectionBubble);

var _status = __webpack_require__(1820);

var _browserHelper = __webpack_require__(34);

var _browserHelper2 = _interopRequireDefault(_browserHelper);

var _sdkCompatibleHelper = __webpack_require__(82);

var _core = __webpack_require__(1573);

var _dom = __webpack_require__(1610);

var _table_view = __webpack_require__(1809);

var _isEqual = __webpack_require__(501);

var _isEqual2 = _interopRequireDefault(_isEqual);

__webpack_require__(2061);

var _ui_sheet = __webpack_require__(1807);

var _utils = __webpack_require__(1575);

var _ContextMenu = __webpack_require__(2040);

var _ContextMenu2 = _interopRequireDefault(_ContextMenu);

var _share = __webpack_require__(375);

var _common = __webpack_require__(19);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var __decorate = undefined && undefined.__decorate || function (decorators, target, key, desc) {
    var c = arguments.length,
        r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc,
        d;
    if ((typeof Reflect === "undefined" ? "undefined" : (0, _typeof3.default)(Reflect)) === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);else for (var i = decorators.length - 1; i >= 0; i--) {
        if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    }return c > 3 && r && Object.defineProperty(target, key, r), r;
};

var EmbedSheet = function (_React$PureComponent) {
    (0, _inherits3.default)(EmbedSheet, _React$PureComponent);

    function EmbedSheet(props) {
        var _this2 = this;

        (0, _classCallCheck3.default)(this, EmbedSheet);

        var _this = (0, _possibleConstructorReturn3.default)(this, (EmbedSheet.__proto__ || Object.getPrototypeOf(EmbedSheet)).call(this, props));

        _this._virtualScrollSyncing = false;
        _this.stickyOffset = 0;
        _this.initScreenHeight = window.innerHeight;
        _this._isInVirtualScroll = false; // 是否处于虚拟滚动
        _this.isActive = false;
        _this.onScroll = function () {
            if (_this.state.screenShotBlob) {
                return;
            }
            if (_this.isFixSize()) {
                return;
            }
            _this._syncVirtualScroll();
        };
        _this.handleTouchMove = function (e) {
            var sheet = _this.getCurrentSheet();
            if (sheet && sheet.isEditing()) {
                sheet.endEdit(false, true);
            }
        };
        _this.getBindList = function () {
            return [{ key: _sheet.Events.Focus, handler: _this.onFocus }, { key: _sheet.Events.LoseFocus, handler: _this.onLoseFocus }, { key: _sheet.Events.ValueChanged, handler: _this.handleCellValueChanged }, { key: _sheet.Events.EditStarting, handler: _this.handleEditStarting }, { key: _sheet.Events.EditEnded, handler: _this.handleEditEnded }, { key: _sheet.Events.CutSheet, handler: _this.deleteSheet }, { key: _sheet.Events.CellPress, handler: _this.onCellPress }];
        };
        _this.deleteSheet = function () {
            _this.props.shell.onDeleteSheet();
        };
        _this.collectMoveToNextRow = function (e) {
            var _this$props = _this.props,
                sheetId = _this$props.sheetId,
                activeSheetId = _this$props.activeSheetId;

            if (e.detail.editState === 1 && sheetId === activeSheetId) {
                (0, _tea.collectSuiteEvent)('click_sheet_edit_action', { sheet_edit_action_type: 'click_keyboard_next_row' });
            }
        };
        _this.handleExitFullScreenMode = function () {
            var sheet = _this.getCurrentSheet();
            if (sheet && _this._shell) {
                _this._shell.activate();
                _this.toggleSheetEventsBinding(true);
                _this._shell.sheetView().registerShell(); // register shell again. (remove after refactor)
                sheet.setSheetHost(_this._fasterDom);
                sheet.clearSelection(true);
                _this._shell.sheetView().detectLifetimeOnce(); // rebuild, might miss some notification.
            }
        };
        _this.handleEnterFullScreenMode = function () {
            _this.toggleSheetEventsBinding(false);
            _this._shell && _this._shell.deactive();
        };
        _this.handleEditStarting = function (type, event) {
            _this._editables = [];
            var element = event.sheet._editor;
            element = element && element.parentElement;
            while (element) {
                var contenteditable = element.getAttribute('contenteditable');
                if (contenteditable === 'true' || contenteditable === '') {
                    _this._editables.push(element);
                    element.setAttribute('contenteditable', 'false');
                }
                element = element.parentElement;
            }
            if (_this._isInVirtualScroll) {
                (0, _tea.collectSuiteEvent)('client_dev_embedsheet_edit_in_virtual_scroll', {
                    isSupportSticky: _this.isSupportSticky
                });
            }
        };
        _this.handleEditEnded = function () {
            if (!_this._editables) {
                return;
            }
            for (var i = 0, ii = _this._editables.length; i < ii; i++) {
                _this._editables[i].setAttribute('contenteditable', 'true');
            }
        };
        _this.handleCellValueChanged = function () {
            var _ref = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee(type, event) {
                var segmentArray, toUsers, toGroup, rsp, cellEditInfo, commandManager;
                return _regenerator2.default.wrap(function _callee$(_context) {
                    while (1) {
                        switch (_context.prev = _context.next) {
                            case 0:
                                segmentArray = event.newValue;

                                if (Array.isArray(segmentArray)) {
                                    _context.next = 3;
                                    break;
                                }

                                return _context.abrupt("return");

                            case 3:
                                toUsers = segmentArray.reduce(function (pre, seg) {
                                    if (seg.type === 'mention' && seg.mentionType === 0 && seg.mentionNotify) {
                                        pre.push(seg.token);
                                    }
                                    return pre;
                                }, []);
                                toGroup = segmentArray.reduce(function (pre, seg) {
                                    if (seg.type === 'mention' && seg.mentionType === 6 && seg.mentionNotify) {
                                        pre.push(seg.token);
                                    }
                                    return pre;
                                }, []);

                                _MentionNotificationQueue2.default.addGroupMention(toGroup, _const.SOURCE_ENUM.DOC, '');
                                _MentionNotificationQueue2.default.addUserMention(toUsers, _const.SOURCE_ENUM.DOC);
                                _context.next = 9;
                                return _MentionNotificationQueue2.default.sendMentionNotifications();

                            case 9:
                                rsp = _context.sent;

                                if (rsp.length > 0 && rsp[0].code === 0 && rsp[0].data && segmentArray && segmentArray.length > 0) {
                                    // 补上AT的Mention信息
                                    segmentArray.forEach(function (item) {
                                        if (item.type === 'mention' && item.mentionType === 0) {
                                            item.mentionId = rsp[0].data.mention_id;
                                        }
                                    }, []);
                                    cellEditInfo = {
                                        cmd: 'editCell',
                                        sheetId: event.sheet.id(),
                                        sheetName: event.sheetName,
                                        row: event.row,
                                        col: event.col,
                                        newValue: event.newValue,
                                        newSegmentArray: segmentArray,
                                        autoFormat: event.autoFormat,
                                        editingFormatter: event.editingFormatter
                                    };
                                    // 二次更新让后台记录MentionId

                                    commandManager = event.sheet._commandManager();

                                    event.sheet.suspendEvent();
                                    commandManager.execute(cellEditInfo);
                                    event.sheet.resumeEvent();
                                }

                            case 11:
                            case "end":
                                return _context.stop();
                        }
                    }
                }, _callee, _this2);
            }));

            return function (_x, _x2) {
                return _ref.apply(this, arguments);
            };
        }();
        _this.doViewportResize = function () {
            var isMobile = _browserHelper2.default.isMobile;

            var sheetView = _this._shell.sheetView();
            if (!sheetView) {
                return;
            }

            var _sheetView$contentSiz = sheetView.contentSizeHint(),
                width = _sheetView$contentSiz.width,
                height = _sheetView$contentSiz.height;

            var maxWidth = _this.props.maxWidth;
            if (isMobile) {
                if (!maxWidth) return; // 避免 maxWidth 为 0 导致显示错误
                var screenWidth = window.innerWidth; // TODO: 有没有更好的办法获取容器宽度
                var docPaddingWidth = Math.floor((screenWidth - maxWidth) / 2);
                maxWidth = screenWidth - docPaddingWidth - 6; // 右边间距
                // 移动端doc两边的padding宽度可能会比默认行头宽度小，所以需要手动调整行头宽度
                var sheet = _this.getCurrentSheet();
                if (sheet && docPaddingWidth < sheet.defaults.rowHeaderColWidth) {
                    sheet.defaults.rowHeaderColWidth = docPaddingWidth;
                }
            } else {
                var RIGHT_SPACE = 40; // pc 端表格右侧有 40px 留白
                maxWidth = maxWidth - RIGHT_SPACE;
            }
            var maxHeight = _this.props.maxHeight || Infinity;
            // show right margin
            if (maxWidth - 2 > width) {
                sheetView.setRightMargin(true);
            } else {
                sheetView.setRightMargin(false);
            }
            width += sheetView._rightMargin;
            var options = _this.props.collaSpread.spread.options;
            var showHorizontalScrollbar = width > maxWidth;
            options.showHorizontalScrollbar = showHorizontalScrollbar;
            if (showHorizontalScrollbar) {
                width = maxWidth;
                sheetView.setBottomMargin(true);
            } else {
                sheetView.setBottomMargin(false);
            }
            height += sheetView._bottomMargin;
            var showVerticalScrollbar = height > maxHeight;
            if (showVerticalScrollbar) {
                if (width > maxWidth) {
                    width = maxWidth;
                    options.showHorizontalScrollbar = true;
                }
                height = maxHeight;
            }
            options.showVerticalScrollbar = showVerticalScrollbar;
            if (_this.state.width !== width || _this.state.height !== height) {
                _this.setState({ width: width, height: height });
            }
        };
        _this._asyncVirtualScroll = function () {
            setTimeout(function () {
                _this._syncVirtualScroll();
            }, 300);
        };
        _this.onFocus = function (e, args) {
            return;
        };
        _this.onLoseFocus = function (e, args) {
            var sheet = args.sheet;
            if (sheet && _this.getCurrentSheet() === sheet) {
                sheet.endEdit();
                if (!args.ignoreRepaintSelection) {
                    sheet.clearSelection(true);
                }
            }
        };
        _this.onCellPress = function (type, info) {
            var spread = _this.props.collaSpread.spread;
            var row = info.row,
                col = info.col;

            var activeSheet = spread.getActiveSheet();
            if (activeSheet === _this.getCurrentSheet()) {
                var selectionRange = activeSheet.getSelections()[0];
                if (!(selectionRange && selectionRange.contains(row, col, 1, 1))) {
                    activeSheet.setActiveCell(row, col);
                }
            } else {
                _this.selectCurrentSheet();
                activeSheet = spread.getActiveSheet();
                activeSheet && activeSheet.setActiveCell(row, col);
            }
        };
        _this.selectCurrentSheet = function (e) {
            var setActiveSheetId = _this.props.setActiveSheetId;
            var spread = _this.props.collaSpread.spread;

            var curSheet = _this.getCurrentSheet();
            var activeSheet = spread.getActiveSheet();
            var activeSheetId = activeSheet.id();
            if (activeSheet !== curSheet) {
                activeSheet && activeSheet.clearSelection(true);
                spread.setActiveSheet(curSheet.name(), true);
            }
            if (activeSheetId !== curSheet.id()) {
                setActiveSheetId(curSheet.id());
            }
        };
        _this.setFasterDom = function (elem) {
            if (!elem) return;
            _this._fasterDom = elem;
            _this.createShell(elem);
        };
        _this.getDomRef = function (ref) {
            _this._workbookWrapper = null;
            if ((0, _sdkCompatibleHelper.isSupportSheetEditor)()) {
                var currentTarget = ref;
                while (currentTarget) {
                    if (currentTarget.classList.contains('sheet')) {
                        break;
                    }
                    currentTarget = currentTarget.parentElement;
                }
                if (currentTarget) {
                    _this._workbookWrapper = currentTarget;
                    _this._workbookWrapper.tabIndex = -1;
                }
            }
        };
        _this.getCanvasBoundingRect = function () {
            if (_this._fasterDom) {
                return _this._fasterDom.getBoundingClientRect();
            } else {
                return document.body.getBoundingClientRect();
            }
        };
        _this.handleDoubleClick = (0, _utils.clickToDbClick)(function () {
            if (!_browserHelper2.default.mobile) return;
            var activeSheet = _this.getCurrentSheet();
            if (activeSheet) {
                if (!activeSheet.isEditing()) {
                    activeSheet.startEdit();
                } else {
                    activeSheet.endEdit(undefined);
                    activeSheet.startEdit();
                }
            }
            if (!_this._workbookWrapper) {
                var hostElement = _this._fasterDom;
                while (hostElement) {
                    if (hostElement.classList.contains('sheet')) {
                        break;
                    }
                    hostElement = hostElement.parentElement;
                }
                if (hostElement) {
                    _this._workbookWrapper = hostElement;
                    _this._workbookWrapper.tabIndex = -1;
                }
            }
            _this._workbookWrapper && _this._workbookWrapper.focus();
        }, _sheet.Timeout.dblClickEdit);
        _this.state = {
            width: 308,
            height: 68,
            fasterStyle: {
                position: 'relative',
                top: null,
                bottom: null
            },
            screenShotBlob: null
        };
        _this._menuDom = document.createElement('div');
        document.body.appendChild(_this._menuDom);
        var navigationBar = document.querySelector('.navigation-bar-wrapper');
        if (navigationBar) {
            _this.stickyOffset = navigationBar.offsetHeight || 0;
        }
        // Firefox 使用 sticky 属性会造成 canvas 闪烁
        var isBrowserSupportSticky = [_browserHelper2.default.safari, _browserHelper2.default.chrome].some(function (value) {
            return value;
        });
        var isBrowserNotSupportSticky = [_browserHelper2.default.android, _browserHelper2.default.isLark].some(function (value) {
            return value;
        });
        _this.isSupportSticky = _this.testSupportSticky() && isBrowserSupportSticky && !isBrowserNotSupportSticky;
        _this.scrollContainer = null;
        return _this;
    }

    (0, _createClass3.default)(EmbedSheet, [{
        key: "getCurrentSheet",
        value: function getCurrentSheet() {
            return this.props.collaSpread.spread.getSheetFromId(this.props.sheetId);
        }
    }, {
        key: "componentWillReceiveProps",
        value: function componentWillReceiveProps(nextProps) {
            if (nextProps.isScreenShotMode !== this.props.isScreenShotMode) {
                this.onScreenShot(nextProps.isScreenShotMode);
            }
        }
    }, {
        key: "componentDidMount",
        value: function componentDidMount() {
            var props = this.props;
            var collaSpread = this.props.collaSpread;
            var spread = collaSpread.spread;
            var context = collaSpread.context;
            this.bindEvents();
            window.addEventListener('scroll', this.onScroll, true);
            if (_browserHelper2.default.mobile) {
                window.addEventListener('touchmove', this.handleTouchMove, true);
                window.addEventListener('sheet_in_doc:sheetSelect', this.handleSheetSelectEvent);
                window.addEventListener('sheet:mobile:endEdit', this._asyncVirtualScroll);
                window.addEventListener('sheet:mobile:activeSheetChanged', this.handleActiveSheetChanged);
                window.addEventListener('docsdk:sheet:updateEdit', this.collectMoveToNextRow);
            }
            // onclientvars 和 didmount 是同一时机，所以放在这里。
            var curSheet = this.getCurrentSheet();
            curSheet.clearSelection(true);
            curSheet.setSheetHost(this._fasterDom);
            this._shell.updateSheet(curSheet);
            this.doViewportResize();
            this.setEditable(props.editable);
            // 移动端链接特殊处理，直接打开
            this._hyperlink = new _hyperlink2.default({
                spread: spread
            });
            this._mention = new _Mention2.default({
                sheet: curSheet,
                spread: spread,
                context: context,
                container: this._fasterDom,
                getCanvasBoundingRect: this.getCanvasBoundingRect
            });
            var rowCount = curSheet.getRowCount();
            var colCount = curSheet.getColumnCount();
            window.dispatchEvent((0, _dom.createCustomEvent)('sheetDidRender', {
                detail: { sheetId: this.props.sheetId, cellCount: rowCount * colCount }
            }));
            // 创建DialogOverlay
            var overlay = document.createElement('div');
            var wrapper = document.getElementById('mainContainer') || document.body;
            Object.assign(overlay.style, {
                position: 'fixed',
                'z-index': 99
            });
            overlay.className = 'embed-sheet-dialog-overlay';
            wrapper.appendChild(overlay);
            // 调整WorkSheet在Workbook中的顺位
            var sheetId = this.props.sheetId;
            // 获取所有挂在的表格DOM
            var allEmbedSheetDom = document.querySelectorAll('.embed-spreadsheet-wrap');
            // 查询目标位置
            var targetSheetIndex = (0, _findIndex3.default)(allEmbedSheetDom, function (item) {
                return item.classList.contains("sheet-id-" + sheetId);
            });
            // 查询原位置
            var sourceSheetIndex = spread.getSheetIndexFromId(sheetId);
            // 移动表格
            if (sourceSheetIndex !== -1 && targetSheetIndex !== -1 && sourceSheetIndex !== targetSheetIndex) {
                spread.moveSheet(sourceSheetIndex, targetSheetIndex, false);
            }
        }
    }, {
        key: "componentDidUpdate",
        value: function componentDidUpdate(prevProps, prevState) {
            var state = this.state;
            var props = this.props;
            if (state.screenShotBlob) {
                return;
            }
            this.setZoom(props.zoom);
            if (prevProps.maxWidth !== props.maxWidth) {
                this.doViewportResize();
            }
            if (prevState.height !== state.height && this._virtualWrap) {
                window.dispatchEvent((0, _dom.createCustomEvent)('afterSheetResize', { detail: { sheetId: props.sheetId } }));
            }
            if (prevProps.editable !== props.editable) {
                this.setEditable(props.editable);
            }
            this._syncVirtualScroll();
        }
    }, {
        key: "componentWillUnmount",
        value: function componentWillUnmount() {
            this.unbindEvents();
            this._hyperlink && this._hyperlink.destory();
            this._mention && this._mention.destory();
            this.handleEditEnded();
            if (this._menuDom) {
                this._menuDom.parentNode && this._menuDom.parentNode.removeChild(this._menuDom);
            }
            window.removeEventListener('scroll', this.onScroll, true);
            if (_browserHelper2.default.mobile) {
                window.removeEventListener('touchmove', this.handleTouchMove, true);
                window.removeEventListener('sheet_in_doc:sheetSelect', this.handleSheetSelectEvent);
                window.removeEventListener('sheet:mobile:endEdit', this._asyncVirtualScroll);
                window.removeEventListener('sheet:mobile:activeSheetChanged', this.handleActiveSheetChanged);
                window.removeEventListener('docsdk:sheet:updateEdit', this.collectMoveToNextRow);
            }
            this._shell && this._shell.exit();
        }
    }, {
        key: "setEditable",
        value: function setEditable(b) {
            this.getCurrentSheet().options.isProtected = !b;
            this._shell && this._shell.setEditable(b);
        }
    }, {
        key: "isFixSize",
        value: function isFixSize() {
            return this.props.maxHeight && this.props.maxHeight !== Infinity;
        }
    }, {
        key: "bindEvents",
        value: function bindEvents() {
            var collaSpread = this.props.collaSpread;
            var context = collaSpread.context;
            context.addEventHandler(this);
            context.bind(_collaborative.CollaborativeEvents.ExitFullScreenMode, this.handleExitFullScreenMode);
            context.bind(_collaborative.CollaborativeEvents.EnterFullScreenMode, this.handleEnterFullScreenMode);
            this.toggleSheetEventsBinding(true);
        }
    }, {
        key: "toggleSheetEventsBinding",
        value: function toggleSheetEventsBinding(bind) {
            var bindList = this.getBindList();
            var sheet = this.getCurrentSheet();
            if (!sheet) return;
            bindList.forEach(function (event) {
                if (Array.isArray(event.key)) {
                    event.key.forEach(function (key) {
                        bind ? sheet.bind(key, event.handler) : sheet.unbind(key, event.handler);
                    });
                } else {
                    bind ? sheet.bind(event.key, event.handler) : sheet.unbind(event.key, event.handler);
                }
            });
        }
    }, {
        key: "unbindEvents",
        value: function unbindEvents() {
            var collaSpread = this.props.collaSpread;
            var context = collaSpread.context;
            context.removeEventHandler(this);
            context.unbind(_collaborative.CollaborativeEvents.ExitFullScreenMode, this.handleExitFullScreenMode);
            context.unbind(_collaborative.CollaborativeEvents.EnterFullScreenMode, this.handleEnterFullScreenMode);
            this.toggleSheetEventsBinding(false);
        }
    }, {
        key: "handleActiveSheetChanged",
        value: function handleActiveSheetChanged(e) {
            var _e$detail = e.detail,
                newSheet = _e$detail.newSheet,
                oldSheet = _e$detail.oldSheet;

            oldSheet.unpreventFocusCanvas();
            // 两个表格编辑切换
            if (newSheet && this.props.sheetId !== newSheet.id()) {
                this._shell.sheetView().unselectFloatingObjects(true, false, false);
                if (oldSheet && oldSheet.isMobileEditorOpen()) {
                    oldSheet.clearMobileEditor();
                    newSheet.startEdit();
                }
                oldSheet._trigger(_sheet.Events.LoseFocus, { sheet: oldSheet, ignoreRepaintSelection: true });
            }
        }
    }, {
        key: "handleSheetSelectEvent",
        value: function handleSheetSelectEvent(e) {
            var isSelect = e.detail.isSelect;

            if (!isSelect) {
                var sheet = this.getCurrentSheet();
                this._shell.sheetView().unselectFloatingObjects(true, false, false);
                sheet._trigger(_sheet.Events.LoseFocus, { sheet: sheet, ignoreRepaintSelection: true });
            }
        }
    }, {
        key: "setZoom",
        value: function setZoom(zoom) {
            var sheetView = this._shell.sheetView();
            sheetView.zoomContent(zoom);
        }
    }, {
        key: "_scrollY",
        value: function _scrollY(stepY) {
            if (Math.abs(stepY) > 0) {
                var scrollContainer = this._scrollParent(this._canvas);
                var top = 0;
                var left = 0;
                if (scrollContainer instanceof Window || scrollContainer instanceof HTMLBodyElement || scrollContainer instanceof Document) {
                    scrollContainer = window;
                    top = window.pageYOffset || document.documentElement.scrollTop || document.body.scrollTop || 0;
                    left = window.pageXOffset || document.documentElement.scrollLeft || document.body.scrollLeft || 0;
                } else {
                    top = scrollContainer.scrollTop;
                    left = scrollContainer.scrollLeft;
                }
                if (scrollContainer.scrollTo) {
                    scrollContainer.scrollTo(left, top + stepY);
                }
            }
        }
    }, {
        key: "_wakeup",
        value: function _wakeup() {
            // 已经 active，不用再 wakeup
            if (this.isActive) return;
            var fx = this._shell && this._shell.ui();
            if (!fx) return;
            this.isActive = true;
            fx.wakeup();
        }
    }, {
        key: "onWakeup",
        value: function onWakeup(sheetId) {
            // 没有 sheetId 的时候表示广播唤醒
            if (!sheetId || this.props.sheetId === sheetId) {
                this._wakeup();
            }
        }
    }, {
        key: "_suspend",
        value: function _suspend() {
            // 已经 inactive，不用再 suspend
            if (!this.isActive) return;
            var fx = this._shell.ui();
            if (!fx) return;
            this.isActive = false;
            fx.suspend();
        }
    }, {
        key: "onSuspend",
        value: function onSuspend(sheetId) {
            // 没有 sheetId 的时候表示广播唤醒
            if (!sheetId || this.props.sheetId === sheetId) {
                this._suspend();
            }
        }
    }, {
        key: "onSyncVirtualScroll",
        value: function onSyncVirtualScroll() {
            return this._syncVirtualScroll();
        }
    }, {
        key: "onScreenShot",
        value: function onScreenShot(isScreenShotMode) {
            var _this3 = this;

            if (isScreenShotMode) {
                // 不要使用原有封装的的wakeup方法，会导致状态错误
                // 在这里单独写一个对底层的直接调用
                var fx = this._shell && this._shell.ui();
                if (!fx) return;
                fx.wakeup();
                // setTimeout 延迟以确保资源Ready
                setTimeout((0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee2() {
                    var screenShotBlob;
                    return _regenerator2.default.wrap(function _callee2$(_context2) {
                        while (1) {
                            switch (_context2.prev = _context2.next) {
                                case 0:
                                    _context2.next = 2;
                                    return _this3._shell.screenShot(true);

                                case 2:
                                    screenShotBlob = _context2.sent;

                                    _this3.setState({
                                        screenShotBlob: screenShotBlob
                                    }, function () {
                                        _this3.props.shell.onScreenShotReady();
                                    });

                                case 4:
                                case "end":
                                    return _context2.stop();
                            }
                        }
                    }, _callee2, _this3);
                })), 0);
            } else {
                this.setState({
                    screenShotBlob: null
                }, function () {
                    _this3.props.shell.onScreenShotReady();
                });
            }
        }
    }, {
        key: "_syncVirtualScroll",
        value: function _syncVirtualScroll() {
            var bufferZone = 100;
            var windowHeight = _browserHelper2.default.mobile ? this.initScreenHeight : window.innerHeight;
            var ui = this._shell && this._shell.ui();
            var sheetView = this._shell && this._shell.sheetView();
            var editor = this.props.editor;
            // 移动端有些场景会渲染两次，确保editor是最新的
            if (_browserHelper2.default.mobile && window.__editor) {
                editor = window.__editor;
            }
            var idxLine = $(editor.dom.getAceLineForNode(this._virtualWrap)).index();
            var editorOffset = editor.getScrollPos();

            var _editor$getLineRectBy = editor.getLineRectByIndex(idxLine),
                top = _editor$getLineRectBy.top,
                bottom = _editor$getLineRectBy.bottom;

            top -= editorOffset;
            bottom -= editorOffset;
            if (bottom < -bufferZone || windowHeight + bufferZone < top) {
                this._suspend();
            } else {
                this._wakeup();
            }
            var state = this.state;
            // 移动端超过 8 倍屏幕高度时，才开启虚拟滚动
            var limit = _browserHelper2.default.mobile ? windowHeight * 8 : windowHeight;
            var newFasterStyle = void 0;
            if (limit > state.height + this.stickyOffset) {
                ui && ui.updateByCfg({
                    width: state.width,
                    height: state.height
                });
                newFasterStyle = {
                    top: null,
                    bottom: null,
                    position: 'relative'
                };
                this._isInVirtualScroll = false;
            } else {
                var rect = this._virtualWrap.getBoundingClientRect();
                var offset = this.stickyOffset;
                var wrapTop = Math.round(rect.top);
                var wrapBottom = Math.round(rect.bottom);
                var _top = Math.max(offset, wrapTop) - wrapTop;
                // let faster has only visible height
                ui && ui.updateByCfg({
                    width: state.width,
                    height: windowHeight - offset
                });
                this._virtualScrollSyncing = true;
                sheetView && sheetView.contentDoc().updateByCfg({ posY: _top });
                this._virtualScrollSyncing = false;
                var delta = 2;
                var hasAchieveDocStart = wrapTop + delta <= offset;
                var hasAchieveDocEnd = wrapBottom <= this._fasterDom.offsetHeight + delta + offset;
                if (hasAchieveDocStart) {
                    this._isInVirtualScroll = true;
                    if (!this.isSupportSticky) {
                        if (!hasAchieveDocEnd) {
                            newFasterStyle = {
                                top: offset,
                                bottom: null,
                                position: 'fixed'
                            };
                        } else if (hasAchieveDocEnd) {
                            newFasterStyle = {
                                top: null,
                                bottom: 0,
                                position: 'absolute'
                            };
                        }
                    }
                } else if (!hasAchieveDocEnd) {
                    this._isInVirtualScroll = false;
                    if (!this.isSupportSticky) {
                        newFasterStyle = {
                            top: 0,
                            bottom: null,
                            position: 'relative'
                        };
                    }
                }
            }
            if (!(0, _isEqual2.default)(newFasterStyle, this.state.fasterStyle) && newFasterStyle) {
                this.setState({
                    fasterStyle: newFasterStyle
                });
            }
        }
    }, {
        key: "createShell",
        value: function createShell(container) {
            var _this4 = this;

            this._shell = new _ui_sheet.SheetShell(container, this.props.collaSpread.spread, this.props.collaSpread.context, true);
            this._shell.sheetView().addListener(_core.FEventType.BeforeFlush, function () {
                _this4._syncVirtualScroll();
                setTimeout(function () {
                    return _this4.doViewportResize();
                });
                return false;
            });
            this._shell.sheetView().children().each(function (child) {
                if (child instanceof _table_view.TableView) {
                    child.contentDoc().addListener(_core.FEventType.AfterChange, function (e) {
                        if (_this4.isFixSize()) {
                            return false;
                        }
                        var ce = e;
                        if ('posX' in ce.changes && 'posY' in ce.changes) {
                            var x = ce.changes['posX'];
                            var y = ce.changes['posY'];
                            if (Math.abs(x.current - x.before) > Math.abs(y.current - y.before)) {
                                y.current = y.before;
                            }
                        }
                        var changes = ce.changes;
                        if (!_this4._isInVirtualScroll && !_this4._virtualScrollSyncing && changes.posY !== undefined) {
                            var oPosY = changes.posY.before || 0;
                            _this4._scrollY(changes.posY.current - oPosY);
                            changes.posY.current = oPosY;
                        }
                        return false;
                    });
                }
            });
        }
    }, {
        key: "_scrollParent",
        value: function _scrollParent(node) {
            var p = node;
            if (this.scrollContainer) {
                return this.scrollContainer;
            }
            var style = p && getComputedStyle(p);
            while (p && (p.scrollHeight <= p.clientHeight || style.overflowY !== 'scroll' && style.overflowY !== 'auto')) {
                p = p.parentElement;
                style = p && getComputedStyle(p);
            }
            this.scrollContainer = p || window;
            return this.scrollContainer;
        }
    }, {
        key: "testSupportSticky",
        value: function testSupportSticky() {
            var testNode = document.createElement('div');
            var prefixes = ['', '-webkit-'];
            return prefixes.some(function (prefix) {
                try {
                    testNode.style.position = prefix + 'sticky';
                } catch (e) {
                    // Raven上报
                    window.Raven && window.Raven.captureException(e);
                    // ConsoleError
                    console.error(e);
                }
                return testNode.style.position !== '';
            });
        }
    }, {
        key: "render",
        value: function render() {
            var _this5 = this;

            var _state = this.state,
                width = _state.width,
                height = _state.height,
                screenShotBlob = _state.screenShotBlob;
            var _props = this.props,
                copyPermission = _props.copyPermission,
                editable = _props.editable,
                online = _props.online,
                collaSpreadLoaded = _props.collaSpreadLoaded,
                sheetId = _props.sheetId,
                isSelect = _props.isSelect;
            var spread = this.props.collaSpread.spread;
            var isMobile = _browserHelper2.default.isMobile;

            var sheetContainerStyle = {
                width: width,
                height: height,
                position: 'relative'
            };
            var _state$fasterStyle = this.state.fasterStyle,
                position = _state$fasterStyle.position,
                top = _state$fasterStyle.top,
                bottom = _state$fasterStyle.bottom;

            var canCopy = copyPermission === _common.USER_TYPE_ON_SUITE.READABLE || editable;
            if (this.isFixSize()) {
                sheetContainerStyle.margin = 'auto';
            }
            var fasterStyle = {
                position: position
            };
            if (top != null) {
                fasterStyle.top = top;
            } else if (bottom != null) {
                fasterStyle.bottom = bottom;
            }
            var fasterCanvasStyle = {
                display: 'block'
            };
            var screenShotImg = null;
            if (screenShotBlob) {
                console.log("SheetScreenShot " + sheetId);
                var imgSrc = window.URL.createObjectURL(screenShotBlob);
                fasterCanvasStyle.display = 'none';
                screenShotImg = _react2.default.createElement("img", { src: imgSrc, style: { width: '100%' }, onLoad: function onLoad() {
                        window.URL.revokeObjectURL(imgSrc);
                    } });
            }
            return _react2.default.createElement("div", { className: "spreadsheet-wrap embed-spreadsheet-wrap sheet-id-" + sheetId, ref: this.getDomRef }, !online && _react2.default.createElement("div", { className: "spreadsheet-info spreadsheet-info_offline" }, _react2.default.createElement(_info2.default, { className: "spreadsheet-info__icon" }), _react2.default.createElement("span", null, t('sheet.no_offline_edit_support'))), !online && !collaSpreadLoaded && _react2.default.createElement("div", { className: "spreadsheet-info" }, _react2.default.createElement(_info2.default, { className: "spreadsheet-info__icon" }), _react2.default.createElement("span", null, t('sheet.still_loading_tips'))), _react2.default.createElement("div", { className: "faster-wrapper", style: sheetContainerStyle, ref: function ref(_ref3) {
                    return _this5._virtualWrap = _ref3;
                }, onClick: this.handleDoubleClick }, _react2.default.createElement("div", { className: "\n                spreadsheet embed-spreadsheet faster\n                " + (this.isSupportSticky ? 'faster-sticky' : '') + "\n                " + (collaSpreadLoaded ? 'spread-loaded' : '') + "\n                " + (isSelect ? 'embed-spreadsheet_select' : '') + "\n              ", style: this.isSupportSticky ? {} : fasterStyle, ref: this.setFasterDom, onClick: this.selectCurrentSheet }, isMobile && editable && _react2.default.createElement(_headerSelectionBubble2.default, { isEmbed: true, sheet: this.getCurrentSheet(), getSheetView: function getSheetView() {
                    return _this5._shell.sheetView();
                } }), screenShotImg, _react2.default.createElement("canvas", { className: "spreadsheet-canvas", style: fasterCanvasStyle, ref: function ref(_ref4) {
                    return _this5._canvas = _ref4;
                } })), _sdkCompatibleHelper.isSupportSheetContextMenu && _react2.default.createElement(_ContextMenu2.default, { spread: spread, sheetId: sheetId, editable: editable, commentable: false, canCopy: canCopy, isEmbed: true, sheetRef: this._canvas, getSheetView: function getSheetView() {
                    return _this5._shell.sheetView();
                } })), _react2.default.createElement(_status.SheetStatusCollector, { spread: spread }));
        }
    }]);
    return EmbedSheet;
}(_react2.default.PureComponent);

__decorate([(0, _bind.Bind)()], EmbedSheet.prototype, "handleActiveSheetChanged", null);
__decorate([(0, _bind.Bind)()], EmbedSheet.prototype, "handleSheetSelectEvent", null);
exports.default = (0, _reactRedux.connect)(function (state) {
    return {
        editable: (0, _sheet2.editableSelector)(state) && state.sheet.status.online,
        onComment: state.sheet.embedToolbar.onComment,
        canCopy: (0, _share.selectCopyPermission)(state),
        online: state.sheet.status.online
    };
}, function (dispatch) {
    return (0, _redux.bindActionCreators)({
        setActiveSheetId: _sheet3.setActiveSheetId,
        showHyperlinkEditor: _sheet3.showHyperlinkEditor
    }, dispatch);
})(EmbedSheet);
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 3238:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 16 16", fill: "#88909A" }, props),
    _react2.default.createElement("path", { d: "M8 15.5a7.5 7.5 0 1 1 0-15 7.5 7.5 0 0 1 0 15zm0-1a6.5 6.5 0 1 0 0-13 6.5 6.5 0 0 0 0 13zM6 8.22v-.5C7.1 6.53 7.93 5.99 8.52 6.1c.89.17.8.94.74 1.23-.05.3-1.8 4.6-1.44 4.66.24.04.72-.34 1.44-1.16v.63C8.6 12.48 7.75 13 6.68 13c-.67 0-.82-.59-.56-1.26.56-1.46 1.52-3.95 1.52-4.42 0-.47-.54-.17-1.63.9zM8.7 5.3a1.15 1.15 0 1 1 0-2.3 1.15 1.15 0 0 1 0 2.3z" })
  );
};

/***/ }),

/***/ 3239:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.default = undefined;

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _commandManager = __webpack_require__(1672);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var EmbedUndoManager = function () {
    function EmbedUndoManager(spread, undoManger) {
        var _this = this;

        (0, _classCallCheck3.default)(this, EmbedUndoManager);

        this.spread = spread;
        this.undoManger = undoManger;
        this.execCmd = function (cmdData, type) {
            var spread = _this.spread;

            var sheet = spread.getSheetFromId(cmdData.sheetId);
            if (!sheet) return;
            try {
                var cmd = spread.commandManager()[cmdData.cmd];
                if (cmd) {
                    cmd.execute(spread, cmdData, type);
                }
            } catch (e) {
                // Raven上报
                window.Raven && window.Raven.captureException(e);
                // ConsoleError
                console.error(e);
            }
        };
        undoManger.onNotify(this.execCmd);
    }

    (0, _createClass3.default)(EmbedUndoManager, [{
        key: '_addCommand',
        value: function _addCommand(cmdData, actionType) {
            if (cmdData && actionType === _commandManager.ActionType.execute) {
                this.undoManger.do(cmdData);
            }
        }
    }, {
        key: 'canUndo',
        value: function canUndo() {
            return true;
        }
    }, {
        key: 'undo',
        value: function undo() {
            this.undoManger.undo();
            return true;
        }
    }, {
        key: 'canRedo',
        value: function canRedo() {
            return true;
        }
    }, {
        key: 'redo',
        value: function redo() {
            this.undoManger.redo();
            return true;
        }
    }, {
        key: 'clear',
        value: function clear() {
            //
        }
    }, {
        key: 'dispose',
        value: function dispose() {
            var sheetId = this.spread.getActiveSheet().id();
            this.undoManger.clearBySheetId(sheetId);
            this.undoManger.offNotify(this.execCmd);
        }
    }]);
    return EmbedUndoManager;
}();

exports.default = EmbedUndoManager;

/***/ }),

/***/ 3240:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.parseHtml2Snapshot = parseHtml2Snapshot;

var _parseText2Value = __webpack_require__(1674);

var _datetimeHelper = __webpack_require__(1673);

var _htmlParser = __webpack_require__(1784);

function parseHtml2Snapshot(html) {
    var tableData = (0, _htmlParser.parseHtml)(html);
    if (tableData == null) {
        return null;
    }
    var snapshot = {
        rowCount: tableData.rowCount,
        columnCount: tableData.columnCount
    };
    var columns = tableData.columns,
        rows = tableData.rows,
        data = tableData.data;

    if (columns && columns.length) {
        snapshot.columns = columns.map(function (column) {
            return column === null ? null : { size: column };
        });
    }
    if (rows && rows.length) {
        snapshot.rows = rows.map(function (row) {
            return row === null ? null : { size: row };
        });
    }
    var spans = [];
    var dataTable = {};
    for (var i = 0, ii = data.length; i < ii; i++) {
        var row = data[i];
        var rowData = {};
        dataTable[i] = rowData;
        for (var j = 0, jj = row.length; j < jj; j++) {
            var col = row[j];
            if (col.colSpan > 1 || col.rowSpan > 1) {
                spans.push({
                    row: i,
                    col: j,
                    colCount: col.colSpan,
                    rowCount: col.rowSpan
                });
            }
            var colData = {};
            var value = col.value;

            var style = col.style;
            if (typeof value !== 'string') {
                colData.value = value;
            } else {
                if (value !== '') {
                    var formaterRef = { value: null };
                    var setvalue = (0, _parseText2Value.parseText2Value)(null, value, true, formaterRef);
                    var autodisplayformatter = formaterRef.value;
                    if (setvalue != null) {
                        colData.value = setvalue;
                    }
                    if (autodisplayformatter) {
                        autodisplayformatter.isAuto = true;
                        if (setvalue != null && _datetimeHelper.DateTimeHelper._isDate(setvalue)) {
                            setvalue = _datetimeHelper.DateTimeHelper._toOADateString(setvalue);
                        }
                        colData.value = setvalue != null ? setvalue : value;
                        style = Object.assign({}, style, { formatter: autodisplayformatter.toJSON() });
                    }
                }
            }
            if (style) {
                colData.style = style;
            }
            rowData[j] = colData;
        }
    }
    if (spans.length) {
        snapshot.spans = spans;
    }
    snapshot.data = { dataTable: dataTable };
    return snapshot;
}

/***/ }),

/***/ 3241:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});

var _popover = __webpack_require__(3242);

var _popover2 = _interopRequireDefault(_popover);

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _redux = __webpack_require__(65);

var _classnames = __webpack_require__(29);

var _classnames2 = _interopRequireDefault(_classnames);

var _reactRedux = __webpack_require__(238);

var _sheet = __webpack_require__(715);

var _tea = __webpack_require__(47);

__webpack_require__(3243);

var _qaFullscreen = __webpack_require__(2059);

var _qaFullscreen2 = _interopRequireDefault(_qaFullscreen);

var _qaDelete = __webpack_require__(3244);

var _qaDelete2 = _interopRequireDefault(_qaDelete);

var _qaAccessButton = __webpack_require__(3245);

var _qaAccessButton2 = _interopRequireDefault(_qaAccessButton);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var AccessPlateRaw = function AccessPlateRaw(props) {
    var _onClick = function _onClick(type) {
        props.hideDropdownMenu();
        props.hideFindbar();
        props.onItemClick(type);
    };
    return _react2.default.createElement("ul", { className: (0, _classnames2.default)('sheet-quick-access-plate layout-column', {
            'sheet-quick-access-plate--hidden': !props.visible
        }) }, _react2.default.createElement("li", { className: "sheet-quick-access-plate__item layout-row layout-cross-center", onClick: function onClick() {
            return _onClick('FULLSCREEN');
        } }, _react2.default.createElement(_qaFullscreen2.default, { className: "sheet-quick-access-plate__icon" }), _react2.default.createElement("span", null, t('sheet.fullscreen'))), props.editable && _react2.default.createElement("li", { className: "sheet-quick-access-plate__item layout-row layout-cross-center", onClick: function onClick() {
            return _onClick('DELETE');
        } }, _react2.default.createElement(_qaDelete2.default, { className: "sheet-quick-access-plate__icon" }), _react2.default.createElement("span", null, t('sheet.delete'))));
};
var AccessPlate = (0, _reactRedux.connect)(null, function (dispatch) {
    return (0, _redux.bindActionCreators)({
        hideFindbar: _sheet.hideFindbar,
        hideDropdownMenu: _sheet.hideDropdownMenu
    }, dispatch);
})(AccessPlateRaw);

var EmbedSheetQuickAccess = function (_React$Component) {
    (0, _inherits3.default)(EmbedSheetQuickAccess, _React$Component);

    function EmbedSheetQuickAccess() {
        (0, _classCallCheck3.default)(this, EmbedSheetQuickAccess);

        var _this = (0, _possibleConstructorReturn3.default)(this, (EmbedSheetQuickAccess.__proto__ || Object.getPrototypeOf(EmbedSheetQuickAccess)).apply(this, arguments));

        _this.state = {
            plateActive: false
        };
        _this.handleOnDropdownItemClick = function (e) {
            _this.setState({
                plateActive: false
            });
            if (e === 'FULLSCREEN') {
                _this.props.onEnterFullScreen();
                (0, _tea.collectSuiteEvent)('click_enter_full_screen', { source: 'click_btn' });
            } else if (e === 'DELETE') {
                _this.props.onDeleteSheet();
                (0, _tea.collectSuiteEvent)('click_doc_delete_sheet');
            }
        };
        _this.handlePopVisibleChange = function (visible) {
            if (_this.state.plateActive !== visible) {
                _this.setState({
                    plateActive: visible
                });
            }
        };
        return _this;
    }

    (0, _createClass3.default)(EmbedSheetQuickAccess, [{
        key: 'render',
        value: function render() {
            var props = this.props,
                state = this.state;
            var spread = props.spread,
                editable = props.editable;
            var plateActive = state.plateActive;
            // if (!visible || !online) {
            //   return null;
            // }
            // if (!spreadLoaded) {
            //   return null;
            // }

            var triggerStyle = {
                fill: plateActive ? '#07F' : '#C0C4C9',
                colir: plateActive ? '#07F' : '#C0C4C9'
            };
            var plate = _react2.default.createElement(AccessPlate, { spread: spread, editable: editable, visible: plateActive, onItemClick: this.handleOnDropdownItemClick });
            return _react2.default.createElement("div", { className: "sheet-quick-access-wrapper" }, _react2.default.createElement(_popover2.default, { prefixCls: "sheet-quick-access-popover", content: plate, trigger: "hover", mouseLeaveDelay: 0.5, placement: "bottomRight", visible: plateActive, onVisibleChange: this.handlePopVisibleChange }, _react2.default.createElement(_qaAccessButton2.default, { style: triggerStyle })));
        }
    }]);
    return EmbedSheetQuickAccess;
}(_react2.default.Component);

exports.default = EmbedSheetQuickAccess;
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 3242:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var React = _interopRequireWildcard(_react);

var _tooltip = __webpack_require__(1818);

var _tooltip2 = _interopRequireDefault(_tooltip);

var _warning = __webpack_require__(1819);

var _warning2 = _interopRequireDefault(_warning);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj['default'] = obj; return newObj; } }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

var Popover = function (_React$Component) {
    (0, _inherits3['default'])(Popover, _React$Component);

    function Popover() {
        (0, _classCallCheck3['default'])(this, Popover);

        var _this = (0, _possibleConstructorReturn3['default'])(this, (Popover.__proto__ || Object.getPrototypeOf(Popover)).apply(this, arguments));

        _this.saveTooltip = function (node) {
            _this.tooltip = node;
        };
        return _this;
    }

    (0, _createClass3['default'])(Popover, [{
        key: 'getPopupDomNode',
        value: function getPopupDomNode() {
            return this.tooltip.getPopupDomNode();
        }
    }, {
        key: 'getOverlay',
        value: function getOverlay() {
            var _props = this.props,
                title = _props.title,
                prefixCls = _props.prefixCls,
                content = _props.content;

            (0, _warning2['default'])(!('overlay' in this.props), 'Popover[overlay] is removed, please use Popover[content] instead, ' + 'see: https://u.ant.design/popover-content');
            return React.createElement(
                'div',
                null,
                title && React.createElement(
                    'div',
                    { className: prefixCls + '-title' },
                    title
                ),
                React.createElement(
                    'div',
                    { className: prefixCls + '-inner-content' },
                    content
                )
            );
        }
    }, {
        key: 'render',
        value: function render() {
            var props = (0, _extends3['default'])({}, this.props);
            delete props.title;
            return React.createElement(_tooltip2['default'], (0, _extends3['default'])({}, props, { ref: this.saveTooltip, overlay: this.getOverlay() }));
        }
    }]);
    return Popover;
}(React.Component);

exports['default'] = Popover;

Popover.defaultProps = {
    prefixCls: 'ant-popover',
    placement: 'top',
    transitionName: 'zoom-big',
    trigger: 'hover',
    mouseEnterDelay: 0.1,
    mouseLeaveDelay: 0.1,
    overlayStyle: {}
};
module.exports = exports['default'];

/***/ }),

/***/ 3243:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3244:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M16.5 7H19a1 1 0 0 1 0 2h-1v8.95c0 1.13-1 2.05-2.25 2.05h-7.5C7.01 20 6 19.08 6 17.95V9H5a1 1 0 1 1 0-2h11.5zM16 9H8v8.79c0 .03.17.21.5.21h7c.33 0 .5-.18.5-.21V9zM9 4h6a1 1 0 0 1 0 2H9a1 1 0 1 1 0-2zm1.25 7c.41 0 .75.34.75.75v3.5a.75.75 0 1 1-1.5 0v-3.5c0-.41.34-.75.75-.75zm3.5 0c.41 0 .75.34.75.75v3.5a.75.75 0 1 1-1.5 0v-3.5c0-.41.34-.75.75-.75z", fillRule: "nonzero" })
  );
};

/***/ }),

/***/ 3245:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "28", height: "28", viewBox: "0 0 28 28", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M14 0a14 14 0 1 1 0 28 14 14 0 0 1 0-28zm0 1.5a12.5 12.5 0 1 0 0 25 12.5 12.5 0 0 0 0-25zM10 10h8a1 1 0 0 1 0 2h-8a1 1 0 0 1 0-2zm0 6h8a1 1 0 0 1 0 2h-8a1 1 0 0 1 0-2z", fillRule: "nonzero" })
  );
};

/***/ }),

/***/ 3246:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _reactRedux = __webpack_require__(238);

var _status = __webpack_require__(1820);

exports.default = (0, _reactRedux.connect)(function (state) {
    return {
        spread: state.sheet.activeSpread
    };
})(_status.SheetStatusCollector);

/***/ }),

/***/ 3250:
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/babel-runtime/helpers/extends.js
var helpers_extends = __webpack_require__(10);
var extends_default = /*#__PURE__*/__webpack_require__.n(helpers_extends);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/babel-runtime/helpers/objectWithoutProperties.js
var objectWithoutProperties = __webpack_require__(26);
var objectWithoutProperties_default = /*#__PURE__*/__webpack_require__.n(objectWithoutProperties);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/babel-runtime/helpers/classCallCheck.js
var classCallCheck = __webpack_require__(5);
var classCallCheck_default = /*#__PURE__*/__webpack_require__.n(classCallCheck);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/babel-runtime/helpers/possibleConstructorReturn.js
var possibleConstructorReturn = __webpack_require__(6);
var possibleConstructorReturn_default = /*#__PURE__*/__webpack_require__.n(possibleConstructorReturn);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/babel-runtime/helpers/inherits.js
var inherits = __webpack_require__(9);
var inherits_default = /*#__PURE__*/__webpack_require__.n(inherits);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/react/index.js
var react = __webpack_require__(1);
var react_default = /*#__PURE__*/__webpack_require__.n(react);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/prop-types/index.js
var prop_types = __webpack_require__(0);
var prop_types_default = /*#__PURE__*/__webpack_require__.n(prop_types);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/rc-trigger/es/index.js + 11 modules
var es = __webpack_require__(543);

// CONCATENATED MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/rc-tooltip/es/placements.js
var autoAdjustOverflow = {
  adjustX: 1,
  adjustY: 1
};

var targetOffset = [0, 0];

var placements = {
  left: {
    points: ['cr', 'cl'],
    overflow: autoAdjustOverflow,
    offset: [-4, 0],
    targetOffset: targetOffset
  },
  right: {
    points: ['cl', 'cr'],
    overflow: autoAdjustOverflow,
    offset: [4, 0],
    targetOffset: targetOffset
  },
  top: {
    points: ['bc', 'tc'],
    overflow: autoAdjustOverflow,
    offset: [0, -4],
    targetOffset: targetOffset
  },
  bottom: {
    points: ['tc', 'bc'],
    overflow: autoAdjustOverflow,
    offset: [0, 4],
    targetOffset: targetOffset
  },
  topLeft: {
    points: ['bl', 'tl'],
    overflow: autoAdjustOverflow,
    offset: [0, -4],
    targetOffset: targetOffset
  },
  leftTop: {
    points: ['tr', 'tl'],
    overflow: autoAdjustOverflow,
    offset: [-4, 0],
    targetOffset: targetOffset
  },
  topRight: {
    points: ['br', 'tr'],
    overflow: autoAdjustOverflow,
    offset: [0, -4],
    targetOffset: targetOffset
  },
  rightTop: {
    points: ['tl', 'tr'],
    overflow: autoAdjustOverflow,
    offset: [4, 0],
    targetOffset: targetOffset
  },
  bottomRight: {
    points: ['tr', 'br'],
    overflow: autoAdjustOverflow,
    offset: [0, 4],
    targetOffset: targetOffset
  },
  rightBottom: {
    points: ['bl', 'br'],
    overflow: autoAdjustOverflow,
    offset: [4, 0],
    targetOffset: targetOffset
  },
  bottomLeft: {
    points: ['tl', 'bl'],
    overflow: autoAdjustOverflow,
    offset: [0, 4],
    targetOffset: targetOffset
  },
  leftBottom: {
    points: ['br', 'bl'],
    overflow: autoAdjustOverflow,
    offset: [-4, 0],
    targetOffset: targetOffset
  }
};

/* harmony default export */ var es_placements = (placements);
// CONCATENATED MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/rc-tooltip/es/Content.js






var Content_Content = function (_React$Component) {
  inherits_default()(Content, _React$Component);

  function Content() {
    classCallCheck_default()(this, Content);

    return possibleConstructorReturn_default()(this, _React$Component.apply(this, arguments));
  }

  Content.prototype.componentDidUpdate = function componentDidUpdate() {
    var trigger = this.props.trigger;

    if (trigger) {
      trigger.forcePopupAlign();
    }
  };

  Content.prototype.render = function render() {
    var _props = this.props,
        overlay = _props.overlay,
        prefixCls = _props.prefixCls,
        id = _props.id;

    return react_default.a.createElement(
      'div',
      { className: prefixCls + '-inner', id: id, role: 'tooltip' },
      typeof overlay === 'function' ? overlay() : overlay
    );
  };

  return Content;
}(react_default.a.Component);

Content_Content.propTypes = {
  prefixCls: prop_types_default.a.string,
  overlay: prop_types_default.a.oneOfType([prop_types_default.a.node, prop_types_default.a.func]).isRequired,
  id: prop_types_default.a.string,
  trigger: prop_types_default.a.any
};
/* harmony default export */ var es_Content = (Content_Content);
// CONCATENATED MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/rc-tooltip/es/Tooltip.js











var Tooltip_Tooltip = function (_Component) {
  inherits_default()(Tooltip, _Component);

  function Tooltip() {
    var _temp, _this, _ret;

    classCallCheck_default()(this, Tooltip);

    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return _ret = (_temp = (_this = possibleConstructorReturn_default()(this, _Component.call.apply(_Component, [this].concat(args))), _this), _this.getPopupElement = function () {
      var _this$props = _this.props,
          arrowContent = _this$props.arrowContent,
          overlay = _this$props.overlay,
          prefixCls = _this$props.prefixCls,
          id = _this$props.id;

      return [react_default.a.createElement(
        'div',
        { className: prefixCls + '-arrow', key: 'arrow' },
        arrowContent
      ), react_default.a.createElement(es_Content, {
        key: 'content',
        trigger: _this.trigger,
        prefixCls: prefixCls,
        id: id,
        overlay: overlay
      })];
    }, _this.saveTrigger = function (node) {
      _this.trigger = node;
    }, _temp), possibleConstructorReturn_default()(_this, _ret);
  }

  Tooltip.prototype.getPopupDomNode = function getPopupDomNode() {
    return this.trigger.getPopupDomNode();
  };

  Tooltip.prototype.render = function render() {
    var _props = this.props,
        overlayClassName = _props.overlayClassName,
        trigger = _props.trigger,
        mouseEnterDelay = _props.mouseEnterDelay,
        mouseLeaveDelay = _props.mouseLeaveDelay,
        overlayStyle = _props.overlayStyle,
        prefixCls = _props.prefixCls,
        children = _props.children,
        onVisibleChange = _props.onVisibleChange,
        afterVisibleChange = _props.afterVisibleChange,
        transitionName = _props.transitionName,
        animation = _props.animation,
        placement = _props.placement,
        align = _props.align,
        destroyTooltipOnHide = _props.destroyTooltipOnHide,
        defaultVisible = _props.defaultVisible,
        getTooltipContainer = _props.getTooltipContainer,
        restProps = objectWithoutProperties_default()(_props, ['overlayClassName', 'trigger', 'mouseEnterDelay', 'mouseLeaveDelay', 'overlayStyle', 'prefixCls', 'children', 'onVisibleChange', 'afterVisibleChange', 'transitionName', 'animation', 'placement', 'align', 'destroyTooltipOnHide', 'defaultVisible', 'getTooltipContainer']);

    var extraProps = extends_default()({}, restProps);
    if ('visible' in this.props) {
      extraProps.popupVisible = this.props.visible;
    }
    return react_default.a.createElement(
      es["a" /* default */],
      extends_default()({
        popupClassName: overlayClassName,
        ref: this.saveTrigger,
        prefixCls: prefixCls,
        popup: this.getPopupElement,
        action: trigger,
        builtinPlacements: placements,
        popupPlacement: placement,
        popupAlign: align,
        getPopupContainer: getTooltipContainer,
        onPopupVisibleChange: onVisibleChange,
        afterPopupVisibleChange: afterVisibleChange,
        popupTransitionName: transitionName,
        popupAnimation: animation,
        defaultPopupVisible: defaultVisible,
        destroyPopupOnHide: destroyTooltipOnHide,
        mouseLeaveDelay: mouseLeaveDelay,
        popupStyle: overlayStyle,
        mouseEnterDelay: mouseEnterDelay
      }, extraProps),
      children
    );
  };

  return Tooltip;
}(react["Component"]);

Tooltip_Tooltip.propTypes = {
  trigger: prop_types_default.a.any,
  children: prop_types_default.a.any,
  defaultVisible: prop_types_default.a.bool,
  visible: prop_types_default.a.bool,
  placement: prop_types_default.a.string,
  transitionName: prop_types_default.a.oneOfType([prop_types_default.a.string, prop_types_default.a.object]),
  animation: prop_types_default.a.any,
  onVisibleChange: prop_types_default.a.func,
  afterVisibleChange: prop_types_default.a.func,
  overlay: prop_types_default.a.oneOfType([prop_types_default.a.node, prop_types_default.a.func]).isRequired,
  overlayStyle: prop_types_default.a.object,
  overlayClassName: prop_types_default.a.string,
  prefixCls: prop_types_default.a.string,
  mouseEnterDelay: prop_types_default.a.number,
  mouseLeaveDelay: prop_types_default.a.number,
  getTooltipContainer: prop_types_default.a.func,
  destroyTooltipOnHide: prop_types_default.a.bool,
  align: prop_types_default.a.object,
  arrowContent: prop_types_default.a.any,
  id: prop_types_default.a.string
};
Tooltip_Tooltip.defaultProps = {
  prefixCls: 'rc-tooltip',
  mouseEnterDelay: 0,
  destroyTooltipOnHide: false,
  mouseLeaveDelay: 0.1,
  align: {},
  placement: 'right',
  trigger: ['hover'],
  arrowContent: null
};


/* harmony default export */ var es_Tooltip = (Tooltip_Tooltip);
// CONCATENATED MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/rc-tooltip/es/index.js


/* harmony default export */ var rc_tooltip_es = __webpack_exports__["default"] = (es_Tooltip);

/***/ }),

/***/ 3251:
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/react/index.js
var react = __webpack_require__(1);
var react_default = /*#__PURE__*/__webpack_require__.n(react);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/prop-types/index.js
var prop_types = __webpack_require__(0);
var prop_types_default = /*#__PURE__*/__webpack_require__.n(prop_types);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/react-dom/index.js
var react_dom = __webpack_require__(21);
var react_dom_default = /*#__PURE__*/__webpack_require__.n(react_dom);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/rc-trigger/es/index.js + 11 modules
var es = __webpack_require__(543);

// CONCATENATED MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/rc-dropdown/es/placements.js
var autoAdjustOverflow = {
  adjustX: 1,
  adjustY: 1
};

var targetOffset = [0, 0];

var placements = {
  topLeft: {
    points: ['bl', 'tl'],
    overflow: autoAdjustOverflow,
    offset: [0, -4],
    targetOffset: targetOffset
  },
  topCenter: {
    points: ['bc', 'tc'],
    overflow: autoAdjustOverflow,
    offset: [0, -4],
    targetOffset: targetOffset
  },
  topRight: {
    points: ['br', 'tr'],
    overflow: autoAdjustOverflow,
    offset: [0, -4],
    targetOffset: targetOffset
  },
  bottomLeft: {
    points: ['tl', 'bl'],
    overflow: autoAdjustOverflow,
    offset: [0, 4],
    targetOffset: targetOffset
  },
  bottomCenter: {
    points: ['tc', 'bc'],
    overflow: autoAdjustOverflow,
    offset: [0, 4],
    targetOffset: targetOffset
  },
  bottomRight: {
    points: ['tr', 'br'],
    overflow: autoAdjustOverflow,
    offset: [0, 4],
    targetOffset: targetOffset
  }
};

/* harmony default export */ var es_placements = (placements);
// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/react-lifecycles-compat/react-lifecycles-compat.es.js
var react_lifecycles_compat_es = __webpack_require__(742);

// CONCATENATED MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/rc-dropdown/es/Dropdown.js
var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

function _objectWithoutProperties(obj, keys) { var target = {}; for (var i in obj) { if (keys.indexOf(i) >= 0) continue; if (!Object.prototype.hasOwnProperty.call(obj, i)) continue; target[i] = obj[i]; } return target; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }








var Dropdown_Dropdown = function (_Component) {
  _inherits(Dropdown, _Component);

  function Dropdown(props) {
    _classCallCheck(this, Dropdown);

    var _this = _possibleConstructorReturn(this, _Component.call(this, props));

    Dropdown_initialiseProps.call(_this);

    if ('visible' in props) {
      _this.state = {
        visible: props.visible
      };
    } else {
      _this.state = {
        visible: props.defaultVisible
      };
    }
    return _this;
  }

  Dropdown.getDerivedStateFromProps = function getDerivedStateFromProps(nextProps) {
    if ('visible' in nextProps) {
      return {
        visible: nextProps.visible
      };
    }
    return null;
  };

  Dropdown.prototype.getMenuElement = function getMenuElement() {
    var _props = this.props,
        overlay = _props.overlay,
        prefixCls = _props.prefixCls;

    var extraOverlayProps = {
      prefixCls: prefixCls + '-menu',
      onClick: this.onClick
    };
    if (typeof overlay.type === 'string') {
      delete extraOverlayProps.prefixCls;
    }
    return react_default.a.cloneElement(overlay, extraOverlayProps);
  };

  Dropdown.prototype.getPopupDomNode = function getPopupDomNode() {
    return this.trigger.getPopupDomNode();
  };

  Dropdown.prototype.render = function render() {
    var _props2 = this.props,
        prefixCls = _props2.prefixCls,
        children = _props2.children,
        transitionName = _props2.transitionName,
        animation = _props2.animation,
        align = _props2.align,
        placement = _props2.placement,
        getPopupContainer = _props2.getPopupContainer,
        showAction = _props2.showAction,
        hideAction = _props2.hideAction,
        overlayClassName = _props2.overlayClassName,
        overlayStyle = _props2.overlayStyle,
        trigger = _props2.trigger,
        otherProps = _objectWithoutProperties(_props2, ['prefixCls', 'children', 'transitionName', 'animation', 'align', 'placement', 'getPopupContainer', 'showAction', 'hideAction', 'overlayClassName', 'overlayStyle', 'trigger']);

    var triggerHideAction = hideAction;
    if (!triggerHideAction && trigger.indexOf('contextMenu') !== -1) {
      triggerHideAction = ['click'];
    }

    return react_default.a.createElement(
      es["a" /* default */],
      _extends({}, otherProps, {
        prefixCls: prefixCls,
        ref: this.saveTrigger,
        popupClassName: overlayClassName,
        popupStyle: overlayStyle,
        builtinPlacements: es_placements,
        action: trigger,
        showAction: showAction,
        hideAction: triggerHideAction || [],
        popupPlacement: placement,
        popupAlign: align,
        popupTransitionName: transitionName,
        popupAnimation: animation,
        popupVisible: this.state.visible,
        afterPopupVisibleChange: this.afterVisibleChange,
        popup: this.getMenuElement(),
        onPopupVisibleChange: this.onVisibleChange,
        getPopupContainer: getPopupContainer
      }),
      children
    );
  };

  return Dropdown;
}(react["Component"]);

Dropdown_Dropdown.propTypes = {
  minOverlayWidthMatchTrigger: prop_types_default.a.bool,
  onVisibleChange: prop_types_default.a.func,
  onOverlayClick: prop_types_default.a.func,
  prefixCls: prop_types_default.a.string,
  children: prop_types_default.a.any,
  transitionName: prop_types_default.a.string,
  overlayClassName: prop_types_default.a.string,
  animation: prop_types_default.a.any,
  align: prop_types_default.a.object,
  overlayStyle: prop_types_default.a.object,
  placement: prop_types_default.a.string,
  overlay: prop_types_default.a.node,
  trigger: prop_types_default.a.array,
  alignPoint: prop_types_default.a.bool,
  showAction: prop_types_default.a.array,
  hideAction: prop_types_default.a.array,
  getPopupContainer: prop_types_default.a.func,
  visible: prop_types_default.a.bool,
  defaultVisible: prop_types_default.a.bool
};
Dropdown_Dropdown.defaultProps = {
  prefixCls: 'rc-dropdown',
  trigger: ['hover'],
  showAction: [],
  overlayClassName: '',
  overlayStyle: {},
  defaultVisible: false,
  onVisibleChange: function onVisibleChange() {},

  placement: 'bottomLeft'
};

var Dropdown_initialiseProps = function _initialiseProps() {
  var _this2 = this;

  this.onClick = function (e) {
    var props = _this2.props;
    var overlayProps = props.overlay.props;
    // do no call onVisibleChange, if you need click to hide, use onClick and control visible
    if (!('visible' in props)) {
      _this2.setState({
        visible: false
      });
    }
    if (props.onOverlayClick) {
      props.onOverlayClick(e);
    }
    if (overlayProps.onClick) {
      overlayProps.onClick(e);
    }
  };

  this.onVisibleChange = function (visible) {
    var props = _this2.props;
    if (!('visible' in props)) {
      _this2.setState({
        visible: visible
      });
    }
    props.onVisibleChange(visible);
  };

  this.getMinOverlayWidthMatchTrigger = function () {
    var _props3 = _this2.props,
        minOverlayWidthMatchTrigger = _props3.minOverlayWidthMatchTrigger,
        alignPoint = _props3.alignPoint;

    if ('minOverlayWidthMatchTrigger' in _this2.props) {
      return minOverlayWidthMatchTrigger;
    }

    return !alignPoint;
  };

  this.afterVisibleChange = function (visible) {
    if (visible && _this2.getMinOverlayWidthMatchTrigger()) {
      var overlayNode = _this2.getPopupDomNode();
      var rootNode = react_dom_default.a.findDOMNode(_this2);
      if (rootNode && overlayNode && rootNode.offsetWidth > overlayNode.offsetWidth) {
        overlayNode.style.minWidth = rootNode.offsetWidth + 'px';
        if (_this2.trigger && _this2.trigger._component && _this2.trigger._component.alignInstance) {
          _this2.trigger._component.alignInstance.forceAlign();
        }
      }
    }
  };

  this.saveTrigger = function (node) {
    _this2.trigger = node;
  };
};

Object(react_lifecycles_compat_es["polyfill"])(Dropdown_Dropdown);

/* harmony default export */ var es_Dropdown = (Dropdown_Dropdown);
// CONCATENATED MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/rc-dropdown/es/index.js

/* harmony default export */ var rc_dropdown_es = __webpack_exports__["default"] = (es_Dropdown);

/***/ })

}]);
//# sourceMappingURL=https://s3.pstatp.com/eesz/resource/bear/js/embed-sheet.d6221dd155c60c803cc8.js.map