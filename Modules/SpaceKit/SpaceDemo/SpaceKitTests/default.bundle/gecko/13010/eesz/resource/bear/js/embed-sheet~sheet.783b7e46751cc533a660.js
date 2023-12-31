(window["webpackJsonp"] = window["webpackJsonp"] || []).push([[8],{

/***/ 1660:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.activeChartIdSelector = exports.chartSelector = exports.selectSheetClientVars = exports.dropdownMenuSelector = exports.historyLocalVisible = exports.historyVisible = exports.reopentCommentSelector = exports.commentTargetSelector = exports.commentDataSelector = exports.commentToggleSelector = exports.findbarSelector = exports.chartOptionsSelector = exports.chartPanelSelector = exports.isShowChartSettingPanelSelector = exports.isFilteredSelector = exports.formatPainterSelector = exports.rangeStatusSelector = exports.cellStatusSelector = exports.toggleNavBarSelector = exports.hyperlinkEditorSelector = exports.coordSelector = exports.toolbarDisableSelector = exports.lockedInfoSelector = exports.isLockedSelector = exports.commentableSelector = exports.editablePermissionSelector = exports.editableSelector = exports.titleSelector = undefined;

var _isEqual2 = __webpack_require__(748);

var _isEqual3 = _interopRequireDefault(_isEqual2);

var _reselect = __webpack_require__(131);

var _share = __webpack_require__(342);

var _suite = __webpack_require__(84);

var _dom = __webpack_require__(1686);

var _sheet = __webpack_require__(744);

var _permissionHelper = __webpack_require__(302);

var permissionHelper = _interopRequireWildcard(_permissionHelper);

var _sdkCompatibleHelper = __webpack_require__(45);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var createDeepEqualSelector = (0, _reselect.createSelectorCreator)(_reselect.defaultMemoize, _isEqual3.default);
var titleSelector = exports.titleSelector = function titleSelector(state) {
    var objs = (0, _suite.selectCurrentSuiteByObjToken)(state);
    return objs ? objs.get('title') : '';
};
var editableSelector = exports.editableSelector = function editableSelector(state) {
    // 离线编辑
    if (!state.sheet.status.online && !_sdkCompatibleHelper.isSupportSheetOfflineEdit) return false;
    // 表格被错误限制编辑
    if (state.sheet.status.frozen) {
        return false;
    }
    // 表格加载完成状态
    if (!state.sheet.fetchState.spreadState.loaded) {
        return false;
    }
    // 当前 sheet 被锁定，同只读
    if (state.sheet.status.sheetPermission === false) {
        return false;
    }
    // 表格权限
    var permissionInfo = (0, _share.selectCurrentSuitePermissionInfo)(state);
    var permissions = permissionInfo ? permissionInfo.get('permissions') : state.sheet.permissions;
    return permissionHelper.getIsEditable(permissions);
};
// 没有权限数据的时候, 默认有编辑权限
var editablePermissionSelector = exports.editablePermissionSelector = function editablePermissionSelector(state) {
    var permissionInfo = (0, _share.selectCurrentSuitePermissionInfo)(state);
    var permissions = permissionInfo ? permissionInfo.get('permissions') : state.sheet.permissions;
    return permissionHelper.getIsEditable(permissions);
};
var commentableSelector = exports.commentableSelector = function commentableSelector(state) {
    return (0, _share.ifhaveCommentPermission)(state);
};
var isLockedSelector = exports.isLockedSelector = function isLockedSelector(state) {
    var _state$sheet$status = state.sheet.status,
        _state$sheet$status$h = _state$sheet$status.hasPermission,
        hasPermission = _state$sheet$status$h === undefined ? true : _state$sheet$status$h,
        _state$sheet$status$s = _state$sheet$status.sheetPermission,
        sheetPermission = _state$sheet$status$s === undefined ? true : _state$sheet$status$s;

    return !hasPermission || !sheetPermission;
};
var lockedInfoSelector = exports.lockedInfoSelector = function lockedInfoSelector(state) {
    var _state$sheet$status2 = state.sheet.status,
        hasPermission = _state$sheet$status2.hasPermission,
        sheetPermission = _state$sheet$status2.sheetPermission,
        rowPermission = _state$sheet$status2.rowPermission,
        colPermission = _state$sheet$status2.colPermission;

    return { hasPermission: hasPermission, sheetPermission: sheetPermission, rowPermission: rowPermission, colPermission: colPermission };
};
var toolbarDisableSelector = exports.toolbarDisableSelector = function toolbarDisableSelector(state) {
    if (state.sheet.status.emptySheet) return true;
    return !editableSelector(state);
};
var coordSelector = exports.coordSelector = createDeepEqualSelector(function (state) {
    return state.sheet.coord;
}, function (coord) {
    return coord;
});
var hyperlinkEditorSelector = exports.hyperlinkEditorSelector = createDeepEqualSelector(function (state) {
    return state.sheet.toolbar.hyperlinkEditor;
}, function (hyperlinkEditor) {
    return hyperlinkEditor;
});
var toggleNavBarSelector = exports.toggleNavBarSelector = function toggleNavBarSelector(state) {
    return state.sheet.toolbar && state.sheet.toolbar.toggleNavBar;
};
var cellStatusSelector = exports.cellStatusSelector = createDeepEqualSelector(function (state) {
    return state.sheet.toolbar.cellStatus;
}, function (cellStatus) {
    var backColor = cellStatus.backColor,
        foreColor = cellStatus.foreColor,
        _cellStatus$font = cellStatus.font,
        font = _cellStatus$font === undefined ? '' : _cellStatus$font,
        _cellStatus$textDecor = cellStatus.textDecoration,
        textDecoration = _cellStatus$textDecor === undefined ? _sheet.TextDecorationType.none : _cellStatus$textDecor,
        formatter = cellStatus.formatter,
        _cellStatus$hAlign = cellStatus.hAlign,
        hAlign = _cellStatus$hAlign === undefined ? _sheet.HorizontalAlign.Left : _cellStatus$hAlign,
        _cellStatus$vAlign = cellStatus.vAlign,
        vAlign = _cellStatus$vAlign === undefined ? _sheet.VerticalAlign.Bottom : _cellStatus$vAlign,
        wordWrap = cellStatus.wordWrap,
        cellType = cellStatus.cellType;

    var parsedFont = (0, _dom.parseFont)(font);
    var fontSize = parsedFont.fontSize || _sheet.DefaultFontSize;
    if (fontSize.indexOf('pt') === -1) {
        fontSize = (0, _dom.px2pt)(fontSize);
    }
    return {
        formatter: formatter || 'normal',
        backColor: backColor,
        foreColor: foreColor,
        fontSize: parseInt(fontSize, 10),
        bold: (0, _dom.isBold)(parsedFont.fontWeight),
        italic: parsedFont.fontStyle === 'italic',
        underline: !!(textDecoration && textDecoration & _sheet.TextDecorationType.underline),
        lineThrough: !!(textDecoration && textDecoration & _sheet.TextDecorationType.lineThrough),
        hAlign: hAlign,
        vAlign: vAlign,
        wordWrap: wordWrap,
        cellType: cellType,
        hyperlink: cellType && cellType.typeName === '8'
    };
});
var rangeStatusSelector = exports.rangeStatusSelector = createDeepEqualSelector(function (state) {
    return state.sheet.toolbar.rangeStatus;
}, function (rangeStatus) {
    var _rangeStatus$mergable = rangeStatus.mergable,
        mergable = _rangeStatus$mergable === undefined ? false : _rangeStatus$mergable,
        _rangeStatus$splitabl = rangeStatus.splitable,
        splitable = _rangeStatus$splitabl === undefined ? false : _rangeStatus$splitabl,
        _rangeStatus$sortable = rangeStatus.sortable,
        sortable = _rangeStatus$sortable === undefined ? false : _rangeStatus$sortable,
        _rangeStatus$painterF = rangeStatus.painterFormatable,
        painterFormatable = _rangeStatus$painterF === undefined ? false : _rangeStatus$painterF;

    return {
        mergable: mergable,
        splitable: splitable,
        sortable: sortable,
        painterFormatable: painterFormatable
    };
});
var formatPainterSelector = exports.formatPainterSelector = createDeepEqualSelector(function (state) {
    return state.sheet.formatPainter;
}, function (formatPainter) {
    var painterFormatting = formatPainter.painterFormatting;

    return {
        painterFormatting: painterFormatting
    };
});
var isFilteredSelector = exports.isFilteredSelector = createDeepEqualSelector(function (state) {
    return state.sheet.toolbar.isFiltered;
}, function (isFiltered) {
    return isFiltered;
});
var isShowChartSettingPanelSelector = exports.isShowChartSettingPanelSelector = function isShowChartSettingPanelSelector(state) {
    return state.sheet.chart.isShowChartSettingPanel;
};
var chartPanelSelector = exports.chartPanelSelector = function chartPanelSelector(state) {
    return state.sheet.chart;
};
var chartOptionsSelector = exports.chartOptionsSelector = function chartOptionsSelector(state) {
    return state.sheet.chartOptions;
};
var findbarSelector = exports.findbarSelector = function findbarSelector(state) {
    return state.sheet.findbar;
};
var commentToggleSelector = exports.commentToggleSelector = function commentToggleSelector(state) {
    return state.sheet.comment.toggle;
};
var commentDataSelector = exports.commentDataSelector = function commentDataSelector(state) {
    return state.sheet.comment.data;
};
var commentTargetSelector = exports.commentTargetSelector = function commentTargetSelector(state) {
    return state.sheet.comment.target;
};
var reopentCommentSelector = exports.reopentCommentSelector = function reopentCommentSelector(state) {
    return state.sheet.comment.reopenCommentId;
};
var historyVisible = exports.historyVisible = function historyVisible(state) {
    return state.sheet.history.visible;
};
var historyLocalVisible = exports.historyLocalVisible = function historyLocalVisible(state) {
    return state.sheet.history.localVisible;
};
var dropdownMenuSelector = exports.dropdownMenuSelector = function dropdownMenuSelector(state) {
    return state.sheet.dropdownMenu;
};
var selectSheetClientVars = exports.selectSheetClientVars = function selectSheetClientVars(state) {
    return state.sheet.clientVars;
};
var chartSelector = exports.chartSelector = function chartSelector(state) {
    return state.sheet.chart;
};
var activeChartIdSelector = exports.activeChartIdSelector = function activeChartIdSelector(state) {
    return state.sheet.chart.activeChartId;
};

/***/ }),

/***/ 1678:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.clickToDbClick = undefined;
exports.shouldOpenLink = shouldOpenLink;
exports.openLink = openLink;
exports.defineProperty = defineProperty;
exports.transWordWrapTeaName = transWordWrapTeaName;
exports.transHAlignTeaName = transHAlignTeaName;
exports.transVAlignTeaName = transVAlignTeaName;
exports.compatibleOldWordWrapData = compatibleOldWordWrapData;
exports.getCursorHintText = getCursorHintText;
exports.setFilter = setFilter;
exports.setSpreadEdit = setSpreadEdit;
exports.setSheetProtected = setSheetProtected;
exports.doubleTapWrapper = doubleTapWrapper;

var _string = __webpack_require__(163);

var _sheetCommon = __webpack_require__(1591);

var _browserHelper = __webpack_require__(27);

var _browserHelper2 = _interopRequireDefault(_browserHelper);

var _$moirae = __webpack_require__(449);

var _$moirae2 = _interopRequireDefault(_$moirae);

var _i18nHelper = __webpack_require__(222);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

// 如果mac下command键 || wimdows下ctrol键，则不打开链接
function shouldOpenLink(fEvent) {
    var isMac = _browserHelper2.default.isMac;

    if (isMac && fEvent && fEvent.metaKey) {
        return false;
    } else if (!isMac && fEvent.ctrlKey) {
        return false;
    }
    return true;
}
function openLink() {
    var link = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : '';

    if (typeof link !== 'string') {
        return false;
    }
    link = link.trim();
    if (link === '') return false;
    if (!(0, _string.hasUrlProtocol)(link)) {
        link = 'http://' + link;
    }
    if (link) {
        try {
            // 移动端open不可用
            if (_browserHelper2.default.isMobile) {
                location.href = link;
                return true;
            } else {
                var newWindow = window.open(link, '_blank');
                // 防止新窗口使用 window.opener.location = '钓鱼网站' 发起恶意钓鱼攻击
                newWindow && (newWindow.opener = null);
            }
        } catch (e) {
            // Raven上报
            _$moirae2.default.ravenCatch(e);
            return false;
        }
        return true;
    }
    return false;
}
function defineProperty(propertyName, defaultValue, callback) {
    var valueChecker = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : function (a, b) {
        return a !== b;
    };

    var temp = function temp(newValue) {
        var shouldCallback = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : true;

        if (!this.hasOwnProperty('_ps')) {
            this._ps = {};
        }
        var ps = this._ps;
        if (typeof newValue !== 'undefined') {
            var oldValue = ps.hasOwnProperty(propertyName) ? ps[propertyName] : defaultValue;
            if (shouldCallback === false || valueChecker === null || valueChecker.call(this, newValue, oldValue)) {
                ps[propertyName] = newValue;
                if (shouldCallback && callback) {
                    callback.call(this, newValue, oldValue);
                }
            }
        }
        return ps.hasOwnProperty(propertyName) ? ps[propertyName] : defaultValue;
    };
    temp.isDefault = function () {
        return temp() === defaultValue;
    };
    return temp;
}
function transWordWrapTeaName(key) {
    switch (key) {
        case '0':
            return 'overflow';
        case '1':
            return 'autowrap';
        case '2':
            return 'clip';
        default:
            return 'overflow';
    }
}
function transHAlignTeaName(key) {
    switch (key) {
        case 0:
            return 'left';
        case 1:
            return 'center';
        case 2:
            return 'right';
        default:
            return 'left';
    }
}
function transVAlignTeaName(key) {
    switch (key) {
        case 0:
            return 'up';
        case 1:
            return 'center';
        case 2:
            return 'down';
        default:
            return 'down';
    }
}
function compatibleOldWordWrapData(wordWrap) {
    if (wordWrap === false) return _sheetCommon.WORD_WRAP_TYPE.OVERFLOW;
    if (wordWrap === true) return _sheetCommon.WORD_WRAP_TYPE.AUTOWRAP;
    return wordWrap;
}
function getName(user) {
    var name = void 0;
    if (_i18nHelper.LANG_MAP.zh) {
        name = user.cn_name || user.en_name;
    }
    if (_i18nHelper.LANG_MAP.en) {
        name = user.en_name || user.cn_name;
    }
    return name || user.user_name;
}
var COMPRESS_USERS_COUNT = 3; // 光标文字只显示前3个用户
var COMPRESS_EXCEED_USERS_COUNT = 2;
function getCursorHintText(users) {
    var hintText = users.length > COMPRESS_USERS_COUNT ? t('common.cursor_hint_text', users.slice(0, COMPRESS_EXCEED_USERS_COUNT).map(function (user) {
        return getName(user);
    }).join('、'), users.length - COMPRESS_EXCEED_USERS_COUNT) : users.map(function (user) {
        return getName(user);
    }).join('、');
    return hintText;
}
function setFilter(sheet, content) {
    var commandManager = sheet.getParent().commandManager();
    if (!content) {
        // 删除过滤器
        commandManager.execute({
            cmd: 'setFilter',
            sheetName: sheet.name(),
            sheetId: sheet.id(),
            range: null
        });
        return;
    }
    var type = content.type,
        compare = content.compare,
        expected = content.expected,
        contents = content.contents,
        range = content.range,
        col = content.col;

    commandManager.execute({
        cmd: 'setFilter',
        sheetName: sheet.name(),
        sheetId: sheet.id(),
        range: range,
        type: type,
        compare: compare,
        expected: expected,
        contents: contents,
        col: col
    });
}
function setSpreadEdit(spread, editable) {
    if (typeof editable !== 'boolean') {
        console.error('param has to be a boolean');
        return;
    }
    spread.sheets.forEach(function (sheet) {
        return sheet.options.isProtected = !editable;
    });
    if (!editable) {
        var activeSheet = spread.getActiveSheet();
        activeSheet && activeSheet.endEdit(true);
    }
}
function setSheetProtected(sheet, editable) {
    if (!sheet) return;
    sheet.options.isProtected = !editable;
    if (!editable) {
        sheet.endEdit(true);
    }
}
function doubleTapWrapper(fn) {
    var delay = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : 500;

    var lastTouchTime = void 0;
    var lastClientX = void 0;
    var lastClientY = void 0;
    return function (e) {
        var touch = e.changedTouches[0];
        if (!touch) return;
        if (lastTouchTime) {
            var touchTime = Date.now();
            var clientX = touch.clientX;
            var clientY = touch.clientY;
            if (Math.abs(clientX - lastClientX) < 20 && Math.abs(clientY - lastClientY) < 20 && touchTime - lastTouchTime <= delay) {
                fn(e);
            }
            if (touchTime - lastTouchTime <= 500) {
                // ios辣鸡双击会都莫名往上滚，禁止掉
                // 辣鸡Android会跟native输入框抢焦点导致键盘关闭，禁止掉
                e.preventDefault();
            }
        }
        lastTouchTime = Date.now();
        lastClientX = touch.clientX;
        lastClientY = touch.clientY;
    };
}
var clickToDbClick = exports.clickToDbClick = function clickToDbClick(cb) {
    var delay = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : 800;

    var touchtime = 0;
    var x = 0;
    var y = 0;
    return function (event) {
        if (touchtime === 0) {
            touchtime = new Date().getTime();
            x = event.clientX;
            y = event.clientY;
        } else {
            if (new Date().getTime() - touchtime < (delay || 800) && Math.abs(event.clientX - x) < 20 && Math.abs(event.clientY - y) < 20) {
                cb(event);
                touchtime = 0;
                x = 0;
                y = 0;
            } else {
                touchtime = new Date().getTime();
                x = event.clientX;
                y = event.clientY;
            }
        }
    };
};
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(25)))

/***/ }),

/***/ 1798:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.LogStatus = exports.LogStage = undefined;
exports.stageTracker = stageTracker;

var _$moirae = __webpack_require__(449);

var _$moirae2 = _interopRequireDefault(_$moirae);

var _eventEmitter = __webpack_require__(110);

var _eventEmitter2 = _interopRequireDefault(_eventEmitter);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var taskQueue = [];
var timestampMap = {};
var LogStage = exports.LogStage = {
    LOAD_SHEET_PAGE: 'load_sheet_page',
    RENDER_SHEET_PAGE: 'render_sheet_page',
    CONNECT_WEBSOCKET: 'connect_websocket',
    DOWNLOAD_RESOURCE: 'download_resource',
    FETCH_CLIENT_VARS: 'fetch_client_vars',
    UNGZIP_CLIENT_VARS: 'ungzip_client_vars',
    APPLY_SNAPSHOT: 'apply_snapshot',
    FETCH_SUB_BLOCK: 'fetch_sub_block',
    FASTER_FIRST_TICK: 'faster_first_tick',
    INIT_CALC: 'init_calc'
};
var LogStatus = exports.LogStatus = undefined;
(function (LogStatus) {
    LogStatus[LogStatus["START"] = 0] = "START";
    LogStatus[LogStatus["END"] = 1] = "END";
    LogStatus[LogStatus["ERROR"] = 2] = "ERROR";
})(LogStatus || (exports.LogStatus = LogStatus = {}));
function isSheetRenderStageEvent(event) {
    return !!LogStage[event.toUpperCase()];
}
function stageTracker(event, stage, options) {
    options = options || {};
    var isRenderPageEvent = event === LogStage.RENDER_SHEET_PAGE;
    var isDownloadResourceEvent = event === LogStage.DOWNLOAD_RESOURCE;
    var nowTime = Date.now();
    // 时间大于500ms，认为是预加载未完成
    if (isRenderPageEvent || isDownloadResourceEvent) {
        options.open_from = window.renderStartTS - window.tapVisitStartTS >= 500 ? 'reload' : 'router';
    }
    var finalHandler = function finalHandler(type) {
        var startTime = timestampMap[event + '_start'];
        if (startTime) {
            var costTime = 0;
            if (options.costTime) {
                costTime = options.costTime;
            } else {
                costTime = isDownloadResourceEvent && window.tapVisitStartTS && window.renderStartTS ? window.renderStartTS - window.tapVisitStartTS : nowTime - startTime;
            }
            if (isSheetRenderStageEvent(event)) {
                taskQueue.push(function () {
                    console.info('[SHEET LOG] render-node-log: ' + event + ' end', nowTime);
                    console.info('[SHEET LOG] render-stage-log: ' + event + ' cost ' + costTime + 'ms');
                    _$moirae2.default.teaLog(Object.assign({
                        key: 'sheet_performance_operation',
                        operation: event + '_' + type
                    }, options));
                    _$moirae2.default.teaLog(Object.assign({
                        key: 'sheet_performance_stage',
                        stage: event,
                        type: type,
                        time_cost: costTime
                    }, options));
                });
            } else {
                _$moirae2.default.teaLog(Object.assign({
                    key: 'sheet_performance_operation',
                    operation: event + '_' + type
                }, options));
                _$moirae2.default.teaLog(Object.assign({
                    key: 'sheet_performance_stage',
                    stage: event,
                    type: type,
                    time_cost: costTime
                }, options));
            }
            if (type === 'error') {
                console.info('[SHEET LOG] render-node-log: ' + event + ' error');
            }
            delete timestampMap[event + '_start'];
        }
    };
    if (stage === LogStatus.START) {
        var startTime = nowTime;
        // 这些事件的起始时间从 点击访问 算起
        if ((isRenderPageEvent || isDownloadResourceEvent) && window.tapVisitStartTS) {
            startTime = window.tapVisitStartTS;
        }
        timestampMap[event + '_start'] = startTime;
        if (isSheetRenderStageEvent(event)) {
            taskQueue.push(function () {
                console.info('[SHEET LOG] render-node-log: ' + event + ' start', nowTime);
                _$moirae2.default.teaLog(Object.assign({
                    key: 'sheet_performance_operation',
                    operation: event + '_start'
                }, options));
            });
        } else {
            _$moirae2.default.teaLog(Object.assign({
                key: 'sheet_performance_operation',
                operation: event + '_start'
            }, options));
        }
    } else if (stage === LogStatus.END) {
        finalHandler('success');
    } else if (stage === LogStatus.ERROR) {
        finalHandler('error');
    }
}
function doTask() {
    taskQueue.forEach(function (fn) {
        fn && fn.apply(null);
    });
    taskQueue.length = 0;
}
_eventEmitter2.default.on('sheet_page_loaded', doTask);
_eventEmitter2.default.on('sheet_page_unmount', doTask);

/***/ }),

/***/ 1800:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.ChartCommandType = undefined;

var _toConsumableArray2 = __webpack_require__(58);

var _toConsumableArray3 = _interopRequireDefault(_toConsumableArray2);

var _typeof2 = __webpack_require__(82);

var _typeof3 = _interopRequireDefault(_typeof2);

var _round2 = __webpack_require__(3875);

var _round3 = _interopRequireDefault(_round2);

var _isNumber2 = __webpack_require__(774);

var _isNumber3 = _interopRequireDefault(_isNumber2);

exports.undo = undo;
exports.redo = redo;
exports.clear = clear;
exports.setFormatter = setFormatter;
exports.setFontStyle = setFontStyle;
exports.setTextDecoration = setTextDecoration;
exports.changeDecimalPlace = changeDecimalPlace;
exports.decimalPlaceState = decimalPlaceState;
exports.mergeState = mergeState;
exports.isCleanMerge = isCleanMerge;
exports.mergeCells = mergeCells;
exports.setRangeValue = setRangeValue;
exports.sortRange = sortRange;
exports.freezeSheet = freezeSheet;
exports.cellStatus = cellStatus;
exports.rangeStatus = rangeStatus;
exports.setFormulaFromToolBar = setFormulaFromToolBar;
exports.setRowColChange = setRowColChange;
exports.setHyperlink = setHyperlink;
exports.setCellInnerImage = setCellInnerImage;
exports.addChart = addChart;
exports.setChart = setChart;
exports.delChart = delChart;
exports.setFilterAction = setFilterAction;
exports.hasFilter = hasFilter;
exports.hasHiddenRow = hasHiddenRow;
exports.hiddenRowCount = hiddenRowCount;
exports.hasHiddenCol = hasHiddenCol;
exports.hiddenColCount = hiddenColCount;
exports.setRowColVisible = setRowColVisible;
exports.rangesSubOverlap = rangesSubOverlap;

var _sheetCommon = __webpack_require__(1591);

var _sheetCore = __webpack_require__(1594);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var ChartCommandType = exports.ChartCommandType = undefined;
(function (ChartCommandType) {
    ChartCommandType[ChartCommandType["Add"] = 0] = "Add";
    ChartCommandType[ChartCommandType["Set"] = 1] = "Set";
    ChartCommandType[ChartCommandType["Del"] = 2] = "Del";
})(ChartCommandType || (exports.ChartCommandType = ChartCommandType = {}));
// formatter 为常规的情况下，允许增减小数位数的表现值。
var performanceValCanChangeDecimalPlace = [/^-?\d+(\.\d+)?%?$/, /^-?[￥$]?\d{1,3}(,\d{3})*(\.\d+)?$/];
// 允许增减小数位数的 formatter。
var formattersCanChangeDecimalPlace = [/^[￥$]?#,##0(\.0+)?$/, /^0(\.0+)?%?$/];
function undo(spread) {
    spread.undoManager().undo();
}
function redo(spread) {
    spread.undoManager().redo();
}
function clear(spread) {
    var sheet = spread.getActiveSheet();
    spread.commandManager().execute({
        cmd: 'doClear',
        sheetId: sheet.id(),
        sheetName: sheet.name()
    });
}
/**
 * 以 number format codes 设置单元格格式
 * 文档：https://support.office.com/zh-cn/article/数字格式代码-5026bbd6-04bc-48cd-bf33-80f18b4eae68
 * 文档：http://sphelp.grapecity.com/webhelp/SpreadSheets10/webframe.html#cellformat.html
 */
function setFormatter(spread, formatter) {
    var sheet = spread.getActiveSheet();
    if (formatter === 'normal') formatter = null;
    spread.commandManager().execute({
        cmd: 'setFormatter',
        sheetId: sheet.id(),
        sheetName: sheet.name(),
        selections: sheet.getSelections(),
        value: formatter
    });
}
var styleFontEle = document.createElement('div');
function setFontStyle(spread, prop, isLabelStyle, optionValue1, optionValue2, toggle) {
    var sheet = spread.getActiveSheet();
    spread.commandManager().execute({
        cmd: 'setStyleFont',
        sheetId: sheet.id(),
        sheetName: sheet.name(),
        selections: sheet.getSelections(),
        styleEle: styleFontEle,
        prop: prop,
        isLabelStyle: isLabelStyle,
        optionValue1: optionValue1,
        optionValue2: optionValue2,
        toggle: toggle
    });
}
function setTextDecoration(spread, flag, active) {
    var sheet = spread.getActiveSheet();
    spread.commandManager().execute({
        cmd: 'setTextDecoration',
        sheetId: sheet.id(),
        sheetName: sheet.name(),
        selections: sheet.getSelections(),
        flag: flag,
        active: active
    });
}
function changeDecimalPlaceCore(formatter, type) {
    return formatter.replace(/0(\.0+)?/, function (str) {
        if (type === 'decrease') {
            if (str === '0') {
                // 没有小数位时。
                return str;
            } else {
                // 有小数位时。
                return str === '0.0' ? '0' : str.substring(0, str.length - 1);
            }
        } else if (type === 'increase') {
            if (str === '0') {
                // 没有小数位时。
                return str + '.0';
            } else {
                // 有小数位时。
                // 小数位数最多为 15，这里注意 str 的长度包括了 '0.'。
                return str.length - 2 < 15 ? str + '0' : str;
            }
        }
        return str;
    });
}
function changeDecimalPlace(spread, type) {
    var activeSheet = spread.getActiveSheet();
    var selections = activeSheet.getSelections();
    // 对现有选区从左到右，从上至下排序
    var sortedSelections = selections.sort(function (x, y) {
        if (x.rowFrom() === y.rowFrom()) {
            return x.colFrom() - y.colFrom();
        } else {
            return x.rowFrom() - y.rowFrom();
        }
    });
    var selectionsToChangeDecimalPlace = new _sheetCore.Sheets._SelectionModel();
    var baseFormatter = void 0;
    var _iteratorNormalCompletion = true;
    var _didIteratorError = false;
    var _iteratorError = undefined;

    try {
        for (var _iterator = sortedSelections[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {
            var selection = _step.value;

            // 点击行、列头时 row、col 为 -1
            var row = selection.rowFrom();
            var col = selection.colFrom();
            var rowCount = selection.rowCount();
            var colCount = selection.colCount();
            var hiddenRows = activeSheet.getHiddenRows();
            var hiddenCols = activeSheet.getHiddenCols();
            for (var i = row; i < row + rowCount; ++i) {
                // 跳过隐藏行及过滤行
                if (hiddenRows[i]) continue;

                var _loop = function _loop(j) {
                    // 跳过隐藏列
                    if (hiddenCols[j]) return 'continue';
                    var value = activeSheet.getSafeValue(i, j);
                    // 单元格存储值不为数字
                    if (Number.isNaN(parseFloat(value)) || !isFinite(value)) return 'continue';
                    var formatter = activeSheet.getFormatter(i, j);
                    // 单元格没有 formatter 则取 _autoFormatter
                    if (!formatter) {
                        var style = activeSheet.getStyle(i, j);
                        if (style && style._autoFormatter) {
                            formatter = style._autoFormatter;
                        }
                    }
                    // formatter 为 GeneralFormatter 则取 formatter.formatCached
                    if (formatter && typeof formatter !== 'string' && formatter.formatCached) {
                        formatter = formatter.formatCached;
                    }
                    if (!formatter || formatter === 'General' || formatter === 'normal') {
                        // 单元格 formatter 为常规，则只有表现值符合 performanceValCanChangeDecimalPlace 内的任一规则方可增减小数位数
                        var displayValue = activeSheet.getText(i, j);
                        var isPerformanceValCanChangeDecimalPlace = performanceValCanChangeDecimalPlace.some(function (formatterRule, index) {
                            var displayValueTestResult = formatterRule.test(displayValue);
                            if (selectionsToChangeDecimalPlace.length === 0) {
                                // 根据 displayValue 构造 formatter
                                if (displayValueTestResult) {
                                    if (index === 0) {
                                        formatter = '0';
                                    } else if (index === 1) {
                                        formatter = '#,##0';
                                    }
                                }
                            }
                            return displayValueTestResult;
                        });
                        if (!isPerformanceValCanChangeDecimalPlace) return 'continue';
                        if (selectionsToChangeDecimalPlace.length === 0) {
                            // 根据 displayValue 构造 formatter
                            if (displayValue.indexOf('$') !== -1) {
                                formatter = '$' + formatter;
                            } else if (displayValue.indexOf('￥') !== -1) {
                                formatter = '￥' + formatter;
                            }
                            var matchedResult = displayValue.match(/\d+\.(\d+)/);
                            if (matchedResult) {
                                // 有小数位时。
                                formatter += '.';
                                for (var _i = 0; _i < matchedResult[1].length; ++_i) {
                                    formatter += '0';
                                }
                            }
                            if (displayValue.indexOf('%') !== -1) {
                                formatter += '%';
                            }
                            baseFormatter = changeDecimalPlaceCore(formatter, type);
                        }
                    } else {
                        // 单元格 formatter 不为常规，则要符合 performanceValCanChangeDecimalPlace 内的任一规则方可增减小数位数
                        var isFormattersCanChangeDecimalPlace = formattersCanChangeDecimalPlace.some(function (formatterRule) {
                            return formatterRule.test(formatter);
                        });
                        if (!isFormattersCanChangeDecimalPlace) return 'continue';
                        if (selectionsToChangeDecimalPlace.length === 0) {
                            baseFormatter = changeDecimalPlaceCore(formatter, type);
                        }
                    }
                    selectionsToChangeDecimalPlace.add(new _sheetCore.Range(i, j, 1, 1, activeSheet));
                };

                for (var j = col; j < col + colCount; ++j) {
                    var _ret = _loop(j);

                    if (_ret === 'continue') continue;
                }
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

    if (selectionsToChangeDecimalPlace.length === 0) return;
    spread.commandManager().execute({
        cmd: 'setFormatter',
        sheetId: activeSheet.id(),
        sheetName: activeSheet.name(),
        selections: selectionsToChangeDecimalPlace,
        value: baseFormatter
    });
}
function decimalPlaceState(activeSheet, selections) {
    var decimalPlaceDecreasable = false;
    var decimalPlaceIncreasable = false;
    var _iteratorNormalCompletion2 = true;
    var _didIteratorError2 = false;
    var _iteratorError2 = undefined;

    try {
        for (var _iterator2 = selections[Symbol.iterator](), _step2; !(_iteratorNormalCompletion2 = (_step2 = _iterator2.next()).done); _iteratorNormalCompletion2 = true) {
            var selection = _step2.value;

            // 点击行、列头时 row、col 为 -1
            var row = selection.rowFrom();
            var col = selection.colFrom();
            var rowCount = selection.rowCount();
            var colCount = selection.colCount();
            var hiddenRows = activeSheet.getHiddenRows();
            var hiddenCols = activeSheet.getHiddenCols();
            for (var i = row; i < row + rowCount; ++i) {
                // 跳过隐藏行及过滤行
                if (hiddenRows[i]) continue;

                var _loop2 = function _loop2(j) {
                    // 跳过隐藏列
                    if (hiddenCols[j]) return 'continue';
                    var value = activeSheet.getSafeValue(i, j);
                    // 单元格存储值不为数字
                    if (Number.isNaN(parseFloat(value)) || !isFinite(value)) return 'continue';
                    var formatter = activeSheet.getFormatter(i, j);
                    // 单元格没有 formatter 则取 _autoFormatter
                    if (!formatter) {
                        var style = activeSheet.getStyle(i, j);
                        if (style && style._autoFormatter) {
                            formatter = style._autoFormatter;
                        }
                    }
                    // formatter 为 GeneralFormatter 则取 formatter.formatCached
                    if (formatter && typeof formatter !== 'string' && formatter.formatCached) {
                        formatter = formatter.formatCached;
                    }
                    if (!formatter || formatter === 'General' || formatter === 'normal') {
                        // 单元格 formatter 为常规，则只有表现值符合 performanceValCanChangeDecimalPlace 内的任一规则方可增减小数位数
                        var displayValue = activeSheet.getText(i, j);
                        var isPerformanceValCanChangeDecimalPlace = performanceValCanChangeDecimalPlace.some(function (formatterRule) {
                            return formatterRule.test(displayValue);
                        });
                        if (!isPerformanceValCanChangeDecimalPlace) return 'continue';
                        var displayValueMatchedResult = displayValue.match(/\d+\.(\d+)/);
                        if (displayValueMatchedResult && displayValueMatchedResult[1]) {
                            // 有小数位时，允许减少小数位数
                            decimalPlaceDecreasable = true;
                            if (displayValueMatchedResult[1].length < 15) {
                                // 小数位数小于 15，允许增加小数位数
                                decimalPlaceIncreasable = true;
                            }
                        } else {
                            // 无小数位时，允许增加小数位数，不允许减少小数位数
                            decimalPlaceIncreasable = true;
                        }
                    } else {
                        // 单元格 formatter 不为常规，则要符合 performanceValCanChangeDecimalPlace 内的任一规则方可增减小数位数
                        var isFormattersCanChangeDecimalPlace = formattersCanChangeDecimalPlace.some(function (formatterRule) {
                            return formatterRule.test(formatter);
                        });
                        if (!isFormattersCanChangeDecimalPlace) return 'continue';
                        var formatterMatchedResult = formatter.match(/0\.(0+)/);
                        if (formatterMatchedResult && formatterMatchedResult[1]) {
                            // 有小数位时，允许减少小数位数
                            decimalPlaceDecreasable = true;
                            if (formatterMatchedResult[1].length < 15) {
                                // 小数位数小于 15，允许增加小数位数
                                decimalPlaceIncreasable = true;
                            }
                        } else {
                            // 无小数位时，允许增加小数位数，不允许减少小数位数
                            decimalPlaceIncreasable = true;
                        }
                    }
                    if (decimalPlaceDecreasable && decimalPlaceIncreasable) {
                        // 若选区已经允许增减小数位数，则可以先溜了
                        return {
                            v: {
                                decimalPlaceDecreasable: decimalPlaceDecreasable,
                                decimalPlaceIncreasable: decimalPlaceIncreasable
                            }
                        };
                    }
                };

                for (var j = col; j < col + colCount; ++j) {
                    var _ret2 = _loop2(j);

                    switch (_ret2) {
                        case 'continue':
                            continue;

                        default:
                            if ((typeof _ret2 === 'undefined' ? 'undefined' : (0, _typeof3.default)(_ret2)) === "object") return _ret2.v;
                    }
                }
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

    return {
        decimalPlaceDecreasable: decimalPlaceDecreasable,
        decimalPlaceIncreasable: decimalPlaceIncreasable
    };
}
function mergeState(spread) {
    var sheet = spread.getActiveSheet();
    var selections = sheet.getSelections();
    var splitable = false;
    var mergable = false; // 多个选区时不能合并或取消合并单元格
    if (selections.length === 1) {
        var selection = selections[0];
        var spans = sheet.getSpans(selection);
        var spansCount = spans.length;
        if (spansCount === 1 && selection.equal(spans[0])) {
            // 选区只有一个合并单元格，并且选区与合并单元格一样，才可以取消合并
            splitable = true;
        } else if (spansCount > 1 || selection.rowCount() > 1 || selection.colCount() > 1) {
            // 有多个合并单元格，那肯定可以合并
            // 如果没有合并单元格，就必须选中多个格子才能合并
            mergable = true;
        }
    }
    return {
        mergable: mergable,
        splitable: splitable
    };
}
/** 判断可否可以合并的依据：全部没有值，或者有且只有一个单元格有值  */
function isCleanMerge(spread) {
    var sheet = spread.getActiveSheet();
    var selections = sheet.getSelections();
    var selection = selections[0];
    if (!selection) return false;
    var row = selection.rowFrom();
    var col = selection.colFrom();
    var rowCount = selection.rowCount();
    var colCount = selection.colCount();
    var numCellHasValue = 0;
    for (var x = row; x < row + rowCount; x++) {
        for (var y = col; y < col + colCount; y++) {
            if (sheet.getValue(x, y) !== null || sheet.getSegmentArray(x, y)) {
                numCellHasValue++;
            }
        }
    }
    return numCellHasValue <= 1;
}
/**
 * @param flag true: 合并, false: 取消合并
 */
function mergeCells(spread, flag) {
    var _mergeState = mergeState(spread),
        mergable = _mergeState.mergable,
        splitable = _mergeState.splitable;

    var sheet = spread.getActiveSheet();
    if (flag ? mergable : splitable) {
        spread.commandManager().execute({
            cmd: 'mergeCells',
            sheetId: sheet.id(),
            sheetName: sheet.name(),
            ranges: sheet.getSelections(),
            flag: flag
        });
        return true;
    }
    return false;
}
function setRangeValue(spread, prop, value) {
    var sheet = spread.getActiveSheet();
    spread.commandManager().execute({
        cmd: 'setRangeValue',
        sheetId: sheet.id(),
        sheetName: sheet.name(),
        selections: sheet.getSelections(),
        prop: prop,
        value: value
    });
}
function sortRange(spread, target, index, ascending) {
    var sheet = spread.getActiveSheet();
    return spread.commandManager().execute({
        cmd: 'sortRange',
        sheetId: sheet.id(),
        sheetName: sheet.name(),
        target: target,
        index: index,
        ascending: ascending
    });
}
function freezeSheet(spread, row, col) {
    var sheet = spread.getActiveSheet();
    var cmdMgr = spread.commandManager();
    return cmdMgr.execute({
        cmd: _sheetCommon.ACTIONS.FREEZE_SHEET,
        sheetId: sheet.id(),
        target: {
            row: row,
            col: col
        }
    });
}
function cellStatus(spread) {
    var sheet = spread.getActiveSheet();
    if (!sheet) return {};
    var col = sheet.getActiveColumnIndex();
    var row = sheet.getActiveRowIndex();
    var style = sheet.getActualStyle(row, col); // style.toJSON可能为undefined
    style = style && style.toJSON() || {};
    var _style = style,
        hAlign = _style.hAlign;

    if (hAlign == null || hAlign === _sheetCommon.HorizontalAlign.General) {
        var value = sheet.getValue(row, col);
        hAlign = (0, _isNumber3.default)(value) ? _sheetCommon.HorizontalAlign.Right : _sheetCommon.HorizontalAlign.Left;
    }
    style.hAlign = hAlign;
    return style;
}
/*
  选区属性计算函数，功能包含右下角自动计算出平均值，数量，总和 支持多选区
  思路： 分别遍历每一个选区，找出每一个选区中的非隐藏区，将数据push到计算数组（数组内容为选区Expr）ranges中
        调用Spreasd自带计算引擎进行计算
*/
function rangeStatus(spread) {
    var sheet = spread.getActiveSheet();
    if (!sheet || sheet['_id_'] === '-1') return {};
    var selections = sheet.getSelections();
    var sortable = selections.length === 1 && selections[0].rowCount() !== 1; // 可排序
    var painterFormatable = selections.length === 1;
    var calcExpression = ''; // 区域的 A1:B2 的表达
    var toCompileExpression = ''; // 求值的表达式
    var subOverlapRanges = [];
    var selectionsLen = selections.length;
    subOverlapRanges.push(selections[0]);
    if (selectionsLen > 1) {
        for (var i = 1; i < selectionsLen; i++) {
            subOverlapRanges.push.apply(subOverlapRanges, (0, _toConsumableArray3.default)(rangesSubOverlap(selections.slice(0, i), [selections[i]], 0)));
        }
    }
    subOverlapRanges.forEach(function (range) {
        if (range) {
            var row = range.rowFrom();
            var col = range.colFrom();
            var rowCount = range.rowCount();
            var colCount = range.colCount();
            // 记录每一个小的非隐藏区的边界
            var startRow = row;
            var recordRow = row;
            var endRow = row + rowCount - 1;
            var recordRowArr = [];
            while (startRow <= endRow) {
                if (!sheet.getRowVisible(startRow)) {
                    if (recordRow !== startRow) {
                        recordRowArr.push([recordRow, startRow - 1]);
                    }
                    recordRow = startRow + 1;
                } else if (startRow === endRow) {
                    recordRowArr.push([recordRow, startRow]);
                }
                startRow++; // 此处变量命名应为index 迭代
            }
            var startCol = col;
            var recordCol = col;
            var endCol = col + colCount - 1;
            var recordColArr = [];
            while (startCol <= endCol) {
                if (!sheet.getColumnVisible(startCol)) {
                    if (recordCol !== startCol) {
                        recordColArr.push([recordCol, startCol - 1]);
                    }
                    recordCol = startCol + 1;
                } else if (startCol === endCol) {
                    recordColArr.push([recordCol, startCol]);
                }
                startCol++;
            }
            // 生成一个除去隐藏区域的 表达式的计算区域
            var baseRef = new _sheetCore.CellRange(0, 0, sheet);
            recordRowArr.forEach(function (rowRange) {
                recordColArr.forEach(function (colRange) {
                    var rg = new _sheetCore.Range(rowRange[0], colRange[0], rowRange[1] - rowRange[0] + 1, colRange[1] - colRange[0] + 1, sheet);
                    calcExpression += rg.toString({ ref: baseRef }) + ',';
                });
            });
        }
    });
    if (calcExpression.length) calcExpression = calcExpression.slice(0, calcExpression.length - 1);
    var ctx = { ref: new _sheetCore.Range(0, 0, 1, 1, sheet), spread: sheet.parent };
    var variant = void 0;
    var operatorArr = ['AVERAGE', 'SUM', 'COUNTA'];
    var result = {};
    if (sheet && calcExpression.length > 0) {
        var _iteratorNormalCompletion3 = true;
        var _didIteratorError3 = false;
        var _iteratorError3 = undefined;

        try {
            for (var _iterator3 = operatorArr[Symbol.iterator](), _step3; !(_iteratorNormalCompletion3 = (_step3 = _iterator3.next()).done); _iteratorNormalCompletion3 = true) {
                var item = _step3.value;

                toCompileExpression = item + '(' + calcExpression + ')';
                variant = sheet.getCalcEngine().compile(toCompileExpression, ctx);
                var value = variant.formulaVar.getValue();
                result[item.toLocaleLowerCase()] = (0, _isNumber3.default)(value) ? (0, _round3.default)(value, 3) : 0;
            }
        } catch (err) {
            _didIteratorError3 = true;
            _iteratorError3 = err;
        } finally {
            try {
                if (!_iteratorNormalCompletion3 && _iterator3.return) {
                    _iterator3.return();
                }
            } finally {
                if (_didIteratorError3) {
                    throw _iteratorError3;
                }
            }
        }
    }
    result.count = result.counta;
    return Object.assign({}, mergeState(spread), decimalPlaceState(sheet, selections), {
        sortable: sortable,
        painterFormatable: painterFormatable
    }, result);
}
function setFormulaFromToolBar(spread, formula) {
    var sheet = spread.getActiveSheet();
    sheet.startEdit(false, '');
    var fbx = sheet._formulaTextBox;
    if (fbx) {
        fbx.setText('=' + formula + '(');
    }
}
function setRowColChange(sheet, params) {
    // 单元格数量限制，有增加行或者列时判断是否超过最大数量
    if (params.method === 'add') {
        var totalRowCount = sheet.getRowCount();
        var totalColCount = sheet.getColumnCount();
        if (params.type === 'row') {
            totalRowCount += params.count;
        } else if (params.type === 'col') {
            totalColCount += params.count;
        }
        if (totalRowCount * totalColCount > _sheetCommon.CELL_LIMIT) {
            sheet._raiseInvalidOperation(6, t('sheet.cell_limit_exceed'));
            return;
        }
    }
    sheet._commandManager().execute(Object.assign({}, params, {
        cmd: 'setRowColChange',
        sheetId: sheet.id()
    }));
}
function setHyperlink(spread, params) {
    var sheet = spread.getActiveSheet();
    spread.commandManager().execute(Object.assign({}, params, {
        cmd: 'editCell',
        sheetId: sheet.id()
    }));
}
function setCellInnerImage(spread, sheetId, params) {
    spread.commandManager().execute(Object.assign({}, params, {
        cmd: 'editCell',
        sheetId: sheetId
    }));
}
function addChart(spread, chartBlock) {
    return _setChart(spread, chartBlock, ChartCommandType.Add);
}
function setChart(spread, chartBlock) {
    return _setChart(spread, chartBlock, ChartCommandType.Set);
}
function delChart(spread, sheetId, chartId) {
    spread.commandManager().execute({
        cmd: 'setChart',
        commandType: ChartCommandType.Del,
        sheetId: sheetId,
        chartId: chartId
    });
}
function _setChart(spread, chartBlock, type) {
    spread.commandManager().execute({
        cmd: 'setChart',
        commandType: type,
        sheetId: chartBlock.sheetId,
        chartId: chartBlock.chartId,
        data: chartBlock
    });
}
function setFilterAction(status, sheet, range) {
    var commandManager = sheet.getParent().commandManager();
    switch (status) {
        case 'delFilter':
            // 删除过滤器
            commandManager.execute({
                cmd: 'setFilter',
                sheetName: sheet.name(),
                sheetId: sheet.id(),
                range: null
            });
            break;
        case 'setFilter':
            commandManager.execute({
                cmd: 'setFilter',
                sheetName: sheet.name(),
                sheetId: sheet.id(),
                range: range,
                value: null
            });
            break;
        default: // 包含纵向合并单元格 doNothing
    }
}
function hasFilter(spread) {
    var sheet = spread.getActiveSheet();
    return !!(sheet && sheet.rowFilter && sheet.rowFilter());
}
function hasHiddenRow(sheet, row, count) {
    var end = row + count;
    while (row < end) {
        if (!sheet.getRowVisible(row)) return true;
        row++;
    }
    return false;
}
function hiddenRowCount(sheet) {
    if (!sheet._rowInfos || !sheet._rowInfos._infos) return 0;
    return sheet._rowInfos._infos.filter(function (x) {
        return x && x.visible === false;
    }).length;
}
function hasHiddenCol(sheet, col, count) {
    var end = col + count;
    while (col < end) {
        if (!sheet.getColumnVisible(col)) return true;
        col++;
    }
    return false;
}
function hiddenColCount(sheet) {
    if (!sheet._colInfos || !sheet._colInfos._infos) return 0;
    return sheet._colInfos._infos.filter(function (x) {
        return x && x.visible === false;
    }).length;
}
function setRowColVisible(spread, action, range) {
    var sheet = spread.getActiveSheet();
    spread.commandManager().execute({
        cmd: 'setRowColVisible',
        sheetId: sheet.id(),
        action: action,
        ranges: [range]
    });
}
function rangesSubOverlap(ranges, targets, i) {
    var range = ranges[i];
    if (!range) {
        return targets;
    } else {
        var len = targets.length;
        var result = [];
        for (var _i2 = 0; _i2 < len; _i2++) {
            result.push.apply(result, (0, _toConsumableArray3.default)(targets[_i2].sub(range)));
        }
        return rangesSubOverlap(ranges, result, ++i);
    }
}
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(25)))

/***/ }),

/***/ 1801:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.addTimeout = addTimeout;
exports.clearAllTimeout = clearAllTimeout;
exports.clearGroupTimeout = clearGroupTimeout;
exports.addGroupTimeout = addGroupTimeout;
var timeoutSet = {};
var timeoutList = [];
function addTimeout(func) {
    var timeout = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : 0;

    var timer = setTimeout(func, timeout);
    timeoutList.push(timer);
    return timer;
}
function clearAllTimeout() {
    clearTimeouts(timeoutList);
    timeoutSet = {};
}
function clearGroupTimeout(key) {
    try {
        var list = timeoutSet[key];
        if (list && list.length > 0) {
            clearTimeouts(list);
        }
        delete timeoutSet[key];
    } catch (e) {
        //
    }
}
function addGroupTimeout(key, func) {
    var timeout = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : 0;

    timeoutSet[key] = timeoutSet[key] || [];
    timeoutSet[key].push(addTimeout(func, timeout));
}
function clearTimeouts(list) {
    list.forEach(function (timer) {
        timer && clearTimeout(timer);
    });
    list.length = 0;
}

/***/ }),

/***/ 1802:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.ExecOnlyActiveSheet = undefined;

var _ExecOnlyActiveSheet = __webpack_require__(3472);

var _ExecOnlyActiveSheet2 = _interopRequireDefault(_ExecOnlyActiveSheet);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.ExecOnlyActiveSheet = _ExecOnlyActiveSheet2.default;

/***/ }),

/***/ 1893:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _pick2 = __webpack_require__(233);

var _pick3 = _interopRequireDefault(_pick2);

var _uniq2 = __webpack_require__(352);

var _uniq3 = _interopRequireDefault(_uniq2);

exports.uniqFitRow = uniqFitRow;
exports.isCellLimitExceed = isCellLimitExceed;
exports.eachCell = eachCell;
exports.rowFilterOnSpreadLoaded = rowFilterOnSpreadLoaded;
exports.applyRowData = applyRowData;
exports.pickSheetSnapshot = pickSheetSnapshot;
exports.pickSnapshot = pickSnapshot;
exports.omitSheetComments = omitSheetComments;
exports.omitSpreadComments = omitSpreadComments;
exports.getCopyUrl = getCopyUrl;
exports.numberToRowOrColText = numberToRowOrColText;
exports.rowOrColTextToNumber = rowOrColTextToNumber;

var _sheetCore = __webpack_require__(1594);

var _sheetCommon = __webpack_require__(1591);

var _qs = __webpack_require__(353);

var _domainHelper = __webpack_require__(557);

var _string = __webpack_require__(163);

var _$moirae = __webpack_require__(449);

var _$moirae2 = _interopRequireDefault(_$moirae);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function uniqFitRow(sheet, changedRows, startCol, endCol) {
    return (0, _uniq3.default)(changedRows).reduce(function (pre, row) {
        var maxCellHeight = sheet._getRowHeightHint(row, undefined, startCol, endCol);
        var userRowHeight = sheet._userRowHeight[row] || sheet.defaults.rowHeight || 22;
        var rowHeight = maxCellHeight > userRowHeight ? maxCellHeight : userRowHeight;
        var currentHeight = sheet.getRowHeight(row);
        if (currentHeight !== rowHeight) {
            sheet.setRowHeight(row, rowHeight);
            pre.push({
                action: _sheetCommon.ACTIONS.SET_ROW_HEIGHT,
                sheet_id: sheet.id(),
                target: {
                    row: row,
                    row_count: 1
                },
                value: rowHeight
            });
        }
        return pre;
    }, []);
}
function isCellLimitExceed(sheet, changesets) {
    var rowCount = sheet.getRowCount();
    var colCount = sheet.getColumnCount();
    for (var i = 0; i < changesets.length; i++) {
        var changeset = changesets[i];
        if (changeset.action === 'addRow' || changeset.action === 'addCol') {
            if (rowCount * colCount > _sheetCommon.CELL_LIMIT) {
                return true;
            }
        }
    }
    return false;
}
function eachCell(selections, cb) {
    selections.forEach(function (selection, selectionIndex) {
        var row = selection.row,
            col = selection.col;
        var rowCount = selection.rowCount,
            colCount = selection.colCount;

        row = row === -1 ? 0 : row;
        col = col === -1 ? 0 : col;
        for (var r = row; r < row + rowCount; r++) {
            for (var c = col; c < col + colCount; c++) {
                cb && cb(r, c, selectionIndex);
            }
        }
    });
}
function rowFilterOnSpreadLoaded(spread) {
    // 在加载完的时候进行reFilter
    var sheets = spread.sheets;
    sheets.forEach(function (sheet) {
        var rowFilter = sheet.rowFilter();
        if (rowFilter) {
            rowFilter.reFilter();
        }
    });
}
function applyRowData(spread, sheetId, rowData) {
    var sheet = spread.getSheetFromId(sheetId);
    if (!sheet) {
        return; // sheet@doc receive some redundant sheets
    }
    var model = sheet._getModel();
    for (var row in rowData) {
        var rowInstance = rowData[row];
        for (var col in rowInstance) {
            var cell = rowInstance[col];
            if (Array.isArray(cell.value)) {
                cell.segmentArray = cell.value;
            } else if (cell.formula && cell.formula.trim() !== '') {
                (0, _sheetCore.setNodeVarByValue)(cell, sheet, parseInt(row, 10), parseInt(col, 10), '=' + cell.formula);
            } else {
                (0, _sheetCore.setNodeVarByValue)(cell, sheet, parseInt(row, 10), parseInt(col, 10), cell.value, true);
            }
            if (cell.style) {
                var style = new _sheetCore.Sheets.Style();
                /**
                 * 兼容老的链接 celltype
                 */
                if (cell.style.cellType && cell.style.cellType.typeName === '8') {
                    var link = cell.style.cellType.link;

                    var text = cell.value;
                    delete cell.style.cellType;
                    if (typeof text === 'string') {
                        cell.segmentArray = [{
                            type: 'url',
                            text: text || link,
                            link: link
                        }];
                    }
                }
                style.fromJSON(cell.style);
                cell.style = style;
            }
            if (cell.formula) {
                try {
                    sheet.setVarByValue(parseInt(row, 10), parseInt(col, 10), cell.formula);
                } catch (e) {
                    // Raven上报
                    _$moirae2.default.ravenCatch(e);
                }
                delete cell.formula;
            }
            model.dataTable[row] || (model.dataTable[row] = {});
            model.dataTable[row][col] = cell;
        }
    }
    sheet.notifyShell(_sheetCore.ShellNotifyType.LayoutChange);
}
/**
 * TODO: 这里有新字段拓展都需要添加，需要改进
 */
function pickSheetSnapshot(sheet) {
    return (0, _pick3.default)(sheet, ['columns', 'data', 'frozenColCount', 'frozenRowCount', 'id', 'index', 'name', 'rowFilter', 'rows', 'spans', 'rowCount', 'columnCount', 'chartMap']);
}
/**
 * 只拿实际有用的Snapshot字段
 */
function pickSnapshot(snapshot) {
    var sheets = snapshot.sheets;

    var newSheets = {};
    for (var sheetName in sheets) {
        var sheet = sheets[sheetName];
        newSheets[sheetName] = pickSheetSnapshot(sheet);
    }
    return {
        sheetCount: Object.keys(newSheets).length,
        version: snapshot.version,
        sheets: newSheets
    };
}
// side effect omit: comments
// snapshot: sheet snapshot
function omitSheetComments(sheet) {
    var table = sheet.data.dataTable;
    if (!table) return sheet;
    var rows = Object.keys(table);
    for (var i = 0; i < rows.length; i++) {
        var rowData = table[rows[i]];
        var cols = Object.keys(rowData || {});
        for (var j = 0; j < cols.length; j++) {
            var colData = rowData[cols[j]];
            if (colData && colData.comments) {
                delete colData.comments;
            }
        }
    }
    return sheet;
}
function omitSpreadComments(spread) {
    Object.keys(spread.sheets).forEach(function (name) {
        return omitSheetComments(spread.sheets[name]);
    });
    return spread;
}
function getCopyUrl(token) {
    var _window$location = window.location,
        origin = _window$location.origin,
        search = _window$location.search,
        hash = _window$location.hash;

    var query = (0, _qs.parse)(search.slice(1));
    var newQuery = { from: 'copy' };
    if (query.v) {
        newQuery.v = query.v;
    }
    var path = (0, _domainHelper.prependSpace)('/sheet/' + token + '?' + (0, _qs.stringify)(newQuery) + hash);
    return '' + origin + path;
}
function numberToRowOrColText(type, num) {
    return type === 'col' ? (0, _string.intToAZ)(num) : (num + 1).toString();
}
function rowOrColTextToNumber(type, text) {
    if (type === 'col') {
        return (0, _string.AZToInt)(text);
    } else {
        return parseInt(text, 10) - 1;
    }
}

/***/ }),

/***/ 1894:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _io = __webpack_require__(1895);

Object.keys(_io).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function get() {
      return _io[key];
    }
  });
});

/***/ }),

/***/ 1895:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.IO = exports.NetworkState = exports.Channel = exports.axios = undefined;

var _defineProperty2 = __webpack_require__(9);

var _defineProperty3 = _interopRequireDefault(_defineProperty2);

var _objectWithoutProperties2 = __webpack_require__(38);

var _objectWithoutProperties3 = _interopRequireDefault(_objectWithoutProperties2);

var _classCallCheck2 = __webpack_require__(6);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(7);

var _createClass3 = _interopRequireDefault(_createClass2);

var _typeof2 = __webpack_require__(82);

var _typeof3 = _interopRequireDefault(_typeof2);

var _isEqual2 = __webpack_require__(748);

var _isEqual3 = _interopRequireDefault(_isEqual2);

var _isObject2 = __webpack_require__(74);

var _isObject3 = _interopRequireDefault(_isObject2);

var _isEmpty2 = __webpack_require__(454);

var _isEmpty3 = _interopRequireDefault(_isEmpty2);

var _isFunction2 = __webpack_require__(303);

var _isFunction3 = _interopRequireDefault(_isFunction2);

var _forEach2 = __webpack_require__(343);

var _forEach3 = _interopRequireDefault(_forEach2);

var _uniqueId2 = __webpack_require__(350);

var _uniqueId3 = _interopRequireDefault(_uniqueId2);

var _isArray2 = __webpack_require__(53);

var _isArray3 = _interopRequireDefault(_isArray2);

var _reduce2 = __webpack_require__(230);

var _reduce3 = _interopRequireDefault(_reduce2);

var _get2 = __webpack_require__(83);

var _get3 = _interopRequireDefault(_get2);

var _values2 = __webpack_require__(562);

var _values3 = _interopRequireDefault(_values2);

var _axios2 = __webpack_require__(351);

var _axios3 = _interopRequireDefault(_axios2);

var _$bytedSocketBr = __webpack_require__(794);

var _$bytedSocketBr2 = _interopRequireDefault(_$bytedSocketBr);

var _util = __webpack_require__(354);

var _string = __webpack_require__(163);

var _envHeaderHelper = __webpack_require__(459);

var _userHelper = __webpack_require__(65);

var _createRequest = __webpack_require__(579);

var _suiteHelper = __webpack_require__(52);

var _tea = __webpack_require__(42);

var _tea2 = _interopRequireDefault(_tea);

var _sdkCompatibleHelper = __webpack_require__(45);

var _performanceLogHelper = __webpack_require__(458);

var _generateHeadersHelper = __webpack_require__(347);

var _asyncHelper = __webpack_require__(569);

var _generateRequestIdHelper = __webpack_require__(457);

var _$constants = __webpack_require__(5);

var _sliApiMap = __webpack_require__(309);

var _$moirae = __webpack_require__(449);

var _$moirae2 = _interopRequireDefault(_$moirae);

var _networkHelper = __webpack_require__(113);

var _apiUrls = __webpack_require__(307);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var __decorate = undefined && undefined.__decorate || function (decorators, target, key, desc) {
    var c = arguments.length,
        r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc,
        d;
    if ((typeof Reflect === "undefined" ? "undefined" : (0, _typeof3.default)(Reflect)) === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);else for (var i = decorators.length - 1; i >= 0; i--) {
        if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    }return c > 3 && r && Object.defineProperty(target, key, r), r;
};

var createRequest = (0, _sdkCompatibleHelper.isSupportOfflineEdit)() ? _createRequest.createSupportOfflineRequest : _createRequest.createNormalRequest;
var ioInstance = void 0;
var headers = { 'Content-Type': 'application/json' };
var envHeader = (0, _envHeaderHelper.getEnvHeader)();
if (envHeader) {
    headers.Env = envHeader;
}
function logNetworkErrorIfAny(message) {
    if (!message) {
        return;
    }
    var engineType = message.type;
    var messageType = message.data ? message.data.type : '';
    if ((engineType || messageType) && message.code === undefined) {
        (0, _tea2.default)('client_network_no_error_code', {
            engineType: engineType,
            messageType: messageType
        });
    }
    var log = function log(prefix, data) {
        var requestId = data.request_id;
        console.log("Network Error (" + prefix + ": " + (requestId || 'null') + "):", data);
    };
    if (message.code !== undefined && message.code !== 0) {
        log('System', message);
    } else if (message.data) {
        var code = message.data.code;
        if (code !== undefined && code !== 0) {
            log('Service', message);
        }
    }
}
var axios = exports.axios = _axios3.default.create({
    headers: headers,
    withCredentials: true
});
axios.interceptors.request.use(function (request) {
    var requestId = (0, _generateRequestIdHelper.generateRequestId)();
    if (request.data && request.data.context) {
        requestId = request.data.context.request_id || requestId;
        request.data.context.request_id = requestId;
    }
    var generatedHeaderObj = (0, _generateHeadersHelper.generateHeaders)({ requestId: requestId });
    var mergedHeaders = Object.assign({}, generatedHeaderObj, request.headers);
    // request，由于部分老代码调用没有经过paramsFixMiddleware处理，而直接调用request，所以这里额外做一次url前缀处理
    if (_apiUrls.API_PREFIX && request.url.indexOf('/api/') === 0) {
        request.url = _apiUrls.API_PREFIX + request.url;
    }
    return Object.assign(request, { headers: mergedHeaders });
});
axios.interceptors.response.use(function (response) {
    logNetworkErrorIfAny(response.data);
    // @todo 需要对应的错误处理，例如 5 需要login
    if (response.data.code !== 0) {
        return Promise.reject(response);
    }
    try {
        var config = response.config;
        (0, _performanceLogHelper.transformPerformanceData)({
            url: config.url,
            data: {
                code: response.data.code,
                request_id: config.headers['Request-Id'],
                data: config.data
            }
        });
    } catch (e) {
        console.error(e);
    }
    return response.data;
}, function (error) {
    var config = error.config;
    var code = -1;
    if (error.response) {
        code = error.response.data.code || code;
    } else {
        // 在设置触发错误的请求时发生了错误
        console.log('Error', error.message);
    }
    try {
        (0, _performanceLogHelper.transformPerformanceData)({
            url: config.url,
            data: {
                code: code,
                request_id: error.config.headers['Request-Id'],
                data: config.data
            }
        });
    } catch (e) {
        console.error(e);
    }
});
var SOCKET_HEARBEAT = '2';
var RCE_VERSION = 2;
// 需要静默重试的错误码
var RETRY_ERROR_CODE_ARR = [1015, 9998];
var Channel = exports.Channel = undefined;
(function (Channel) {
    Channel["http"] = "http";
    Channel["socket"] = "socket";
})(Channel || (exports.Channel = Channel = {}));
var NetworkState = exports.NetworkState = undefined;
(function (NetworkState) {
    NetworkState["online"] = "online";
    NetworkState["offline"] = "offline";
})(NetworkState || (exports.NetworkState = NetworkState = {}));

var IO = exports.IO = function () {
    function IO(options) {
        var _this = this;

        (0, _classCallCheck3.default)(this, IO);

        /**
         *  当前通道
         */
        this.channel = Channel.http;
        /**
         * 当前状态
         */
        this.state = NetworkState.online;
        /**
         * 心跳间隔，60s
         */
        this.heartbeatInterval = 6000;
        /**
         * 请求超时时间
         * 15s没收到accept就认为提交失败，网络异常
         * 会主动断开连接，并且重连
         */
        this.timeout = 15000;
        /**
         * frontier上传最大字节
         */
        this.maxSize = 1500;
        this.channelStateCallbacks = [];
        /**
         * 获取token的次数，用于失败重试间隔
         */
        this.fetchTokenTimes = 0;
        /**
         * 请求自增id
         */
        this.reqId = 1;
        /**
         * 所有的请求缓存，通过reqId对应
         */
        this.requests = {};
        /**
         * 记录发送了watch的entity
         */
        this.watchEntitys = [];
        // 监听的资源实体
        // 以 `${type}:${token}`为下标
        // value存储 entity, heartbeat配置信息
        this.entities = {};
        this.ticket = '';
        this.scheduleHB = null;
        this.hbErrorCount = 0;
        this.counter = 0;
        // Map<`${type}:${token}`, Map<string, EntityObserver>>;
        this.entityObservers = new Map();
        this.rewatch = function () {
            _$moirae2.default.info(_this.getLogMessage('socket connected'));
            for (var key in _this.entities) {
                var info = key.split(':');
                if (info[1] === (0, _suiteHelper.getToken)()) {
                    _this.watchEntity({
                        type: info[0],
                        token: info[1]
                    });
                    break;
                }
            }
        };
        this.scheduleFinallyCb = function () {
            _$moirae2.default.info(_this.getLogMessage('scheule next heartbeat'));
            _this.hbErrorCount = 0;
            _this.schedule();
        };
        this.scheduleCatchCb = function (e) {
            _this.hbErrorCount += 1;
            if (_this.hbErrorCount % 3 === 0) {
                _$moirae2.default.error({
                    key: 'client_suit_hearbeat_error',
                    hbErrorCount: _this.hbErrorCount
                });
                _$moirae2.default.count('ee.docs.sheet.client_suit_hearbeat_error');
            }
            _$moirae2.default.error(_this.getLogMessage("hearbeat error: " + e));
            _$moirae2.default.error(_this.getLogMessage('scheule next heartbeat'));
            _this.schedule();
            // 心跳异常
            console.error('心跳异常:', e.message, e);
        };
        this.handleOnline = function () {
            _$moirae2.default.info(_this.getLogMessage('online'));
            _this.channel = Channel.http;
            _this.state = NetworkState.online;
            _this.triggerChannelState();
            _this.fetchTimout && clearTimeout(_this.fetchTimout);
            _this.connectSocket();
        };
        this.handleOffline = function () {
            _$moirae2.default.info(_this.getLogMessage('offline'));
            _this.state = NetworkState.offline;
            _this.triggerChannelState();
        };
        this.handleUnload = function () {
            var entities = (0, _values3.default)(_this.entities).map(function (v) {
                return v.entity;
            });
            _this.unRegister(entities);
            _this.socket && _this.socket.close();
        };
        for (var key in options) {
            this[key] = options[key];
        }
        if (!this.memberId) {
            var memberId = parseInt((0, _get3.default)(window, 'DATA.clientVars.data.user_info.member_id'), 10);
            this.memberId = memberId || (0, _util.getDeviceId)(new Date().valueOf());
            this.ticket = (0, _get3.default)(window, 'User.wsTicket');
        }
        this.baseInfo = {
            member_id: this.memberId,
            user_ticket: this.ticket
        };
        if (options && options.autoConnect !== false) {
            this.connectSocket();
        }
        window.addEventListener('online', this.handleOnline);
        window.addEventListener('offline', this.handleOffline);
        // 退出时关闭socket链接
        window.addEventListener('unload', this.handleUnload);
        this.hasListener = true; // 监听标志位，避免重复监听
        this.schedule();
    }

    (0, _createClass3.default)(IO, [{
        key: "register",

        /**
         * 注册entity，做好本地配置
         * @param {array|object} entities 资源列表， { type, token } = entity
         * @param {object} options 配置
         *        message: message相关配置
         *          handler: message处理函数
         *          filter: message过滤器, 可以为 function or entity
         *        heartbeat: 心跳相关配置，可以为空
         */
        value: function register(entity, options) {
            var key = IO.keyOf(entity);
            this.entities[key] = {
                entity: entity,
                message: options.message,
                heartbeats: (0, _reduce3.default)(options.heartbeats, function (prev, heartbeat, name) {
                    prev[name] = IO.initHeartbeat(heartbeat);
                    return prev;
                }, {}),
                acceptWatchHandler: options.acceptWatchHandler
            };
            if (!this.hasListener) {
                window.addEventListener('online', this.handleOnline);
                window.addEventListener('offline', this.handleOffline);
                window.addEventListener('unload', this.handleUnload);
                this.hasListener = true;
            }
        }
        /**
         * 手动调用watch
         * @param entity
         */

    }, {
        key: "watch",
        value: function watch(entity) {
            console.log('!watch entity', entity);
            this.watchEntitys.push(entity);
            this.watchEntity(entity);
        }
    }, {
        key: "watchEntity",
        value: function watchEntity(entity) {
            var _this2 = this;

            if (!entity) return;
            var entityKey = IO.keyOf(entity);
            return this.request({
                type: 'COLLABROOM',
                data: {
                    type: 'WATCH',
                    entities: [entity]
                }
            }).then(function (message) {
                // 需要检查message内，watch的entity是否watch成功
                var acceptedEntities = (0, _get3.default)(message, 'data.entities') || [];
                var curAcceptedEntity = acceptedEntities.find(function (_ref) {
                    var type = _ref.type,
                        token = _ref.token;

                    if (type === entity.type && token === entity.token) {
                        return true;
                    }
                    return false;
                });
                if (!curAcceptedEntity || curAcceptedEntity.succ !== 1) {
                    throw new Error("watching entity failed! " + entity.type + " " + entity.token);
                }
                var registeredEntity = _this2.entities[entityKey];
                if (registeredEntity && registeredEntity.acceptWatchHandler) {
                    registeredEntity.acceptWatchHandler(message);
                }
            });
        }
        /**
         * unwatch将删除entity的所有配置，并发送unwatch请求到服务端
         */

    }, {
        key: "unRegister",
        value: function unRegister(entities) {
            var _this3 = this;

            entities = (0, _isArray3.default)(entities) ? entities : [entities];
            entities.forEach(function (entity) {
                var key = IO.keyOf(entity);
                console.log('delete entities key:', key);
                _this3.watchEntitys = _this3.watchEntitys.filter(function (item) {
                    return item.token !== entity.token || item.type !== entity.type;
                });
                delete _this3.entities[key];
            });
            this.request({
                type: 'COLLABROOM',
                data: {
                    type: 'UNWATCH',
                    entities: entities
                }
            });
            window.removeEventListener('online', this.handleOnline);
            window.removeEventListener('offline', this.handleOffline);
            window.removeEventListener('unload', this.handleUnload);
            this.hasListener = false;
        }
        /**
         * 注册需要关注的entity，可增加heartbeat和处理handler
         */

    }, {
        key: "registerEntityObserver",
        value: function registerEntityObserver(entity, options) {
            var key = IO.keyOf(entity);
            var registeredId = (0, _uniqueId3.default)();
            var observers = this.entityObservers.get(key);
            var heartbeats = (0, _reduce3.default)(options.heartbeats, function (prev, heartbeat, name) {
                prev[name] = IO.initHeartbeat(heartbeat);
                return prev;
            }, {});
            var observer = {
                heartbeats: heartbeats,
                messageHandler: options.messageHandler
            };
            if (observers) {
                observers.set(registeredId, observer);
            } else {
                var entityObservers = new Map();
                entityObservers.set(registeredId, observer);
                this.entityObservers.set(key, entityObservers);
            }
            return registeredId;
        }
    }, {
        key: "updateEntityObserver",
        value: function updateEntityObserver(entity, registeredId, options) {
            var key = IO.keyOf(entity);
            var observers = this.entityObservers.get(key);
            if (!observers) {
                throw new Error("no observers found: " + key);
            }
            var observer = observers.get(registeredId);
            if (!observer) {
                throw new Error("no observer found: " + key + " " + registeredId);
            }
            var needUpdateHeartbeats = options.heartbeats,
                extra = (0, _objectWithoutProperties3.default)(options, ["heartbeats"]);

            var nextHeartbeats = observer.heartbeats;
            if (needUpdateHeartbeats) {
                (0, _forEach3.default)(needUpdateHeartbeats, function (heartbeat, name) {
                    nextHeartbeats[name] = IO.initHeartbeat(heartbeat);
                });
            }
            observers.set(registeredId, Object.assign({}, observer, extra, { heartbeats: nextHeartbeats }));
        }
        /**
         * 取消关注entity
         * @param entity
         * @param registeredId
         */

    }, {
        key: "unregisterEntityObserver",
        value: function unregisterEntityObserver(entity, registeredId) {
            var key = IO.keyOf(entity);
            var observers = this.entityObservers.get(key);
            if (observers) {
                observers.delete(registeredId);
            }
        }
    }, {
        key: "addHeartbeat",
        value: function addHeartbeat(entity, name, heartbeat) {
            var key = IO.keyOf(entity);
            var curEntityInfo = this.entities[key];
            if (!curEntityInfo) {
                console.warn && console.warn('fail to add heartbeat because entity is not registered: ', key);
                return;
            }
            curEntityInfo.heartbeats[name] = IO.initHeartbeat(heartbeat);
        }
    }, {
        key: "removeHeartbeat",
        value: function removeHeartbeat(entity, name) {
            var key = IO.keyOf(entity);
            var curEntityInfo = this.entities[key];
            if (!curEntityInfo) {
                console.warn && console.warn('fail to remove heartbeat because entity is not registered: ', key);
                return;
            }
            delete curEntityInfo.heartbeats[name];
        }
    }, {
        key: "request",
        value: function request(payload) {
            var options = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};

            var channel = options.channel || this.channel;
            channel = channel === Channel.http ? Channel.http : Channel.socket;
            if (channel === Channel.socket) {
                return this.requestBySocket(payload, options);
            } else {
                return this.requestByHttp(payload, options);
            }
        }
    }, {
        key: "requestByHttp",
        value: function requestByHttp(payload) {
            var options = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};

            return this._requestByHttp(Object.assign({}, payload, {
                version: payload.version || RCE_VERSION,
                data: Object.assign({}, this.baseInfo, payload.data),
                req_id: payload.req_id || this.reqId++,
                context: {
                    os: (0, _tea.getOSNameByBrowser)(),
                    app_version: (0, _tea.getAppVersion)(),
                    os_version: (0, _tea.getOSVersionByBrowser)(),
                    platform: (0, _tea.getPlatForm)()
                }
            }), options);
        }
    }, {
        key: "requestBySocket",
        value: function requestBySocket(payload, options) {
            var newPayload = Object.assign({}, payload, {
                version: payload.version || RCE_VERSION,
                data: Object.assign({}, this.baseInfo, payload.data),
                req_id: payload.req_id || this.reqId++,
                context: {
                    os: (0, _tea.getOSNameByBrowser)(),
                    app_version: (0, _tea.getAppVersion)(),
                    os_version: (0, _tea.getOSVersionByBrowser)(),
                    request_id: (0, _generateRequestIdHelper.generateRequestId)(),
                    platform: (0, _tea.getPlatForm)()
                }
            });
            // frontier对提交的包体积有限制为2k，前端限制为1.5k，避免存在字符串计算不一致的情况
            if ((0, _string.isSizeofOver)(JSON.stringify(newPayload), this.maxSize)) {
                return this._requestByHttp(newPayload, options);
            }
            return this._requestBySocket(newPayload, options);
        }
        // 有些api可能还未兼容长链设计，可以单独请求，直接用axios也可以

    }, {
        key: "requestApi",
        value: function requestApi(payload) {
            return createRequest(axios)(payload);
        }
        /**
         * 业务正常收到消息时，需要手动set一下心跳version，保证心跳不会误报
         */

    }, {
        key: "setHeartbeatVersion",
        value: function setHeartbeatVersion(entity, moduleName, version) {
            var key = IO.keyOf(entity);
            var entityInfo = this.entities[key];
            var config = entityInfo && entityInfo.heartbeats && entityInfo.heartbeats[moduleName];
            if (config) {
                config.version = version;
            }
        }
    }, {
        key: "getHeartbeatInfo",
        value: function getHeartbeatInfo(type, token) {
            var key = type + ":" + token;
            var entityInfo = this.entities[key];
            if (entityInfo && entityInfo.heartbeats) {
                return Object.assign({}, entityInfo.heartbeats);
            }
            return null;
        }
    }, {
        key: "reset",
        value: function reset() {
            this.counter = 0;
            this.reqId = 1;
            this.requests = {};
            this.entities = {};
            this.channelStateCallbacks = [];
            if (this.scheduleHB) {
                clearTimeout(this.scheduleHB);
                this.scheduleHB = null;
            }
        }
        // --------------------
        // 以上为外部接口

    }, {
        key: "setBaseInfoTicket",
        value: function setBaseInfoTicket(ticket) {
            this.baseInfo.user_ticket = ticket;
        }
    }, {
        key: "fetchFrontierTicketForReconnect",
        value: function fetchFrontierTicketForReconnect(cb) {
            var _this4 = this;

            this.fetchFrontierTicketReq && this.fetchFrontierTicketReq.cancel && this.fetchFrontierTicketReq.cancel();
            this.fetchFrontierTicketReq = createRequest(axios)({
                url: '/api/passport/ws_ticket/',
                method: 'post',
                noStore: true
            }).then(function (response) {
                _this4.ticket = response.data && response.data.ticket;
                if (_this4.ticket) {
                    _this4.setBaseInfoTicket(_this4.ticket);
                    _this4.fetchTokenTimes = 0;
                    if (_this4.socketConfig) {
                        _this4.socketConfig.query.session_ticket = _this4.ticket;
                    }
                    cb && cb((0, _util.formatURL)(_this4.socketConfig));
                } else {
                    _this4.refetchFrontierTicket(_this4.fetchFrontierTicketForReconnect, cb);
                }
            }).catch(function (err) {
                // 失败重试
                console.log('fetch frontier token error', err);
                _this4.refetchFrontierTicket(_this4.fetchFrontierTicketForReconnect, cb);
            });
        }
    }, {
        key: "fetchFrontierTicket",
        value: function fetchFrontierTicket() {
            var _this5 = this;

            var User = window.User;
            if (User.wsTicket) {
                _$moirae2.default.info(this.getLogMessage("Use ticket " + User.wsTicket));
                this.ticket = User.wsTicket;
                delete User.wsTicket;
                this.setBaseInfoTicket(this.ticket);
                this._connectSocket(this.ticket);
            } else {
                _$moirae2.default.info(this.getLogMessage('request ticket'));
                createRequest(axios)({
                    url: '/api/passport/ws_ticket/',
                    method: 'post',
                    noStore: true
                }).then(function (response) {
                    _this5.ticket = response.data && response.data.ticket;
                    if (_this5.ticket) {
                        _$moirae2.default.info(_this5.getLogMessage("Use ticket " + _this5.ticket));
                        _this5.setBaseInfoTicket(_this5.ticket);
                        _this5.fetchTokenTimes = 0;
                        _this5._connectSocket(_this5.ticket);
                    } else {
                        _$moirae2.default.info(_this5.getLogMessage('REFETCH ticket'));
                        _this5.refetchFrontierTicket(_this5.fetchFrontierTicket);
                    }
                }).catch(function (err) {
                    // 失败重试
                    console.log('fetch frontier token error', err);
                    _this5.refetchFrontierTicket(_this5.fetchFrontierTicket);
                });
            }
        }
    }, {
        key: "refetchFrontierTicket",
        value: function refetchFrontierTicket(func, cb) {
            var _this6 = this;

            this.fetchTimout && clearTimeout(this.fetchTimout);
            this.fetchTimout = window.setTimeout(function () {
                func.call(_this6, cb);
            }, Math.min(++this.fetchTokenTimes * 1000), 15000);
        }
    }, {
        key: "_connectSocket",
        value: function _connectSocket(ticket) {
            _$moirae2.default.info(this.getLogMessage('connect socket'));
            var host = this.host;

            var envConfig = {
                default: {
                    fpid: 54,
                    appKey: '5a4d135f57bfbf0461ad10cc7f1d3658',
                    aid: '1191'
                },
                preview: {
                    fpid: 61,
                    appKey: '4af89272b20e69c0f78512189e86d13d',
                    aid: '10011'
                }
            };
            var config = envConfig[window._env || 'default'];
            var fpid = config.fpid,
                appKey = config.appKey,
                aid = config.aid;

            var accessSalt = 'f8a69f1719916z';
            var url = this.getSocketAddr();
            var query = Object.assign({
                aid: aid,
                fpid: fpid,
                sdk_version: 1,
                version_code: 5806,
                session_ticket: ticket,
                device_id: this.memberId,
                version: 2
            }, host ? { /* for test env */host: host } : {});
            this.socketConfig = {
                url: url,
                receiveClientVarsFromOutSide: true,
                protocols: 'pbbp2',
                // Allow deployers to host Etherpad on a non-root path
                lookupType: 'protocol.Frame',
                reconnectionAttempts: 9007199254740992,
                reconnection: true,
                reconnectInterval: 1000,
                reconnectionDelayMax: 15000,
                reconnections: 2000,
                appKey: appKey,
                fpid: fpid,
                accessSalt: accessSalt,
                query: query,
                beforeReconnect: this.beforeReconnect.bind(this)
            };
            // 建立连接前需要确保旧连接被释放
            var oldSocket = this.socket;
            if (oldSocket) {
                oldSocket.connected && oldSocket.close();
            }
            this.socket = new _$bytedSocketBr2.default(this.socketConfig);
            this.bindSocketEvent();
        }
    }, {
        key: "connectSocket",
        value: function connectSocket() {
            if (!(0, _userHelper.isDocRnEnabled)()) {
                this.fetchFrontierTicket();
            }
        }
    }, {
        key: "beforeReconnect",
        value: function beforeReconnect(cb) {
            this.fetchFrontierTicketForReconnect(cb);
        }
        /**
         * init: connecting->connect
         * disconnect->reconnecting（maybe many times）->connecting->reconnect->connect
         */

    }, {
        key: "bindSocketEvent",
        value: function bindSocketEvent() {
            var _this7 = this;

            var canUse = ['connect', 'reconnect'];
            canUse.forEach(function (event) {
                _this7.socket.on(event, function () {
                    _this7.channel = Channel.socket;
                    _this7.state = NetworkState.online;
                    _this7.triggerChannelState();
                });
            });
            var canNotUse = ['disconnect', 'connecting', 'reconnecting', 'reconnect_failed', 'error', 'reconnect_attempt', 'reconnect_error', 'close'];
            canNotUse.forEach(function (event) {
                _this7.socket.on(event, function () {
                    if (_this7.channel === Channel.http) return;
                    // socket 不可用，切为 http
                    _this7.channel = Channel.http;
                    // 一直是offline，不用响应
                    if (_this7.state === NetworkState.offline) return;
                    // 通知变化
                    _$moirae2.default.info(_this7.getLogMessage("socket error, current state: " + event));
                    _this7.triggerChannelState();
                });
            });
            this.socket.on('reconnect', this.rewatch);
            this.socket.on('connect', this.rewatch);
            this.socket.on('message', function (message) {
                _this7.channel = Channel.socket;
                _this7.state = NetworkState.online;
                _this7.handleMessage(message);
            });
        }
    }, {
        key: "getSocketAddr",
        value: function getSocketAddr() {
            var User = window.User;
            if (User.wsServer) return User.wsServer;
            if (location.protocol === 'http:' && location.host !== 'docs.bytedance.net') {
                return 'ws://10.6.24.195:5998/ws/v2';
            }
            if ((0, _networkHelper.isProdEnv)()) {
                return _networkHelper.wsURL;
            }
            return 'wss://bear-test.bytedance.net/ws/v2';
        }
    }, {
        key: "_requestByHttp",
        value: function _requestByHttp(payload) {
            var _this8 = this;

            var options = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
            var retryTimeout = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : 0;

            var type = payload.data && payload.data.type;
            var id = '';
            if (payload.context) {
                id = (0, _generateRequestIdHelper.generateRequestId)();
                payload.context.request_id = id;
            }
            var reqId = payload.req_id;
            var noStore = options.noStore === undefined ? true : options.noStore;
            _$moirae2.default.info(this.getLogMessage("send req(" + (id || reqId) + ") " + type + " by http"));
            try {
                _$moirae2.default.count('ee.docs.sheet.client_suit_request_http');
            } catch (ex) {
                // ConsoleError
                console.error(ex);
                // Raven上报
                window.Raven && window.Raven.captureException(ex);
            }
            var promise = createRequest(axios)({
                url: "" + _$constants.apiUrls.POST_RCE_MESSAGE,
                method: 'post',
                params: { member_id: this.memberId },
                data: payload,
                noStore: noStore,
                timeout: options.timeout || this.timeout,
                contentType: 'application/json',
                headers: (0, _defineProperty3.default)({}, _sliApiMap.X_COMMAND, _sliApiMap.API_RCE_PANDORA)
            }).then(function (message) {
                var data = message.data;
                // 中间拦截做统一错误处理
                // 某些错误码需要静默重试
                if (data && data.type === 'ERROR' && RETRY_ERROR_CODE_ARR.indexOf(data.code) >= 0) {
                    _$moirae2.default.info(_this8.getLogMessage("RESEND req(" + (id || reqId) + ") for error code " + data.code));
                    // 每次重试请求delay 3s
                    var timeout = retryTimeout + 3000;
                    return new Promise(function (resolve, reject) {
                        setTimeout(function () {
                            _this8._requestByHttp(payload, Object.assign({}, options), timeout).then(resolve, reject);
                        }, timeout);
                    });
                }
                _$moirae2.default.info(_this8.getLogMessage("req(" + (id || reqId) + ") " + type + " by http is resolved"));
                return message;
            }).catch(function (e) {
                // 超时后进行重试
                if (options.timeoutRetry && e && e.code === 'ECONNABORTED') {
                    _$moirae2.default.info(_this8.getLogMessage("RESEND req(" + (id || reqId) + ") by http for error " + e));
                    return _this8._requestByHttp(payload, Object.assign({}, options, { timeoutRetry: Math.max(0, options.timeoutRetry - 1) }));
                }
                _$moirae2.default.info(_this8.getLogMessage("req(" + (id || reqId) + ") " + type + " by http is rejected for error " + e));
                _$moirae2.default.count('ee.docs.doc.client_io_rejected');
                return Promise.reject(e);
            });
            promise.reqId = payload.req_id;
            return promise;
        }
    }, {
        key: "_requestBySocket",
        value: function _requestBySocket(payload, options) {
            var _this9 = this;

            var type = payload.data && payload.data.type;
            var reqId = payload.req_id;
            var id = payload.context && payload.context.request_id || reqId;
            var promise = new Promise(function (resolve, reject) {
                var request = {
                    payload: payload,
                    options: options,
                    resolve: resolve,
                    reject: reject,
                    resendByHttp: function resendByHttp() {
                        // 发短链
                        _$moirae2.default.info(_this9.getLogMessage("RESEND req(" + (id || reqId) + ") " + type + " by http"));
                        _this9._requestByHttp(payload, options).then(resolve, reject);
                        delete _this9.requests[reqId];
                    }
                };
                _this9.requests[reqId] = request;
                _$moirae2.default.info(_this9.getLogMessage("send req(" + id + ") " + type + " by socket"));
                _this9.socket.json.send(payload);
                setTimeout(function () {
                    // 长链未处理，转ajax重试
                    if (_this9.requests[reqId]) {
                        _$moirae2.default.info(_this9.getLogMessage("req(" + id + ") " + type + " by socket timeout"));
                        _this9.requests[reqId].resendByHttp();
                    }
                }, options.timeout || _this9.timeout);
            });
            promise.reqId = reqId;
            setTimeout(function () {
                try {
                    _$moirae2.default.count('ee.docs.sheet.client_suit_request_socket');
                } catch (ex) {
                    // ConsoleError
                    console.error(ex);
                    // Raven上报
                    window.Raven && window.Raven.captureException(ex);
                }
            }, 2000);
            return promise;
        }
    }, {
        key: "handleMessage",
        value: function handleMessage(message) {
            var _this10 = this;

            // '2'是FR的心跳包标记，见byted-socket-br.config.heartbeat
            if (!message || message.data && message.data === SOCKET_HEARBEAT) return;
            logNetworkErrorIfAny(message);
            var type = message.data && message.data.type;
            var id = message.request_id;
            var reqId = message.req_id;
            var requests = this.requests;
            // 有 reqId ，是主动请求
            if (reqId && requests[reqId]) {
                // server告知over_size传输字节过大，主动http补充一次
                if (message.data && message.data.over_size === 1) {
                    _$moirae2.default.info(this.getLogMessage("req(" + id + ") " + type + " by socket is oversize"));
                    requests[reqId].resendByHttp();
                    return;
                }
                _$moirae2.default.info(this.getLogMessage("req(" + id + ") " + type + " by socket is resolved"));
                requests[reqId].resolve(message);
                delete requests[reqId];
                return;
            }
            _$moirae2.default.info(this.getLogMessage("message(" + id + ") " + type + " is received by socket"));
            // 被动广播的消息
            (0, _forEach3.default)(this.entities, function (entity) {
                var _ref2 = entity.message || {},
                    handler = _ref2.handler,
                    filter = _ref2.filter;

                if (!(0, _isFunction3.default)(filter) && (0, _isEmpty3.default)(filter) || (0, _isFunction3.default)(filter) && filter(message) || (0, _isObject3.default)(filter) && (0, _isEqual3.default)(filter, {
                    type: message.type,
                    token: (0, _get3.default)(message, 'data.token')
                })) {
                    handler && handler(message);
                }
                // 有一些没那么重要的服务（比如说评论）也在监听这个消息
                var entityObservers = _this10.entityObservers.get(IO.keyOf(entity.entity));
                if (entityObservers) {
                    entityObservers.forEach(function (entityObserver, registeredId) {
                        try {
                            entityObserver.messageHandler(message);
                        } catch (e) {
                            console.error("entityObserver handle message error: " + registeredId + ", " + e);
                        }
                    });
                }
            });
        }
    }, {
        key: "getTicket",
        value: function getTicket() {
            return this.ticket;
        }
    }, {
        key: "getMemberId",
        value: function getMemberId() {
            return this.memberId;
        }
    }, {
        key: "sendHeartbeats",
        value: function sendHeartbeats(finallyCb, catchCb) {
            var _this11 = this;

            var channels = []; // 触发心跳检查的请求参数
            var triggers = []; // 触发心跳检查的module指针
            (0, _forEach3.default)(this.entities, function (entity) {
                if (_this11.watchEntitys.some(function (item) {
                    return item.token === entity.entity.token && item.type === entity.entity.type;
                })) {
                    var channel = {
                        type: entity.entity.type,
                        token: entity.entity.token,
                        modules: []
                    };
                    var collectTrigger = function collectTrigger(info, name) {
                        // 心跳需要带的module信息
                        if (_this11.counter >= info.counter + info.interval) {
                            triggers.push(info);
                            channel.modules.push(name);
                        }
                    };
                    (0, _forEach3.default)(entity.heartbeats, collectTrigger);
                    var entityObservers = _this11.entityObservers.get(IO.keyOf(entity.entity));
                    if (entityObservers) {
                        entityObservers.forEach(function (entityObserver) {
                            (0, _forEach3.default)(entityObserver.heartbeats, collectTrigger);
                        });
                    }
                    channels.push(channel);
                }
            });
            var counter = this.counter;
            this.request({
                type: 'COLLABROOM',
                data: {
                    type: 'USER_HEARTBEAT',
                    member_id: this.memberId,
                    user_ticket: this.ticket,
                    channels: channels
                },
                version: 2
            }, {
                noStore: true
            }).then(function (response) {
                try {
                    // 如果目前是断网环境，则判定为上线
                    if (_this11.state === NetworkState.offline) {
                        _$moirae2.default.info({
                            key: 'client_suit_hearbeat_resume'
                        });
                        _$moirae2.default.count('ee.docs.sheet.client_suit_hearbeat_resume');
                        _this11.handleOnline();
                    }
                    var channelInfo = response.data.channel_info;
                    // 修改心跳间隔
                    var interval = parseInt(response.data.interval, 10);
                    if (interval) {
                        _this11.heartbeatInterval = interval * 1000;
                    }
                    // 更新计数器
                    (0, _forEach3.default)(triggers, function (info) {
                        info.counter = counter;
                    });
                    // 处理服务端返回的心跳数据
                    (0, _forEach3.default)(channelInfo, function (info) {
                        var key = info.type + ":" + info.token;
                        var entityInfo = _this11.entities[key];
                        if ((0, _isEmpty3.default)(entityInfo)) {
                            return;
                        }
                        (0, _forEach3.default)(info.modules, function (module) {
                            var moduleName = module.name;
                            var version = parseInt(module.version, 10);
                            var config = entityInfo.heartbeats[moduleName];
                            // 没有注册的心跳module，不用处理
                            if (!(0, _isEmpty3.default)(config)) {
                                // 对比本地状态
                                _this11.checkHeartbeat(version, config, entityInfo);
                            }
                            var entityObservers = _this11.entityObservers.get(key);
                            if (entityObservers) {
                                try {
                                    entityObservers.forEach(function (entityObserver) {
                                        var heartbeat = entityObserver.heartbeats[moduleName];
                                        if (heartbeat) {
                                            // 对比本地状态
                                            _this11.checkHeartbeat(version, heartbeat, entityInfo);
                                        }
                                    });
                                } catch (e) {
                                    console.error('entityObservers handle heartbeat failed', moduleName, version);
                                }
                            }
                        });
                    });
                } finally {
                    if (finallyCb) {
                        finallyCb();
                    }
                }
            }).catch(function (e) {
                if (catchCb) {
                    catchCb(e);
                }
            });
        }
    }, {
        key: "syncMemberBaseRev",
        value: function syncMemberBaseRev(entity, revision) {
            var type = entity.type,
                token = entity.token;

            var entityHeartbeat = this.getHeartbeatInfo(type, token) || {};
            var memberHeartBeat = entityHeartbeat.member_channel;
            if (!memberHeartBeat) return Promise.resolve();
            var curVersion = memberHeartBeat.version;
            var nextVersion = curVersion + 1;
            if (revision === nextVersion) {
                this.setHeartbeatVersion(entity, 'member_channel', revision);
                return Promise.resolve();
            }
            return Promise.resolve({
                nextVersion: nextVersion
            });
        }
    }, {
        key: "checkHeartbeat",
        value: function checkHeartbeat(remoteVersion, heartbeat, entityInfo) {
            var oldVersion = heartbeat.version,
                callback = heartbeat.callback;
            // 对比本地状态

            if (remoteVersion > oldVersion) {
                heartbeat.version = remoteVersion;
                // 如果有差异，执行回调
                if (callback) {
                    callback(remoteVersion, oldVersion, entityInfo);
                }
            }
        }
    }, {
        key: "schedule",
        value: function schedule() {
            var _this12 = this;

            this.scheduleHB && clearTimeout(this.scheduleHB);
            // 定时发送HB
            this.scheduleHB = window.setTimeout(function () {
                if (_this12.state === NetworkState.offline) {
                    _$moirae2.default.info(_this12.getLogMessage('offline'));
                    _this12.schedule();
                    return;
                }
                _this12.counter++;
                _$moirae2.default.info(_this12.getLogMessage('send hearbeat'));
                _this12.sendHeartbeats(_this12.scheduleFinallyCb, _this12.scheduleCatchCb);
            }, this.heartbeatInterval);
        }
    }, {
        key: "triggerChannelState",
        value: function triggerChannelState() {
            var _this13 = this;

            this.channelStateCallbacks.forEach(function (cb) {
                cb(_this13.state, _this13.channel);
            });
        }
    }, {
        key: "getLogMessage",
        value: function getLogMessage(str) {
            return "IO: memberId(" + this.memberId + "): " + str;
        }
    }, {
        key: "registerChannelState",
        value: function registerChannelState(cb) {
            this.channelStateCallbacks.push(cb);
        }
    }, {
        key: "unregisterChannelState",
        value: function unregisterChannelState(cb) {
            var index = this.channelStateCallbacks.indexOf(cb);
            if (index !== -1) {
                this.channelStateCallbacks.splice(index, 1);
            }
        }
    }, {
        key: "closeChannel",
        value: function closeChannel() {
            this.scheduleHB && clearTimeout(this.scheduleHB);
            this.socket && this.socket.close();
            window.removeEventListener('online', this.handleOnline);
            window.removeEventListener('offline', this.handleOffline);
        }
    }], [{
        key: "keyOf",
        value: function keyOf(entity) {
            return entity.type + ":" + entity.token;
        }
    }, {
        key: "initHeartbeat",
        value: function initHeartbeat(options) {
            return Object.assign({
                interval: 1,
                version: 0,
                counter: 0
            }, options);
        }
    }, {
        key: "getInstance",
        value: function getInstance(options) {
            if (ioInstance == null) {
                var User = window.User;
                ioInstance = new IO(Object.assign({
                    host: User.host
                }, options));
                return ioInstance;
            } else {
                return ioInstance;
            }
        }
    }]);
    return IO;
}();

__decorate([(0, _asyncHelper.AsyncRetry)(3)], IO.prototype, "watchEntity", null);

/***/ }),

/***/ 1896:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.ErrorTypes = undefined;

var _defineProperty2 = __webpack_require__(9);

var _defineProperty3 = _interopRequireDefault(_defineProperty2);

var _ErrorOptions;

exports.showError = showError;
exports.showServerErrorModal = showServerErrorModal;
exports.showSpreadErrorToast = showSpreadErrorToast;
exports.showSpreadLoadingToast = showSpreadLoadingToast;
exports.removeSpreadToast = removeSpreadToast;
exports.rerender = rerender;

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _sheet = __webpack_require__(744);

var _apiUrls = __webpack_require__(307);

var _$store = __webpack_require__(64);

var _$store2 = _interopRequireDefault(_$store);

var _sheet2 = __webpack_require__(745);

var _lark = __webpack_require__(826);

var _toastHelper = __webpack_require__(301);

var _toast = __webpack_require__(554);

var _toast2 = _interopRequireDefault(_toast);

var _sheetCommon = __webpack_require__(1591);

var _modal = __webpack_require__(1897);

var _$moirae = __webpack_require__(449);

var _$moirae2 = _interopRequireDefault(_$moirae);

var _offline = __webpack_require__(148);

var _tea = __webpack_require__(42);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var ErrorTypes = exports.ErrorTypes = undefined;
(function (ErrorTypes) {
    /**
     * clientVars版本不连续或者snapshot格式有问题
     */
    ErrorTypes[ErrorTypes["ERROR_CLIENT_VARS"] = 0] = "ERROR_CLIENT_VARS";
    /**
     * 排序的时候包含了合并单元格
     */
    ErrorTypes[ErrorTypes["ERROR_SORT_INCLUDE_MERGE"] = 1] = "ERROR_SORT_INCLUDE_MERGE";
    /**
     * 合并范围内的单元格有值
     */
    ErrorTypes[ErrorTypes["ERROR_MERGE_CONTAIN_VALUE"] = 2] = "ERROR_MERGE_CONTAIN_VALUE";
    /**
     * 合并范围内有已合并单元格
     */
    ErrorTypes[ErrorTypes["ERROR_MERGE_CONTAIN_MERGE"] = 3] = "ERROR_MERGE_CONTAIN_MERGE";
    /**
     * 工作表名重复
     */
    ErrorTypes[ErrorTypes["ERROR_INVALID_SHEET_NAME"] = 4] = "ERROR_INVALID_SHEET_NAME";
    /**
     * 目标单元格不存在
     */
    ErrorTypes[ErrorTypes["ERROR_CELL_NOT_EXIST"] = 5] = "ERROR_CELL_NOT_EXIST";
    /**
     * 目标工作表不存在
     */
    ErrorTypes[ErrorTypes["ERROR_SHEET_NOT_EXIST"] = 6] = "ERROR_SHEET_NOT_EXIST";
    /**
     * 目标工作表被隐藏
     */
    ErrorTypes[ErrorTypes["ERROR_SHEET_HID"] = 7] = "ERROR_SHEET_HID";
    /**
     * 操作冲突
     */
    ErrorTypes[ErrorTypes["ERROR_ACTION_CONFLICT"] = 8] = "ERROR_ACTION_CONFLICT";
    /**
     * 收到 recover
     */
    ErrorTypes[ErrorTypes["ERROR_RECEIVE_RECOVER"] = 9] = "ERROR_RECEIVE_RECOVER";
    /**
     * 服务器返回报错
     */
    ErrorTypes[ErrorTypes["ERROR_ERROR"] = 10] = "ERROR_ERROR";
    /**
     * ISO 12 cavnvas 内存不够报错
     */
    ErrorTypes[ErrorTypes["ERROR_CANVAS"] = 11] = "ERROR_CANVAS";
    /**
     * 引擎升级
     */
    ErrorTypes[ErrorTypes["ERROR_UPGRADE_SNAPSHOT"] = 12] = "ERROR_UPGRADE_SNAPSHOT";
    /**
     * 协作者引擎升级
     */
    ErrorTypes[ErrorTypes["ERROR_SYNC_UPGRADE_SNAPSHOT"] = 13] = "ERROR_SYNC_UPGRADE_SNAPSHOT";
})(ErrorTypes || (exports.ErrorTypes = ErrorTypes = {}));
var ErrorOptions = (_ErrorOptions = {}, (0, _defineProperty3.default)(_ErrorOptions, ErrorTypes.ERROR_CLIENT_VARS, {
    title: '',
    body: t('sheet.data_type_error'),
    confirmText: t('common.confirm'),
    cancelText: '',
    maskClosable: true,
    onConfirm: function onConfirm() {
        rerender();
    }
}), (0, _defineProperty3.default)(_ErrorOptions, ErrorTypes.ERROR_SORT_INCLUDE_MERGE, {
    title: '',
    body: t('sheet.merge_no_sort'),
    confirmText: t('common.confirm'),
    closable: true,
    cancelText: '',
    maskClosable: true
}), (0, _defineProperty3.default)(_ErrorOptions, ErrorTypes.ERROR_MERGE_CONTAIN_VALUE, {
    title: t('common.prompt'),
    body: t('sheet.confirm_merge'),
    confirmText: t('common.confirm'),
    closable: true,
    cancelText: t('common.cancel'),
    maskClosable: true
}), (0, _defineProperty3.default)(_ErrorOptions, ErrorTypes.ERROR_MERGE_CONTAIN_MERGE, {
    title: '',
    body: t('sheet.split_before_do'),
    confirmText: t('common.confirm'),
    closable: true,
    cancelText: '',
    maskClosable: true
}), (0, _defineProperty3.default)(_ErrorOptions, ErrorTypes.ERROR_INVALID_SHEET_NAME, {
    title: '',
    confirmText: t('common.confirm'),
    closable: true,
    cancelText: '',
    maskClosable: false
}), (0, _defineProperty3.default)(_ErrorOptions, ErrorTypes.ERROR_CELL_NOT_EXIST, {
    title: t('oops.title'),
    confirmText: t('common.confirm'),
    closable: true,
    cancelText: '',
    maskClosable: true
}), (0, _defineProperty3.default)(_ErrorOptions, ErrorTypes.ERROR_SHEET_NOT_EXIST, {
    title: t('oops.title'),
    body: t('sheet.worksheet_deleted'),
    confirmText: t('common.confirm'),
    closable: true,
    cancelText: '',
    maskClosable: false
}), (0, _defineProperty3.default)(_ErrorOptions, ErrorTypes.ERROR_SHEET_HID, {
    title: '',
    body: t('sheet.had.been.hidden'),
    confirmText: t('common.confirm'),
    closable: true,
    cancelText: '',
    maskClosable: false
}), (0, _defineProperty3.default)(_ErrorOptions, ErrorTypes.ERROR_ACTION_CONFLICT, {
    title: t('oops.title'),
    body: t('common.action_conflict'),
    confirmText: t('common.refresh'),
    cancelText: '',
    closable: true,
    maskClosable: false
}), (0, _defineProperty3.default)(_ErrorOptions, ErrorTypes.ERROR_RECEIVE_RECOVER, {
    title: t('common.prompt'),
    body: t('sheet.history.receive_recover'),
    confirmText: t('common.refresh'),
    cancelText: '',
    closable: true,
    maskClosable: false
}), (0, _defineProperty3.default)(_ErrorOptions, ErrorTypes.ERROR_ERROR, {
    title: t('oops.title'),
    confirmText: t('common.refresh'),
    closable: true,
    cancelText: '',
    maskClosable: false,
    onConfirm: function onConfirm() {
        rerender();
    }
}), (0, _defineProperty3.default)(_ErrorOptions, ErrorTypes.ERROR_CANVAS, {
    title: '',
    body: t('sheet.canvas_ios12_error'),
    confirmText: t('common.confirm'),
    cancelText: '',
    maskClosable: true
}), (0, _defineProperty3.default)(_ErrorOptions, ErrorTypes.ERROR_UPGRADE_SNAPSHOT, {
    title: t('common.prompt'),
    body: t('mobile.sheet.engine.upgrade.uneditable'),
    confirmText: t('mobile.sheet.engine.ungrade.cancel_edit'),
    cancelText: t('mobile.sheet.engine.ungrade.continue_edit'),
    onConfirm: function onConfirm() {
        // 如果暂不编辑，则禁用编辑权限
        _$store2.default.dispatch((0, _sheet2.freezeSheetToggle)(true));
        _$moirae2.default.teaLog({
            key: 'sheet_operation_dialog',
            action: 'click_not_edit_old_calc',
            dialog_type: 'new_cal_engine'
        });
    },
    onCancel: function onCancel() {
        //
        _$moirae2.default.teaLog({
            key: 'sheet_operation_dialog',
            action: 'click_edit_old_calc',
            dialog_type: 'new_cal_engine'
        });
    },
    closable: false,
    maskClosable: false
}), (0, _defineProperty3.default)(_ErrorOptions, ErrorTypes.ERROR_SYNC_UPGRADE_SNAPSHOT, {
    title: t('common.prompt'),
    body: t('sheet.snapshot_upgrade'),
    confirmText: t('common.refresh'),
    closable: false,
    maskClosable: false,
    onConfirm: function onConfirm() {
        // 用户行为埋点：点击「刷新」升级弹窗按钮
        (0, _tea.collectSuiteEvent)('sheet_operation_dialog', {
            action: 'click_refresh',
            dialog_type: 'new_cal_engine'
        });
        window.replace(location.pathname);
    }
}), _ErrorOptions);
function showError(type) {
    var options = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};

    (0, _modal.showModal)(Object.assign({}, ErrorOptions[type], options));
    if (type !== ErrorTypes.ERROR_ERROR) {
        _$moirae2.default.teaLog({
            key: 'show_error_modal',
            error_code: type
        });
        _$moirae2.default.count('ee.docs.sheet.show_error_modal_' + type);
        _$moirae2.default.count('ee.docs.sheet.show_error');
    }
}
/**
 * 唤起客服服务
 */
function callCustomerService() {
    _$store2.default.dispatch((0, _lark.fetchDocsCustomerServiceChatId)()).then(function (res) {
        var chatId = res.payload && res.payload.chat_id;
        location.href = _apiUrls.LARK_CHAT_SCHEMA + chatId;
    }, function () {
        (0, _toastHelper.showToast)({
            type: 1,
            message: t('feedback.additional_fail'),
            duration: 3
        });
    });
}
/**
 * 显示服务器错误的 modal
 */
function showServerErrorModal(code) {
    var module = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : 'unknow';

    var options = {};
    // 字段定义有变动，这个 code 可能是 number 也可能是 string
    // 统一为 string 来比对
    switch (code + '') {
        case _sheetCommon.Errors.ERR_FORBIDDEN:
            Object.assign(options, {
                body: t('sheet.no_permission'),
                onConfirm: function onConfirm() {}
            });
            break;
        case _sheetCommon.Errors.ERR_NO_WRITE_PERMISSION:
            Object.assign(options, {
                body: t('sheet.no_write_permission'),
                confirmText: t('common.refresh'),
                onConfirm: function onConfirm() {
                    window.replace(location.pathname);
                }
            });
            break;
        case _sheetCommon.Errors.ERR_NO_COMMENT_PERMISSION:
            Object.assign(options, {
                body: t('sheet.no_comment_permission')
            });
            break;
        case _sheetCommon.Errors.ERR_LOGIN_REQUIRE:
        case _sheetCommon.Errors.ERR_NOT_IN_SESSION:
            Object.assign(options, {
                body: t('sheet.please_login'),
                onConfirm: function onConfirm() {
                    rerender();
                }
            });
            break;
        case _sheetCommon.Errors.ERR_OBJECT_DELETED:
        case _sheetCommon.Errors.ERR_NOT_FOUND:
        case _sheetCommon.Errors.ERR_NOTE_DELETED:
        case _sheetCommon.Errors.ERR_NOTE_NOT_EXISTS:
        case _sheetCommon.Errors.ERR_GET_EXACT_NOTE:
            Object.assign(options, {
                body: t('sheet.workbook_deleted')
            });
            break;
        case _sheetCommon.Errors.ERR_NOT_IN_ROOM:
            Object.assign(options, {
                body: t('sheet.lost_connect')
            });
            break;
        case _sheetCommon.Errors.ERR_RCE_LIVE_SYNC:
            Object.assign(options, {
                body: t('sheet.data_save_fail')
            });
            break;
        case _sheetCommon.Errors.ERR_OLD_VERSION:
            // 静默刷新，无需弹窗
            return;
        case _sheetCommon.Errors.ERROR_MAX_CELL_LIMIT:
            _$moirae2.default.teaLog({
                key: 'show_exceed_max_line_tip'
            });
            _$moirae2.default.count('ee.docs.sheet.show_exceed_max_line_tip');
            Object.assign(options, {
                title: t('sheet.cell_limit_exceed'),
                body: t('sheet.error_cell_limit_exceed', _sheet.CELL_LIMIT_COMMA)
            });
            break;
        case _sheetCommon.Errors.ERROR_APPLY_ACTION_EX:
            _$moirae2.default.teaLog({
                key: 'show_apply_action_ex'
            });
            _$moirae2.default.count('ee.docs.sheet.show_apply_action_ex');
            Object.assign(options, {
                title: t('oops.title'),
                body: t('sheet.apply_action_error')
            });
            break;
        case _sheetCommon.Errors.ERROR_MAX_CELL_LIMIT_OPERATION:
            _$moirae2.default.teaLog({
                key: 'show_exceed_max_line_tip'
            });
            _$moirae2.default.count('ee.docs.sheet.show_exceed_max_line_tip');
            // 此处分开处理是为了让弹窗后不刷新页面
            Object.assign(options, {
                title: t('sheet.cell_limit_exceed'),
                body: t('sheet.error_cell_limit_exceed', _sheet.CELL_LIMIT_COMMA),
                confirmText: t('common.confirm'),
                onConfirm: function onConfirm() {}
            });
            break;
        case _sheetCommon.Errors.ERR_CHANGESET_EXCEED_LIMIT:
            Object.assign(options, {
                title: t('sheet.error.exceed_limit_title'),
                body: _react2.default.createElement(_react2.default.Fragment, null, t('sheet.error.exceed_limit').split('\\n').map(function (text) {
                    return _react2.default.createElement("div", { key: text }, text);
                })),
                cancelText: t('guide.custom'),
                onCancel: callCustomerService
            });
            break;
        case _sheetCommon.Errors.ERROR_WORKER_SEND_USER_CHANGE:
            Object.assign(options, {
                title: t('oops.title'),
                body: t('sheet.worker_error_onsend'),
                confirmText: t('common.confirm'),
                onConfirm: callCustomerService
            });
            break;
        case _sheetCommon.Errors.ERROR_PERM_LOCK:
            Object.assign(options, {
                title: t('oops.title'),
                body: t('sheet.error_perm_lock') + (' (code: ' + code + ')'),
                confirmText: t('common.confirm'),
                onConfirm: function onConfirm() {
                    rerender();
                }
            });
            break;
        case _sheetCommon.Errors.ERROR_SEND_HIGH_PRORITY_MESSAGE:
            Object.assign(options, {
                title: t('oops.title'),
                body: t('sheet.error_send_high_prority'),
                cancelText: t('guide.custom'),
                onCancel: callCustomerService,
                confirmText: t('common.confirm'),
                onConfirm: function onConfirm() {}
            });
            break;
        case _offline.EMPTY_RESULT + '':
            break;
        case _sheetCommon.Errors.ERR_REQUEST_FAIL:
        case _sheetCommon.Errors.ERR_INVALID_PARAM:
        case _sheetCommon.Errors.ERR_DATA_EXCEED_LIMIT:
        case _sheetCommon.Errors.ERR_UNCHANGE:
        case _sheetCommon.Errors.ERR_CHAGESET_VALID_FAIL:
        case _sheetCommon.Errors.ERR_500:
        case _sheetCommon.Errors.ERR_FETCH_CLIENTVARS:
        case _sheetCommon.Errors.ERR_FETCH_BLOCKS:
        case _sheetCommon.Errors.ERR_CLIENTVARS_INVALID:
        case _sheetCommon.Errors.ERR_MESSAGE_INVALID:
        case _sheetCommon.Errors.ERR_SYNC_ALGO_FAIL:
        case _sheetCommon.Errors.ERR_USER_LIST_SYNC:
        default:
            Object.assign(options, {
                body: t('sheet.server_error_retry') + (' (code: ' + code + ')')
            });
            showSpreadErrorToast(t('sheet.server_error_onedit'));
            break;
    }
    if (code + '' === _offline.EMPTY_RESULT + '') return; // fake clientvars不弹错误
    options.code = code;
    showError(ErrorTypes.ERROR_ERROR, options);
    // 上报错误码和来源
    _$moirae2.default.teaLog({
        key: 'show_server_error_modal',
        status_code: code,
        error_code: getStringCode(code),
        module: module
    });
    try {
        throw new Error('SLAError:' + code + ' Module:' + module);
    } catch (ex) {
        // Raven上报
        _$moirae2.default.ravenCatch(ex, {
            tags: {
                scm: JSON.stringify(window.scm),
                key: 'SLA_' + code
            }
        });
    }
    _$moirae2.default.count('ee.docs.sheet.show_server_error_modal_' + code);
    _$moirae2.default.count('ee.docs.sheet.show_server_error');
}
function getStringCode(code) {
    if (code === null || code === undefined || !code.toString) {
        return 'unknown';
    } else {
        return code.toString();
    }
}
var SPREAD_TOAST_KEY = '__SPREAD_TOAST__';
function showSpreadErrorToast(message) {
    (0, _toastHelper.showToast)({
        type: 1,
        message: message,
        duration: 3,
        closable: false
    });
}
function showSpreadLoadingToast(content) {
    _toast2.default.show({
        key: SPREAD_TOAST_KEY,
        type: 'loading',
        content: content,
        duration: 0,
        closable: false
    });
}
function removeSpreadToast() {
    _toast2.default.remove(SPREAD_TOAST_KEY);
}
function rerender() {
    window.replace(location.pathname);
}
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(25)))

/***/ }),

/***/ 1897:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.showModal = showModal;

var _modal = __webpack_require__(588);

var _modal2 = _interopRequireDefault(_modal);

var _sdkCompatibleHelper = __webpack_require__(45);

var _modalHelper = __webpack_require__(747);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function showModal() {
    var options = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};

    if ((0, _sdkCompatibleHelper.isSupportNativeAlert)()) {
        try {
            nativeAlert(options);
        } catch (e) {
            _modal2.default.show(options);
        }
    } else {
        _modal2.default.show(options);
    }
}
function nativeAlert(options) {
    if (!options) {
        return;
    }
    var title = options.title,
        cancelText = options.cancelText,
        confirmText = options.confirmText,
        onConfirm = options.onConfirm,
        onCancel = options.onCancel,
        body = options.body;

    var buttons = [];
    if (cancelText) {
        buttons.push({
            id: 'cancel',
            text: cancelText,
            is_highlight: false,
            color: _modalHelper.BUTTON_COLOR.DEFAULT
        });
    }
    if (confirmText) {
        buttons.push({
            id: 'sure',
            text: confirmText,
            is_highlight: true,
            color: _modalHelper.BUTTON_COLOR.BLUE
        });
    }
    var message = parseBodyText(body);
    var opt = {
        title: title,
        message: message,
        buttons: buttons,
        onSuccess: function onSuccess(btn) {
            if (!btn) return;
            if (btn.id === 'cancel') {
                onCancel && onCancel();
            } else if (btn.id === 'sure') {
                onConfirm && onConfirm();
            }
        }
    };
    window.lark.biz.util.showAlert(opt);
    console.info('SHEET SHOW ERROR MODAL; Code: ' + options.code + '; Title: ' + title + '; Message: ' + message);
}
function parseBodyText(body) {
    var text = '';
    var walk = function walk(node) {
        if (!node) return;
        if (typeof node === 'string') {
            text = text + node + '\n';
            return;
        }
        if (!node.props || !node.props.children) return;
        var children = node.props.children;
        if (typeof children === 'string') {
            text = text + children + '\n';
        } else if (Array.isArray(children)) {
            children.forEach(walk);
        } else {
            walk(children);
        }
    };
    walk(body);
    return text;
}

/***/ }),

/***/ 1900:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _modal = __webpack_require__(1897);

Object.keys(_modal).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function get() {
      return _modal[key];
    }
  });
});

var _error = __webpack_require__(1896);

Object.keys(_error).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function get() {
      return _error[key];
    }
  });
});

var _expandSortModal = __webpack_require__(3456);

Object.keys(_expandSortModal).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function get() {
      return _expandSortModal[key];
    }
  });
});

/***/ }),

/***/ 2125:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.CollaborativeSpread = undefined;

var _defineProperty2 = __webpack_require__(9);

var _defineProperty3 = _interopRequireDefault(_defineProperty2);

var _regenerator = __webpack_require__(12);

var _regenerator2 = _interopRequireDefault(_regenerator);

var _asyncToGenerator2 = __webpack_require__(99);

var _asyncToGenerator3 = _interopRequireDefault(_asyncToGenerator2);

var _classCallCheck2 = __webpack_require__(6);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(7);

var _createClass3 = _interopRequireDefault(_createClass2);

var _isEmpty2 = __webpack_require__(265);

var _isEmpty3 = _interopRequireDefault(_isEmpty2);

__webpack_require__(3361);

__webpack_require__(3369);

__webpack_require__(3376);

var _browserHelper = __webpack_require__(27);

var _browserHelper2 = _interopRequireDefault(_browserHelper);

var _i18nHelper = __webpack_require__(222);

var _sheetCommon = __webpack_require__(1591);

var _logHelper = __webpack_require__(3377);

var logHelper = _interopRequireWildcard(_logHelper);

var _sheetHelper = __webpack_require__(1893);

var sheetHelper = _interopRequireWildcard(_sheetHelper);

var _hyperlinkHelper = __webpack_require__(3380);

var _sheetIo = __webpack_require__(1621);

var _changeset = __webpack_require__(3381);

var _engine = __webpack_require__(3382);

var _sync = __webpack_require__(3385);

var _utils = __webpack_require__(1678);

var _sheetCore = __webpack_require__(1594);

var _modal = __webpack_require__(1900);

var _status = __webpack_require__(3467);

var _stageTracker = __webpack_require__(1798);

var _tea = __webpack_require__(42);

var _toast = __webpack_require__(554);

var _toast2 = _interopRequireDefault(_toast);

var _$moirae = __webpack_require__(449);

var _$moirae2 = _interopRequireDefault(_$moirae);

var _$store = __webpack_require__(64);

var _$store2 = _interopRequireDefault(_$store);

var _storage = __webpack_require__(3469);

__webpack_require__(3470);

__webpack_require__(3471);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var mobile = _browserHelper2.default.mobile,
    isIOS = _browserHelper2.default.isIOS,
    osversion = _browserHelper2.default.osversion;
var Events = _sheetCore.Sheets.Events,
    Workbook = _sheetCore.Sheets.Workbook,
    Worksheet = _sheetCore.Sheets.Worksheet;

var SUCCESS_RESPONSE_CODE = 0;
var SHEET_OPRATION = 'sheet_opration';
var collaCount = 0;
/**
 * 在GC.Spread的基础上封装的Spread。
 * 目标是通过applyActions将远端的Action应用
 * 所有对表格的操作都转换为Action通知出去
 */

var CollaborativeSpread = function () {
    function CollaborativeSpread(token) {
        var sheetId = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : '';
        var isEmbed = arguments[2];
        var spreadOptions = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : {};

        var _this = this;

        var handleClientVarsError = arguments[4];
        var handleClientVarsReady = arguments[5];
        (0, _classCallCheck3.default)(this, CollaborativeSpread);

        this.spreadLoaded = false;
        this._editable = false;
        this._logStageMap = {};
        this._hasAppliedRowData = false;
        this.getContextBindList = function () {
            var ret = [{ key: _sheetIo.CollaborativeEvents.SPREAD_LOADED, handler: _this.onSpreadLoaded }, { key: _sheetIo.CollaborativeEvents.DATA_TABLE, handler: _this.onDataTable }, { key: _sheetIo.CollaborativeEvents.APPLY_ACTIONS_LOCAL, handler: _this.applyActionsLocal }, { key: _sheetIo.CollaborativeEvents.RECOVER_SPREAD, handler: _this.onRecover }];
            // controlled by embed-sheet-manager
            if (!_this._spreadOptions.embed) {
                ret = ret.concat([{ key: _sheetIo.CollaborativeEvents.CLIENT_VARS, handler: _this.onClientVars }, { key: _sheetIo.CollaborativeEvents.APPLY_ACTIONS, handler: _this.applyActions }]);
            }
            return ret;
        };
        this.fetchClientVars = function () {
            var _ref = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee(sheetId) {
                var message;
                return _regenerator2.default.wrap(function _callee$(_context) {
                    while (1) {
                        switch (_context.prev = _context.next) {
                            case 0:
                                _context.prev = 0;
                                _context.next = 3;
                                return _this.sync.getClientVars(sheetId);

                            case 3:
                                message = _context.sent;

                                if (!(message.code !== SUCCESS_RESPONSE_CODE || message.data.code !== SUCCESS_RESPONSE_CODE)) {
                                    _context.next = 6;
                                    break;
                                }

                                return _context.abrupt('return', _this._handleClientVarsError(message));

                            case 6:
                                _context.next = 8;
                                return _this.sync.handleClientVarsMessage(message);

                            case 8:
                                _this._handleClientVarsReady(message);
                                _context.next = 14;
                                break;

                            case 11:
                                _context.prev = 11;
                                _context.t0 = _context['catch'](0);

                                _this._handleClientVarsError(_context.t0);

                            case 14:
                            case 'end':
                                return _context.stop();
                        }
                    }
                }, _callee, _this, [[0, 11]]);
            }));

            return function (_x3) {
                return _ref.apply(this, arguments);
            };
        }();
        this.onRecover = function (data) {
            if (data.snapshot) {
                _this.applySnapshot(data.snapshot);
            }
            if (data.changesets) {
                _this.applyChangesets(data.changesets, true);
            }
            _this.setEditable(_this._editable);
        };
        this.onDataTable = function (sheetId, rowData) {
            // 独立sheet首屏只初始化了一个sheet，这里需要覆盖初始化
            if (!_this._hasAppliedRowData && !_this._context.isEmbed()) {
                _this._hasAppliedRowData = true;
                _this._originalSnapshot.sheets = _this._originalSheets;
                _this.applySnapshot(_this._originalSnapshot);
            }
            sheetHelper.applyRowData(_this.spread, sheetId, rowData);
        };
        this.onSpreadLoaded = function (data) {
            var spread = _this._spread;
            var fs = spread.getCalcEngine().fmlSpace();
            var version = spread.getSpreadVersion();
            (0, _tea.collectSuiteEvent)('client_sheet_snapshot_version', {
                snapshot_version: version
            });
            sheetHelper.rowFilterOnSpreadLoaded(spread);
            fs.ignoreDirty(false);
            fs.dirtyAll();
            if (data && data.changeset_list) {
                _this.applyChangesets(data.changeset_list || [], true);
            }
            _this.spreadLoaded = true;
        };
        this.applyActionsLocal = function (actions) {
            var triggerEvent = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : false;

            _this.applyActions(actions, triggerEvent, true);
        };
        /**
         * 绑定sheet相关的事件
         */
        this.bindEvents = function () {
            _this.unbindEvents();
            var spread = _this._spread;
            var bindList = _this.getBindList();
            if (!spread) {
                return;
            }
            for (var event in bindList) {
                spread.bind(event, bindList[event]);
            }
            logHelper.bindSpread(spread);
        };
        this._onActiveSheetChanged = function (e, args) {
            _this._context && _this._context.trigger(_sheetIo.CollaborativeEvents.ACTIVE_SHEET_CHANGE, args);
        };
        this._onInvalid = function (event, args) {
            var invalidType = args.invalidType,
                message = args.message;

            if (invalidType === _sheetCommon.InvalidOperationType.copyPaste) {
                _toast2.default.show({
                    key: 'INVALID_OPRERATION',
                    type: 'error',
                    content: '' + message,
                    duration: 3000,
                    closable: false
                });
            } else {
                console.trace('InvalidType: ' + invalidType + ' - msg: ' + message); // 临时记录都有什么样的invalid参数输出
                if (invalidType === 1 || invalidType === 7) {
                    _toast2.default.show({
                        key: 'INVALID_OPRERATION',
                        type: 'error',
                        content: '' + message,
                        duration: 3000,
                        closable: false
                    });
                } else if (invalidType === 2) {
                    (0, _modal.showModal)({
                        title: t('common.prompt'),
                        body: t('sheet.fill_no_merge'),
                        confirmText: t('common.confirm'),
                        cancelText: false
                    });
                    // 拖到被保护的单元格
                } else if (invalidType === _sheetCommon.InvalidOperationType.editProtectedRange) {
                    (0, _modal.showModal)({
                        title: t('common.prompt'),
                        body: t('sheet.protection.cannot_start_edit'),
                        confirmText: t('common.confirm'),
                        cancelText: false
                    });
                    (0, _tea.collectSuiteEvent)(SHEET_OPRATION, {
                        action: 'protect_range_remind'
                    });
                } else if (invalidType === 6) {
                    // 看到 invalidType 1~5 都有用，但是没有处理逻辑，只能先用6了
                    (0, _modal.showServerErrorModal)(_sheetCommon.Errors.ERROR_MAX_CELL_LIMIT_OPERATION, 'collaborative_spread');
                }
            }
        };
        this._onClipboardPasted = function (e, args) {
            args.sheet.options.clipBoardOptions = _sheetCommon.ClipboardPasteOptions.all;
        };
        this._onCommandExecuted = function (e, args) {
            var sheet = args.sheet,
                changedRows = args.changedRows,
                commandName = args.commandName;
            var changesets = args.changesets;

            if (sheet && changesets) {
                // 检查行列是否超限
                if (sheetHelper.isCellLimitExceed(sheet, changesets)) {
                    _this._context && _this._context.trigger(_sheetIo.CollaborativeEvents.ERROR, { code: _sheetCommon.Errors.ERROR_MAX_CELL_LIMIT });
                    return;
                }
                // 单元格链接转换
                if (commandName === 'editCell' || commandName === 'clipboardPaste') {
                    (0, _hyperlinkHelper.convertLink)(sheet, changesets);
                }
                // 补充自动行高计算结果
                if (args.commandName === 'resizeColumn') {
                    var setColumnWidthChangeset = changesets.filter(function (cs) {
                        return cs.action === 'setColumnWidth';
                    });
                    if (setColumnWidthChangeset.length) {
                        var _setColumnWidthChange = setColumnWidthChangeset[0].target,
                            col = _setColumnWidthChange.col,
                            col_count = _setColumnWidthChange.col_count;

                        var startCol = col;
                        var endCol = col + col_count - 1;
                        changesets = changesets.concat(sheetHelper.uniqFitRow(sheet, changedRows, startCol, endCol));
                    }
                } else {
                    changesets = changesets.concat(sheetHelper.uniqFitRow(sheet, changedRows));
                }
            }
            if (changesets) {
                _this._context && _this._context.trigger(_sheetIo.CollaborativeEvents.PRODUCE_ACTIONS, changesets);
            } else {
                _sheetIo.watchDog.watchDone();
            }
        };
        this.switch = function () {
            _this._sync.connect(_this._defaultSheetId);
        };
        this.destroy = function () {
            _this._hasAppliedRowData = false;
            _this._originalSheets = {};
            _this._originalSnapshot = {};
            _this.unbindEvents();
            _this.unbindCollaborativeEvents();
            _this._spread.destroy();
            _this._statusCollector.destroy();
            _this._engine.destroy();
            _this._sync.destroy();
            _this._engine = null;
            _this._sync = null;
            _this._backup = null;
            _this._spread = null;
            _this._context = null;
            var wnd = window;
            if (wnd.Spread) {
                wnd.Spread.collaSpread = null;
                wnd.Spread.spread = null;
                wnd.Spread.sync = null;
                wnd.Spread.engine = null;
                wnd.Spread.backup = null;
                wnd.Spread.context = null;
                wnd.Spread = null;
                wnd.spread = null;
            }
        };
        this.onClientVars = function (data) {
            // 标志为false
            _this._hasAppliedRowData = false;
            var spread = _this._spread;
            spread.getCalcEngine().fmlSpace().ignoreDirty(true);
            var snapshot = data.snapshot;
            var cloneSnapshot = Object.assign({}, snapshot);
            // ------- 独立sheet首屏时只初始化一个sheet ----- //
            if (!_this._context.isEmbed()) {
                var sheets = snapshot.sheets;
                var sheetNames = Object.keys(sheets);
                var startIndex = snapshot.startSheetIndex;
                _this._originalSnapshot = snapshot;
                _this._originalSheets = sheets;
                var activeSheet = void 0;
                for (var i = 0; i < sheetNames.length; i++) {
                    var sheet = sheets[sheetNames[i]];
                    if (sheet.index === startIndex) {
                        activeSheet = sheet;
                        break;
                    }
                }
                if (activeSheet) {
                    cloneSnapshot.sheets = (0, _defineProperty3.default)({}, activeSheet.name, activeSheet);
                }
            }
            // ------------------------//
            // 应用 Snapshot
            !_this._logStageMap[_stageTracker.LogStage.APPLY_SNAPSHOT] && (0, _stageTracker.stageTracker)(_stageTracker.LogStage.APPLY_SNAPSHOT, _stageTracker.LogStatus.START);
            _this.applySnapshot(cloneSnapshot);
            !_this._logStageMap[_stageTracker.LogStage.APPLY_SNAPSHOT] && (0, _stageTracker.stageTracker)(_stageTracker.LogStage.APPLY_SNAPSHOT, _stageTracker.LogStatus.END);
            _this._logStageMap[_stageTracker.LogStage.APPLY_SNAPSHOT] = true;
        };
        this.applyActions = function (actions) {
            var triggerEvent = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : false;
            var local = arguments[2];

            var spread = _this._spread;
            var context = _this._context;
            if (!triggerEvent) {
                spread.suspendEvent();
            }
            var executor = new _changeset.SheetChangesetExec(_this._context);
            try {
                actions.map(function (action) {
                    if ((0, _isEmpty3.default)(action)) {
                        return;
                    }
                    var sheet = spread.getSheetFromId(action.sheet_id);
                    if ((0, _sheetIo.isSpreadAction)(action.action)) {
                        executor.execAction(spread, action, triggerEvent, local);
                    } else {
                        executor.execAction(sheet, action, triggerEvent, local);
                    }
                });
                context && context.trigger(_sheetIo.CollaborativeEvents.AFTER_APPLY_ACTIONS, actions, local);
            } catch (e) {
                throw e;
            } finally {
                if (!triggerEvent) {
                    spread.resumeEvent();
                }
            }
            /**
             * FIXME: 这个设计不合理，要修改
             */
            spread.trigger(Events.CommandExecuted, {});
        };
        this.setEditable = function (editable) {
            _this._editable = editable;
            var spread = _this._spread;
            if (!spread) return;
            (0, _utils.setSpreadEdit)(spread, editable);
        };
        this._spreadOptions = Object.assign({}, spreadOptions);
        this._context = new _sheetIo.CollaborativeContext(token);
        this._context.setEmbed(isEmbed);
        this._spread = new _sheetCore.Sheets.Workbook(null, this._spreadOptions);
        this._spread._context = this._context;
        this._backup = new _sheetIo.Backup(_storage.MobileStorage);
        this._sync = new _sync.SheetSync(this._context, this._backup);
        this._engine = new _engine.SheetEngine(this._context, this._backup);
        this._handleClientVarsError = handleClientVarsError;
        this._handleClientVarsReady = handleClientVarsReady;
        (0, _sheetCore.commandRegister)(this._spread); // 暂时调试用
        var locale = (0, _i18nHelper.getLocale)();
        if (locale === 'en-US') {
            _sheetCore.Common.CultureManager.culture('en-us');
        } else if (locale === 'zh-CN') {
            _sheetCore.Common.CultureManager.culture('zh-cn');
        } else if (locale === 'ja-JP') {
            _sheetCore.Common.CultureManager.culture('ja-JP');
        }
        this._defaultSheetId = sheetId;
        this._statusCollector = new _status.SheetStatusCollector(_$store2.default);
        this._statusCollector.setSpread(this._spread);
        this.bindCollaborativeEvents();
        this.bindEvents();
        var wnd = window;
        wnd.Spread = {};
        wnd.Spread.collaSpread = this;
        wnd.Spread.spread = this.spread;
        wnd.Spread.sync = this._sync;
        wnd.Spread.engine = this._engine;
        wnd.Spread.context = this._context;
        wnd.Spread.backup = this._backup;
        wnd.spread = wnd.Spread.spread;
        collaCount += 1;
        this._id = 'Colla_' + collaCount;
        console.log('Create CollaSpread', this._id);
    }

    (0, _createClass3.default)(CollaborativeSpread, [{
        key: 'bindCollaborativeEvents',
        value: function bindCollaborativeEvents() {
            var context = this._context;
            this.unbindCollaborativeEvents();
            this.getContextBindList().map(function (event) {
                context && context.bind(event.key, event.handler);
            });
        }
    }, {
        key: 'unbindCollaborativeEvents',
        value: function unbindCollaborativeEvents() {
            var context = this._context;
            this.getContextBindList().map(function (event) {
                context && context.unbind(event.key, event.handler);
            });
        }
    }, {
        key: 'applySnapshot',
        value: function applySnapshot(snapshot) {
            var spread = this._spread;
            try {
                spread.fromJSON(Object.assign({}, this._spreadOptions, snapshot));
            } catch (e) {
                // Raven上报
                _$moirae2.default.ravenCatch(e, {
                    tags: {
                        scm: JSON.stringify(window.scm),
                        key: 'APPLY_SNAPSHOT_ERROR'
                    }
                });
                // 移动端 IOS12 表格太多情况报错，弹特殊文案
                if (mobile && isIOS && parseInt(osversion, 10) === 12) {
                    (0, _modal.showError)(_modal.ErrorTypes.ERROR_CANVAS);
                } else {
                    (0, _modal.showError)(_modal.ErrorTypes.ERROR_CLIENT_VARS);
                }
            }
        }
    }, {
        key: 'applyChangesets',
        value: function applyChangesets(changesets, local) {
            var spread = this._spread;
            spread.suspendEvent();
            var executor = new _changeset.SheetChangesetExec(this._context);
            try {
                changesets.forEach(function (changeset) {
                    var actions = changeset.content || [];
                    actions.forEach(function (action) {
                        if ((0, _isEmpty3.default)(action)) {
                            return;
                        }
                        var sheet = spread.getSheetFromId(action.sheet_id);
                        if ((0, _sheetIo.isSpreadAction)(action.action)) {
                            executor.execAction(spread, action, false, local);
                        } else {
                            executor.execAction(sheet, action, false, local);
                        }
                    });
                });
            } catch (e) {
                throw e;
            } finally {
                spread.resumeEvent();
            }
            // 进行刷新重绘
            var activeSheet = spread.getActiveSheet();
            activeSheet && spread.trigger(Events.ActiveSheetChanged, {
                newSheet: activeSheet
            });
        }
    }, {
        key: 'getBindList',
        value: function getBindList() {
            var _ref2;

            return _ref2 = {}, (0, _defineProperty3.default)(_ref2, Events.ActiveSheetChanged, this._onActiveSheetChanged), (0, _defineProperty3.default)(_ref2, Events.ClipboardPasted, this._onClipboardPasted), (0, _defineProperty3.default)(_ref2, Events.InvalidOperation, this._onInvalid), (0, _defineProperty3.default)(_ref2, Events.CommandExecuted, this._onCommandExecuted), _ref2;
        }
    }, {
        key: 'unbindEvents',
        value: function unbindEvents() {
            var spread = this._spread;
            var bindList = this.getBindList();
            if (!spread) {
                return;
            }
            for (var event in bindList) {
                spread.unbind(event, bindList[event]);
            }
            logHelper.unbindSpread(spread);
        }
    }, {
        key: 'getActiveSheet',
        value: function getActiveSheet() {
            return this._spread.getActiveSheet();
        }
    }, {
        key: 'spread',
        get: function get() {
            return this._spread;
        }
    }, {
        key: 'editable',
        get: function get() {
            return this._editable;
        }
    }, {
        key: 'context',
        get: function get() {
            return this._context;
        }
    }, {
        key: 'sync',
        get: function get() {
            return this._sync;
        }
    }, {
        key: 'engine',
        get: function get() {
            return this._engine;
        }
    }, {
        key: 'backup',
        get: function get() {
            return this._backup;
        }
    }]);
    return CollaborativeSpread;
}();

exports.CollaborativeSpread = CollaborativeSpread;
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(25)))

/***/ }),

/***/ 2139:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.default = undefined;

var _regenerator = __webpack_require__(12);

var _regenerator2 = _interopRequireDefault(_regenerator);

var _asyncToGenerator2 = __webpack_require__(99);

var _asyncToGenerator3 = _interopRequireDefault(_asyncToGenerator2);

var _classCallCheck2 = __webpack_require__(6);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(7);

var _createClass3 = _interopRequireDefault(_createClass2);

var _typeof2 = __webpack_require__(82);

var _typeof3 = _interopRequireDefault(_typeof2);

var _isUndefined2 = __webpack_require__(227);

var _isUndefined3 = _interopRequireDefault(_isUndefined2);

var _$decorators = __webpack_require__(553);

var _utils = __webpack_require__(1678);

var _sheet = __webpack_require__(744);

var _sheetCommon = __webpack_require__(1591);

var _tea = __webpack_require__(42);

var _timeoutHelper = __webpack_require__(1801);

var _decorators = __webpack_require__(1802);

var _sdkCompatibleHelper = __webpack_require__(45);

var _const = __webpack_require__(742);

var _eventEmitter = __webpack_require__(110);

var _eventEmitter2 = _interopRequireDefault(_eventEmitter);

var _MentionNotificationQueue = __webpack_require__(3473);

var _MentionNotificationQueue2 = _interopRequireDefault(_MentionNotificationQueue);

var _sharingConfirmationHelper = __webpack_require__(2140);

var _apis = __webpack_require__(1664);

var _$store = __webpack_require__(64);

var _$store2 = _interopRequireDefault(_$store);

var _share = __webpack_require__(342);

var _suiteHelper = __webpack_require__(52);

var _user = __webpack_require__(72);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var __decorate = undefined && undefined.__decorate || function (decorators, target, key, desc) {
    var c = arguments.length,
        r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc,
        d;
    if ((typeof Reflect === "undefined" ? "undefined" : (0, _typeof3.default)(Reflect)) === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);else for (var i = decorators.length - 1; i >= 0; i--) {
        if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    }return c > 3 && r && Object.defineProperty(target, key, r), r;
};

var Mention = function () {
    function Mention(props) {
        var _this = this;

        (0, _classCallCheck3.default)(this, Mention);

        this._mentionConfirmMap = {};
        this.getBindList = function () {
            return {
                sheet: [{ key: _sheetCommon.Events.SegClick, handler: _this.handleMobileMentionClick }, { key: _sheetCommon.Events.CellClick, handler: _this.handleMobileCellClick }, { key: _sheetCommon.Events.SegHover, handler: _this.handleMobileMentionLeave }, { key: _sheetCommon.Events.ValueChanged, handler: _this.handleValueChanged }]
            };
        };
        this.getActivePos = function () {
            var activeSheet = _this.props.sheet || _this.props.spread.getActiveSheet();
            if (activeSheet) {
                return activeSheet.getActiveRowIndex() + "_" + activeSheet.getActiveColumnIndex();
            } else {
                return '';
            }
        };
        this.props = props;
        this._lastActivePos = '';
        this.bindEvents();
    }

    (0, _createClass3.default)(Mention, [{
        key: "bindEvents",
        value: function bindEvents() {
            var _this2 = this;

            var bindList = this.getBindList();
            var listener = this.props.sheet || this.props.spread;
            bindList.sheet.forEach(function (event) {
                listener.bind(event.key, event.handler);
            });
            // mention confirm 埋点
            window.lark.biz.mention.onMentionConfirm = function (_ref) {
                var mention_type = _ref.mention_type,
                    token = _ref.token,
                    source = _ref.source,
                    zone = _ref.zone,
                    mention_sequence_num = _ref.mention_sequence_num;

                mention_type = String(mention_type);
                mention_sequence_num = Number(mention_sequence_num);
                switch (mention_type) {
                    case '0':
                        // User，先将数据存起来，等拿到 mention 通知请求响应的 uuid 再上报。
                        _this2._mentionConfirmMap[token] = {
                            mention_type: mention_type,
                            source: source,
                            zone: zone,
                            mention_sequence_num: mention_sequence_num
                        };
                        break;
                    case '1':
                    case '3':
                        // Docs
                        _this2._collectMentionConfirm({
                            mention_type: mention_type,
                            source: source,
                            zone: zone,
                            mention_sequence_num: mention_sequence_num
                        });
                        break;
                }
            };
            // mention confirm 埋点
            _eventEmitter2.default.on('onMentionConfirm', this._onMentionConfirm);
        }
    }, {
        key: "unBindEvents",
        value: function unBindEvents() {
            var bindList = this.getBindList();
            var listener = this.props.sheet || this.props.spread;
            bindList.sheet.forEach(function (event) {
                listener.unbind(event.key, event.handler);
            });
            // mention confirm 埋点
            _eventEmitter2.default.off('onMentionConfirm', this._onMentionConfirm);
            // mention confirm 埋点
            window.lark.biz.mention.onMentionConfirm = undefined;
        }
    }, {
        key: "handleMobileCellClick",
        value: function handleMobileCellClick(type, event) {
            var _this3 = this;

            // 防止mention click事件后触发
            setTimeout(function () {
                _this3._lastActivePos = _this3.getActivePos();
            }, 200);
        }
    }, {
        key: "handleMobileMentionLeave",
        value: function handleMobileMentionLeave(type, event) {
            var seg = event.info.seg;
            if (!seg || seg.type() !== 'mention') {
                this._lastActivePos = '';
            }
        }
    }, {
        key: "handleMobileMentionClick",
        value: function handleMobileMentionClick(type, event) {
            var activeSheet = this.props.sheet || this.props.spread.getActiveSheet();
            if (activeSheet && activeSheet.isEditing()) return; // 忽略双击进入编辑的情况
            var seg = event.info.seg;
            if (!seg || seg.type() !== 'mention') return;
            var iseg = seg.seg;
            if (!(0, _suiteHelper.isSuiteMention)(iseg.mentionType)) {
                return;
            }
            var newActivePos = this.getActivePos();
            if (newActivePos === this._lastActivePos) {
                var mentionType = iseg.mentionType;
                (0, _tea.collectSuiteEvent)('click_sheet_view', { sheet_view_action: mentionType === 0 ? 'a_user' : 'a_file' });
                // 清除评论那边异步处理，寻求更好的办法。。。。
                (0, _timeoutHelper.clearGroupTimeout)('sheet_comments');
                // 纯为了打点而异步
                setTimeout(function () {
                    if (mentionType === 0) {
                        if ((0, _sdkCompatibleHelper.isSupportUserProfile)()) {
                            window.lark.biz.util.showProfile({
                                userId: iseg.token
                            });
                        }
                        return;
                    }
                    var link = iseg.link,
                        text = iseg.text;

                    var url = decodeURIComponent(link || text);
                    url && (0, _utils.openLink)(url);
                }, 100);
            } else {
                this._lastActivePos = newActivePos;
            }
        }
    }, {
        key: "handleValueChanged",
        value: function () {
            var _ref2 = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee(type, event) {
                var _this4 = this;

                var spread, segmentArray, oldArray, oldUser, currentUserId, toUsers, isEmbed, currentUserPermissions, tipsText, res, needNotify, mentionKeyId, rsp, sheet, row, col, model, node, currentSegmentArray, succ, cellEditInfo, commandManager;
                return _regenerator2.default.wrap(function _callee$(_context) {
                    while (1) {
                        switch (_context.prev = _context.next) {
                            case 0:
                                spread = this.props.spread;
                                segmentArray = event.newValue;
                                oldArray = event.oldValue;

                                if (Array.isArray(segmentArray)) {
                                    _context.next = 5;
                                    break;
                                }

                                return _context.abrupt("return");

                            case 5:
                                // 单元格里目前不能at group，因此只考虑过滤user
                                oldUser = [];

                                if (Array.isArray(oldArray)) {
                                    oldUser = oldArray.reduce(function (pre, seg) {
                                        if (seg.type === 'mention' && seg.mentionType === 0 && seg.mentionNotify) {
                                            pre.push(seg.token);
                                        }
                                        return pre;
                                    }, []);
                                }
                                currentUserId = (0, _user.selectCurrentUserId)(_$store2.default.getState());
                                toUsers = segmentArray.reduce(function (pre, seg) {
                                    if (seg.type === 'mention' && seg.mentionType === 0 && seg.mentionNotify && !oldUser.includes(seg.token)) {
                                        pre.push(seg.token);
                                    }
                                    return pre;
                                }, []).filter(function (id) {
                                    return id !== currentUserId;
                                });
                                isEmbed = this.props.context.isEmbed();

                                if (!(toUsers.length === 0)) {
                                    _context.next = 12;
                                    break;
                                }

                                return _context.abrupt("return");

                            case 12:
                                currentUserPermissions = (0, _share.selectCurrentPermission)(_$store2.default.getState()) || [];
                                tipsText = t('mobile.mention.notify.user');
                                // 判断当前用户是否有分享权限

                                if (!(currentUserPermissions.indexOf(8) > -1)) {
                                    _context.next = 19;
                                    break;
                                }

                                _context.next = 17;
                                return this.checkReadPermission({
                                    fileType: (0, _suiteHelper.suiteTypeNum)(),
                                    fileId: (0, _suiteHelper.getToken)(),
                                    ownerId: toUsers[0],
                                    ownerType: 0
                                });

                            case 17:
                                res = _context.sent;

                                if (res.code !== 0 || !res.data || !res.data.existed) {
                                    tipsText = t('mobile.authorize.notify.user');
                                    needNotify = 1;

                                    _MentionNotificationQueue2.default.addAuthorizePermission((0, _suiteHelper.suiteTypeNum)(), (0, _suiteHelper.getToken)(), [{
                                        owner_id: toUsers[0],
                                        owner_type: 0,
                                        permission: 1
                                    }], needNotify, 'sheet');
                                }

                            case 19:
                                mentionKeyId = generateRandomString(16);

                                if (isEmbed) {
                                    _MentionNotificationQueue2.default.addUserMention(toUsers, _const.SOURCE_ENUM.DOC);
                                } else {
                                    _MentionNotificationQueue2.default.addUserMentionV2(toUsers, {
                                        type: 'mention',
                                        sheet_id: event.sheet.id(),
                                        key_id: mentionKeyId,
                                        row: event.row.toString(),
                                        col: event.col.toString()
                                    });
                                }
                                _MentionNotificationQueue2.default.register(toUsers[0], new Promise(function (resolve, reject) {
                                    _this4.showTips(tipsText, function (callId) {
                                        if (callId === 3) {
                                            // 撤销
                                            resolve(_sharingConfirmationHelper.TOAST_CONFIRM_RESULT.CANCELED);
                                            (0, _apis.hideNativeTips)();
                                        }
                                    });
                                }), 8000);
                                // 发送通知并从后端获取mention_id
                                _context.prev = 22;
                                rsp = {};

                                if (!isEmbed) {
                                    _context.next = 30;
                                    break;
                                }

                                _context.next = 27;
                                return _MentionNotificationQueue2.default.sendMentionNotifications();

                            case 27:
                                rsp = _context.sent;
                                _context.next = 33;
                                break;

                            case 30:
                                _context.next = 32;
                                return _MentionNotificationQueue2.default.sendMentionNotifications2(_const.SOURCE_ENUM.SHEET);

                            case 32:
                                rsp = _context.sent;

                            case 33:
                                (0, _apis.hideNativeTips)();
                                sheet = event.sheet, row = event.row, col = event.col;
                                model = sheet._getModel();
                                node = model.getNode(row, col);
                                currentSegmentArray = JSON.parse(JSON.stringify(node.segmentArray));
                                succ = rsp && rsp.length > 0 && rsp[0].code === 0 && rsp[0].data && currentSegmentArray && currentSegmentArray.length > 0;

                                if (!succ) {
                                    _context.next = 54;
                                    break;
                                }

                                // 补上AT的Mention信息
                                currentSegmentArray.forEach(function (item) {
                                    var data = rsp[0].data;
                                    if (rsp.length > 1) {
                                        if (rsp[0].data.entities || rsp[0].data.mention_id) {
                                            data = rsp[0].data;
                                        } else if (rsp[1].data.entities || rsp[1].data.mention_id) {
                                            data = rsp[1].data;
                                        }
                                    }
                                    if (isEmbed) {
                                        if (item.type === 'mention' && item.mentionType === 0 && (0, _isUndefined3.default)(item.mentionId)) {
                                            item.mentionId = data.mention_id;
                                        }
                                    } else {
                                        if (item.type === 'mention' && item.mentionType === 0) {
                                            item.mentionKeyId = mentionKeyId;
                                            item.mentionId = data.entities.users[item.token];
                                        }
                                    }
                                }, []);
                                cellEditInfo = {
                                    cmd: 'editCell',
                                    sheetId: event.sheet.id(),
                                    sheetName: event.sheetName,
                                    row: event.row,
                                    col: event.col,
                                    newValue: currentSegmentArray,
                                    newSegmentArray: currentSegmentArray,
                                    autoFormat: event.autoFormat,
                                    editingFormatter: event.editingFormatter
                                };
                                // 二次更新让后台记录MentionId

                                _context.prev = 42;
                                commandManager = event.sheet._commandManager();

                                spread.unbind(_sheetCommon.Events.ValueChanged, this.handleValueChanged);
                                commandManager.execute(cellEditInfo);
                                _context.next = 51;
                                break;

                            case 48:
                                _context.prev = 48;
                                _context.t0 = _context["catch"](42);
                                throw _context.t0;

                            case 51:
                                _context.prev = 51;

                                setTimeout(function () {
                                    spread.bind(_sheetCommon.Events.ValueChanged, _this4.handleValueChanged);
                                }, 500);
                                return _context.finish(51);

                            case 54:
                                _context.next = 60;
                                break;

                            case 56:
                                _context.prev = 56;
                                _context.t1 = _context["catch"](22);

                                console.error('[SHEET LOG - send notification]', _context.t1);
                                (0, _apis.hideNativeTips)();

                            case 60:
                            case "end":
                                return _context.stop();
                        }
                    }
                }, _callee, this, [[22, 56], [42, 48, 51, 54]]);
            }));

            function handleValueChanged(_x, _x2) {
                return _ref2.apply(this, arguments);
            }

            return handleValueChanged;
        }()
    }, {
        key: "checkReadPermission",
        value: function () {
            var _ref3 = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee2(params) {
                return _regenerator2.default.wrap(function _callee2$(_context2) {
                    while (1) {
                        switch (_context2.prev = _context2.next) {
                            case 0:
                                return _context2.abrupt("return", (0, _apis.checkReadPermission)(params));

                            case 1:
                            case "end":
                                return _context2.stop();
                        }
                    }
                }, _callee2, this);
            }));

            function checkReadPermission(_x3) {
                return _ref3.apply(this, arguments);
            }

            return checkReadPermission;
        }()
    }, {
        key: "showTips",
        value: function showTips(text, callback) {
            (0, _apis.showNativeTips)([{
                id: 1,
                base64Image: '',
                text: ''
            }, {
                id: 2,
                base64Image: '',
                text: text
            }, {
                id: 3,
                base64Image: '',
                text: t('mobile.mention.notify.undo')
            }], callback);
        }
    }, {
        key: "_collectMentionConfirm",
        value: function _collectMentionConfirm(_ref4) {
            var mention_type = _ref4.mention_type,
                source = _ref4.source,
                zone = _ref4.zone,
                mention_sequence_num = _ref4.mention_sequence_num,
                uuid = _ref4.uuid;

            // tslint:disable-next-line
            var mention_sub_type = void 0;
            switch (mention_type) {
                case '0':
                    mention_type = 'user';
                    break;
                case '1':
                    mention_type = 'link_file';
                    mention_sub_type = 'doc';
                    break;
                case '3':
                    mention_type = 'link_file';
                    mention_sub_type = 'sheet';
                    break;
                default:
                    break;
            }
            var payload = Object.assign({}, {
                mention_type: mention_type,
                source: source,
                zone: zone,
                mention_sequence_num: mention_sequence_num
            }, mention_sub_type && { mention_sub_type: mention_sub_type }, uuid && { uuid: uuid });
            (0, _tea.collectSuiteEvent)('docs_confirm_mention', payload);
        }
    }, {
        key: "_onMentionConfirm",
        value: function _onMentionConfirm(uuid, userIds) {
            var _iteratorNormalCompletion = true;
            var _didIteratorError = false;
            var _iteratorError = undefined;

            try {
                for (var _iterator = userIds[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {
                    var userId = _step.value;

                    if (this._mentionConfirmMap[userId]) {
                        this._collectMentionConfirm(Object.assign({}, this._mentionConfirmMap[userId], { uuid: uuid }));
                        delete this._mentionConfirmMap[userId];
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
    }, {
        key: "destroy",
        value: function destroy() {
            this.unBindEvents();
            (0, _apis.hideNativeTips)();
        }
    }]);
    return Mention;
}();

exports.default = Mention;

__decorate([(0, _$decorators.Bind)(), (0, _decorators.ExecOnlyActiveSheet)(), (0, _$decorators.Debounce)(_sheet.Timeout.mentionClickJump)], Mention.prototype, "handleMobileCellClick", null);
__decorate([(0, _$decorators.Bind)(), (0, _decorators.ExecOnlyActiveSheet)()], Mention.prototype, "handleMobileMentionLeave", null);
__decorate([(0, _$decorators.Bind)(), (0, _decorators.ExecOnlyActiveSheet)(), (0, _$decorators.Debounce)(_sheet.Timeout.mentionClickJump)], Mention.prototype, "handleMobileMentionClick", null);
__decorate([(0, _$decorators.Bind)(), (0, _decorators.ExecOnlyActiveSheet)({ doNotThrowErrorWithoutActiveSheet: true })], Mention.prototype, "handleValueChanged", null);
__decorate([(0, _$decorators.Bind)(), (0, _decorators.ExecOnlyActiveSheet)()], Mention.prototype, "_onMentionConfirm", null);
var chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
function generateRandomString() {
    var length = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : 20;

    var randomString = '';
    for (var i = 0; i < length; i++) {
        var randomNumber = Math.floor(Math.random() * chars.length);
        randomString += chars[randomNumber];
    }
    return randomString;
}
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(25)))

/***/ }),

/***/ 2140:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.isGroupReadable = exports.isUserReadable = exports.confirmSharing = exports.DURATION_BEFORE_CLOSING = exports.TOAST_CONFIRM_RESULT = undefined;

var _regenerator = __webpack_require__(12);

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

var _toast = __webpack_require__(554);

var _toast2 = _interopRequireDefault(_toast);

var _apis = __webpack_require__(1664);

var _share = __webpack_require__(342);

var _permissionHelper = __webpack_require__(302);

var _suite = __webpack_require__(84);

var _user = __webpack_require__(72);

var _const = __webpack_require__(742);

var _common = __webpack_require__(19);

var _common2 = __webpack_require__(19);

var _share2 = __webpack_require__(78);

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
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(25)))

/***/ }),

/***/ 2141:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.default = undefined;

var _classCallCheck2 = __webpack_require__(6);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(7);

var _createClass3 = _interopRequireDefault(_createClass2);

var _typeof2 = __webpack_require__(82);

var _typeof3 = _interopRequireDefault(_typeof2);

var _$decorators = __webpack_require__(553);

var _utils = __webpack_require__(1678);

var _sheetCommon = __webpack_require__(1591);

var _sheet = __webpack_require__(744);

var _timeoutHelper = __webpack_require__(1801);

var _tea = __webpack_require__(42);

var _decorators = __webpack_require__(1802);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var __decorate = undefined && undefined.__decorate || function (decorators, target, key, desc) {
    var c = arguments.length,
        r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc,
        d;
    if ((typeof Reflect === "undefined" ? "undefined" : (0, _typeof3.default)(Reflect)) === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);else for (var i = decorators.length - 1; i >= 0; i--) {
        if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    }return c > 3 && r && Object.defineProperty(target, key, r), r;
};

var Hyperlink = function () {
    function Hyperlink(props) {
        var _this = this;

        (0, _classCallCheck3.default)(this, Hyperlink);

        this.bindEvents = function () {
            if (!_this.props.spread) return;
            _this.props.spread.bind(_sheetCommon.Events.SegClick, _this.handleClickLink);
            _this.props.spread.bind(_sheetCommon.Events.CellClick, _this.handleClickCell);
        };
        this.getActivePos = function () {
            if (!_this.props.spread) return '';
            var activeSheet = _this.props.spread.getActiveSheet();
            if (activeSheet) {
                var sheetId = activeSheet._id;
                return sheetId + "_" + activeSheet.getActiveRowIndex() + "_" + activeSheet.getActiveColumnIndex();
            } else {
                return '';
            }
        };
        this.unBindEvents = function () {
            if (!_this.props.spread) return;
            _this.props.spread.unbind(_sheetCommon.Events.SegClick, _this.handleClickLink);
            _this.props.spread.unbind(_sheetCommon.Events.CellClick, _this.handleClickCell);
        };
        this.props = props;
        this.lastActivePos = '';
        this.bindEvents();
    }

    (0, _createClass3.default)(Hyperlink, [{
        key: "handleClickCell",
        value: function handleClickCell() {
            var _this2 = this;

            // 防止seg click事件后触发
            setTimeout(function () {
                _this2.lastActivePos = _this2.getActivePos();
            }, 200);
        }
    }, {
        key: "handleClickLink",
        value: function handleClickLink(etype, event) {
            var seg = event.info.seg;
            if (!seg || seg.type() !== 'url') return;
            var activeSheet = this.props.spread.getActiveSheet();
            if (activeSheet && activeSheet.isEditing()) return; // 忽略双击进入编辑的情况
            var newActivePos = this.getActivePos();
            if (newActivePos === this.lastActivePos) {
                (0, _tea.collectSuiteEvent)('click_sheet_view', { sheet_view_action: 'url' });
                // 清除评论那边异步处理，寻求更好的办法。。。。
                (0, _timeoutHelper.clearGroupTimeout)('sheet_comments');
                setTimeout(function () {
                    var _seg$seg = seg.seg,
                        link = _seg$seg.link,
                        text = _seg$seg.text;

                    var url = decodeURIComponent(link || text);
                    url && (0, _utils.openLink)(url);
                }, 100);
            } else {
                this.lastActivePos = newActivePos;
            }
        }
    }, {
        key: "destroy",
        value: function destroy() {
            this.unBindEvents();
        }
    }]);
    return Hyperlink;
}();

exports.default = Hyperlink;

__decorate([(0, _$decorators.Bind)(), (0, _decorators.ExecOnlyActiveSheet)(), (0, _$decorators.Debounce)(_sheet.Timeout.linkClickJump)], Hyperlink.prototype, "handleClickCell", null);
__decorate([(0, _$decorators.Bind)(), (0, _decorators.ExecOnlyActiveSheet)(), (0, _$decorators.Debounce)(_sheet.Timeout.linkClickJump)], Hyperlink.prototype, "handleClickLink", null);

/***/ }),

/***/ 2142:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _headerSelectionBubble = __webpack_require__(3489);

var _headerSelectionBubble2 = _interopRequireDefault(_headerSelectionBubble);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.default = _headerSelectionBubble2.default;

/***/ }),

/***/ 2143:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.default = undefined;

var _classCallCheck2 = __webpack_require__(6);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(7);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(10);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(11);

var _inherits3 = _interopRequireDefault(_inherits2);

var _typeof2 = __webpack_require__(82);

var _typeof3 = _interopRequireDefault(_typeof2);

var _noop2 = __webpack_require__(304);

var _noop3 = _interopRequireDefault(_noop2);

var _react = __webpack_require__(1);

var _sheet = __webpack_require__(744);

var _sheetShell = __webpack_require__(1713);

var _sdkCompatibleHelper = __webpack_require__(45);

var _sheetCore = __webpack_require__(1594);

var _sheetCommon = __webpack_require__(1591);

var _eventEmitter = __webpack_require__(110);

var _eventEmitter2 = _interopRequireDefault(_eventEmitter);

var _$constants = __webpack_require__(5);

var _core = __webpack_require__(1704);

var _toastHelper = __webpack_require__(301);

var _$decorators = __webpack_require__(553);

var _tea = __webpack_require__(42);

var _decorators = __webpack_require__(1802);

var _modalHelper = __webpack_require__(747);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var __decorate = undefined && undefined.__decorate || function (decorators, target, key, desc) {
    var c = arguments.length,
        r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc,
        d;
    if ((typeof Reflect === "undefined" ? "undefined" : (0, _typeof3.default)(Reflect)) === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);else for (var i = decorators.length - 1; i >= 0; i--) {
        if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    }return c > 3 && r && Object.defineProperty(target, key, r), r;
};

var CellBubble;
(function (CellBubble) {
    CellBubble["CallOout"] = "call_out";
    CellBubble["Cut"] = "cut";
    CellBubble["Copy"] = "copy";
    CellBubble["Paste"] = "paste";
    CellBubble["Clear"] = "clear";
})(CellBubble || (CellBubble = {}));
var MenuId;
(function (MenuId) {
    MenuId["Cut"] = "CUT";
    MenuId["Copy"] = "COPY";
    MenuId["Paste"] = "PASTE";
    MenuId["Clear"] = "CLEAR";
    MenuId["Comment"] = "COMMENT";
})(MenuId || (MenuId = {}));

var ContextMenu = function (_PureComponent) {
    (0, _inherits3.default)(ContextMenu, _PureComponent);

    function ContextMenu(props) {
        (0, _classCallCheck3.default)(this, ContextMenu);
        return (0, _possibleConstructorReturn3.default)(this, (ContextMenu.__proto__ || Object.getPrototypeOf(ContextMenu)).call(this, props));
    }

    (0, _createClass3.default)(ContextMenu, [{
        key: "componentDidMount",
        value: function componentDidMount() {
            var isEmbed = this.props.isEmbed;

            this._bindEvents();
            if (!isEmbed) {
                window.lark.biz.navigation.requestCustomContextMenu = this._requestCustomContextMenu;
                window.lark.biz.navigation.onContextMenuClick = this._handleContextMenuClick;
            }
        }
    }, {
        key: "componentWillUnmount",
        value: function componentWillUnmount() {
            var isEmbed = this.props.isEmbed;

            this._unbindEvents();
            if (!isEmbed) {
                window.lark.biz.navigation.requestCustomContextMenu = _noop3.default;
                window.lark.biz.navigation.onContextMenuClick = _noop3.default;
            }
        }
    }, {
        key: "render",
        value: function render() {
            return null;
        }
    }, {
        key: "_bindEvents",
        value: function _bindEvents() {
            var _props = this.props,
                spread = _props.spread,
                shell = _props.shell;

            shell && shell.bind(_sheetShell.ShellEvent.SHEET_VIEW.ZOOM, this._closeMenu);
            if (spread) {
                spread.bind(_sheetCommon.Events.CellClick, this._closeMenu);
                spread.bind(_sheetCommon.Events.TopPosChanged, this._closeMenu);
                spread.bind(_sheetCommon.Events.LeftPosChanged, this._closeMenu);
            }
            shell && shell.bind(_sheetShell.ShellEvent.SHEET_VIEW.ZOOM, this._closeMenu);
            _eventEmitter2.default.on(_$constants.events.MOBILE.CONTEXT_MENU.showSheetContextMenu, this._showMenu);
            _eventEmitter2.default.on('clear_sheet_selection', this._closeMenu);
        }
    }, {
        key: "_unbindEvents",
        value: function _unbindEvents() {
            var _props2 = this.props,
                spread = _props2.spread,
                shell = _props2.shell;

            if (spread) {
                spread.unbind(_sheetCommon.Events.CellClick, this._closeMenu);
                spread.unbind(_sheetCommon.Events.TopPosChanged, this._closeMenu);
                spread.unbind(_sheetCommon.Events.LeftPosChanged, this._closeMenu);
            }
            shell && shell.unbind(_sheetShell.ShellEvent.SHEET_VIEW.ZOOM, this._closeMenu);
            _eventEmitter2.default.off(_$constants.events.MOBILE.CONTEXT_MENU.showSheetContextMenu, this._showMenu);
            _eventEmitter2.default.off('clear_sheet_selection', this._closeMenu);
        }
    }, {
        key: "_collectCtxMenuEvent",
        value: function _collectCtxMenuEvent(cellBubble) {
            (0, _tea.collectSuiteEvent)('client_sheet_cell_edit', {
                cell_bubble: cellBubble,
                file_is_have_edit: this.props.editable
            });
        }
    }, {
        key: "_handleContextMenuClick",
        value: function _handleContextMenuClick(_ref) {
            var id = _ref.id;
            var _props3 = this.props,
                spread = _props3.spread,
                canCopy = _props3.canCopy,
                isLocked = _props3.isLocked,
                isEmbed = _props3.isEmbed;

            var activeSheet = spread.getActiveSheet();
            var clipboardHelper = activeSheet._getClipboardHelper();
            switch (id) {
                case MenuId.Cut:
                    this._collectCtxMenuEvent(CellBubble.Cut);
                    spread.commandManager().execute({
                        cmd: 'clickCut',
                        sheetName: activeSheet.name(),
                        sheetId: activeSheet.id(),
                        teaSource: _sheet.COMMAND_SOURCE.CONTEXT_MENU
                    });
                    break;
                case MenuId.Copy:
                    if (!canCopy) {
                        (0, _toastHelper.showToast)({
                            type: 1,
                            message: t('permission.can_not_copy'),
                            duration: 3
                        });
                        return;
                    }
                    this._collectCtxMenuEvent(CellBubble.Copy);
                    spread.commandManager().execute({
                        cmd: 'clickCopy',
                        sheetName: activeSheet.name(),
                        sheetId: activeSheet.id(),
                        teaSource: _sheet.COMMAND_SOURCE.CONTEXT_MENU
                    });
                    break;
                case MenuId.Paste:
                    if (isLocked) {
                        (0, _modalHelper.showAlert)(t('common.oops'), t('sheet.protection.cannot_start_edit'));
                        (0, _tea.collectSuiteEvent)('sheet_opration', {
                            action: 'protect_range_remind'
                        });
                        return;
                    }
                    this._collectCtxMenuEvent(CellBubble.Paste);
                    clipboardHelper._select();
                    // 用来触发 'paste' 事件
                    window.lark.biz.navigation.handlePasteMenuClick();
                    break;
                case MenuId.Clear:
                    this._collectCtxMenuEvent(CellBubble.Clear);
                    spread.commandManager().execute({
                        cmd: 'clear',
                        sheetName: activeSheet.name(),
                        sheetId: activeSheet.id(),
                        teaSource: _sheet.COMMAND_SOURCE.CONTEXT_MENU
                    });
                    _eventEmitter2.default.emit('setSheetToolbar');
                    break;
                case MenuId.Comment:
                    if (isEmbed) {
                        var host = activeSheet ? activeSheet._host : null;
                        _eventEmitter2.default.emit('startSheetBlockComment', host);
                    } else {
                        var row = activeSheet.getActiveRowIndex();
                        var col = activeSheet.getActiveColumnIndex();
                        _eventEmitter2.default.emit(_sheet.Events.AddComment, { row: row, col: col });
                    }
                    break;
                default:
                    break;
            }
            spread && spread.focus();
        }
    }, {
        key: "_getMenuItems",
        value: function _getMenuItems() {
            var _props4 = this.props,
                editable = _props4.editable,
                commentable = _props4.commentable,
                isLocked = _props4.isLocked;

            var editableItems = editable && !isLocked ? [{
                id: MenuId.Cut,
                text: t('mobile.sheet.cut')
            }, {
                id: MenuId.Copy,
                text: t('mobile.sheet.copy')
            }, {
                id: MenuId.Paste,
                text: t('mobile.sheet.paste')
            }, {
                id: MenuId.Clear,
                text: t('mobile.sheet.clear')
            }] : [{
                id: MenuId.Copy,
                text: t('mobile.sheet.copy')
            }];
            var commentableItems = commentable ? [{
                id: MenuId.Comment,
                text: t('mobile.sheet.comment')
            }] : [];
            return editableItems.concat(commentableItems);
        }
    }, {
        key: "_requestCustomContextMenu",
        value: function _requestCustomContextMenu() {
            var isEmbed = this.props.isEmbed;

            if (isEmbed) {
                window.lark.biz.navigation.requestCustomContextMenu = this._tempReqCustomCtxMenu;
                window.lark.biz.navigation.onContextMenuClick = this._handleContextMenuClick;
            }
            // native 那边会根据剪切板是否有内容来决定是否屏蔽掉 “粘贴” 按钮。
            return {
                items: this._getMenuItems(),
                onSuccess: 'window.lark.biz.navigation.onContextMenuClick'
            };
        }
    }, {
        key: "_showMenu",
        value: function _showMenu(x, y, showMenuWithItems) {
            var _props5 = this.props,
                sheetRef = _props5.sheetRef,
                spread = _props5.spread,
                shell = _props5.shell,
                isEmbed = _props5.isEmbed;

            var sheetView = shell.sheetView();
            var activeSheet = spread.getActiveSheet();
            if (!activeSheet || !_sdkCompatibleHelper.isSupportSheetContextMenu) return;
            var sheetRect = void 0;
            if (isEmbed) {
                if (!sheetRef) {
                    return;
                }
                sheetRect = sheetRef.getBoundingClientRect();
                x -= sheetRect.left;
                y -= sheetRect.top;
            }
            // 长按在表头边界区域不出菜单
            var cellsOffset = sheetView.getContentBounds();
            if (cellsOffset.x > x || cellsOffset.y > y) return;

            var _sheetView$globalPoin = sheetView.globalPoint2Cell(new _core.FPoint(x, y)),
                row = _sheetView$globalPoin.row,
                col = _sheetView$globalPoin.col;

            var spans = activeSheet._getSpanModel();
            var span = spans.find(row, col);
            if (span) {
                row = span.rowFrom();
                col = span.colFrom();
            }
            // 长按在选区内才出菜单
            var selectionRange = activeSheet.getSelections()[0];
            var isInsideSelection = selectionRange && selectionRange.contain(new _sheetCore.Range(row, col, 1, 1, activeSheet));
            if (!isInsideSelection) return;
            function readyToShowContextMenu() {
                var table = sheetView.detectTableByCell(row, col);
                var cellAttr = table.range2ViewRect(new _sheetCore.Range(row, col, 1, 1, activeSheet));
                cellAttr.x *= sheetView.zoom;
                cellAttr.y *= sheetView.zoom;
                cellAttr.width *= sheetView.zoom;
                cellAttr.height *= sheetView.zoom;
                cellsOffset.x *= sheetView.zoom;
                cellsOffset.y *= sheetView.zoom;
                var top = cellAttr.y < 0 ? cellsOffset.y : cellAttr.y + cellsOffset.y;
                var left = cellAttr.x < 0 ? cellsOffset.x : cellAttr.x + cellsOffset.x;
                var bottom = cellAttr.y + cellsOffset.y + cellAttr.height;
                var right = cellAttr.x + cellsOffset.x + cellAttr.width;
                var sheetHeight = isEmbed ? sheetView.height : window.innerHeight;
                if (bottom > sheetHeight) {
                    bottom = sheetHeight;
                }
                if (right > sheetView.width) {
                    right = sheetView.width;
                }
                if (isEmbed) {
                    var verticalOffset = sheetRect.top + window.scrollY;
                    top += verticalOffset;
                    left += sheetRect.left;
                    bottom += verticalOffset;
                    right += sheetRect.left;
                    if (!showMenuWithItems) {
                        this._tempReqCustomCtxMenu = window.lark.biz.navigation.requestCustomContextMenu;
                        window.lark.biz.navigation.requestCustomContextMenu = this._requestCustomContextMenu;
                    }
                }
                this._collectCtxMenuEvent(CellBubble.CallOout);
                window.lark.biz.navigation.showCustomContextMenu({
                    position: {
                        top: top,
                        left: left,
                        bottom: bottom,
                        right: right
                    },
                    items: showMenuWithItems && this._getMenuItems()
                });
            }
            if (activeSheet.isEditing()) {
                _eventEmitter2.default.emit('closeSheetInput');
                // 关闭 sheet 输入框有 50ms 延迟。
                setTimeout(readyToShowContextMenu.bind(this), 200);
            } else {
                readyToShowContextMenu.apply(this);
            }
        }
    }, {
        key: "_closeMenu",
        value: function _closeMenu() {
            window.lark.biz.navigation.closeCustomContextMenu();
        }
    }]);
    return ContextMenu;
}(_react.PureComponent);

exports.default = ContextMenu;

__decorate([(0, _$decorators.Bind)()], ContextMenu.prototype, "_handleContextMenuClick", null);
__decorate([(0, _$decorators.Bind)()], ContextMenu.prototype, "_getMenuItems", null);
__decorate([(0, _$decorators.Bind)()], ContextMenu.prototype, "_requestCustomContextMenu", null);
__decorate([(0, _$decorators.Bind)(), (0, _decorators.ExecOnlyActiveSheet)()], ContextMenu.prototype, "_showMenu", null);
__decorate([(0, _$decorators.Bind)(), (0, _decorators.ExecOnlyActiveSheet)()], ContextMenu.prototype, "_closeMenu", null);
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(25)))

/***/ }),

/***/ 2144:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _classCallCheck2 = __webpack_require__(6);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(7);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(10);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(11);

var _inherits3 = _interopRequireDefault(_inherits2);

var _typeof2 = __webpack_require__(82);

var _typeof3 = _interopRequireDefault(_typeof2);

var _noop2 = __webpack_require__(304);

var _noop3 = _interopRequireDefault(_noop2);

var _react = __webpack_require__(1);

var _reactRedux = __webpack_require__(300);

var _lodashDecorators = __webpack_require__(1898);

var _sheet = __webpack_require__(1660);

var _toolbarHelper = __webpack_require__(1800);

var toolbarHelper = _interopRequireWildcard(_toolbarHelper);

var _sheet2 = __webpack_require__(744);

var _sheet3 = __webpack_require__(744);

var _error = __webpack_require__(1896);

var _eventEmitter = __webpack_require__(110);

var _eventEmitter2 = _interopRequireDefault(_eventEmitter);

var _decorators = __webpack_require__(1802);

var _tea = __webpack_require__(42);

var _sheetCommon = __webpack_require__(1591);

var _events = __webpack_require__(219);

var _events2 = _interopRequireDefault(_events);

__webpack_require__(3497);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

// TODO: 等到工具栏全部功能补齐后移除 toolbar 并将 Toolbar_m 改名为 Toolbar.
var __decorate = undefined && undefined.__decorate || function (decorators, target, key, desc) {
    var c = arguments.length,
        r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc,
        d;
    if ((typeof Reflect === "undefined" ? "undefined" : (0, _typeof3.default)(Reflect)) === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);else for (var i = decorators.length - 1; i >= 0; i--) {
        if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    }return c > 3 && r && Object.defineProperty(target, key, r), r;
};

var WordWrap;
(function (WordWrap) {
    WordWrap[WordWrap["Overflow"] = 0] = "Overflow";
    WordWrap[WordWrap["AutoWrap"] = 1] = "AutoWrap";
    WordWrap[WordWrap["Clip"] = 2] = "Clip";
})(WordWrap || (WordWrap = {}));
var ToolbarId;
(function (ToolbarId) {
    ToolbarId["Keyboard"] = "keyboard";
    ToolbarId["TextAttribute"] = "textAttribute";
    ToolbarId["CellAttribute"] = "cellAttribute";
    ToolbarId["Bold"] = "bold";
    ToolbarId["Italic"] = "italic";
    ToolbarId["Underline"] = "underline";
    ToolbarId["Strikethrough"] = "strikethrough";
    ToolbarId["HorizontalLeft"] = "horizontalLeft";
    ToolbarId["HorizontalCenter"] = "horizontalCenter";
    ToolbarId["HorizontalRight"] = "horizontalRight";
    ToolbarId["VerticalTop"] = "verticalTop";
    ToolbarId["VerticalCenter"] = "verticalCenter";
    ToolbarId["VerticalBottom"] = "verticalBottom";
    ToolbarId["FontSize"] = "fontSize";
    ToolbarId["ForeColor"] = "foreColor";
    ToolbarId["BackColor"] = "backColor";
    ToolbarId["Merge"] = "merge";
    ToolbarId["Overflow"] = "overflow";
    ToolbarId["AutoWrap"] = "autoWrap";
    ToolbarId["Clip"] = "clip";
    ToolbarId["Comment"] = "comment";
    ToolbarId["Undo"] = "undo";
    ToolbarId["Redo"] = "redo";
    ToolbarId["CloseToolbar"] = "closeToolbar";
})(ToolbarId || (ToolbarId = {}));

var Toolbar = function (_PureComponent) {
    (0, _inherits3.default)(Toolbar, _PureComponent);

    function Toolbar(props) {
        (0, _classCallCheck3.default)(this, Toolbar);
        return (0, _possibleConstructorReturn3.default)(this, (Toolbar.__proto__ || Object.getPrototypeOf(Toolbar)).call(this, props));
    }

    (0, _createClass3.default)(Toolbar, [{
        key: "componentDidMount",
        value: function componentDidMount() {
            this._bindEvents();
        }
    }, {
        key: "componentDidUpdate",
        value: function componentDidUpdate(prevProps) {
            var spread = this.props.spread;

            if (!spread) return;
            var activeSheet = spread.getActiveSheet();
            var selections = activeSheet.getSelections();
            if (!activeSheet || activeSheet.id() === '-1' || !selections || selections.length <= 0) return;
            if (prevProps.editable && !this.props.editable) {
                return this._closeSheetToolbar();
            }
            // 等到工具栏全部做完就可以恢复比较 cellStatus 和 rangeStatus 对象了。
            var cellStatusKeys = ['bold', 'italic', 'underline', 'hAlign', 'vAlign', 'lineThrough', 'fontSize', 'foreColor', 'backColor', 'wordWrap'];
            var rangeStatusKeys = ['splitable', 'mergable'];
            var _iteratorNormalCompletion = true;
            var _didIteratorError = false;
            var _iteratorError = undefined;

            try {
                for (var _iterator = cellStatusKeys[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {
                    var cellStatusKey = _step.value;

                    if (prevProps.cellStatus[cellStatusKey] !== this.props.cellStatus[cellStatusKey]) {
                        return this._setSheetToolbar();
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

            var _iteratorNormalCompletion2 = true;
            var _didIteratorError2 = false;
            var _iteratorError2 = undefined;

            try {
                for (var _iterator2 = rangeStatusKeys[Symbol.iterator](), _step2; !(_iteratorNormalCompletion2 = (_step2 = _iterator2.next()).done); _iteratorNormalCompletion2 = true) {
                    var rangeStatusKey = _step2.value;

                    if (prevProps.rangeStatus[rangeStatusKey] !== this.props.rangeStatus[rangeStatusKey]) {
                        return this._setSheetToolbar();
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

            if (prevProps.commentable !== this.props.commentable || !prevProps.editable && this.props.editable) {
                return this._setSheetToolbar();
            }
        }
    }, {
        key: "componentWillUnmount",
        value: function componentWillUnmount() {
            this._unBindEvents();
            this._closeSheetToolbar();
        }
    }, {
        key: "render",
        value: function render() {
            return null;
        }
    }, {
        key: "_bindEvents",
        value: function _bindEvents() {
            var spread = this.props.spread;

            if (spread) {
                spread.bind(_sheetCommon.Events.SelectionChanged, this._handleSelectionChanged);
                spread.bind(_sheetCommon.Events.ValueChanged, this._handleValueChanged);
            }
            _eventEmitter2.default.on('sheet_in_doc:sheetSelect', this._handleSheetSelectChanged);
            _eventEmitter2.default.on('setSheetToolbar', this._setSheetToolbar);
            _eventEmitter2.default.on('closeSheetInput', this._closeSheetInput);
            _eventEmitter2.default.on('closeSheetToolbar', this._closeSheetToolbar);
        }
    }, {
        key: "_unBindEvents",
        value: function _unBindEvents() {
            var spread = this.props.spread;

            if (spread) {
                spread.unbind(_sheetCommon.Events.SelectionChanged, this._handleSelectionChanged);
                spread.unbind(_sheetCommon.Events.ValueChanged, this._handleValueChanged);
            }
            _eventEmitter2.default.off('sheet_in_doc:sheetSelect', this._handleSheetSelectChanged);
            _eventEmitter2.default.off('setSheetToolbar', this._setSheetToolbar);
            _eventEmitter2.default.off('closeSheetInput', this._closeSheetInput);
            _eventEmitter2.default.off('closeSheetToolbar', this._closeSheetToolbar);
        }
        // 这个函数的回调挺坑爹的，oldSelections 一直为空, 而且 rowCount、colCount 总是大于 0。
        // Debounce的原因：1. cellStatus触发不及时；2. editor 先处理CellClick事件切换单元格编辑

    }, {
        key: "_handleSelectionChanged",
        value: function _handleSelectionChanged(type, _ref) {
            var sheet = _ref.sheet;
            var spread = this.props.spread;

            var activeSheet = spread && spread.getActiveSheet();
            if (!activeSheet || activeSheet.id() === '-1' || !sheet || activeSheet.id() !== sheet.id()) {
                return;
            }
            if (activeSheet.getSelections().length > 0) {
                this._setSheetToolbar();
            } else {
                this._closeSheetToolbar();
            }
        }
    }, {
        key: "_handleValueChanged",
        value: function _handleValueChanged() {
            var spread = this.props.spread;

            if (!spread) return;
            var editor = spread.editor;
            if (!editor) return;
            var valueChanged = editor.valueChanged;
            // native 输入框的值改变后会调用 onUpdateEdit，valueChanged 此时为 true，不应该再去设置 native 输入框的值。
            if (!valueChanged) {
                this._setSheetToolbar();
            }
        }
    }, {
        key: "_handleSheetSelectChanged",
        value: function _handleSheetSelectChanged(isSelect) {
            if (!isSelect) {
                this._closeSheetToolbar();
            }
        }
        // 加个 debounce 避免 _handleSelectionChanged 和 componentDidUpdate 重复调用。

    }, {
        key: "_setSheetToolbar",
        value: function _setSheetToolbar(openInput) {
            var _props = this.props,
                spread = _props.spread,
                isLocked = _props.isLocked;

            var activeSheet = spread && spread.getActiveSheet();
            if (!this.props.editable || !activeSheet || activeSheet.getSelections().length === 0) {
                return;
            }
            var undoManager = spread && spread.undoManager();
            var _props$cellStatus = this.props.cellStatus,
                bold = _props$cellStatus.bold,
                italic = _props$cellStatus.italic,
                underline = _props$cellStatus.underline,
                hAlign = _props$cellStatus.hAlign,
                vAlign = _props$cellStatus.vAlign,
                lineThrough = _props$cellStatus.lineThrough,
                fontSize = _props$cellStatus.fontSize,
                foreColor = _props$cellStatus.foreColor,
                backColor = _props$cellStatus.backColor,
                wordWrap = _props$cellStatus.wordWrap;
            var _props$rangeStatus = this.props.rangeStatus,
                splitable = _props$rangeStatus.splitable,
                mergable = _props$rangeStatus.mergable;

            var toolbarItems = [{
                id: ToolbarId.TextAttribute,
                enable: !isLocked,
                children: [{
                    id: ToolbarId.Bold,
                    enable: true,
                    selected: bold
                }, {
                    id: ToolbarId.Italic,
                    enable: true,
                    selected: italic
                }, {
                    id: ToolbarId.Underline,
                    enable: true,
                    selected: underline
                }, {
                    id: ToolbarId.Strikethrough,
                    enable: true,
                    selected: lineThrough
                }, {
                    id: ToolbarId.HorizontalLeft,
                    enable: true,
                    selected: hAlign === _sheetCommon.HorizontalAlign.Left
                }, {
                    id: ToolbarId.HorizontalCenter,
                    enable: true,
                    selected: hAlign === _sheetCommon.HorizontalAlign.Center
                }, {
                    id: ToolbarId.HorizontalRight,
                    enable: true,
                    selected: hAlign === _sheetCommon.HorizontalAlign.Right
                }, {
                    id: ToolbarId.VerticalTop,
                    enable: true,
                    selected: vAlign === _sheetCommon.VerticalAlign.Top
                }, {
                    id: ToolbarId.VerticalCenter,
                    enable: true,
                    selected: vAlign === _sheetCommon.VerticalAlign.Center
                }, {
                    id: ToolbarId.VerticalBottom,
                    enable: true,
                    selected: vAlign === _sheetCommon.VerticalAlign.Bottom
                }, {
                    id: ToolbarId.FontSize,
                    list: ['9', '10', '11', '12', '14', '18', '24', '30', '36'],
                    enable: true,
                    value: String(fontSize)
                }, {
                    id: ToolbarId.ForeColor,
                    list: ['#ffffff', '#f5f5f5', '#e6e6e6', '#9e9e9e', '#000000', '#2aa2ff', '#00d600', '#a710ff', '#fdff00', '#ff0000', '#0052d4', '#137900', '#3a137a', '#c78e01', '#a80000'],
                    enable: true,
                    value: foreColor || '#000000'
                }]
            }, {
                id: ToolbarId.CellAttribute,
                enable: !isLocked,
                children: [{
                    id: ToolbarId.Merge,
                    enable: splitable || mergable,
                    selected: splitable
                }, {
                    id: ToolbarId.Overflow,
                    enable: true,
                    selected: wordWrap === WordWrap.Overflow
                }, {
                    id: ToolbarId.AutoWrap,
                    enable: true,
                    selected: wordWrap === WordWrap.AutoWrap
                }, {
                    id: ToolbarId.Clip,
                    enable: true,
                    selected: wordWrap === WordWrap.Clip
                }, {
                    id: ToolbarId.BackColor,
                    list: ['#ffffff', '#f5f5f5', '#e6e6e6', '#9e9e9e', '#000000', '#c3dafb', '#d3ebd1', '#d9cfea', '#fff3c7', '#fccacb', '#2aa2ff', '#00d600', '#a710ff', '#fdff00', '#ff0000'],
                    enable: true,
                    value: backColor || '#ffffff'
                }]
            }, {
                id: ToolbarId.Comment,
                enable: this.props.commentable
            }, {
                id: ToolbarId.Undo,
                enable: undoManager && undoManager.canUndo()
            }, {
                id: ToolbarId.Redo,
                enable: undoManager && undoManager.canRedo()
            }, {
                id: ToolbarId.CloseToolbar,
                enable: true
            }];
            // const selection = window.getSelection();
            // selection.removeAllRanges();
            var input = void 0;
            var editor = spread.editor;
            if (openInput || editor.isEditing()) {
                var row = activeSheet.getActiveRowIndex();
                var col = activeSheet.getActiveColumnIndex();
                var segmentArray = activeSheet.getSegmentArray(row, col);
                input = {
                    value: segmentArray && segmentArray.length !== 0 ? editor.segmentArrayDeserialization(segmentArray) : editor.getFormattedValue(row, col)
                };
            }
            $('#mobile-message').css('display', 'none');
            if (input && typeof input.value === 'number') {
                input.value = input.value + '';
            }
            window.lark.biz.navigation.setSheetToolbar({
                input: input,
                items: toolbarItems,
                onSuccess: this._handleToolbarItemClick
            });
            _eventEmitter2.default.emit('sheet_in_doc:sheet_toolbar_show');
        }
    }, {
        key: "_closeSheetInput",
        value: function _closeSheetInput() {
            var spread = this.props.spread;

            if (!spread) return;
            var editor = spread.editor;
            if (editor && editor.isEditing()) {
                editor.submitImmediately();
                editor.endEdit(true, false);
            } else {
                this._setSheetToolbar();
            }
        }
    }, {
        key: "_closeSheetToolbar",
        value: function _closeSheetToolbar() {
            var spread = this.props.spread;

            if (!spread) return;
            var activeSheet = spread.getActiveSheet();
            var editor = spread.editor;
            if (editor && editor.isEditing()) {
                editor.submitImmediately();
                editor.endEdit(true, true);
            } else {
                if (activeSheet && activeSheet.getSelections().length > 0) {
                    activeSheet.clearSelection(true);
                    _eventEmitter2.default.emit('clear_sheet_selection', [activeSheet.id()]);
                }
                $('#mobile-message').css('display', 'block');
                window.lark.biz.navigation.setSheetToolbar({
                    items: [],
                    onSuccess: _noop3.default
                });
                _eventEmitter2.default.emit('sheet_in_doc:sheet_toolbar_hide');
            }
        }
    }, {
        key: "_collectToolbarEvent",
        value: function _collectToolbarEvent(id, value) {
            var payload = {
                eventType: 'click',
                source: 'sheet_toolbar',
                attr_op_status: value === 'true' ? 'cancel' : 'effective',
                object_id: "sheet_" + this.props.spread.getActiveSheet().id()
            };
            switch (id) {
                case ToolbarId.Keyboard:
                    if (value === 'false') {
                        payload.action = 'open_keyboard';
                        payload.op_item = 'icon';
                    }
                    break;
                case ToolbarId.TextAttribute:
                    if (value === 'true') {
                        payload.action = 'open_keyboard';
                        payload.op_item = 'form_open';
                    } else if (value === 'false') {
                        payload.action = 'open_font_style';
                    }
                    break;
                case ToolbarId.CellAttribute:
                    if (value === 'true') {
                        payload.action = 'open_keyboard';
                        payload.op_item = 'form_open';
                    } else if (value === 'false') {
                        payload.action = 'open_cell_style';
                    }
                    break;
                case ToolbarId.Bold:
                    payload.action = 'bold';
                    break;
                case ToolbarId.Italic:
                    payload.action = 'font_italic';
                    break;
                case ToolbarId.Underline:
                    payload.action = 'font_underline';
                    break;
                case ToolbarId.Strikethrough:
                    payload.action = 'font_delete';
                    break;
                case ToolbarId.HorizontalLeft:
                    payload.action = 'h_align_left';
                    break;
                case ToolbarId.HorizontalCenter:
                    payload.action = 'h_align_center';
                    break;
                case ToolbarId.HorizontalRight:
                    payload.action = 'h_align_right';
                    break;
                case ToolbarId.VerticalTop:
                    payload.action = 'v_align_up';
                    break;
                case ToolbarId.VerticalCenter:
                    payload.action = 'v_align_center';
                    break;
                case ToolbarId.VerticalBottom:
                    payload.action = 'v_align_down';
                    break;
                case ToolbarId.FontSize:
                    var oldFontSize = Number(this.props.cellStatus.fontSize);
                    var newFontSize = Number(value);
                    if (oldFontSize > newFontSize) {
                        payload.action = 'font_size_decrease';
                    } else if (oldFontSize < newFontSize) {
                        payload.action = 'font_size_increase';
                    }
                    break;
                case ToolbarId.ForeColor:
                    payload.action = 'fore_color';
                    payload.op_item = value;
                    break;
                case ToolbarId.BackColor:
                    payload.action = 'back_color';
                    payload.op_item = value;
                    break;
                case ToolbarId.Overflow:
                    payload.action = 'word_wrap_overflow';
                    break;
                case ToolbarId.AutoWrap:
                    payload.action = 'word_wrap_autowrap';
                    break;
                case ToolbarId.Clip:
                    payload.action = 'word_wrap_clip';
                    break;
                case ToolbarId.Merge:
                    payload.action = 'merge_cells';
                    break;
                case ToolbarId.Comment:
                    payload.action = 'comment';
                    break;
                case ToolbarId.Undo:
                    payload.action = 'undo';
                    break;
                case ToolbarId.Redo:
                    payload.action = 'redo';
                    break;
                default:
                    return;
            }
            (0, _tea.collectSuiteEvent)('sheet_opration', payload);
        }
    }, {
        key: "_handleToolbarItemClick",
        value: function _handleToolbarItemClick(_ref2) {
            var id = _ref2.id,
                value = _ref2.value;
            var _props2 = this.props,
                spread = _props2.spread,
                cellStatus = _props2.cellStatus,
                rangeStatus = _props2.rangeStatus,
                isEmbed = _props2.isEmbed;

            if (!spread) return;
            var activeSheet = spread.getActiveSheet();
            var editor = spread.editor;
            this._collectToolbarEvent(id, value);
            if (id !== ToolbarId.Undo && id !== ToolbarId.Redo && id !== ToolbarId.CloseToolbar) {
                // 点击工具栏除 undo、redo、关闭工具栏外的按钮，图表失焦，重新聚焦于单元格。
                _eventEmitter2.default.emit(_events2.default.MOBILE.SHEET.CLEAR_ACTIVE_CHART);
            }
            switch (id) {
                case ToolbarId.Keyboard:
                    if (value === 'true') {
                        this._closeSheetInput();
                    } else if (value === 'false') {
                        editor && editor.startEdit();
                    }
                    break;
                case ToolbarId.TextAttribute:
                case ToolbarId.CellAttribute:
                    if (value === 'true') {
                        editor && editor.startEdit();
                    } else if (value === 'false') {
                        this._closeSheetInput();
                    }
                    break;
                case ToolbarId.Bold:
                    toolbarHelper.setFontStyle(spread, 'font-weight', false, [cellStatus.bold ? 'normal' : 'bold']);
                    break;
                case ToolbarId.Italic:
                    toolbarHelper.setFontStyle(spread, 'font-style', false, [cellStatus.italic ? 'normal' : 'italic']);
                    break;
                case ToolbarId.Underline:
                    toolbarHelper.setTextDecoration(spread, _sheet3.TextDecorationType[id], cellStatus[id]);
                    break;
                case ToolbarId.Strikethrough:
                    toolbarHelper.setTextDecoration(spread, _sheet3.TextDecorationType['lineThrough'], cellStatus['lineThrough']);
                    break;
                case ToolbarId.HorizontalLeft:
                    toolbarHelper.setRangeValue(spread, 'hAlign', _sheetCommon.HorizontalAlign.Left);
                    break;
                case ToolbarId.HorizontalCenter:
                    toolbarHelper.setRangeValue(spread, 'hAlign', _sheetCommon.HorizontalAlign.Center);
                    break;
                case ToolbarId.HorizontalRight:
                    toolbarHelper.setRangeValue(spread, 'hAlign', _sheetCommon.HorizontalAlign.Right);
                    break;
                case ToolbarId.VerticalTop:
                    toolbarHelper.setRangeValue(spread, 'vAlign', _sheetCommon.VerticalAlign.Top);
                    break;
                case ToolbarId.VerticalCenter:
                    toolbarHelper.setRangeValue(spread, 'vAlign', _sheetCommon.VerticalAlign.Center);
                    break;
                case ToolbarId.VerticalBottom:
                    toolbarHelper.setRangeValue(spread, 'vAlign', _sheetCommon.VerticalAlign.Bottom);
                    break;
                case ToolbarId.FontSize:
                    value += 'pt';
                    toolbarHelper.setFontStyle(spread, 'font-size', false, [value], value);
                    break;
                case ToolbarId.ForeColor:
                case ToolbarId.BackColor:
                    toolbarHelper.setRangeValue(spread, id, value);
                    break;
                case ToolbarId.Overflow:
                    toolbarHelper.setRangeValue(spread, 'wordWrap', WordWrap.Overflow);
                    break;
                case ToolbarId.AutoWrap:
                    toolbarHelper.setRangeValue(spread, 'wordWrap', WordWrap.AutoWrap);
                    break;
                case ToolbarId.Clip:
                    toolbarHelper.setRangeValue(spread, 'wordWrap', WordWrap.Clip);
                    break;
                case ToolbarId.Merge:
                    if (rangeStatus.mergable) {
                        if (toolbarHelper.isCleanMerge(spread)) {
                            toolbarHelper.mergeCells(spread, true);
                        } else {
                            (0, _error.showError)(_error.ErrorTypes.ERROR_MERGE_CONTAIN_VALUE, {
                                onConfirm: function onConfirm() {
                                    toolbarHelper.mergeCells(spread, true);
                                    spread.focus();
                                }
                            });
                        }
                    } else if (rangeStatus.splitable) {
                        toolbarHelper.mergeCells(spread, false);
                    }
                    break;
                case ToolbarId.Comment:
                    if (isEmbed) {
                        var host = activeSheet ? activeSheet._host : null;
                        _eventEmitter2.default.emit('startSheetBlockComment', host);
                    } else {
                        if (activeSheet) {
                            var row = activeSheet.getActiveRowIndex();
                            var col = activeSheet.getActiveColumnIndex();
                            if (editor.isEditing()) {
                                this._closeSheetInput();
                            }
                            setTimeout(function () {
                                _eventEmitter2.default.emit(_sheet2.Events.AddComment, { row: row, col: col });
                            }, 50);
                        }
                    }
                    break;
                case ToolbarId.Undo:
                case ToolbarId.Redo:
                    toolbarHelper[id](spread);
                    this._setSheetToolbar();
                    break;
                case ToolbarId.CloseToolbar:
                    this._closeSheetToolbar();
                    break;
                default:
                    break;
            }
        }
    }]);
    return Toolbar;
}(_react.PureComponent);

__decorate([(0, _lodashDecorators.Bind)(), (0, _lodashDecorators.Debounce)(50), (0, _decorators.ExecOnlyActiveSheet)()], Toolbar.prototype, "_handleSelectionChanged", null);
__decorate([(0, _lodashDecorators.Bind)(), (0, _decorators.ExecOnlyActiveSheet)()], Toolbar.prototype, "_handleValueChanged", null);
__decorate([(0, _lodashDecorators.Bind)(), (0, _decorators.ExecOnlyActiveSheet)()], Toolbar.prototype, "_handleSheetSelectChanged", null);
__decorate([(0, _lodashDecorators.Bind)(), (0, _decorators.ExecOnlyActiveSheet)({ execWithoutActiveSheet: true })], Toolbar.prototype, "_setSheetToolbar", null);
__decorate([(0, _lodashDecorators.Bind)(), (0, _decorators.ExecOnlyActiveSheet)()], Toolbar.prototype, "_closeSheetInput", null);
__decorate([(0, _lodashDecorators.Bind)(), (0, _decorators.ExecOnlyActiveSheet)({ execWithoutActiveSheet: true })], Toolbar.prototype, "_closeSheetToolbar", null);
__decorate([(0, _decorators.ExecOnlyActiveSheet)()], Toolbar.prototype, "_collectToolbarEvent", null);
__decorate([(0, _lodashDecorators.Bind)()], Toolbar.prototype, "_handleToolbarItemClick", null);
var mapStateToProps = function mapStateToProps(state) {
    return {
        cellStatus: (0, _sheet.cellStatusSelector)(state),
        rangeStatus: (0, _sheet.rangeStatusSelector)(state)
    };
};
var mapDispatchToProps = {};
exports.default = (0, _reactRedux.connect)(mapStateToProps, mapDispatchToProps)(Toolbar);

/***/ }),

/***/ 2196:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.ungzip = ungzip;
exports.gzip = gzip;

var _pako = __webpack_require__(2113);

var _pako2 = _interopRequireDefault(_pako);

var _buffer = __webpack_require__(741);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * @param gzipBase64Str 必须是 base64 编码的
 */
function ungzip(gzipBase64Str) {
    return JSON.parse(_pako2.default.ungzip(_buffer.Buffer.from(gzipBase64Str, 'base64'), { level: 9, to: 'string' }));
}
function gzip(data) {
    return _buffer.Buffer.from(_pako2.default.gzip(data, { level: 9 })).toString('base64');
}

/***/ }),

/***/ 3361:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


__webpack_require__(3362);

/***/ }),

/***/ 3362:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


__webpack_require__(3363);

__webpack_require__(3364);

__webpack_require__(3365);

__webpack_require__(3366);

__webpack_require__(3367);

__webpack_require__(3368);

/***/ }),

/***/ 3363:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


var _$moirae = __webpack_require__(449);

var _$moirae2 = _interopRequireDefault(_$moirae);

var _sheetCore = __webpack_require__(1594);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

_sheetCore.dependency.moirae = _$moirae2.default;

/***/ }),

/***/ 3364:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


var _performanceLogHelper = __webpack_require__(458);

var _stageTracker = __webpack_require__(1798);

var _sheetCore = __webpack_require__(1594);

_sheetCore.dependency.commandPerformanceData = _performanceLogHelper.commandPerformanceData;
_sheetCore.dependency.stageTracker = _stageTracker.stageTracker;
_sheetCore.dependency.LogStatus = _stageTracker.LogStatus;

/***/ }),

/***/ 3365:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


var _tea = __webpack_require__(42);

var _sheetCore = __webpack_require__(1594);

_sheetCore.dependency.collectSuiteEvent = _tea.collectSuiteEvent;

/***/ }),

/***/ 3366:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


var _sheetCore = __webpack_require__(1594);

function isProhibitCopy() {
    return false;
}
function beforeCopy(e) {
    if (isProhibitCopy()) {
        e && e.preventDefault();
        return true;
    }
    return false;
}
_sheetCore.dependency.beforeCopy = beforeCopy;

/***/ }),

/***/ 3367:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

var _sheetCore = __webpack_require__(1594);

var ttI18NMap = {
    'sheet.spread.pass_instance_tips': t('sheet.spread.pass_instance_tips'),
    'sheet.spread.target_not_exit_tips': t('sheet.spread.target_not_exit_tips'),
    'sheet.copy_item': t('sheet.copy_item'),
    'sheet.conflict': t('sheet.conflict'),
    'sheet.cell_limit_exceed': t('sheet.cell_limit_exceed'),
    'common.unnamed_document': t('common.unnamed_document'),
    'common.unnamed_sheet': t('common.unnamed_sheet'),
    'sheet.invalid_link': t('sheet.invalid_link'),
    'sheet.overlapping_spans': t('sheet.overlapping_spans'),
    'sheet.protection.sync_permission_fail': t('sheet.protection.sync_permission_fail')
};
_sheetCore.dependency.t = function (source) {
    return ttI18NMap[source];
};
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(25)))

/***/ }),

/***/ 3368:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


var _sheetCore = __webpack_require__(1594);

var _domainHelper = __webpack_require__(557);

_sheetCore.dependency.isOverseaDomain = _domainHelper.isOverseaDomain;
_sheetCore.dependency.replaceImageDataSrc = _domainHelper.replaceImageDataSrc;

/***/ }),

/***/ 3369:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


__webpack_require__(3370);

/***/ }),

/***/ 3370:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


__webpack_require__(3371);

/***/ }),

/***/ 3371:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

var _sheetComponents = __webpack_require__(2126);

var ttI18NMap = {
    'common.edit': t('common.edit'),
    'common.copy': t('common.copy'),
    'common.delete': t('common.delete'),
    'sheet.chart.nodata': t('sheet.chart.nodata'),
    'header.please_enter_title': t('header.please_enter_title')
};
_sheetComponents.dependency.t = function (source) {
    return ttI18NMap[source];
};
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(25)))

/***/ }),

/***/ 3376:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


var _sheetCommon = __webpack_require__(1591);

var _sheetCore = __webpack_require__(1594);

var DEFAULT_THEME_NAME = 'Bytedance';
var DEFAULT_FONT = _sheetCommon.DefaultFontSize + '/1.5 ' + _sheetCommon.DefaultFontFamily;
var DEFAULT_HEAD_FONT = '9pt ' + _sheetCommon.DefaultFontFamily;
var DEFAULT_COLOR_SCHEME = new _sheetCore.Sheets.ColorScheme(DEFAULT_THEME_NAME, '#FFFFFF', '#EEECE1', // background
'#0000', '#1F497D', // text
'#4F81BD', '#C0504D', '#9BBB59', '#8064A2', '#4BACC6', '#F79646', // accent
'#0000FF', // link
'#800080');
var DEFAULT_THEME = new _sheetCore.Sheets.Theme(DEFAULT_THEME_NAME, DEFAULT_COLOR_SCHEME, _sheetCommon.DefaultFontFamily, _sheetCommon.DefaultFontFamily);
var DEFAULT_STYLE = new _sheetCore.Sheets.Style();
DEFAULT_STYLE.font = DEFAULT_FONT;
DEFAULT_STYLE.vAlign = _sheetCommon.VerticalAlign.Bottom;
// 数字默认右对齐，其他文字默认左对齐
// general能满足，但是toolbar要分别展示左对齐和右对齐
DEFAULT_STYLE.hAlign = _sheetCommon.HorizontalAlign.General;
DEFAULT_STYLE.wordWrap = _sheetCommon.WORD_WRAP_TYPE.OVERFLOW;
DEFAULT_STYLE.imeMode = _sheetCommon.ImeMode.auto;
function sheetDefault() {
    this.currentTheme(DEFAULT_THEME);
    var style = new _sheetCore.Sheets.Style();
    style.font = DEFAULT_HEAD_FONT;
    this.setDefaultStyle(style.clone(), _sheetCommon.SheetArea.rowHeader);
    this.setDefaultStyle(style.clone(), _sheetCommon.SheetArea.colHeader);
    this.setDefaultStyle(style.clone(), _sheetCommon.SheetArea.corner);
    var defaultStyle = DEFAULT_STYLE.clone();
    var parent = this.parent;

    if (parent && parent.defaultStyle) {
        Object.assign(defaultStyle, parent.defaultStyle);
    }
    this.setDefaultStyle(defaultStyle, _sheetCommon.SheetArea.viewport);
    Object.assign(this.defaults, {
        rowHeight: 28,
        colHeaderRowHeight: 24,
        colWidth: 120,
        rowHeaderColWidth: 40
    }, parent ? parent.defaults : {});
    this.options.allowCellOverflow = true;
    var rowCount = this.getRowCount();
    this._userRowHeight = [];
    for (var i = 0; i < rowCount; i++) {
        var rowHeight = this.getRowHeight(i);
        this._userRowHeight[i] = rowHeight;
    }
    // 禁掉调整header行高列宽
    this.setColumnResizable(0, false, _sheetCommon.SheetArea.rowHeader);
    this.setRowResizable(0, false, _sheetCommon.SheetArea.colHeader);
    this.setSelection(new _sheetCore.Range(0, 0, 1, 1, this));
}
_sheetCore.Sheets.Worksheet._registerFeature('theme', {
    // 本地添加sheet会走这个
    attach: sheetDefault,
    // 从远端同步的新增sheet会走这个
    fromJson: sheetDefault
});
function workbookDefault() {
    Object.assign(this.options, {
        allowUndo: true,
        allowExtendPasteRange: true,
        allowUserZoom: false,
        isProtected: true,
        // HACK: 目前Canvas透明需要传 backgroundImage 触发 sheet._invalidate() 才能生效
        // tslint:disable-next-line
        backgroundImage: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxIiBoZWlnaHQ9IjEiIHZpZXdCb3g9IjAgMCAxIDEiPjwvc3ZnPg=='
    });
}
_sheetCore.Sheets.Workbook._registerFeature('theme', {
    init: workbookDefault,
    fromJson: workbookDefault
});
// 设置语言
_sheetCore.Common.CultureManager.culture('zh-cn');

/***/ }),

/***/ 3377:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.SheetEvents = undefined;

var _defineProperty2 = __webpack_require__(9);

var _defineProperty3 = _interopRequireDefault(_defineProperty2);

var _slicedToArray2 = __webpack_require__(111);

var _slicedToArray3 = _interopRequireDefault(_slicedToArray2);

var _throttle2 = __webpack_require__(237);

var _throttle3 = _interopRequireDefault(_throttle2);

var _eventHandles;

exports.getTagFromCount = getTagFromCount;
exports.getTagFromRange = getTagFromRange;
exports.bindSpread = bindSpread;
exports.unbindSpread = unbindSpread;

var _tea = __webpack_require__(42);

var _slardar = __webpack_require__(3378);

var Slardar = _interopRequireWildcard(_slardar);

var _sheetCore = __webpack_require__(1594);

var _hotkeyHelper = __webpack_require__(3379);

var _sheetIo = __webpack_require__(1621);

var _sheetCommon = __webpack_require__(1591);

var _$moirae = __webpack_require__(449);

var _$moirae2 = _interopRequireDefault(_$moirae);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var SheetEvents = exports.SheetEvents = undefined;
(function (SheetEvents) {
    /**
     * TODO: 确认清楚记录的范围
     */
    SheetEvents["CREATE_SHEET"] = "sheet_create_sheet";
    /**
     * TODO: 确认清楚记录的范围
     */
    SheetEvents["FIRST_LOAD"] = "sheet_first_load";
    SheetEvents["CTRL_V"] = "sheet_ctrl_v";
    SheetEvents["CTRL_C"] = "sheet_ctrl_c";
    SheetEvents["SET_COL_WIDTH"] = "sheet_set_col_width";
    SheetEvents["SET_ROW_HEIGHT"] = "sheet_set_row_height";
    SheetEvents["SET_FORMATTER"] = "sheet_set_formatter";
})(SheetEvents || (exports.SheetEvents = SheetEvents = {}));
var TAGS;
(function (TAGS) {
    TAGS["CELLS_0_3W"] = "cells_0_3W";
    TAGS["CELLS_3W_6W"] = "cells_3W_6W";
    TAGS["CELLS_6W_9W"] = "cells_6W_9W";
    TAGS["CELLS_9W"] = "cells_9W";
})(TAGS || (TAGS = {}));
function getTagFromCount(count) {
    if (count < 30000) {
        return TAGS.CELLS_0_3W;
    }
    if (count < 60000) {
        return TAGS.CELLS_3W_6W;
    }
    if (count < 90000) {
        return TAGS.CELLS_6W_9W;
    }
    return TAGS.CELLS_9W;
}
function getTagFromRange(rowCount, colCount) {
    return getTagFromCount(rowCount * colCount);
}
var scrolling = false;
var eventHandles = (_eventHandles = {}, (0, _defineProperty3.default)(_eventHandles, _sheetCommon.Events.ClipboardChanging, function (args) {
    Slardar.timeStart(SheetEvents.CTRL_C);
}), (0, _defineProperty3.default)(_eventHandles, _sheetCommon.Events.ClipboardChanged, function (args) {
    var sheet = args.sheet;

    var shortcutKeys = (0, _hotkeyHelper.getShortcutKeys)(args.isCutting ? _sheetCore.Sheets.Commands.CUT : _sheetCore.Sheets.Commands.COPY);
    (0, _tea.collectSuiteEvent)('sheet_opration', {
        action: shortcutKeys && shortcutKeys.join('_').toLowerCase().replace('\u2318', 'command'),
        source: 'body',
        eventType: 'keydown',
        targetId: '',
        targetClass: '',
        object_id: sheet.id()
    });

    var _sheet$getSelections = sheet.getSelections(),
        _sheet$getSelections2 = (0, _slicedToArray3.default)(_sheet$getSelections, 1),
        selection = _sheet$getSelections2[0];

    var rowCount = 0;
    var colCount = 0;
    if (selection) {
        rowCount = selection.rowCount();
        colCount = selection.colCount();
    }
    Slardar.timeEnd(SheetEvents.CTRL_C, getTagFromRange(rowCount, colCount));
}), (0, _defineProperty3.default)(_eventHandles, _sheetCommon.Events.ClipboardPasting, function (args) {
    Slardar.timeStart(SheetEvents.CTRL_V);
}), (0, _defineProperty3.default)(_eventHandles, _sheetCommon.Events.ClipboardPasted, function (_ref) {
    var sheet = _ref.sheet,
        cellRange = _ref.cellRange;

    Slardar.timeEnd(SheetEvents.CTRL_V, getTagFromRange(cellRange.rowCount(), cellRange.colCount()));
    _sheetIo.watchDog.watchStart('e3e59ea01f4dd1351da254aa802444cacfea20f7', sheet);
}), (0, _defineProperty3.default)(_eventHandles, _sheetCommon.Events.ColumnWidthChanging, function (args) {
    Slardar.timeStart(SheetEvents.SET_COL_WIDTH);
}), (0, _defineProperty3.default)(_eventHandles, _sheetCommon.Events.ColumnWidthChanged, function (_ref2) {
    var sheet = _ref2.sheet,
        colList = _ref2.colList;

    Slardar.timeEnd(SheetEvents.SET_COL_WIDTH, getTagFromRange(sheet.getRowCount(), colList.length));
}), (0, _defineProperty3.default)(_eventHandles, _sheetCommon.Events.RowHeightChanging, function (args) {
    Slardar.timeStart(SheetEvents.SET_ROW_HEIGHT);
}), (0, _defineProperty3.default)(_eventHandles, _sheetCommon.Events.RowHeightChanged, function (_ref3) {
    var sheet = _ref3.sheet,
        rowList = _ref3.rowList;

    Slardar.timeEnd(SheetEvents.SET_ROW_HEIGHT, getTagFromRange(rowList.length, sheet.getColumnCount()));
}), (0, _defineProperty3.default)(_eventHandles, _sheetCommon.Events.TopPosChanged, (0, _throttle3.default)(function (spread) {
    if (!scrolling) {
        scrolling = true;
        var sheet = spread.getActiveSheet();
        // 在撤销删除时，可能会导致表格尚未建立
        if (sheet) {
            var cf = caculateFps(sheet.getRowCount(), sheet.getColumnCount());
            cf();
        }
    }
}, 1000)), _eventHandles);
function caculateFps(rowCount, colCount) {
    var startTime = void 0;
    var lastFrameId = void 0;
    var frameCount = -1;
    return function loop() {
        var now = performance.now();
        if (!startTime) {
            startTime = now;
        }
        frameCount++;
        if (now - startTime >= 950) {
            var fps = Math.round(frameCount / (now - startTime) * 1000);
            var fpsData = {
                row_count: rowCount,
                column_count: colCount,
                cell_count: rowCount * colCount,
                sheet_fps: fps
            };
            (0, _tea.collectSuiteEvent)('client_performance_fps', fpsData);
            _$moirae2.default.mean('ee.docs.sheet.faster_fps_' + getTagFromRange(rowCount, colCount), fps);
            frameCount = -1;
            startTime = 0;
            cancelAnimationFrame(lastFrameId);
            scrolling = false;
            return;
        }
        lastFrameId = requestAnimationFrame(function () {
            return loop();
        });
    };
}
function handleSpreadEvent(event, args) {
    var type = event.type;
    var handle = eventHandles[type];
    args = args || this;
    handle(args);
}
function bindSpread(spread) {
    for (var event in eventHandles) {
        spread.bind(event, handleSpreadEvent.bind(spread));
    }
}
function unbindSpread(spread) {
    for (var event in eventHandles) {
        spread.unbind(event, handleSpreadEvent);
    }
}

/***/ }),

/***/ 3378:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.timeStart = timeStart;
exports.timeEnd = timeEnd;
/**
 * TODO: Slardar改用 webpack 的 Externals 来引入
 */
var status = {};
function timeStart(name) {
    if (status[name]) {
        // 在发送log之前，记录同一事件的开始时间可能会被调用多次
        // 这里取第一次调用的时间
        return;
    }
    status[name] = Date.now();
}
function timeEnd(name, tag) {
    var start = status[name];
    if (!start) {
        if (false) {}
        return;
    }
    var duration = Date.now() - start;
    delete status[name];
    var Slardar = window.Slardar;
    // Slardar 是外部第三方资源，无法保证这个资源能稳定加载
    // 如果加载不来，不进行性能打点也没关系
    if (Slardar) {
        Slardar.sendCustomTimeLog(name, tag, duration);
    }
}

/***/ }),

/***/ 3379:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.SHORTCUT_KEY = undefined;

var _defineProperty2 = __webpack_require__(9);

var _defineProperty3 = _interopRequireDefault(_defineProperty2);

var _SHORTCUT_KEY;

exports.getShortcutKeys = getShortcutKeys;
exports.getDisplayShortcutKey = getDisplayShortcutKey;

var _browserHelper = __webpack_require__(27);

var _browserHelper2 = _interopRequireDefault(_browserHelper);

var _sheetCommon = __webpack_require__(1591);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function getShortcutKeys(commandName) {
    if (!(commandName in SHORTCUT_KEY)) {
        return null;
    }
    var isMac = _browserHelper2.default.isMac;

    var keyMap = SHORTCUT_KEY[commandName];
    var shortcutKeys = [];
    if (keyMap.ctrlKey) {
        var ctrl = isMac ? '\u2318' : 'Ctrl';
        shortcutKeys.push(ctrl);
    }
    if (keyMap.metaKey) {
        var meta = isMac ? 'Ctrl' : 'Win';
        shortcutKeys.push(meta);
    }
    if (keyMap.shiftKey) {
        shortcutKeys.push('Shift');
    }
    if (keyMap.altKey) {
        var alt = isMac ? 'Option' : 'Alt';
        shortcutKeys.push(alt);
    }
    shortcutKeys.push(_sheetCommon.KeyCode[keyMap.keyCode]);
    return shortcutKeys;
}
function getDisplayShortcutKey(commandName) {
    var shortcutKeys = getShortcutKeys(commandName);
    if (!shortcutKeys) return '';
    if (shortcutKeys.length === 2 && shortcutKeys[0] === '\u2318') return shortcutKeys.join('');
    return shortcutKeys.join('+');
}
/**
 * MAC 环境下，为了统一处理，
 * 使用 ctrlKey 表示 command 键位，
 * 使用 metaKey 表示 control 键位，
 * 即两个键位进行对换
 */
var SHORTCUT_KEY = exports.SHORTCUT_KEY = (_SHORTCUT_KEY = {}, (0, _defineProperty3.default)(_SHORTCUT_KEY, _sheetCommon.CommandKeys.COMMENT, {
    ctrlKey: true,
    altKey: true,
    keyCode: _sheetCommon.KeyCode.M
}), (0, _defineProperty3.default)(_SHORTCUT_KEY, _sheetCommon.CommandKeys.SELECT_ROW, {
    shiftKey: true,
    keyCode: _sheetCommon.KeyCode.Space
}), (0, _defineProperty3.default)(_SHORTCUT_KEY, _sheetCommon.CommandKeys.SELECT_COLUMN, {
    ctrlKey: true,
    keyCode: _sheetCommon.KeyCode.Space
}), (0, _defineProperty3.default)(_SHORTCUT_KEY, _sheetCommon.CommandKeys.BOLD, {
    ctrlKey: true,
    keyCode: _sheetCommon.KeyCode.B
}), (0, _defineProperty3.default)(_SHORTCUT_KEY, _sheetCommon.CommandKeys.UNDERLINE, {
    ctrlKey: true,
    keyCode: _sheetCommon.KeyCode.U
}), (0, _defineProperty3.default)(_SHORTCUT_KEY, _sheetCommon.CommandKeys.ITALIC, {
    ctrlKey: true,
    keyCode: _sheetCommon.KeyCode.I
}), (0, _defineProperty3.default)(_SHORTCUT_KEY, _sheetCommon.CommandKeys.LINE_THROUGH, {
    ctrlKey: true,
    shiftKey: true,
    keyCode: _sheetCommon.KeyCode.X
}), (0, _defineProperty3.default)(_SHORTCUT_KEY, _sheetCommon.CommandKeys.H_ALIGN_LEFT, {
    ctrlKey: true,
    shiftKey: true,
    keyCode: _sheetCommon.KeyCode.L
}), (0, _defineProperty3.default)(_SHORTCUT_KEY, _sheetCommon.CommandKeys.H_ALIGN_CENTER, {
    ctrlKey: true,
    shiftKey: true,
    keyCode: _sheetCommon.KeyCode.E
}), (0, _defineProperty3.default)(_SHORTCUT_KEY, _sheetCommon.CommandKeys.H_ALIGN_RIGHT, {
    ctrlKey: true,
    shiftKey: true,
    keyCode: _sheetCommon.KeyCode.R
}), (0, _defineProperty3.default)(_SHORTCUT_KEY, _sheetCommon.CommandKeys.DO_CLEAR, {
    ctrlKey: true,
    keyCode: _sheetCommon.KeyCode['\\']
}), (0, _defineProperty3.default)(_SHORTCUT_KEY, _sheetCommon.CommandKeys.MOVE_HEAD, {
    ctrlKey: true,
    keyCode: _sheetCommon.KeyCode.Home
}), (0, _defineProperty3.default)(_SHORTCUT_KEY, _sheetCommon.CommandKeys.MOVE_END, {
    ctrlKey: true,
    keyCode: _sheetCommon.KeyCode.End
}), (0, _defineProperty3.default)(_SHORTCUT_KEY, _sheetCommon.CommandKeys.MOVE_ACTIVE, {
    ctrlKey: true,
    keyCode: _sheetCommon.KeyCode.BackSpace
}), (0, _defineProperty3.default)(_SHORTCUT_KEY, _sheetCommon.CommandKeys.UNDO, {
    ctrlKey: true,
    keyCode: _sheetCommon.KeyCode.Z
}), (0, _defineProperty3.default)(_SHORTCUT_KEY, _sheetCommon.CommandKeys.REDO, {
    ctrlKey: true,
    keyCode: _sheetCommon.KeyCode.Y
}), (0, _defineProperty3.default)(_SHORTCUT_KEY, _sheetCommon.CommandKeys.PASTE_VALUE, {
    ctrlKey: true,
    shiftKey: true,
    keyCode: _sheetCommon.KeyCode.V
}), (0, _defineProperty3.default)(_SHORTCUT_KEY, _sheetCommon.CommandKeys.SELECT_ALL, {
    ctrlKey: true,
    keyCode: _sheetCommon.KeyCode.A
}), (0, _defineProperty3.default)(_SHORTCUT_KEY, _sheetCommon.CommandKeys.FIND, {
    ctrlKey: true,
    shiftKey: true,
    keyCode: _sheetCommon.KeyCode.H
}), (0, _defineProperty3.default)(_SHORTCUT_KEY, _sheetCommon.CommandKeys.NAVIGATION_HOME_2, {
    ctrlKey: true,
    keyCode: _sheetCommon.KeyCode.Left
}), (0, _defineProperty3.default)(_SHORTCUT_KEY, _sheetCommon.CommandKeys.NAVIGATION_END_2, {
    ctrlKey: true,
    keyCode: _sheetCommon.KeyCode.Right
}), (0, _defineProperty3.default)(_SHORTCUT_KEY, _sheetCommon.CommandKeys.NAVIGATION_TOP, {
    ctrlKey: true,
    keyCode: _sheetCommon.KeyCode.Up
}), (0, _defineProperty3.default)(_SHORTCUT_KEY, _sheetCommon.CommandKeys.NAVIGATION_BOTTOM, {
    ctrlKey: true,
    keyCode: _sheetCommon.KeyCode.Down
}), (0, _defineProperty3.default)(_SHORTCUT_KEY, _sheetCommon.CommandKeys.PREVENT_SAVE, {
    ctrlKey: true,
    keyCode: _sheetCommon.KeyCode.S
}), (0, _defineProperty3.default)(_SHORTCUT_KEY, _sheetCommon.CommandKeys.PASTE, {
    ctrlKey: true,
    keyCode: _sheetCommon.KeyCode.V
}), (0, _defineProperty3.default)(_SHORTCUT_KEY, _sheetCommon.CommandKeys.REDO_2, {
    ctrlKey: true,
    shiftKey: true,
    keyCode: _sheetCommon.KeyCode.Z
}), (0, _defineProperty3.default)(_SHORTCUT_KEY, _sheetCommon.CommandKeys.COPY, {
    ctrlKey: true,
    keyCode: _sheetCommon.KeyCode.C
}), (0, _defineProperty3.default)(_SHORTCUT_KEY, _sheetCommon.CommandKeys.CUT, {
    ctrlKey: true,
    keyCode: _sheetCommon.KeyCode.X
}), (0, _defineProperty3.default)(_SHORTCUT_KEY, _sheetCommon.CommandKeys.HORIZONTAL_FILL, {
    ctrlKey: true,
    keyCode: _sheetCommon.KeyCode.R
}), (0, _defineProperty3.default)(_SHORTCUT_KEY, _sheetCommon.CommandKeys.VERTICAL_FILL, {
    ctrlKey: true,
    keyCode: _sheetCommon.KeyCode.D
}), _SHORTCUT_KEY);

/***/ }),

/***/ 3380:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.replaceLinkToAt = exports.fetchDocsTitle = undefined;

var _regenerator = __webpack_require__(12);

var _regenerator2 = _interopRequireDefault(_regenerator);

var _defineProperty2 = __webpack_require__(9);

var _defineProperty3 = _interopRequireDefault(_defineProperty2);

var _asyncToGenerator2 = __webpack_require__(99);

var _asyncToGenerator3 = _interopRequireDefault(_asyncToGenerator2);

var fetchDocsTitle = exports.fetchDocsTitle = function () {
    var _ref = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee(type, token) {
        var _api;

        var api, result;
        return _regenerator2.default.wrap(function _callee$(_context) {
            while (1) {
                switch (_context.prev = _context.next) {
                    case 0:
                        // TODO: 不具有良好的可扩展性，多一种文件类型时，预期是不需要再更改此处
                        api = (_api = {}, (0, _defineProperty3.default)(_api, _common.NUM_FILE_TYPE.DOC, _$constants.apiUrls.GET_NOTE), (0, _defineProperty3.default)(_api, _common.NUM_FILE_TYPE.SHEET, _$constants.apiUrls.GET_SPREADSHEET), _api);
                        _context.next = 3;
                        return _io.axios.get('' + api[type] + token + '/');

                    case 3:
                        result = _context.sent;

                        if (!(result.code === 0)) {
                            _context.next = 6;
                            break;
                        }

                        return _context.abrupt('return', result.data.title);

                    case 6:
                        return _context.abrupt('return', null);

                    case 7:
                    case 'end':
                        return _context.stop();
                }
            }
        }, _callee, this);
    }));

    return function fetchDocsTitle(_x, _x2) {
        return _ref.apply(this, arguments);
    };
}();

var getTitle = function () {
    var _ref2 = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee2(type, token) {
        var suiteTypeNum, title;
        return _regenerator2.default.wrap(function _callee2$(_context2) {
            while (1) {
                switch (_context2.prev = _context2.next) {
                    case 0:
                        suiteTypeNum = getSuiteTypeNum(type);
                        _context2.next = 3;
                        return fetchDocsTitle(suiteTypeNum, token);

                    case 3:
                        title = _context2.sent;

                        if (title != null && title.length === 0) {
                            title = (0, _titleHelper.getUnnamedTitle)(suiteTypeNum);
                        }
                        return _context2.abrupt('return', title);

                    case 6:
                    case 'end':
                        return _context2.stop();
                }
            }
        }, _callee2, this);
    }));

    return function getTitle(_x3, _x4) {
        return _ref2.apply(this, arguments);
    };
}();

var replaceLinkToAt = exports.replaceLinkToAt = function () {
    var _ref3 = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee3(sheet, _ref4) {
        var row = _ref4.row,
            col = _ref4.col,
            value = _ref4.value;
        var spread, sheetId, oldSegmentArray, newSegmentArray, hasDocsLink, i, seg, link, result, type, token, title, mentionType, segmentArray;
        return _regenerator2.default.wrap(function _callee3$(_context3) {
            while (1) {
                switch (_context3.prev = _context3.next) {
                    case 0:
                        spread = sheet.parent;
                        sheetId = sheet.id();
                        oldSegmentArray = sheet.getSegmentArray(row, col);
                        newSegmentArray = [];
                        hasDocsLink = false;
                        i = 0;

                    case 6:
                        if (!(i < value.length)) {
                            _context3.next = 28;
                            break;
                        }

                        seg = value[i];
                        // 不是 url 的或者是 url 但是已经有 link 的都不会转换

                        if (!(seg.type !== 'url' || hasText(seg))) {
                            _context3.next = 11;
                            break;
                        }

                        newSegmentArray.push(seg);
                        return _context3.abrupt('continue', 25);

                    case 11:
                        link = seg.text;
                        result = getDocsReg().exec(link);

                        if (!(result == null)) {
                            _context3.next = 16;
                            break;
                        }

                        newSegmentArray.push(seg);
                        return _context3.abrupt('continue', 25);

                    case 16:
                        hasDocsLink = true;
                        type = result[2];
                        token = result[3];
                        _context3.next = 21;
                        return getTitle(type, token);

                    case 21:
                        title = _context3.sent;
                        mentionType = type === 'sheet' ? _sheet.MENTION_TYPE.SHEET : _sheet.MENTION_TYPE.DOC;

                        newSegmentArray.push({
                            type: 'mention',
                            mentionType: mentionType,
                            mentionNotify: false,
                            text: title,
                            token: token,
                            link: link
                        });
                        newSegmentArray.push({
                            type: 'text',
                            text: ' '
                        });

                    case 25:
                        i++;
                        _context3.next = 6;
                        break;

                    case 28:
                        if (!(hasDocsLink && spread.getSheetFromId(sheetId))) {
                            _context3.next = 32;
                            break;
                        }

                        segmentArray = sheet.getSegmentArray(row, col);

                        if (!(oldSegmentArray === segmentArray)) {
                            _context3.next = 32;
                            break;
                        }

                        return _context3.abrupt('return', {
                            row: row,
                            col: col,
                            newSegmentArray: newSegmentArray
                        });

                    case 32:
                        return _context3.abrupt('return', false);

                    case 33:
                    case 'end':
                        return _context3.stop();
                }
            }
        }, _callee3, this);
    }));

    return function replaceLinkToAt(_x5, _x6) {
        return _ref3.apply(this, arguments);
    };
}();

exports.checkIfDocsLink = checkIfDocsLink;
exports.convertLink = convertLink;

var _io = __webpack_require__(1894);

var _$constants = __webpack_require__(5);

var _common = __webpack_require__(19);

var _titleHelper = __webpack_require__(195);

var _sheet = __webpack_require__(744);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var DOCS_PATTERN = '(https?://)?' + window.location.host + '/(doc|sheet)/([a-zA-Z0-9]+)/?' + '(\\?[;&a-z\\d%_.~+=-]*)?' + '(\\#[-a-z\\d_]*)?';
function getDocsReg() {
    return new RegExp('^' + DOCS_PATTERN + '$', 'i');
}
function checkIfDocsLink(link) {
    return getDocsReg().test(link);
}
function convertLink(sheet, changesets) {
    var newValuePromises = [];
    for (var i = 0; i < changesets.length; i++) {
        var changeset = changesets[i];
        if (changeset.action === 'setCell' && Array.isArray(changeset.value.value)) {
            newValuePromises.push(replaceLinkToAt(sheet, {
                row: changeset.target.row,
                col: changeset.target.col,
                value: changeset.value.value
            }));
        }
    }
    Promise.all(newValuePromises).then(function (newValues) {
        var valueToExcute = newValues.filter(function (value) {
            return !!value;
        });
        valueToExcute.length && sheet._commandManager().execute({
            cmd: 'convertLink',
            sheetId: sheet.id(),
            data: valueToExcute
        });
    });
}

function getSuiteTypeNum(type) {
    return parseInt(_$constants.common.FILE_URL_TYPE_MAP[type], 10);
}

function hasText(seg) {
    return seg.link && seg.text !== seg.link && seg.text !== 'http://' + seg.link;
}

/***/ }),

/***/ 3381:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.SheetChangesetExec = undefined;

var _classCallCheck2 = __webpack_require__(6);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(7);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(10);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _get2 = __webpack_require__(349);

var _get3 = _interopRequireDefault(_get2);

var _inherits2 = __webpack_require__(11);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _$store = __webpack_require__(64);

var _$store2 = _interopRequireDefault(_$store);

var _utils = __webpack_require__(1678);

var _sheetIo = __webpack_require__(1621);

var _sheetCore = __webpack_require__(1594);

var _sheet = __webpack_require__(1660);

var _error = __webpack_require__(1896);

var _browserHelper = __webpack_require__(27);

var _browserHelper2 = _interopRequireDefault(_browserHelper);

var _sheetCommon = __webpack_require__(1591);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var Events = _sheetCore.Sheets.Events; /* tslint:disable */
/**
 * TODO: 该文件与./engine/changeset.ts是不同的
 * 目前有两个同名只是个中间状态，后续会考虑将逻辑区分清楚
 */

var SheetChangesetExec = exports.SheetChangesetExec = function (_BaseChangesetExec) {
    (0, _inherits3.default)(SheetChangesetExec, _BaseChangesetExec);

    function SheetChangesetExec(context) {
        (0, _classCallCheck3.default)(this, SheetChangesetExec);

        var _this = (0, _possibleConstructorReturn3.default)(this, (SheetChangesetExec.__proto__ || Object.getPrototypeOf(SheetChangesetExec)).call(this, console));

        _this.context = context;
        return _this;
    }
    // [ACTIONS.ADD_COMMENTS]


    (0, _createClass3.default)(SheetChangesetExec, [{
        key: 'addComments',
        value: function addComments(sheet, changeset) {
            var _this2 = this;

            var newComments = (0, _get3.default)(SheetChangesetExec.prototype.__proto__ || Object.getPrototypeOf(SheetChangesetExec.prototype), _sheetCommon.ACTIONS.ADD_COMMENTS, this).call(this, sheet, changeset);
            newComments.forEach(function (_ref) {
                var id = _ref.id;

                _this2.context.trigger(_sheetIo.CollaborativeEvents.ACCEPT_COMMENT_CHANGE, {
                    comment_id: id,
                    sheet_id: changeset.sheet_id
                });
            });
            return newComments;
        }
    }, {
        key: 'setSpans',

        // [ACTIONS.SET_SPANS]
        value: function setSpans(sheet, changeset) {
            var value = (0, _get3.default)(SheetChangesetExec.prototype.__proto__ || Object.getPrototypeOf(SheetChangesetExec.prototype), _sheetCommon.ACTIONS.SET_SPANS, this).call(this, sheet, changeset);
            this.context.trigger(_sheetIo.CollaborativeEvents.SPANS_CHANGE, {
                spans: value,
                sheet: sheet
            });
        }
    }, {
        key: 'addSheet',

        // [ACTIONS.ADD_SHEET]
        value: function addSheet(spread, changeset) {
            (0, _get3.default)(SheetChangesetExec.prototype.__proto__ || Object.getPrototypeOf(SheetChangesetExec.prototype), _sheetCommon.ACTIONS.ADD_SHEET, this).call(this, spread, changeset);
            (0, _utils.setSpreadEdit)(spread, (0, _sheet.editableSelector)(_$store2.default.getState()));
        }
    }, {
        key: 'restoreSheet',
        value: function restoreSheet(spread, changeset) {
            (0, _get3.default)(SheetChangesetExec.prototype.__proto__ || Object.getPrototypeOf(SheetChangesetExec.prototype), 'restoreSheet', this).call(this, spread, changeset);
            var sheet_id = changeset.sheet_id;

            (0, _utils.setSpreadEdit)(spread, (0, _sheet.editableSelector)(_$store2.default.getState()));
            this.context.trigger(_sheetIo.CollaborativeEvents.RESTORE_SHEET, sheet_id);
        }
        // [ACTIONS.COPY_SHEET]

    }, {
        key: 'copySheet',
        value: function copySheet(spread, changeset) {
            (0, _get3.default)(SheetChangesetExec.prototype.__proto__ || Object.getPrototypeOf(SheetChangesetExec.prototype), 'copySheet', this).call(this, spread, changeset);
            (0, _utils.setSpreadEdit)(spread, (0, _sheet.editableSelector)(_$store2.default.getState()));
        }
    }, {
        key: 'delSheet',

        // [ACTIONS.DEL_SHEET]
        value: function delSheet(sheet, changeset, local) {
            var _this3 = this;

            var spread = sheet.parent;
            var activeSheet = spread.getActiveSheet();
            var sheetName = sheet.name();
            var triggerSheetChange = function triggerSheetChange() {
                var trigger = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : false;

                (0, _get3.default)(SheetChangesetExec.prototype.__proto__ || Object.getPrototypeOf(SheetChangesetExec.prototype), _sheetCommon.ACTIONS.DEL_SHEET, _this3).call(_this3, sheet, changeset, local);
                var toSheet = spread.getActiveSheet();
                _this3.context.trigger(_sheetIo.CollaborativeEvents.RESUME_ACTION);
                spread.forceResumeEvent();
                spread.trigger(Events.ActiveSheetChanged, {
                    newSheet: toSheet
                });
            };
            if (local) {
                return triggerSheetChange();
            } // 只有当前工作表和别人删除的工作表同名的时候才会弹出提醒
            if (activeSheet && activeSheet.name() === sheetName) {
                this.context.trigger(_sheetIo.CollaborativeEvents.SUSPEND_ACTION);
                (0, _error.showError)(_error.ErrorTypes.ERROR_SHEET_NOT_EXIST, {
                    onConfirm: function onConfirm() {
                        triggerSheetChange(true);
                    },
                    onCancel: function onCancel() {
                        _this3.context.trigger(_sheetIo.CollaborativeEvents.FREEZE_SPREAD);
                    }
                });
            } else {
                triggerSheetChange();
            }
        }
    }, {
        key: 'softDelSheet',
        value: function softDelSheet(spread, changeset) {
            (0, _get3.default)(SheetChangesetExec.prototype.__proto__ || Object.getPrototypeOf(SheetChangesetExec.prototype), 'softDelSheet', this).call(this, spread, changeset);
            this.context.trigger(_sheetIo.CollaborativeEvents.SOFT_DEL_SHEET);
            this.context.trigger(_sheetIo.CollaborativeEvents.RESUME_ACTION);
        }
        // [ACTIONS.ADD_ROW]

    }, {
        key: 'addRow',
        value: function addRow(sheet, changeset) {
            var _this4 = this;

            var target = changeset.target;

            var addRow = function addRow() {
                (0, _get3.default)(SheetChangesetExec.prototype.__proto__ || Object.getPrototypeOf(SheetChangesetExec.prototype), _sheetCommon.ACTIONS.ADD_ROW, _this4).call(_this4, sheet, changeset);
                _this4.context.trigger(_sheetIo.CollaborativeEvents.CELL_COORD_CHANGE, {
                    type: 'add',
                    target: {
                        row: target.row,
                        rowCount: target.rowCount
                    },
                    sheet: sheet
                });
            };
            var row = sheet.getActiveRowIndex();
            var col = sheet.getActiveColumnIndex();
            if (row < target.row) {
                return addRow();
            }
            if (!sheet.isEditing()) {
                addRow();
                sheet.setActiveCell(row + target.rowCount, col);
                return;
            }
            var cellType = sheet.getCellType(row, col);
            var value = cellType.getEditorValue(cellType.getEditingElement());
            sheet.endEdit(true);
            addRow();
            sheet.setActiveCell(row + target.rowCount, col);
            sheet.startEdit(false, value);
        }
    }, {
        key: 'addCol',

        // [ACTIONS.ADD_COL]
        value: function addCol(sheet, changeset) {
            var _this5 = this;

            var target = changeset.target;

            var row = sheet.getActiveRowIndex();
            var col = sheet.getActiveColumnIndex();
            var addCol = function addCol() {
                (0, _get3.default)(SheetChangesetExec.prototype.__proto__ || Object.getPrototypeOf(SheetChangesetExec.prototype), _sheetCommon.ACTIONS.ADD_COL, _this5).call(_this5, sheet, changeset);
                _this5.context.trigger(_sheetIo.CollaborativeEvents.CELL_COORD_CHANGE, {
                    type: 'add',
                    target: {
                        col: target.col,
                        colCount: target.colCount
                    },
                    sheet: sheet
                });
            };
            if (col < target.col) {
                return addCol();
            }
            if (!sheet.isEditing()) {
                addCol();
                sheet.setActiveCell(row, col + target.colCount);
                return;
            }
            var cellType = sheet.getCellType(row, col);
            var value = cellType.getEditorValue(cellType.getEditingElement());
            sheet.endEdit(true);
            addCol();
            sheet.setActiveCell(row, col + target.colCount);
            sheet.startEdit(false, value);
        }
    }, {
        key: 'delRow',

        // [ACTIONS.DEL_ROW]
        value: function delRow(sheet, changeset) {
            var _this6 = this;

            var target = changeset.target;

            var delRow = function delRow() {
                (0, _get3.default)(SheetChangesetExec.prototype.__proto__ || Object.getPrototypeOf(SheetChangesetExec.prototype), _sheetCommon.ACTIONS.DEL_ROW, _this6).call(_this6, sheet, changeset);
                _this6.context.trigger(_sheetIo.CollaborativeEvents.CELL_COORD_CHANGE, {
                    target: {
                        row: target.row,
                        rowCount: target.rowCount
                    },
                    type: 'del',
                    sheet: sheet
                });
            };
            var row = sheet.getActiveRowIndex();
            var col = sheet.getActiveColumnIndex();
            if (row < target.row) {
                return delRow();
            }
            if (!sheet.isEditing()) {
                delRow();
                if (row !== target.row) {
                    sheet.setActiveCell(row - target.rowCount, col);
                }
                return;
            }
            var cellType = sheet.getCellType(row, col);
            var value = cellType.getEditorValue(cellType.getEditingElement());
            sheet.endEdit(true);
            delRow();
            if (row < target.row + target.rowCount) {
                (0, _error.showError)(_error.ErrorTypes.ERROR_CELL_NOT_EXIST, {
                    body: _react2.default.createElement("div", null, _react2.default.createElement("p", null, t('common.cell_has_deleted')), !_browserHelper2.default.mobile ? _react2.default.createElement("p", null, t('sheet.current_content'), value) : null)
                });
            } else {
                sheet.setActiveCell(row - target.rowCount, col);
                sheet.startEdit(false, value);
            }
        }
    }, {
        key: 'delCol',

        // [ACTIONS.DEL_COL]
        value: function delCol(sheet, changeset) {
            var _this7 = this;

            var target = changeset.target;

            var delCol = function delCol() {
                (0, _get3.default)(SheetChangesetExec.prototype.__proto__ || Object.getPrototypeOf(SheetChangesetExec.prototype), _sheetCommon.ACTIONS.DEL_COL, _this7).call(_this7, sheet, changeset);
                _this7.context.trigger(_sheetIo.CollaborativeEvents.CELL_COORD_CHANGE, {
                    target: {
                        col: target.col,
                        colCount: target.colCount
                    },
                    type: 'del',
                    sheet: sheet
                });
            };
            var row = sheet.getActiveRowIndex();
            var col = sheet.getActiveColumnIndex();
            if (col < target.col) {
                return delCol();
            }
            if (!sheet.isEditing()) {
                delCol();
                if (col !== target.col) {
                    sheet.setActiveCell(row, col - target.colCount);
                }
                return;
            }
            var cellType = sheet.getCellType(row, col);
            var value = cellType.getEditorValue(cellType.getEditingElement());
            sheet.endEdit(true);
            delCol();
            if (col < target.col + target.colCount) {
                (0, _error.showError)(_error.ErrorTypes.ERROR_CELL_NOT_EXIST, {
                    body: _react2.default.createElement("div", null, _react2.default.createElement("p", null, t('common.cell_has_deleted')), !_browserHelper2.default.mobile ? _react2.default.createElement("p", null, t('sheet.current_content'), value) : null)
                });
            } else {
                sheet.setActiveCell(row, col - target.colCount);
                sheet.startEdit(false, value);
            }
        }
    }, {
        key: 'hideRow',

        // [ACTIONS.HIDE_ROW]
        value: function hideRow(sheet, changeset) {
            var _this8 = this;

            var target = changeset.target;

            var row = sheet.getActiveRowIndex();
            var col = sheet.getActiveColumnIndex();
            if (row < target.row) {
                return (0, _get3.default)(SheetChangesetExec.prototype.__proto__ || Object.getPrototypeOf(SheetChangesetExec.prototype), _sheetCommon.ACTIONS.HIDE_ROW, this).call(this, sheet, changeset);
            }
            if (!sheet.isEditing()) {
                (0, _get3.default)(SheetChangesetExec.prototype.__proto__ || Object.getPrototypeOf(SheetChangesetExec.prototype), _sheetCommon.ACTIONS.HIDE_ROW, this).call(this, sheet, changeset);
                if (row === target.row) {
                    sheet.setActiveCell(row + target.rowCount, col);
                }
                return;
            }
            if (row < target.row + target.rowCount) {
                // FIXME: 如果不 setTimeout 的话 trigger event 会被暂停, 执行不了更改提交
                setTimeout(function () {
                    sheet.endEdit(false);
                    sheet.setActiveCell(row + target.rowCount, col);
                    (0, _get3.default)(SheetChangesetExec.prototype.__proto__ || Object.getPrototypeOf(SheetChangesetExec.prototype), _sheetCommon.ACTIONS.HIDE_ROW, _this8).call(_this8, sheet, changeset);
                    (0, _error.showError)(_error.ErrorTypes.ERROR_CELL_NOT_EXIST, {
                        body: _react2.default.createElement("div", null, _react2.default.createElement("p", null, t('common.cell_has_hidden')))
                    });
                }, 0);
                return;
            }
            var cellType = sheet.getCellType(row, col);
            var value = cellType.getEditorValue(cellType.getEditingElement());
            sheet.endEdit(true);
            (0, _get3.default)(SheetChangesetExec.prototype.__proto__ || Object.getPrototypeOf(SheetChangesetExec.prototype), _sheetCommon.ACTIONS.HIDE_ROW, this).call(this, sheet, changeset);
            // FIXME: 有没有更好的方式, 如果没有重新渲染完成计算出来的输入框位置会不对
            setTimeout(function () {
                sheet.setActiveCell(row, col);
                sheet.startEdit(false, value);
            }, 0);
        }
    }, {
        key: 'unhideRow',

        // [ACTIONS.UNHIDE_ROW]
        value: function unhideRow(sheet, changeset) {
            var target = changeset.target;

            var row = sheet.getActiveRowIndex();
            var col = sheet.getActiveColumnIndex();
            if (row < target.row || !sheet.isEditing()) {
                return (0, _get3.default)(SheetChangesetExec.prototype.__proto__ || Object.getPrototypeOf(SheetChangesetExec.prototype), _sheetCommon.ACTIONS.UNHIDE_ROW, this).call(this, sheet, changeset);
            }
            var cellType = sheet.getCellType(row, col);
            var value = cellType.getEditorValue(cellType.getEditingElement());
            sheet.endEdit(true);
            (0, _get3.default)(SheetChangesetExec.prototype.__proto__ || Object.getPrototypeOf(SheetChangesetExec.prototype), _sheetCommon.ACTIONS.UNHIDE_ROW, this).call(this, sheet, changeset);
            // FIXME:
            setTimeout(function () {
                sheet.setActiveCell(row, col);
                sheet.startEdit(false, value);
            }, 0);
        }
    }, {
        key: 'hideCol',

        // [ACTIONS.HIDE_COL]
        value: function hideCol(sheet, changeset) {
            var _this9 = this;

            var target = changeset.target;

            var row = sheet.getActiveRowIndex();
            var col = sheet.getActiveColumnIndex();
            if (col < target.col) {
                return (0, _get3.default)(SheetChangesetExec.prototype.__proto__ || Object.getPrototypeOf(SheetChangesetExec.prototype), _sheetCommon.ACTIONS.HIDE_COL, this).call(this, sheet, changeset);
            }
            if (!sheet.isEditing()) {
                (0, _get3.default)(SheetChangesetExec.prototype.__proto__ || Object.getPrototypeOf(SheetChangesetExec.prototype), _sheetCommon.ACTIONS.HIDE_COL, this).call(this, sheet, changeset);
                if (col === target.col) {
                    sheet.setActiveCell(row, col + target.colCount);
                }
                return;
            }
            if (col < target.col + target.colCount) {
                // FIXME:
                setTimeout(function () {
                    sheet.endEdit(false);
                    (0, _get3.default)(SheetChangesetExec.prototype.__proto__ || Object.getPrototypeOf(SheetChangesetExec.prototype), _sheetCommon.ACTIONS.HIDE_COL, _this9).call(_this9, sheet, changeset);
                    sheet.setActiveCell(row, col + target.colCount);
                    (0, _error.showError)(_error.ErrorTypes.ERROR_CELL_NOT_EXIST, {
                        body: _react2.default.createElement("div", null, _react2.default.createElement("p", null, t('common.cell_has_hidden')))
                    });
                }, 0);
                return;
            }
            var cellType = sheet.getCellType(row, col);
            var value = cellType.getEditorValue(cellType.getEditingElement());
            sheet.endEdit(true);
            (0, _get3.default)(SheetChangesetExec.prototype.__proto__ || Object.getPrototypeOf(SheetChangesetExec.prototype), _sheetCommon.ACTIONS.HIDE_COL, this).call(this, sheet, changeset);
            // FIXME:
            setTimeout(function () {
                sheet.setActiveCell(row, col);
                sheet.startEdit(false, value);
            }, 0);
        }
    }, {
        key: 'unhideCol',

        // [ACTIONS.UNHIDE_COL]
        value: function unhideCol(sheet, changeset) {
            var target = changeset.target;

            var row = sheet.getActiveRowIndex();
            var col = sheet.getActiveColumnIndex();
            if (col < target.col || !sheet.isEditing()) {
                return (0, _get3.default)(SheetChangesetExec.prototype.__proto__ || Object.getPrototypeOf(SheetChangesetExec.prototype), _sheetCommon.ACTIONS.UNHIDE_COL, this).call(this, sheet, changeset);
            }
            var cellType = sheet.getCellType(row, col);
            var value = cellType.getEditorValue(cellType.getEditingElement());
            sheet.endEdit(true);
            (0, _get3.default)(SheetChangesetExec.prototype.__proto__ || Object.getPrototypeOf(SheetChangesetExec.prototype), _sheetCommon.ACTIONS.UNHIDE_COL, this).call(this, sheet, changeset);
            // FIXME:
            setTimeout(function () {
                sheet.setActiveCell(row, col);
                sheet.startEdit(false, value);
            }, 0);
        }
    }, {
        key: 'freezeSheet',

        // [ACTIONS.FREEZE_SHEET]
        value: function freezeSheet(sheet, changeset) {
            // 手机端不显示冻结行，pc变成冻结行后，手机端不要同步，直接return
            if (_browserHelper2.default.mobile) {
                return;
            }
            (0, _get3.default)(SheetChangesetExec.prototype.__proto__ || Object.getPrototypeOf(SheetChangesetExec.prototype), _sheetCommon.ACTIONS.FREEZE_SHEET, this).call(this, sheet, changeset);
        }
    }, {
        key: 'setSheet',

        // [ACTIONS.SET_SHEET]
        value: function setSheet(sheet, changeset, local) {
            var value = changeset.value;

            if (sheet) {
                if (value.property_name === "visibility") {
                    this.setSheet_hidden(sheet, changeset, local);
                } else {
                    (0, _get3.default)(SheetChangesetExec.prototype.__proto__ || Object.getPrototypeOf(SheetChangesetExec.prototype), 'renameSheet', this).call(this, sheet, changeset);
                }
            }
        }
    }, {
        key: 'setSheet_hidden',
        value: function setSheet_hidden(sheet, changeset, local) {
            var _this10 = this;

            var spread = sheet.parent;
            var activeSheet = spread.getActiveSheet();
            var sheetId = sheet.id();
            var hiddenStatus = changeset.value.hidden;
            var triggerSheetChange = function triggerSheetChange() {
                var trigger = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : false;

                (0, _get3.default)(SheetChangesetExec.prototype.__proto__ || Object.getPrototypeOf(SheetChangesetExec.prototype), 'hideSheet', _this10).call(_this10, sheet, changeset);
                var toSheet = void 0;
                var activeIndex = spread.getActiveSheetIndex();
                if (!hiddenStatus && activeIndex < 0) {
                    toSheet = sheet;
                } else {
                    toSheet = spread.getActiveSheet();
                }
                spread.trigger(Events.ActiveSheetChanged, {
                    newSheet: toSheet
                });
            };
            if (local) {
                return triggerSheetChange();
            }
            // 只有当前工作表和别人隐藏的工作表同名的时候才会弹出提醒
            if (activeSheet && activeSheet.id() === sheetId && hiddenStatus) {
                (0, _error.showError)(_error.ErrorTypes.ERROR_SHEET_HID, {
                    onConfirm: function onConfirm() {
                        triggerSheetChange(true);
                    },
                    onCancel: function onCancel() {
                        triggerSheetChange(true);
                    }
                });
            } else {
                triggerSheetChange();
            }
        }
    }, {
        key: 'upgradeSnapshot',

        // [ACTIONS.UPGRADE_SNAPSHOT]
        value: function upgradeSnapshot(spread, changeset, local) {
            if (spread.getSpreadVersion() >= _sheetIo.SNAPSHOT_VERSION.NEW_CALC_ENGINE) {
                return;
            }
            (0, _get3.default)(SheetChangesetExec.prototype.__proto__ || Object.getPrototypeOf(SheetChangesetExec.prototype), 'upgradeSnapshot', this).call(this, spread, changeset, local);
            if (!local) {
                (0, _error.showError)(_error.ErrorTypes.ERROR_SYNC_UPGRADE_SNAPSHOT, {});
            }
        }
    }]);
    return SheetChangesetExec;
}(_sheetCore.BaseChangesetExec);

;
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(25)))

/***/ }),

/***/ 3382:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _engine = __webpack_require__(3383);

Object.defineProperty(exports, 'SheetEngine', {
  enumerable: true,
  get: function get() {
    return _engine.SheetEngine;
  }
});

/***/ }),

/***/ 3383:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.SheetEngine = exports.MISS_VERSION_THRESHOLD = undefined;

var _regenerator = __webpack_require__(12);

var _regenerator2 = _interopRequireDefault(_regenerator);

var _asyncToGenerator2 = __webpack_require__(99);

var _asyncToGenerator3 = _interopRequireDefault(_asyncToGenerator2);

var _classCallCheck2 = __webpack_require__(6);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(7);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(10);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _get2 = __webpack_require__(349);

var _get3 = _interopRequireDefault(_get2);

var _inherits2 = __webpack_require__(11);

var _inherits3 = _interopRequireDefault(_inherits2);

var _typeof2 = __webpack_require__(82);

var _typeof3 = _interopRequireDefault(_typeof2);

var _autobindDecorator = __webpack_require__(3384);

var _autobindDecorator2 = _interopRequireDefault(_autobindDecorator);

var _$moirae = __webpack_require__(449);

var _$moirae2 = _interopRequireDefault(_$moirae);

var _collabQueue = __webpack_require__(1722);

var _sheetIo = __webpack_require__(1621);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var __decorate = undefined && undefined.__decorate || function (decorators, target, key, desc) {
    var c = arguments.length,
        r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc,
        d;
    if ((typeof Reflect === "undefined" ? "undefined" : (0, _typeof3.default)(Reflect)) === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);else for (var i = decorators.length - 1; i >= 0; i--) {
        if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    }return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var MISS_VERSION_THRESHOLD = exports.MISS_VERSION_THRESHOLD = 100;
// let self: SheetEngine;
/**
 * 收集本地产生的Action和接受远端的Changeset
 * 并对它们做follow
 */

var SheetEngine = exports.SheetEngine = function (_Engine) {
    (0, _inherits3.default)(SheetEngine, _Engine);

    function SheetEngine(context, backup) {
        (0, _classCallCheck3.default)(this, SheetEngine);

        var _this = (0, _possibleConstructorReturn3.default)(this, (SheetEngine.__proto__ || Object.getPrototypeOf(SheetEngine)).call(this, context, backup));

        _this.queue = null;
        _this.docRev = 0;
        // TODO: 不知道什么时候会调用
        _this.sendNextChangeset = function (docRev) {
            _this.docRev = docRev;
            _this.sendUserChanges(-1100);
            return new Promise(function (resolve, reject) {
                _this.resolveQueueFn = resolve;
                _this.rejectQueueFn = reject;
            });
        };
        return _this;
    }
    // doc 插 sheet 通过统一 queue 管理发送逻辑


    (0, _createClass3.default)(SheetEngine, [{
        key: "registerCSQueue",
        value: function registerCSQueue(collabQueue) {
            if (!collabQueue || this.queue) return;
            this.queue = {
                type: _collabQueue.ChangeSetType.SHEET,
                sendNextCS: this.sendNextChangeset,
                push: function push() {
                    return collabQueue.push(_collabQueue.ChangeSetType.SHEET);
                }
            };
            collabQueue.registerCSQueue(this.queue);
        }
        // TODO: 不知道什么时候会调用

    }, {
        key: "resolveQueue",
        value: function resolveQueue() {
            if (this.resolveQueueFn) {
                this.resolveQueueFn();
                this.resolveQueueFn = null;
            }
        }
        // TODO: 不知道什么时候会调用

    }, {
        key: "rejectQueue",
        value: function rejectQueue() {
            if (this.rejectQueueFn) {
                this.rejectQueueFn();
                this.rejectQueueFn = null;
            }
        }
    }, {
        key: "onAcceptCommit",
        value: function () {
            var _ref = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee(data) {
                return _regenerator2.default.wrap(function _callee$(_context) {
                    while (1) {
                        switch (_context.prev = _context.next) {
                            case 0:
                                _context.next = 2;
                                return (0, _get3.default)(SheetEngine.prototype.__proto__ || Object.getPrototypeOf(SheetEngine.prototype), "onAcceptCommit", this).call(this, data);

                            case 2:
                                this.resolveQueue();

                            case 3:
                            case "end":
                                return _context.stop();
                        }
                    }
                }, _callee, this);
            }));

            function onAcceptCommit(_x) {
                return _ref.apply(this, arguments);
            }

            return onAcceptCommit;
        }()
    }, {
        key: "onConflict",
        value: function onConflict() {
            (0, _get3.default)(SheetEngine.prototype.__proto__ || Object.getPrototypeOf(SheetEngine.prototype), "onConflict", this).call(this);
            this.rejectQueue();
        }
    }, {
        key: "onCollectUserChangeStart",
        value: function onCollectUserChangeStart(transId, op) {
            _$moirae2.default.teaLog({
                key: 'client_sheet_eng_collect_user_change',
                opLength: op.length,
                transId: transId
            });
            _$moirae2.default.count('ee.docs.sheet.client_sheet_eng_collect_user_change');
        }
    }, {
        key: "onCollectUserChangeBeforeSetLocalActions",
        value: function onCollectUserChangeBeforeSetLocalActions(transId, localActions) {
            // TODO: 补注释
            _$moirae2.default.teaLog({
                key: 'client_sheet_eng_collect_user_change_before_set',
                localActionsLength: localActions.length,
                transId: transId
            });
        }
    }, {
        key: "onCollectUserChangeAfterSetLocalActions",
        value: function onCollectUserChangeAfterSetLocalActions(transId) {
            _$moirae2.default.count('ee.docs.sheet.client_sheet_eng_set_localaction_fin');
        }
    }, {
        key: "onCollectUserChangeEnd",
        value: function onCollectUserChangeEnd(transId) {
            _$moirae2.default.count('ee.docs.sheet.client_sheet_eng_collect_user_change_fin');
        }
    }, {
        key: "onIllegalOpsFound",
        value: function onIllegalOpsFound(transId, illegalOps) {
            _$moirae2.default.teaLog({
                key: 'client_sheet_eng_collect_user_change_illegal',
                illegalOps: illegalOps.length,
                transId: transId
            });
            _$moirae2.default.count('ee.docs.sheet.client_sheet_eng_collect_user_change_illegal');
        }
    }, {
        key: "onSendUserChangeStart",
        value: function onSendUserChangeStart(transId) {
            transId && _$moirae2.default.teaLog({
                key: 'client_sheet_eng_send_user_change',
                ready: !!this.ready,
                network: this.network,
                submittingChangeset: !!this.submittingChangeset,
                localActionsLength: this.localActions.length,
                transId: transId
            });
            transId && _$moirae2.default.count('ee.docs.sheet.client_sheet_eng_send_user_change');
        }
    }, {
        key: "onBeforeSendUserChange",
        value: function onBeforeSendUserChange(transId, changeset) {
            if (this.queue) {
                changeset.doc_rev = this.docRev;
            }
        }
    }, {
        key: "onSendUserChangeEnd",
        value: function onSendUserChangeEnd(transId) {
            transId && _$moirae2.default.teaLog({
                key: 'client_sheet_eng_send_user_change_fin',
                transId: transId
            });
        }
    }, {
        key: "onSetLocalActionEnd",
        value: function onSetLocalActionEnd(transId) {
            transId && _$moirae2.default.teaLog({
                key: 'client_sheet_eng_set_localaction_fin',
                transId: transId
            });
        }
    }, {
        key: "onHandleBackup_LocalAction",
        value: function onHandleBackup_LocalAction(actions) {
            _$moirae2.default.teaLog({
                key: 'file_edit_merge_offline',
                actions_size: actions.length
            });
            _$moirae2.default.count('ee.docs.sheet.file_edit_merge_offline');
        }
    }, {
        key: "onApplyActionsError",
        value: function onApplyActionsError(ex) {
            // Raven上报
            _$moirae2.default.ravenCatch(ex, {
                tags: {
                    scm: JSON.stringify(window.scm),
                    key: 'SHEET_APPLY_ACTION_EX'
                }
            });
        }
    }, {
        key: "onApplyActionsCoreError",
        value: function onApplyActionsCoreError(ex) {
            // Raven上报
            _$moirae2.default.ravenCatch(ex, {
                tags: {
                    scm: JSON.stringify(window.scm),
                    // 双下划线加以区分，莫动
                    key: 'SHEET__APPLY_ACTION_EX'
                }
            });
        }
    }, {
        key: "onForwardChangesetsError",
        value: function onForwardChangesetsError(ex) {
            _$moirae2.default.ravenCatch(ex);
        }
    }, {
        key: "onSetBackupError",
        value: function onSetBackupError(ex) {
            // Raven上报
            _$moirae2.default.ravenCatch(ex, {
                tags: {
                    scm: JSON.stringify(window.scm),
                    key: 'SHEET_SET_BACKUP_EX'
                }
            });
        }
    }, {
        key: "onBeforePageUnload",
        value: function onBeforePageUnload() {
            // 上报
            _$moirae2.default.teaLog({
                key: 'client_sheet_eng_before_unload',
                network: this.network,
                localAction: this.localActions.length,
                submittingCS: !!this.submittingChangeset
            });
        }
    }]);
    return SheetEngine;
}(_sheetIo.Engine);

__decorate([_autobindDecorator2.default], SheetEngine.prototype, "onAcceptCommit", null);
__decorate([_autobindDecorator2.default], SheetEngine.prototype, "onConflict", null);

/***/ }),

/***/ 3385:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _sync = __webpack_require__(3386);

Object.keys(_sync).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function get() {
      return _sync[key];
    }
  });
});

/***/ }),

/***/ 3386:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.SheetSync = undefined;

var _defineProperty2 = __webpack_require__(9);

var _defineProperty3 = _interopRequireDefault(_defineProperty2);

var _regenerator = __webpack_require__(12);

var _regenerator2 = _interopRequireDefault(_regenerator);

var _slicedToArray2 = __webpack_require__(111);

var _slicedToArray3 = _interopRequireDefault(_slicedToArray2);

var _asyncToGenerator2 = __webpack_require__(99);

var _asyncToGenerator3 = _interopRequireDefault(_asyncToGenerator2);

var _classCallCheck2 = __webpack_require__(6);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(7);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(10);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(11);

var _inherits3 = _interopRequireDefault(_inherits2);

var _typeof2 = __webpack_require__(82);

var _typeof3 = _interopRequireDefault(_typeof2);

var _blueimpMd = __webpack_require__(568);

var _blueimpMd2 = _interopRequireDefault(_blueimpMd);

var _io = __webpack_require__(345);

var _sheet = __webpack_require__(745);

var _sync = __webpack_require__(166);

var _$constants = __webpack_require__(5);

var _encryption = __webpack_require__(164);

var _memberHelper = __webpack_require__(766);

var _services = __webpack_require__(776);

var _permissionHelper = __webpack_require__(302);

var _common = __webpack_require__(19);

var _error = __webpack_require__(348);

var _offlineEditHelper = __webpack_require__(220);

var _offline = __webpack_require__(148);

var _performanceLogHelper = __webpack_require__(458);

var _routeHelper = __webpack_require__(67);

var _sheet2 = __webpack_require__(1660);

var _tea = __webpack_require__(42);

var _tea2 = _interopRequireDefault(_tea);

var _$moirae = __webpack_require__(449);

var _$moirae2 = _interopRequireDefault(_$moirae);

var _$store = __webpack_require__(64);

var _$store2 = _interopRequireDefault(_$store);

var _performanceStatisticHelper = __webpack_require__(311);

var _constants = __webpack_require__(5);

var _eventEmitter = __webpack_require__(110);

var _eventEmitter2 = _interopRequireDefault(_eventEmitter);

var _stageTracker = __webpack_require__(1798);

var _lodashDecorators = __webpack_require__(1898);

var _sheetIo = __webpack_require__(1621);

var _domainHelper = __webpack_require__(557);

var _generateHeadersHelper = __webpack_require__(347);

var _apiUrls = __webpack_require__(307);

var _getAllUrlParams = __webpack_require__(231);

var _generateRequestIdHelper = __webpack_require__(457);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var __decorate = undefined && undefined.__decorate || function (decorators, target, key, desc) {
    var c = arguments.length,
        r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc,
        d;
    if ((typeof Reflect === "undefined" ? "undefined" : (0, _typeof3.default)(Reflect)) === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);else for (var i = decorators.length - 1; i >= 0; i--) {
        if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    }return c > 3 && r && Object.defineProperty(target, key, r), r;
};

(0, _sheetIo.setGenerateHeaders)(_generateHeadersHelper.generateHeaders);
var isEmbed = false;
var MOBILE_DEFAULT_ROWS = 50; // 移动端首屏行数
var MOBILE_DEFAULY_COLS = 8; // 移动端首屏列数
/**
 * 封装sheet使用IO的逻辑。
 */

var SheetSync = exports.SheetSync = function (_Sync) {
    (0, _inherits3.default)(SheetSync, _Sync);

    function SheetSync(context, backup) {
        var _this2 = this;

        (0, _classCallCheck3.default)(this, SheetSync);

        var _this = (0, _possibleConstructorReturn3.default)(this, (SheetSync.__proto__ || Object.getPrototypeOf(SheetSync)).call(this, context, (0, _io.IOCreator)().getInstance({}), {
            handleSetUser: _memberHelper.handleSetUser,
            handleUserNewInfo: _memberHelper.handleUserNewInfo,
            handleUserLeave: _memberHelper.handleUserLeave,
            handleResetMembers: _memberHelper.handleResetMembers,
            handleMembersMessage: _memberHelper.handleMembersMessage,
            getSuiteMembers: _memberHelper.getSuiteMembers
        }, _$constants.apiUrls, _domainHelper.PcPrependAPI, backup, { supportOffline: true }));

        _this.messageSendStart = 0;
        _this.logStageMap = {};
        _this.metaData = null;
        _this.handleNewClientVarsData = function () {
            var _ref = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee(message) {
                var data, ungzipWorks;
                return _regenerator2.default.wrap(function _callee$(_context) {
                    while (1) {
                        switch (_context.prev = _context.next) {
                            case 0:
                                // 更新本地缓存
                                if (message.data.type === 'CLIENT_VARS' && !message.data.code) {
                                    if (message.data.fakeCode === _offline.EMPTY_RESULT) {
                                        _$store2.default.dispatch((0, _sheet.setSheetClientVars)({
                                            fakeCode: _offline.EMPTY_RESULT,
                                            type: _offline.CLIENT_VARS,
                                            token: (0, _blueimpMd2.default)(_this.token) || ''
                                        }));
                                    } else if (message.from !== _offline.CACHE) {
                                        _$store2.default.dispatch((0, _sheet.resetSheetClientVars)());
                                        (0, _offlineEditHelper.setData)({
                                            key: _offline.SHEET_CLIENT_VARS,
                                            data: message,
                                            dataType: _offline.DATA_TYEP_MAIN
                                        });
                                    }
                                }
                                data = message.data;
                                ungzipWorks = [];

                                if (data.gzip_snapshot) {
                                    ungzipWorks.push(_this.worker.exec('ungzip', data.gzip_snapshot));
                                }
                                if (data.extra_data) {
                                    data.extra_data.blocks = data.extra_data.blocks || [];
                                    ungzipWorks.push(_this.worker.exec('ungzipBlocks', data.extra_data.blocks, data.version));
                                }
                                Promise.all(ungzipWorks).then(function (result) {
                                    var _result = (0, _slicedToArray3.default)(result, 2),
                                        snapshot = _result[0],
                                        dataTable = _result[1];

                                    if (snapshot) {
                                        data.snapshot = snapshot;
                                    }
                                    if (dataTable && data.extra_data) {
                                        delete data.extra_data.gzip_datatable;
                                        var sheetId = data.extra_data.sheet_id;
                                        data.extra_data.row_count = data.extra_data.blocks.reduce(function (count, block) {
                                            return count + block.row_count;
                                        }, 0);
                                        // sheetId 可能不存在与 snapshot 中
                                        if (snapshot) {
                                            var sheetSnapshot = (0, _sheetIo.getSheetDataById)(sheetId, snapshot);
                                            sheetSnapshot.data = { dataTable: dataTable };
                                        }
                                    }
                                    // 拉取sub blocks
                                    _this.createSubBlockFetcher().loadSplitData({
                                        clientVarsData: data,
                                        sheetIdsToFetch: [],
                                        clientVarsFromCache: false
                                    }, function (msg) {
                                        // do nothing
                                    });
                                }).catch(function (e) {
                                    //
                                });

                            case 6:
                            case "end":
                                return _context.stop();
                        }
                    }
                }, _callee, _this2);
            }));

            return function (_x) {
                return _ref.apply(this, arguments);
            };
        }();
        isEmbed = context.isEmbed();
        backup.setLogger(_$moirae2.default);
        return _this;
    }

    (0, _createClass3.default)(SheetSync, [{
        key: "syncMemberBaseRev",
        value: function syncMemberBaseRev(revision) {
            var _this3 = this;

            this.io.syncMemberBaseRev({ token: this.token, type: this.suite }, revision).then(function (ret) {
                if (!ret) return;
                var nextVersion = ret.nextVersion;
                // 人数超过50人（非精确，用unique有性能瓶颈），就延后到心跳去拉
                // 避免出现极端情况，把后台拉挂
                var members = _this3.memberHelper.getSuiteMembers(_this3.suite, _this3.token);
                if (revision > nextVersion && members.length < 150) {
                    _this3.reFetchRoomMembers();
                }
            });
        }
    }, {
        key: "getIsEditable",
        value: function getIsEditable(permissions) {
            if (permissions) {
                return (0, _permissionHelper.getIsEditable)(permissions);
            } else {
                var state = _$store2.default.getState();
                if (state && (0, _sheet2.editablePermissionSelector)(state)) {
                    return true;
                } else {
                    return false;
                }
            }
        }
    }, {
        key: "onHandleNewChangesEnd",
        value: function onHandleNewChangesEnd() {
            // 更新本地clientVars缓存
            this.updateClientVarsCache();
        }
    }, {
        key: "updateClientVarsCache",
        value: function updateClientVarsCache() {
            var _this4 = this;

            var url = _apiUrls.POST_RCE_MESSAGE + "?member_id=" + this.io.getMemberId();
            var payload = {
                type: this.suite,
                data: {
                    member_id: this.io.getMemberId(),
                    user_ticket: this.io.getTicket(),
                    base_rev: 0,
                    extra_data: {
                        row: 0,
                        row_count: MOBILE_DEFAULT_ROWS,
                        col: 0,
                        col_count: MOBILE_DEFAULY_COLS,
                        sheet_id: ''
                    },
                    version: _sheetIo.DATA_VERSION.NODE,
                    type: _sheetIo.MessageTypes.CLIENT_VARS,
                    token: this.token,
                    open_type: parseInt((0, _getAllUrlParams.getAllUrlParams)(location.href)['open_type'] || 0, 10)
                },
                version: 2,
                req_id: 2
            };
            var config = {
                key: _offline.SHEET_CLIENT_VARS,
                headers: (0, _defineProperty3.default)({
                    'Content-Type': 'application/json',
                    'Request-Id': (0, _generateRequestIdHelper.generateRequestId)()
                }, _sheetIo.X_COMMAND, _sheetIo.API_SHEET_RCE_MESSAGE),
                readStore: false,
                noStore: true
            };
            var req = this.postRequest(url, payload, config);
            req.promise.then(function (message) {
                if (message && message.code === 0 && message.data && message.data.code === 0 && message.token === _this4.token) {
                    return message;
                } else {
                    throw message;
                }
            }).catch(function (ex) {
                // 不处理获取失败，仅仅做打点上报
                console.info('[SHEET LOG] update native cache: fetch clientVars failed', ex);
            }).then(this.handleNewClientVarsData);
        }
    }, {
        key: "postRequest",
        value: function postRequest(url, data, config) {
            var promise = (0, _offlineEditHelper.fetch)(url, Object.assign({
                method: 'POST',
                body: data,
                noStore: true
            }, config, {
                serverFirst: isEmbed
            }));
            return {
                promise: promise,
                source: promise
            };
        }
    }, {
        key: "getRequest",
        value: function getRequest(url, config) {
            var param = config ? config.params : {};
            var key = config ? config.key : '';
            var promise = (0, _offlineEditHelper.fetch)(url, {
                method: 'GET',
                body: param,
                serverFirst: isEmbed,
                readStore: config.readStore,
                key: key
            });
            return {
                promise: promise,
                source: promise
            };
        }
    }, {
        key: "onChannelOnline",
        value: function onChannelOnline() {
            _$store2.default.dispatch((0, _sheet.channelOnline)());
        }
    }, {
        key: "onChannelOffline",
        value: function onChannelOffline() {
            _$store2.default.dispatch((0, _sheet.channelOffline)());
        }
    }, {
        key: "onSubmitChangesetStart",
        value: function onSubmitChangesetStart(transId, cs) {
            transId && _$moirae2.default.teaLog({
                key: 'client_sheet_sync_submit_cs',
                csLength: cs.content.length,
                baseRev: cs.base_rev,
                transId: transId
            });
        }
    }, {
        key: "onSubmitChangesetEnd",
        value: function onSubmitChangesetEnd(transId) {
            transId && _$moirae2.default.teaLog({
                key: 'client_sheet_sync_submit_cs_fin',
                transId: transId
            });
            transId && _$moirae2.default.count('ee.docs.sheet.client_sheet_sync_submit_cs_fin');
        }
    }, {
        key: "onMonitorChangeset",
        value: function onMonitorChangeset(monitorCount, cs) {
            _$moirae2.default.teaLog({
                key: 'client_sheet_monitor_sending_changset',
                monitorCount: monitorCount,
                token: (0, _blueimpMd2.default)(this.token) || '',
                baseRevision: cs.base_rev
            });
            _$moirae2.default.count('ee.docs.sheet.client_sheet_monitor_sending_chanset');
        }
    }, {
        key: "onClientVarsInvalid",
        value: function onClientVarsInvalid(empty) {
            !empty && _$moirae2.default.count('ee.docs.sheet.clientvars_invalid');
        }
    }, {
        key: "onHandleClientVarsStart",
        value: function onHandleClientVarsStart(message) {
            !this.logStageMap[_stageTracker.LogStage.UNGZIP_CLIENT_VARS] && (0, _stageTracker.stageTracker)(_stageTracker.LogStage.UNGZIP_CLIENT_VARS, _stageTracker.LogStatus.START);
            // 权限信息
            _$store2.default.dispatch((0, _sheet.setSheetPermissions)(message.data.permissions));
            if (message.data.type === 'CLIENT_VARS' && !message.data.code) {
                if (message.data.fakeCode === _offline.EMPTY_RESULT) {
                    _$store2.default.dispatch((0, _sheet.setSheetClientVars)({
                        fakeCode: _offline.EMPTY_RESULT,
                        type: _offline.CLIENT_VARS,
                        token: (0, _blueimpMd2.default)(this.token) || ''
                    }));
                } else if (message.from !== _offline.CACHE) {
                    _$store2.default.dispatch((0, _sheet.resetSheetClientVars)());
                    (0, _offlineEditHelper.setData)({
                        key: _offline.SHEET_CLIENT_VARS,
                        data: message,
                        dataType: _offline.DATA_TYEP_MAIN
                    });
                }
                // native日志和tea上报
                if (!isEmbed) {
                    _performanceStatisticHelper.REPORTDATA[this.token] = {
                        clientvar_from: message.from,
                        file_type: 'sheet',
                        sheet_count: message.data.snapshot && message.data.snapshot.sheetCount
                    };
                    _eventEmitter2.default.trigger(_constants.events.MOBILE.DOCS.Statistics.fetchClientVarsEnd, [{
                        fetchClientVarsTime: 1,
                        docs_result_code: 0,
                        docs_result_key: 'other'
                    }]);
                }
            } else if (message.data.type === 'ERROR' && !isEmbed) {
                _eventEmitter2.default.trigger(_constants.events.MOBILE.DOCS.Statistics.fetchClientVarsEnd, [{
                    fetchClientVarsTime: 1,
                    docs_result_code: message.data.code,
                    docs_result_key: 'pull_data'
                }]);
            }
        }
    }, {
        key: "onHandleClientVarsEnd",
        value: function onHandleClientVarsEnd(message) {
            !this.logStageMap[_stageTracker.LogStage.UNGZIP_CLIENT_VARS] && (0, _stageTracker.stageTracker)(_stageTracker.LogStage.UNGZIP_CLIENT_VARS, _stageTracker.LogStatus.END);
            this.logStageMap[_stageTracker.LogStage.UNGZIP_CLIENT_VARS] = true; // 已打点
            return;
        }
    }, {
        key: "onHandleClientVarsFail",
        value: function onHandleClientVarsFail(ex) {
            !this.logStageMap[_stageTracker.LogStage.UNGZIP_CLIENT_VARS] && (0, _stageTracker.stageTracker)(_stageTracker.LogStage.UNGZIP_CLIENT_VARS, _stageTracker.LogStatus.ERROR);
            this.logStageMap[_stageTracker.LogStage.UNGZIP_CLIENT_VARS] = true; // 已打点
            return;
        }
    }, {
        key: "onFetchSplitDataStart",
        value: function onFetchSplitDataStart() {
            !this.logStageMap[_stageTracker.LogStage.FETCH_SUB_BLOCK] && (0, _stageTracker.stageTracker)(_stageTracker.LogStage.FETCH_SUB_BLOCK, _stageTracker.LogStatus.START);
            return;
        }
    }, {
        key: "onHandleMessageFromServerStart",
        value: function onHandleMessageFromServerStart(message) {
            return;
        }
    }, {
        key: "onHandleMessageFromServerEnd",
        value: function onHandleMessageFromServerEnd(message) {
            return;
        }
    }, {
        key: "onHandleMessageFromServerError",
        value: function onHandleMessageFromServerError(ex) {
            return;
        }
    }, {
        key: "onSplitDataHandlerMeta",
        value: function onSplitDataHandlerMeta(data) {
            this.metaData = data;
        }
    }, {
        key: "onSplitDataHandlerRows",
        value: function onSplitDataHandlerRows(data) {
            _$store2.default.dispatch((0, _sheet.loadRowData)(data.sheetId, data.row));
        }
    }, {
        key: "onSplitDataHandlerComplete",
        value: function onSplitDataHandlerComplete(data) {
            !this.logStageMap[_stageTracker.LogStage.FETCH_SUB_BLOCK] && (0, _stageTracker.stageTracker)(_stageTracker.LogStage.FETCH_SUB_BLOCK, _stageTracker.LogStatus.END);
            this.logStageMap[_stageTracker.LogStage.FETCH_SUB_BLOCK] = true; // 已打点
            _$moirae2.default.mean('ee.docs.sheet.split_data.load_succ', 1);
            if (this.metaData) {
                var _metaData = this.metaData,
                    sheetId = _metaData.sheetId,
                    rowCount = _metaData.rowCount,
                    snapshot = _metaData.snapshot;

                this.metaData && _$store2.default.dispatch((0, _sheet.snapshotMeta)(sheetId, rowCount, snapshot));
            }
            _$store2.default.dispatch((0, _sheet.snapshotLoaded)());
        }
    }, {
        key: "onSplitDataHandlerError",
        value: function onSplitDataHandlerError(msg, errCode, from) {
            !this.logStageMap[_stageTracker.LogStage.FETCH_SUB_BLOCK] && (0, _stageTracker.stageTracker)(_stageTracker.LogStage.FETCH_SUB_BLOCK, _stageTracker.LogStatus.ERROR);
            this.logStageMap[_stageTracker.LogStage.FETCH_SUB_BLOCK] = true; // 已打点
            _$moirae2.default.mean('ee.docs.sheet.split_data.load_succ', 0);
        }
    }, {
        key: "onSheetNotInClientVars",
        value: function onSheetNotInClientVars(sheetIdList) {
            _$moirae2.default.ravenCatch('sheet not in clientvars', {
                tags: {
                    scm: JSON.stringify(window.scm),
                    key: 'EMBEDSHEET_NOT_IN_CLIENTVARS'
                }
            });
            _$moirae2.default.count('ee.docs.sheet.embedsheet_not_in_clientvars');
        }
    }, {
        key: "onFetchSheetSplitData",
        value: function onFetchSheetSplitData() {
            _$store2.default.dispatch((0, _sheet.snapshotLoading)());
        }
    }, {
        key: "onTriggerSpreadLoaded",
        value: function onTriggerSpreadLoaded() {
            return;
        }
    }, {
        key: "onSendRecover",
        value: function onSendRecover() {
            return;
        }
    }, {
        key: "onSendRecoverError",
        value: function onSendRecoverError(ex) {
            _$moirae2.default.ravenCatch(ex);
        }
    }, {
        key: "onHighCSSucc",
        value: function onHighCSSucc(e) {
            if (e.retryCount) {
                _$moirae2.default.teaLog({
                    key: 'client_sheet_high_priority_retry_succ',
                    retryCount: e.retryCount
                });
                _$moirae2.default.count('ee.docs.sheet.client_sheet_high_priority_retry_succ');
            }
        }
    }, {
        key: "onHighCSFail",
        value: function onHighCSFail(ex) {
            _$moirae2.default.teaLog({
                key: 'client_sheet_high_priority_failed',
                retryCount: ex.retryCount || 0,
                code: ex.code || '',
                message: ex.message || ''
            });
            _$moirae2.default.count('ee.docs.sheet.client_sheet_high_priority_failed');
        }
    }, {
        key: "onSendMessageStart",
        value: function onSendMessageStart() {
            this.messageSendStart = Date.now();
        }
    }, {
        key: "onSendMessageFail",
        value: function onSendMessageFail(transId, data, retryCount) {
            transId && _$moirae2.default.teaLog({
                key: 'client_sheet_sendmessage_fail',
                network: this.network,
                token: (0, _blueimpMd2.default)(this.token) || '',
                type: data.type,
                length: data.content && data.content.length || 0 || 0,
                retryCount: retryCount,
                transId: transId
            });
            transId && _$moirae2.default.count('ee.docs.sheet.client_sheet_sendmessage_fail');
        }
    }, {
        key: "onSendMessageSucc",
        value: function onSendMessageSucc(transId, changeset) {
            // if (changeset) {
            //   EventEmitter.emit(events.MOBILE.SHEET.SEND_CHANGESET_SUCC, changeset);
            // }
            var messageCostTime = Date.now() - this.messageSendStart;
            if (messageCostTime < 1000) {
                _$moirae2.default.mean('ee.docs.sheet.client_sheet_message_speed', messageCostTime);
            }
            transId && _$moirae2.default.count('ee.docs.sheet.client_sheet_sendmessage_succ');
        }
    }, {
        key: "onSendMessageLockFailed",
        value: function onSendMessageLockFailed(transId) {
            transId && _$moirae2.default.teaLog({
                key: 'client_sheet_sendmessage_fail_1015',
                transId: transId
            });
            transId && _$moirae2.default.count('ee.docs.sheet.client_sheet_sendmessage_fail_1015');
        }
    }, {
        key: "onSendUserChangeStart",
        value: function onSendUserChangeStart() {
            return;
        }
    }, {
        key: "onSendUserChangeEnd",
        value: function onSendUserChangeEnd(tranId, changeset) {
            if (changeset) {
                _eventEmitter2.default.emit(_constants.events.MOBILE.SHEET.SEND_CHANGESET_SUCC, changeset);
            }
            return;
        }
    }, {
        key: "onSendUserChangeFailed",
        value: function onSendUserChangeFailed(transId, changeset) {
            _$moirae2.default.teaLog({
                key: 'client_sheet_send_user_cs_failed',
                transId: transId
            });
            _$moirae2.default.count('ee.docs.sheet.client_sheet_send_user_cs_failed');
        }
    }, {
        key: "onSendUserChangeSucc",
        value: function onSendUserChangeSucc(transId) {
            _$moirae2.default.count('ee.docs.sheet.client_sheet_send_user_cs_succ');
        }
    }, {
        key: "onSendUserChangeInvalid",
        value: function onSendUserChangeInvalid(transId, changeset) {
            if (transId === 0) {
                _$moirae2.default.ravenCatch(new Error('TransId === 0'), {
                    scm: JSON.stringify(window.scm),
                    key: 'SHEET_TRANS_ID_0'
                });
            }
            if (!changeset || !changeset.content || changeset.content.length === 0) {
                _$moirae2.default.count('ee.docs.sheet.client_sheet_sync_send_cs_null');
            }
        }
    }, {
        key: "onSendUserChangeProtobuf",
        value: function onSendUserChangeProtobuf(transId) {
            transId && (0, _tea2.default)('client_file_edit', {
                file_type: 'sheet',
                file_id: (0, _encryption.encryptTea)(this.token),
                transId: transId
            });
        }
    }, {
        key: "onSendUserChangeProtobufFailed",
        value: function onSendUserChangeProtobufFailed(transId, ex) {
            _$moirae2.default.ravenCatch(ex);
            _$moirae2.default.teaLog({
                key: 'client_sheet_worker_failed',
                msg: ex.message,
                transId: transId
            });
            _$moirae2.default.count('ee.docs.sheet.client_sheet_worker_failed');
        }
    }, {
        key: "onSendUserChangeLogicFailed",
        value: function onSendUserChangeLogicFailed(transId) {
            _$moirae2.default.teaLog({
                key: 'client_sheet_sendmessage_logic_fail',
                transId: transId
            });
            _$moirae2.default.count('ee.docs.sheet.client_sheet_send_user_cs_logic_fail');
        }
    }, {
        key: "onFetchMissVersion",
        value: function onFetchMissVersion(isOverSize, versionTobeFetch) {
            var suffix = isOverSize ? '_overSize' : '';
            var rptFetchMissVersion = "client_sheet_fetch_miss_version" + suffix;
            _$moirae2.default.teaLog({
                key: rptFetchMissVersion,
                versionTobeFetch: versionTobeFetch.join('_')
            });
        }
    }, {
        key: "onFetchMissVersionFail",
        value: function onFetchMissVersionFail(ex) {
            _$moirae2.default.ravenCatch(ex);
        }
    }, {
        key: "onFetchMissVersionWait",
        value: function onFetchMissVersionWait(isOverSize, versionFetching, versionWait) {
            var suffix = isOverSize ? '_overSize' : '';
            var rptFetchMissVersionWait = "client_sheet_fetch_miss_version_wait" + suffix;
            _$moirae2.default.teaLog({
                key: rptFetchMissVersionWait,
                versionTobeFetch: versionWait.join('_'),
                versionFetching: versionFetching.join('_')
            });
            _$moirae2.default.count("ee.docs.sheet." + rptFetchMissVersionWait);
        }
    }, {
        key: "onFetchClientVarsStart",
        value: function onFetchClientVarsStart() {
            !this.logStageMap[_stageTracker.LogStage.FETCH_CLIENT_VARS] && (0, _stageTracker.stageTracker)(_stageTracker.LogStage.FETCH_CLIENT_VARS, _stageTracker.LogStatus.START);
            if (!isEmbed) {
                _eventEmitter2.default.trigger(_constants.events.MOBILE.DOCS.Statistics.fetchClientVarsStart, [{ file_type: 'sheet' }]);
            }
        }
    }, {
        key: "onFetchClientVarsSucc",
        value: function onFetchClientVarsSucc() {
            !this.logStageMap[_stageTracker.LogStage.FETCH_CLIENT_VARS] && (0, _stageTracker.stageTracker)(_stageTracker.LogStage.FETCH_CLIENT_VARS, _stageTracker.LogStatus.END);
            this.logStageMap[_stageTracker.LogStage.FETCH_CLIENT_VARS] = true; // 已打点
            _$moirae2.default.count('ee.docs.sheet.fetch_client_vars_succ');
            // 如果成功请求，不用关心此服务此前的状态, 直接清除不可用标记. added by liaowenhao.
            _$store2.default.dispatch((0, _services.clearFailedServices)([_common.NUM_FILE_TYPE.SHEET]));
        }
    }, {
        key: "onFetchClientVarsFailed",
        value: function onFetchClientVarsFailed(e, errCode, requestId) {
            !this.logStageMap[_stageTracker.LogStage.FETCH_CLIENT_VARS] && (0, _stageTracker.stageTracker)(_stageTracker.LogStage.FETCH_CLIENT_VARS, _stageTracker.LogStatus.ERROR);
            this.logStageMap[_stageTracker.LogStage.FETCH_CLIENT_VARS] = true; // 已打点
            _$moirae2.default.count('ee.docs.sheet.fetch_client_vars_failed');
            try {
                (0, _performanceLogHelper.transformPerformanceData)({
                    url: "" + _$constants.apiUrls.POST_RCE_MESSAGE,
                    data: {
                        code: errCode,
                        data: {
                            type: 'CLIENT_VARS'
                        },
                        request_id: requestId
                    }
                });
            } catch (error) {
                // Raven上报
                _$moirae2.default.ravenCatch(error);
            }
            // 非超时错误，标记该服务不可用. added by liaowenhao.
            if (errCode !== _error.STATUS_CODE.TIMEOUT) {
                _$store2.default.dispatch((0, _services.setFailedServices)([_common.NUM_FILE_TYPE.SHEET]));
            }
            // Raven上报
            _$moirae2.default.ravenCatch(e, {
                tags: {
                    scm: JSON.stringify(window.scm),
                    key: 'FETCH_CLIENT_VARS_ERROR'
                }
            });
        }
    }, {
        key: "onVersionTooOld",
        value: function onVersionTooOld() {
            _$moirae2.default.count('ee.docs.sheet.refetch_client_vars');
        }
    }, {
        key: "onReFetchRoomMembers",
        value: function onReFetchRoomMembers() {
            return;
        }
    }, {
        key: "onReFetchRoomMembersFailed",
        value: function onReFetchRoomMembersFailed() {
            (0, _tea2.default)('reFetchRoomMembers error');
        }
    }, {
        key: "onConnect",
        value: function onConnect() {
            this.metaData = null;
            return;
        }
    }, {
        key: "onDisConnect",
        value: function onDisConnect() {
            return;
        }
    }, {
        key: "isSheetRoute",
        value: function isSheetRoute() {
            return (0, _routeHelper.locateRoute)().isSheet;
        }
    }, {
        key: "getPermissionHBOption",
        value: function getPermissionHBOption() {
            return (0, _sync.getHeartbeatsOption)();
        }
    }, {
        key: "onServerMsgSyncPerf",
        value: function onServerMsgSyncPerf(cost) {
            _$moirae2.default.mean('ee.docs.sheet.message_sync_cost', cost);
        }
    }]);
    return SheetSync;
}(_sheetIo.Sync);

__decorate([(0, _lodashDecorators.Debounce)(5000)], SheetSync.prototype, "updateClientVarsCache", null);

/***/ }),

/***/ 3456:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});

var _radio = __webpack_require__(3457);

var _radio2 = _interopRequireDefault(_radio);

exports.showExpandSortModal = showExpandSortModal;

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _modal = __webpack_require__(1897);

__webpack_require__(3466);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function showExpandSortModal() {
    var defaultExpand = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : true;

    var radioStyle = {
        display: 'block',
        color: '#182333',
        fontSize: '14px',
        height: '28px',
        lineHeight: '28px'
    };
    return new Promise(function (resolve) {
        var shouldExpand = defaultExpand;
        (0, _modal.showModal)({
            title: t('sheet.tips.sort_warning'),
            body: _react2.default.createElement("div", { style: {
                    fontSize: '14px',
                    color: '#667080'
                } }, _react2.default.createElement("p", null, t('sheet.tips.sort_warning_no_sort')), _react2.default.createElement("p", null, t('sheet.tips.what_do_you_want')), _react2.default.createElement(_radio2.default.Group, { prefixCls: "cp-radio", onChange: function onChange(e) {
                    shouldExpand = e.target.value;
                }, defaultValue: shouldExpand }, _react2.default.createElement(_radio2.default, { prefixCls: "cp-radio", style: radioStyle, value: true }, t('sheet.expand_selection')), _react2.default.createElement(_radio2.default, { prefixCls: "cp-radio", style: radioStyle, value: false }, t('sheet.use_current_selection')))),
            closable: true,
            maskClosable: false,
            cancelText: t('common.cancel'),
            confirmText: t('common.determine'),
            onConfirm: function onConfirm() {
                resolve({
                    confirm: true,
                    shouldExpand: shouldExpand
                });
            },
            onCancel: function onCancel() {
                resolve({
                    confirm: false,
                    shouldExpand: shouldExpand
                });
            }
        });
    });
}
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(25)))

/***/ }),

/***/ 3466:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3467:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.SheetStatusCollector = undefined;

var _SheetStatusCollector = __webpack_require__(3468);

var _SheetStatusCollector2 = _interopRequireDefault(_SheetStatusCollector);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.SheetStatusCollector = _SheetStatusCollector2.default;

/***/ }),

/***/ 3468:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.default = undefined;

var _classCallCheck2 = __webpack_require__(6);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(7);

var _createClass3 = _interopRequireDefault(_createClass2);

var _sheetCommon = __webpack_require__(1591);

var _sheet = __webpack_require__(745);

var _toolbarHelper = __webpack_require__(1800);

var toolbarHelper = _interopRequireWildcard(_toolbarHelper);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var SheetStatusCollector = function () {
    function SheetStatusCollector(_store) {
        var _this = this;

        (0, _classCallCheck3.default)(this, SheetStatusCollector);

        this._status = null;
        this._updateStatus = null;
        this._store = _store;
        this._unsubscribe = this._store.subscribe(function () {
            _this._status = _store.getState().sheet.status;
        });
    }
    /**
     * 其实没有太大必要，在切换 SpreadSheet 的时候，collaSpread 是会被销毁的额。
     */


    (0, _createClass3.default)(SheetStatusCollector, [{
        key: 'setSpread',
        value: function setSpread(spread) {
            if (spread === this._spread) return;
            this.unbindEvents(this._spread);
            this._spread = spread;
            this.bindEvents(spread);
        }
    }, {
        key: 'destroy',
        value: function destroy() {
            this._unsubscribe();
            this.unbindEvents(this._spread);
        }
    }, {
        key: 'getBindList',
        value: function getBindList() {
            return [_sheetCommon.Events.CommandExecuted, _sheetCommon.Events.SelectionChanged, _sheetCommon.Events.DragDropBlockCompleted, _sheetCommon.Events.ClipboardPasted, _sheetCommon.Events.ActiveSheetChanged];
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
        key: 'updateSheetStatus',
        value: function updateSheetStatus(arg) {
            this._store.dispatch((0, _sheet.updateSheetStatus)(arg));
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
            this.updateSheetStatus({
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
            if (!this._status) return true;
            var emptySheet = !spread || !spread.getActiveSheet();
            if (emptySheet && this._status.emptySheet !== emptySheet) {
                this.updateSheetStatus({ emptySheet: true });
            }
            return emptySheet;
        }
    }]);
    return SheetStatusCollector;
}();

exports.default = SheetStatusCollector;

/***/ }),

/***/ 3469:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.MobileStorage = undefined;

var _regenerator = __webpack_require__(12);

var _regenerator2 = _interopRequireDefault(_regenerator);

var _asyncToGenerator2 = __webpack_require__(99);

var _asyncToGenerator3 = _interopRequireDefault(_asyncToGenerator2);

var _classCallCheck2 = __webpack_require__(6);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(7);

var _createClass3 = _interopRequireDefault(_createClass2);

var _offlineStorageHelper = __webpack_require__(313);

var _sheetIo = __webpack_require__(1621);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var MobileStorage = exports.MobileStorage = function () {
    function MobileStorage() {
        (0, _classCallCheck3.default)(this, MobileStorage);
    }

    (0, _createClass3.default)(MobileStorage, null, [{
        key: 'getItem',
        value: function () {
            var _ref = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee(key, opts) {
                var _ref2, data;

                return _regenerator2.default.wrap(function _callee$(_context) {
                    while (1) {
                        switch (_context.prev = _context.next) {
                            case 0:
                                _context.prev = 0;
                                _context.next = 3;
                                return (0, _offlineStorageHelper.getData)(Object.assign({ key: key }, opts || {}));

                            case 3:
                                _ref2 = _context.sent;
                                data = _ref2.data;
                                return _context.abrupt('return', data);

                            case 8:
                                _context.prev = 8;
                                _context.t0 = _context['catch'](0);
                                return _context.abrupt('return', null);

                            case 11:
                            case 'end':
                                return _context.stop();
                        }
                    }
                }, _callee, this, [[0, 8]]);
            }));

            function getItem(_x, _x2) {
                return _ref.apply(this, arguments);
            }

            return getItem;
        }()
    }, {
        key: 'setItem',
        value: function setItem(key, data, opts) {
            this.itemMaps[key] = true;
            return (0, _offlineStorageHelper.setData)(Object.assign({ key: key, data: data }, opts || {}));
        }
    }, {
        key: 'removeItem',
        value: function removeItem(key, opts) {
            delete this.itemMaps[key];
            return (0, _offlineStorageHelper.setData)(Object.assign({ key: key, data: null }, opts || {}));
        }
    }, {
        key: 'drive',
        value: function drive() {
            return 'nativeCache';
        }
        // 从客户端获取当前 spread 的全部相关缓存

    }, {
        key: 'getAllStorage',
        value: function getAllStorage(spread) {
            var _spread$_context = spread._context,
                token = _spread$_context.token,
                userId = _spread$_context.userId;

            var keys = ['actions', 'submit', 'follow', 'records', 'rev', 'backuping'].map(function (item) {
                return 'sheet.bu.' + item + '.' + token + '.' + userId + '.0';
            });
            var keyPairs = {};
            Promise.all(keys.map(function (item) {
                return MobileStorage.getItem(item);
            })).then(function (resList) {
                resList.forEach(function (res, idx) {
                    keyPairs[keys[idx]] = res;
                });
                return keyPairs;
            }).then(function (pairs) {
                console.table(pairs);
                return pairs;
            });
        }
    }]);
    return MobileStorage;
}();

MobileStorage.itemMaps = {};
MobileStorage.backupType = _sheetIo.BackupType;
// 添加到 Windows，便于快速访问
window.MobileStorage = MobileStorage;

/***/ }),

/***/ 3470:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3471:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3472:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.default = ExecOnlyActiveSheet;

var _suiteHelper = __webpack_require__(52);

/**
 * 注意!!!!!!!
 * 1. 该装饰器只能用于嵌入 sheet。
 * 2. 改装饰器无需用于 native 的回调函数，因为其本身就只会调用一次。
 * 3. 被该装饰器装饰的函数在 componentWillUnmount 钩子里执行可能会报错，因为此时已经没有 activeSheet 了。
 */
function ExecOnlyActiveSheet(options) {
    return function (target, propertyKey, descriptor) {
        if (!descriptor) {
            throw new TypeError('descriptor is undefined.');
        }
        var originalFn = void 0;
        if (descriptor.get) {
            originalFn = descriptor.get();
            if (typeof originalFn !== 'function') {
                throw SyntaxError('@ExecOnlyActiveSheet can only be used on functions, not ' + originalFn + '.');
            }
            descriptor.get = function () {
                return ExecOnlyActiveSheetCore.call(this, originalFn, options);
            };
        } else if (descriptor.value) {
            originalFn = descriptor.value;
            if (typeof originalFn !== 'function') {
                throw SyntaxError('@ExecOnlyActiveSheet can only be used on functions, not ' + originalFn + '.');
            }
            descriptor.value = function () {
                for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
                    args[_key] = arguments[_key];
                }

                return ExecOnlyActiveSheetCore.call(this, originalFn, options).apply(this, args);
            };
        } else {
            throw new TypeError('descriptor.get and descriptor.value cannot be undefined.');
        }
    };
}
function ExecOnlyActiveSheetCore(originalFn, options) {
    var _this = this;

    if (!options) {
        options = {
            execWithoutSpread: false,
            execWithoutActiveSheet: false,
            doNotThrowErrorWithoutSpread: false,
            doNotThrowErrorWithoutActiveSheet: false
        };
    }
    var _options = options,
        execWithoutSpread = _options.execWithoutSpread,
        execWithoutActiveSheet = _options.execWithoutActiveSheet,
        doNotThrowErrorWithoutSpread = _options.doNotThrowErrorWithoutSpread,
        doNotThrowErrorWithoutActiveSheet = _options.doNotThrowErrorWithoutActiveSheet;

    return function () {
        for (var _len2 = arguments.length, args = Array(_len2), _key2 = 0; _key2 < _len2; _key2++) {
            args[_key2] = arguments[_key2];
        }

        if ((0, _suiteHelper.suiteType)() !== 'doc') {
            return originalFn.apply(_this, args);
        }
        if (_this.props) {
            var spread = _this.props.spread || _this.props.collaSpread.spread;
            if (spread) {
                var activeSheet = typeof spread.getActiveSheet === 'function' && spread.getActiveSheet();
                if (activeSheet) {
                    var sheetId = _this.props.sheetId;

                    if (!sheetId) {
                        console.error('The component\'s props "sheetId" could not be undefined.');
                    }
                    if (activeSheet.id() === sheetId) {
                        return originalFn.apply(_this, args);
                    }
                } else if (execWithoutActiveSheet) {
                    return originalFn.apply(_this, args);
                } else if (!doNotThrowErrorWithoutActiveSheet) {
                    console.error('The component\'s props "spread" doesn\'t have an activeSheet.');
                }
            } else if (execWithoutSpread) {
                return originalFn.apply(_this, args);
            } else if (!doNotThrowErrorWithoutSpread) {
                console.error('The component\'s props "spread" could not be undefined.');
            }
        }
    };
}

/***/ }),

/***/ 3473:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.MentionNotificationQueue = undefined;

var _toConsumableArray2 = __webpack_require__(58);

var _toConsumableArray3 = _interopRequireDefault(_toConsumableArray2);

var _regenerator = __webpack_require__(12);

var _regenerator2 = _interopRequireDefault(_regenerator);

var _asyncToGenerator2 = __webpack_require__(99);

var _asyncToGenerator3 = _interopRequireDefault(_asyncToGenerator2);

var _classCallCheck2 = __webpack_require__(6);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(7);

var _createClass3 = _interopRequireDefault(_createClass2);

var _defineProperty2 = __webpack_require__(9);

var _defineProperty3 = _interopRequireDefault(_defineProperty2);

var _notifiers;

var _const = __webpack_require__(742);

var _security = __webpack_require__(452);

var _apis = __webpack_require__(1664);

var _utils = __webpack_require__(1631);

var _bytedXEditor = __webpack_require__(299);

var _$store = __webpack_require__(64);

var _$store2 = _interopRequireDefault(_$store);

var _uniq = __webpack_require__(1849);

var _uniq2 = _interopRequireDefault(_uniq);

var _string = __webpack_require__(163);

var _sharingConfirmationHelper = __webpack_require__(2140);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var AUTHORIZE = 1111; // 授权阅读权限
var notifiers = (_notifiers = {}, (0, _defineProperty3.default)(_notifiers, _const.TYPE_ENUM.USER, _apis.notifyAdd), (0, _defineProperty3.default)(_notifiers, _const.TYPE_ENUM.GROUP, _apis.notifyGroup), (0, _defineProperty3.default)(_notifiers, AUTHORIZE, _apis.authorizePermission), _notifiers);
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
        this.users = [];
        this.groups = [];
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
            var cell = param.cell;
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
                var spread = window.spread;
                var activeSheet = spread ? spread.getActiveSheet() : null;
                // 如果不是独立SHEET，则走旧接口，独立SHEET走新结构体，以支持定位
                if (source !== _const.SOURCE_ENUM.SHEET_COMMENT || !activeSheet) {
                    this.addUserMention(toUsers, source);
                } else {
                    // 用于独立SHEET定位使用的MentionKeyId
                    var mentionKeyId = (0, _string.generateRandomString)(16);
                    // 使用全局变量进行传递
                    // TODO: 需要更改
                    window.sheetMentionKeyId = mentionKeyId;
                    // row 和 col 不一定是当前活动的单元格
                    this.addUserMentionV2(toUsers, {
                        type: 'comment_mention',
                        sheet_id: activeSheet.id(),
                        key_id: mentionKeyId,
                        row: cell && cell.row.toString(),
                        col: cell && cell.col.toString()
                    });
                }
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
    }, {
        key: 'addAuthorizePermission',
        value: function addAuthorizePermission(fileType, fileId, owners, needNotifyLark, source) {
            if (!owners || owners.length <= 0) return;
            this.queue.push({
                type: AUTHORIZE,
                config: {
                    fileType: fileType,
                    fileId: fileId,
                    needNotifyLark: needNotifyLark,
                    owners: JSON.stringify(owners),
                    source: source
                }
            });
        }
    }, {
        key: 'addUserMentionV2',
        value: function addUserMentionV2(toUsers, query) {
            var _this2 = this;

            if (toUsers.length === 0) {
                return;
            }
            toUsers.forEach(function (item) {
                _this2.users.push({
                    id: item,
                    query: query
                });
            });
        }
    }, {
        key: 'addGroupMentionV2',
        value: function addGroupMentionV2(toGroup, query) {
            var _this3 = this;

            if (toGroup.length === 0) {
                return;
            }
            toGroup.forEach(function (item) {
                _this3.groups.push({
                    id: item,
                    query: query
                });
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
         * 等注册的 confirmation 出结果再发通知
         */

    }, {
        key: 'sendMentionNotifications2',
        value: function () {
            var _ref4 = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee3(source) {
                var decisions, shareInfo, groups, users, queue, promises;
                return _regenerator2.default.wrap(function _callee3$(_context3) {
                    while (1) {
                        switch (_context3.prev = _context3.next) {
                            case 0:
                                // 等待用户决定完（等8秒或点击撤销）
                                decisions = [].concat((0, _toConsumableArray3.default)(this.decisionSet));

                                this.decisionSet.clear();
                                _context3.next = 4;
                                return Promise.all(decisions);

                            case 4:
                                // 不需要通知自己
                                shareInfo = this.getShareInfo();

                                this.removeTargetToNotify(shareInfo.userId);
                                groups = [].concat((0, _toConsumableArray3.default)(this.groups));
                                users = [].concat((0, _toConsumableArray3.default)(this.users));

                                if (!(users.length === 0 && groups.length === 0)) {
                                    _context3.next = 10;
                                    break;
                                }

                                return _context3.abrupt('return');

                            case 10:
                                this.groups = [];
                                this.users = [];
                                queue = [].concat((0, _toConsumableArray3.default)(this.queue));

                                this.queue = [];
                                promises = queue.map(function (_ref5) {
                                    var type = _ref5.type,
                                        config = _ref5.config;
                                    return notifiers[type](config);
                                });
                                return _context3.abrupt('return', Promise.all(promises.concat([notifiers[_const.TYPE_ENUM.GROUP]({
                                    source: source,
                                    token: shareInfo.fileToken,
                                    target: _const.TARGET_ENUM.LARK,
                                    entities: {
                                        group_chats: groups,
                                        users: users
                                    }
                                })])));

                            case 16:
                            case 'end':
                                return _context3.stop();
                        }
                    }
                }, _callee3, this);
            }));

            function sendMentionNotifications2(_x5) {
                return _ref4.apply(this, arguments);
            }

            return sendMentionNotifications2;
        }()
        /**
         * 不给指定的人发消息
         */

    }, {
        key: 'removeTargetToNotify',
        value: function removeTargetToNotify(tokenToRm) {
            this.queue = this.queue.reduce(function (newQueue, _ref6) {
                var type = _ref6.type,
                    oldConfig = _ref6.config;

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
                    var groupChats = _config.entities.group_chats.filter(function (_ref7) {
                        var id = _ref7.id;
                        return tokenToRm !== id;
                    });
                    // 还有 group_chats 才留下当前的 notification
                    if (groupChats.length > 0) {
                        _config.entities = Object.assign({}, _config.entities, { group_chats: groupChats });
                        newQueue.push({ type: type, config: _config });
                    }
                } else if (type === AUTHORIZE) {
                    var _config2 = Object.assign({}, oldConfig);
                    // 去掉 group_chats 中需要删除的 tokens
                    var owners = JSON.parse(_config2.owners);
                    owners = owners.filter(function (_ref8) {
                        var owner_id = _ref8.owner_id;
                        return owner_id !== tokenToRm;
                    });
                    if (owners.length > 0) {
                        newQueue.push({ type: type, config: _config2 });
                    }
                } else {
                    /* istanbul ignore next: 正常情况下不应该出现未知的 type */
                    newQueue.push({ type: type, config: oldConfig });
                }
                return newQueue;
            }, []);
            this.users = this.users.filter(function (item) {
                return item.id !== tokenToRm;
            });
            this.groups = this.groups.filter(function (item) {
                return item.id !== tokenToRm;
            });
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

/***/ 3489:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.default = undefined;

var _classCallCheck2 = __webpack_require__(6);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(7);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(10);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(11);

var _inherits3 = _interopRequireDefault(_inherits2);

var _typeof2 = __webpack_require__(82);

var _typeof3 = _interopRequireDefault(_typeof2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _sheetCommon = __webpack_require__(1591);

var _sheetCore = __webpack_require__(1594);

var _tea = __webpack_require__(42);

var _classnames = __webpack_require__(127);

var _classnames2 = _interopRequireDefault(_classnames);

var _$decorators = __webpack_require__(553);

var _toolbarHelper = __webpack_require__(1800);

var toolbarHelper = _interopRequireWildcard(_toolbarHelper);

var _eventEmitter = __webpack_require__(110);

var _eventEmitter2 = _interopRequireDefault(_eventEmitter);

var _plus = __webpack_require__(3490);

var _plus2 = _interopRequireDefault(_plus);

var _minus = __webpack_require__(3491);

var _minus2 = _interopRequireDefault(_minus);

var _sheetShell = __webpack_require__(1713);

__webpack_require__(3492);

var _modalHelper = __webpack_require__(747);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var __decorate = undefined && undefined.__decorate || function (decorators, target, key, desc) {
    var c = arguments.length,
        r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc,
        d;
    if ((typeof Reflect === "undefined" ? "undefined" : (0, _typeof3.default)(Reflect)) === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);else for (var i = decorators.length - 1; i >= 0; i--) {
        if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    }return c > 3 && r && Object.defineProperty(target, key, r), r;
};

var Direction;
(function (Direction) {
    Direction[Direction["Up"] = 0] = "Up";
    Direction[Direction["Down"] = 1] = "Down";
})(Direction || (Direction = {}));
var EVENTS_TO_STOP = ['pointerdown', 'touchstart', 'mousedown'];

var HeaderSelectionBubble = function (_Component) {
    (0, _inherits3.default)(HeaderSelectionBubble, _Component);

    function HeaderSelectionBubble(props) {
        (0, _classCallCheck3.default)(this, HeaderSelectionBubble);

        var _this = (0, _possibleConstructorReturn3.default)(this, (HeaderSelectionBubble.__proto__ || Object.getPrototypeOf(HeaderSelectionBubble)).call(this, props));

        _this.state = {
            isShow: false,
            pos: {
                left: 0,
                right: 0
            },
            type: '',
            selected: -1,
            hideDelete: false
        };
        return _this;
    }

    (0, _createClass3.default)(HeaderSelectionBubble, [{
        key: "componentDidMount",
        value: function componentDidMount() {
            this._bindEvents(this.props.sheet);
        }
    }, {
        key: "componentWillUnmount",
        value: function componentWillUnmount() {
            this._unbind(this.props.sheet);
        }
    }, {
        key: "componentDidUpdate",
        value: function componentDidUpdate(prevProps, prevState) {
            if (prevProps.sheet !== this.props.sheet) {
                this._unbind(prevProps.sheet);
                this._bindEvents(this.props.sheet);
            }
        }
    }, {
        key: "_unbind",
        value: function _unbind(sheet) {
            var _this2 = this;

            if (!sheet) return;
            sheet.unbind(_sheetCommon.Events.SelectionChanged, this._onSelectionChange);
            sheet.unbind(_sheetCommon.Events.LeftPosChanged, this.hide);
            sheet.unbind(_sheetCommon.Events.TopPosChanged, this.hide);
            sheet.unbind(_sheetCommon.Events.LoseFocus, this.hide);
            sheet.unbind(_sheetCommon.Events.HideHeaderBubble, this.hide);
            if (this._wrapDom) {
                EVENTS_TO_STOP.forEach(function (eventName) {
                    _this2._wrapDom.removeEventListener(eventName, _this2._stopPropagation, true);
                });
            }
            var shell = this.props.shell;

            shell && shell.unbind(_sheetShell.ShellEvent.SHEET_VIEW.ZOOM, this.hide);
            _eventEmitter2.default.off('clear_sheet_selection', this.hide);
        }
    }, {
        key: "_bindEvents",
        value: function _bindEvents(sheet) {
            var _this3 = this;

            if (!sheet) return;
            sheet.bind(_sheetCommon.Events.SelectionChanged, this._onSelectionChange);
            sheet.bind(_sheetCommon.Events.LeftPosChanged, this.hide);
            sheet.bind(_sheetCommon.Events.TopPosChanged, this.hide);
            sheet.bind(_sheetCommon.Events.LoseFocus, this.hide);
            sheet.bind(_sheetCommon.Events.HideHeaderBubble, this.hide);
            // 用 react 提供的事件绑定是代理到document的，没办法阻止 spreadsheet 上用类 jQuery 的方式绑定的事件，
            // 这里只能在这里单独在容器上用原生饭方式阻止冒泡
            if (this._wrapDom) {
                EVENTS_TO_STOP.forEach(function (eventName) {
                    _this3._wrapDom.addEventListener(eventName, _this3._stopPropagation, true);
                });
            }
            var shell = this.props.shell;

            shell && shell.bind(_sheetShell.ShellEvent.SHEET_VIEW.ZOOM, this.hide);
            _eventEmitter2.default.on('clear_sheet_selection', this.hide);
        }
    }, {
        key: "_showRowSelected",
        value: function _showRowSelected(row, range) {
            var _props = this.props,
                sheet = _props.sheet,
                shell = _props.shell;

            if (!sheet || !shell) return;
            var sheetView = shell.sheetView();
            var rect = sheetView.getContentBounds();
            var table = sheetView.detectTableByCell(row, 0);
            var layout = table.range2ViewRect(range);
            var y = layout.y,
                height = layout.height;

            var hideDelete = sheet.getRowCount() === 1 ? true : false;
            this._showBubble({
                left: rect.x,
                right: sheetView.width,
                top: y + rect.y,
                bottom: y + height
            }, 'row', row, hideDelete);
        }
    }, {
        key: "_getBubblePosByRect",
        value: function _getBubblePosByRect(rect) {
            var _props2 = this.props,
                shell = _props2.shell,
                isEmbed = _props2.isEmbed;

            var _shell$sheetView = shell.sheetView(),
                zoom = _shell$sheetView.zoom;

            var BUBBLE_HEIGHT = 32;
            var SPACE_HEIGHT = 14;
            var left = (rect.left + rect.right) / 2 * zoom;
            var top = void 0;
            var direction = void 0;
            if (!isEmbed && rect.top < SPACE_HEIGHT + BUBBLE_HEIGHT) {
                top = rect.bottom * zoom + SPACE_HEIGHT;
                direction = Direction.Down;
            } else {
                top = rect.top * zoom - SPACE_HEIGHT - BUBBLE_HEIGHT;
                direction = Direction.Up;
            }
            var pos = { top: top, left: left };
            return { pos: pos, direction: direction };
        }
    }, {
        key: "_showBubble",
        value: function _showBubble(rect, type, num) {
            var hideDelete = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : false;

            var _getBubblePosByRect2 = this._getBubblePosByRect(rect),
                pos = _getBubblePosByRect2.pos,
                direction = _getBubblePosByRect2.direction;

            this.setState({
                isShow: true,
                pos: pos,
                type: type,
                selected: num,
                direction: direction,
                hideDelete: hideDelete
            });
        }
    }, {
        key: "_showColSelected",
        value: function _showColSelected(col, range) {
            var _props3 = this.props,
                sheet = _props3.sheet,
                shell = _props3.shell;

            if (!sheet || !shell) return;
            var sheetView = shell.sheetView();
            var table = sheetView.detectTableByCell(col, 0);
            var layout = table.range2ViewRect(range);
            var rect = sheetView.getContentBounds();
            var x = layout.x,
                width = layout.width;

            var y = 0;
            var height = rect.y;
            var hideDelete = sheet.getColumnCount() === 1 ? true : false;
            this._showBubble({
                left: x + rect.x,
                right: x + width + rect.x,
                top: y,
                bottom: y + height
            }, 'col', col, hideDelete);
        }
    }, {
        key: "hide",
        value: function hide() {
            this.setState({
                isShow: false,
                type: '',
                selected: 0
            });
        }
    }, {
        key: "_onSelectionChange",
        value: function _onSelectionChange(data) {
            var _this4 = this;

            var sheet = this.props.sheet;

            var selections = sheet.getSelections();
            if (selections && selections.length > 0) {
                var range = selections[0];
                if (range instanceof _sheetCore.RowRange) {
                    this._showRowSelected(range.rowFrom(), range);
                } else if (range instanceof _sheetCore.ColumnRange) {
                    var col = range.colFrom();
                    sheet._scrollToCol(col);
                    // 先 scroll 过去才显示
                    setTimeout(function () {
                        _this4._showColSelected(col, range);
                    });
                } else {
                    this.hide();
                }
            } else {
                this.hide();
            }
        }
    }, {
        key: "_setRowAndColAction",
        value: function _setRowAndColAction(params) {
            toolbarHelper.setRowColChange(this.props.sheet, params);
        }
    }, {
        key: "_checkRowAndColLocked",
        value: function _checkRowAndColLocked() {
            if (this.state.type === 'col' && this.props.isChangeColLocked) {
                return false;
            }
            if (this.state.type === 'row' && this.props.isChangeRowLocked) {
                return false;
            }
            return true;
        }
    }, {
        key: "_handleAdd",
        value: function _handleAdd(e) {
            if (!this._checkRowAndColLocked()) {
                (0, _modalHelper.showAlert)(t('common.oops'), t('sheet.protection.cannot_start_edit'));
                (0, _tea.collectSuiteEvent)('sheet_opration', {
                    action: 'protect_range_remind'
                });
                return;
            }
            var _state = this.state,
                type = _state.type,
                selected = _state.selected;

            var sheet = this.props.sheet;
            var range = sheet.getSelections()[0];
            var count = type === 'col' ? range.colCount() : range.rowCount();
            if (count === 0 || type === 'col' && sheet.getColumnCount() === range.colFrom() || type === 'row' && sheet.getRowCount() === range.rowFrom()) return this.hide();
            if (type) {
                (0, _tea.collectSuiteEvent)('sheet_opration', {
                    action: type === 'col' ? 'add_col_right' : 'add_row_down'
                });
                this._setRowAndColAction({
                    type: type === 'col' ? 'col' : 'row',
                    method: 'add',
                    source: selected,
                    target: selected + 1,
                    count: count
                });
                (0, _tea.collectSuiteEvent)('click_add_sheet_range', {
                    add_range_direction: type === 'col' ? 'right' : 'down',
                    range_type: type,
                    range_num: 1,
                    source: 'range_head'
                });
            }
        }
    }, {
        key: "_handleDelete",
        value: function _handleDelete() {
            if (!this._checkRowAndColLocked()) {
                (0, _modalHelper.showAlert)(t('common.oops'), t('sheet.protection.cannot_start_edit'));
                (0, _tea.collectSuiteEvent)('sheet_opration', {
                    action: 'protect_range_remind'
                });
                return;
            }
            var _state2 = this.state,
                type = _state2.type,
                selected = _state2.selected;

            var sheet = this.props.sheet;
            // 删除前先结束编辑
            sheet && sheet.editor && sheet.editor.endEdit(true, false);
            var range = sheet.getSelections()[0];
            var count = type === 'col' ? range.colCount() : range.rowCount();
            if (count === 0 || type === 'col' && sheet.getColumnCount() === range.colFrom() || type === 'row' && sheet.getRowCount() === range.rowFrom()) return this.hide();
            // 如果只有一行 / 一列，不执行删除
            if (type === 'col' && sheet.getColumnCount() === 1 || type === 'row' && sheet.getRowCount() === 1) {
                return;
            }
            if (type) {
                (0, _tea.collectSuiteEvent)('sheet_opration', {
                    action: type === 'col' ? 'del_col' : 'del_row'
                });
                this._setRowAndColAction({
                    type: type === 'col' ? 'col' : 'row',
                    method: 'del',
                    target: selected,
                    count: count
                });
            }
            var newRange = sheet.getSelections()[0];
            if (newRange instanceof _sheetCore.RowRange) {
                var rowCount = sheet.getRowCount();
                if (newRange.rowFrom() === rowCount && rowCount > 0) {
                    sheet.setSelection(new _sheetCore.RowRange(rowCount - 1, 1, sheet));
                }
            } else if (newRange instanceof _sheetCore.ColumnRange) {
                var colCount = sheet.getColumnCount();
                if (newRange.colFrom() === colCount && colCount > 0) {
                    sheet.setSelection(new _sheetCore.ColumnRange(colCount - 1, 1, sheet));
                }
            }
        }
    }, {
        key: "_stopPropagation",
        value: function _stopPropagation(e) {
            e.stopPropagation();
        }
    }, {
        key: "render",
        value: function render() {
            var _this5 = this;

            var _state3 = this.state,
                isShow = _state3.isShow,
                pos = _state3.pos,
                direction = _state3.direction,
                hideDelete = _state3.hideDelete;
            var _props4 = this.props,
                style = _props4.style,
                isLocked = _props4.isLocked;

            return _react2.default.createElement("div", { className: "header-bubble-wrap", style: style, ref: function ref(wrapDom) {
                    return _this5._wrapDom = wrapDom;
                } }, isShow && !isLocked ? _react2.default.createElement("div", { className: (0, _classnames2.default)('header-bubble', {
                    'header-bubble-down': direction === Direction.Down,
                    'header-bubble-up': direction === Direction.Up,
                    'header-bubble-small': hideDelete
                }), style: pos }, !hideDelete && _react2.default.createElement("div", { className: "operation operation-minus", onClick: this._handleDelete }, _react2.default.createElement("div", { className: "operation-icon" }, _react2.default.createElement(_minus2.default, { className: "operation-icon-svg" }))), !hideDelete && _react2.default.createElement("div", { className: "split-line" }), _react2.default.createElement("div", { className: "operation operation-plus", onClick: this._handleAdd }, _react2.default.createElement("div", { className: "operation-icon" }, _react2.default.createElement(_plus2.default, { className: "operation-icon-svg" })))) : null);
        }
    }]);
    return HeaderSelectionBubble;
}(_react.Component);

exports.default = HeaderSelectionBubble;

__decorate([(0, _$decorators.Bind)()], HeaderSelectionBubble.prototype, "_showRowSelected", null);
__decorate([(0, _$decorators.Bind)()], HeaderSelectionBubble.prototype, "_showColSelected", null);
__decorate([(0, _$decorators.Bind)()], HeaderSelectionBubble.prototype, "hide", null);
__decorate([(0, _$decorators.Bind)()], HeaderSelectionBubble.prototype, "_onSelectionChange", null);
__decorate([(0, _$decorators.Bind)()], HeaderSelectionBubble.prototype, "_checkRowAndColLocked", null);
__decorate([(0, _$decorators.Bind)()], HeaderSelectionBubble.prototype, "_handleAdd", null);
__decorate([(0, _$decorators.Bind)()], HeaderSelectionBubble.prototype, "_handleDelete", null);
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(25)))

/***/ }),

/***/ 3490:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(20);

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
    (0, _extends3.default)({ className: styles["icon"] || "icon", viewBox: "0 0 1024 1024", xmlns: "http://www.w3.org/2000/svg", width: "48", height: "48" }, props),
    _react2.default.createElement("defs", null),
    _react2.default.createElement("path", { d: "M980.7 468.45H557.4V45.15a43.35 43.35 0 0 0-86.7 0v423.3H47.4a43.35 43.35 0 0 0 0 86.7h423.3v423.32a43.35 43.35 0 0 0 86.7 0V555.15h423.3a43.35 43.35 0 0 0 0-86.7z", fill: "#fff" })
  );
};

/***/ }),

/***/ 3491:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(20);

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
    (0, _extends3.default)({ className: styles["icon"] || "icon", viewBox: "0 0 1024 1024", xmlns: "http://www.w3.org/2000/svg", width: "48", height: "48" }, props),
    _react2.default.createElement("defs", null),
    _react2.default.createElement("path", { d: "M117.73 458.21h788.48c19.79 0 53.76 24.07 53.76 53.76 0 29.7-33.97 53.76-53.76 53.76H117.73c-19.78 0-53.76-24.06-53.76-53.76 0-29.69 33.98-53.76 53.76-53.76z", fill: "#fff" })
  );
};

/***/ }),

/***/ 3492:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3497:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ })

}]);
//# sourceMappingURL=https://s3.pstatp.com/eesz/resource/bear/js/embed-sheet~sheet.783b7e46751cc533a660.js.map