(window["webpackJsonp"] = window["webpackJsonp"] || []).push([[8],{

/***/ 1562:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _container = __webpack_require__(2768);

var _container2 = _interopRequireDefault(_container);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.default = _container2.default;

/***/ }),

/***/ 2768:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _reactRedux = __webpack_require__(238);

var _reactRouterDom = __webpack_require__(278);

var _sheet = __webpack_require__(2769);

var _sheet2 = _interopRequireDefault(_sheet);

var _suite = __webpack_require__(241);

var _sheet3 = __webpack_require__(715);

var _suite2 = __webpack_require__(69);

var _network = __webpack_require__(1648);

var _sheet4 = __webpack_require__(1597);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var mapDispatchToProps = {
  fetchMobileCurrentSuite: _suite.fetchMobileCurrentSuite,
  getTokenInfo: _suite.getTokenInfo,
  resetSheetClientVars: _sheet3.resetSheetClientVars
};

var mapStateToProps = function mapStateToProps(state) {
  return {
    curSuiteToken: (0, _suite2.selectCurrentSuiteToken)(state),
    curSuite: (0, _suite2.selectCurrentSuiteByObjToken)(state),
    onLine: (0, _network.selectNetworkState)(state).connected,
    clientVars: (0, _sheet4.selectSheetClientVars)(state)
  };
};

exports.default = (0, _reactRouterDom.withRouter)((0, _reactRedux.connect)(mapStateToProps, mapDispatchToProps)(_sheet2.default));

/***/ }),

/***/ 2769:
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

var _class, _temp2;

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _propTypes = __webpack_require__(0);

var _propTypes2 = _interopRequireDefault(_propTypes);

var _watermark = __webpack_require__(1666);

var _watermark2 = _interopRequireDefault(_watermark);

var _browserHelper = __webpack_require__(34);

var _browserHelper2 = _interopRequireDefault(_browserHelper);

var _common = __webpack_require__(19);

var _app_title = __webpack_require__(1963);

var _header = __webpack_require__(1706);

var _header2 = _interopRequireDefault(_header);

var _file_list_load_error = __webpack_require__(1960);

var _file_list_load_error2 = _interopRequireDefault(_file_list_load_error);

var _modal = __webpack_require__(751);

var _modal2 = _interopRequireDefault(_modal);

var _tips = __webpack_require__(1961);

var _tips2 = _interopRequireDefault(_tips);

var _offline = __webpack_require__(137);

var _suiteHelper = __webpack_require__(60);

var _hideLoadingHelper = __webpack_require__(280);

var _useTemplate = __webpack_require__(1962);

var _useTemplate2 = _interopRequireDefault(_useTemplate);

var _mobile_sheet = __webpack_require__(2770);

var _mobile_sheet2 = _interopRequireDefault(_mobile_sheet);

var _hairlinesHelper = __webpack_require__(1970);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var Sheet = (_temp2 = _class = function (_Component) {
  (0, _inherits3.default)(Sheet, _Component);

  function Sheet() {
    var _ref;

    var _temp, _this, _ret;

    (0, _classCallCheck3.default)(this, Sheet);

    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return _ret = (_temp = (_this = (0, _possibleConstructorReturn3.default)(this, (_ref = Sheet.__proto__ || Object.getPrototypeOf(Sheet)).call.apply(_ref, [this].concat(args))), _this), _this.renderModalContent = function (text) {
      // 离线状态 没有缓存数据
      console.info('Offline, render error modal');
      return _react2.default.createElement(
        _modal2.default,
        {
          className: 'error-modal',
          visible: true
        },
        _react2.default.createElement(_tips2.default, {
          handleClick: _this.refresh,
          imgSrc: _file_list_load_error2.default,
          text: text || t('mobile.error.no_cache_data')
        })
      );
    }, _temp), (0, _possibleConstructorReturn3.default)(_this, _ret);
  }

  (0, _createClass3.default)(Sheet, [{
    key: 'componentDidMount',
    value: function componentDidMount() {
      var _props = this.props,
          curSuiteToken = _props.curSuiteToken,
          fetchMobileCurrentSuite = _props.fetchMobileCurrentSuite;

      fetchMobileCurrentSuite(curSuiteToken, _common.NUM_FILE_TYPE.SHEET);
      if (curSuiteToken && curSuiteToken === (0, _suiteHelper.getToken)()) {
        // 防止上一篇内容未clear完毕
        setTimeout(function () {
          (0, _hideLoadingHelper.hideLoading)();
        }, 0);
      }
    }
  }, {
    key: 'componentWillUnmount',
    value: function componentWillUnmount() {
      this.props.resetSheetClientVars();
    }
  }, {
    key: 'render',
    value: function render() {
      var isBytedanceApp = _browserHelper2.default.isLark || _browserHelper2.default.isDocs;
      var _props2 = this.props,
          curSuiteToken = _props2.curSuiteToken,
          curSuite = _props2.curSuite,
          clientVars = _props2.clientVars,
          onLine = _props2.onLine,
          getTokenInfo = _props2.getTokenInfo;


      if (!onLine && clientVars && clientVars.fakeCode === _offline.EMPTY_RESULT) {
        return this.renderModalContent();
      }

      return _react2.default.createElement(
        'div',
        { className: 'flex layout-column ' + ((0, _hairlinesHelper.addHairline)() ? ' hairlines' : '') },
        _react2.default.createElement(_watermark2.default, { platform: 'mobile' }),
        isBytedanceApp && _react2.default.createElement(_app_title.AppTitle, { defaultName: t('common.unnamed_sheet') }),
        isBytedanceApp && _react2.default.createElement(_header2.default, {
          currentNote: curSuite,
          onLine: onLine,
          getTokenInfo: getTokenInfo,
          isTemplate: false
        }),
        _react2.default.createElement(_mobile_sheet2.default, null),
        _react2.default.createElement(_useTemplate2.default, { curSuiteToken: curSuiteToken })
      );
    }
  }]);
  return Sheet;
}(_react.Component), _class.propTypes = {
  curSuiteToken: _propTypes2.default.string,
  curSuite: _propTypes2.default.object,
  fetchMobileCurrentSuite: _propTypes2.default.func,
  onLine: _propTypes2.default.bool,
  getTokenInfo: _propTypes2.default.func,
  clientVars: _propTypes2.default.object,
  resetSheetClientVars: _propTypes2.default.func
}, _temp2);
exports.default = Sheet;
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 2770:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _mobile_sheet = __webpack_require__(2771);

var _mobile_sheet2 = _interopRequireDefault(_mobile_sheet);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.default = _mobile_sheet2.default;

/***/ }),

/***/ 2771:
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

var _each2 = __webpack_require__(1723);

var _each3 = _interopRequireDefault(_each2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _redux = __webpack_require__(65);

var _reactRedux = __webpack_require__(238);

var _reactRouterDom = __webpack_require__(278);

var _sheet = __webpack_require__(713);

var _collaborative_spread = __webpack_require__(1971);

var _collaborative = __webpack_require__(1607);

var _core = __webpack_require__(1573);

var _constants = __webpack_require__(1614);

var _Spread = __webpack_require__(1802);

var _engine = __webpack_require__(2025);

var _status = __webpack_require__(2948);

var _sync = __webpack_require__(2027);

var _Mention = __webpack_require__(1805);

var _Mention2 = _interopRequireDefault(_Mention);

var _hyperlink = __webpack_require__(2030);

var _hyperlink2 = _interopRequireDefault(_hyperlink);

var _comment = __webpack_require__(2031);

var _comment2 = _interopRequireDefault(_comment);

var _tabs = __webpack_require__(2032);

var _headerSelectionBubble = __webpack_require__(2033);

var _headerSelectionBubble2 = _interopRequireDefault(_headerSelectionBubble);

var _sdkCompatibleHelper = __webpack_require__(82);

var _sheet2 = __webpack_require__(1597);

var _suiteHelper = __webpack_require__(60);

var _ui_sheet = __webpack_require__(1807);

var _tool = __webpack_require__(1583);

var _ContextMenu = __webpack_require__(2040);

var _ContextMenu2 = _interopRequireDefault(_ContextMenu);

var _OldContextMenu = __webpack_require__(2991);

var _OldContextMenu2 = _interopRequireDefault(_OldContextMenu);

var _browserHelper = __webpack_require__(34);

var _browserHelper2 = _interopRequireDefault(_browserHelper);

var _modal = __webpack_require__(1623);

var _share = __webpack_require__(62);

var _suite = __webpack_require__(69);

var _sheet3 = __webpack_require__(715);

var _spin = __webpack_require__(1811);

var _toast = __webpack_require__(500);

var _toast2 = _interopRequireDefault(_toast);

var _toastHelper = __webpack_require__(381);

var _zoom_tips = __webpack_require__(3000);

var _zoom_tips2 = _interopRequireDefault(_zoom_tips);

var _utils = __webpack_require__(1575);

var _eventEmitter = __webpack_require__(272);

var _eventEmitter2 = _interopRequireDefault(_eventEmitter);

var _$constants = __webpack_require__(4);

var _share2 = __webpack_require__(375);

var _common = __webpack_require__(19);

var _urlHelper = __webpack_require__(184);

var _shellNotify = __webpack_require__(1576);

var _tea = __webpack_require__(47);

__webpack_require__(2041);

var _emptySheet = __webpack_require__(3004);

var _emptySheet2 = _interopRequireDefault(_emptySheet);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function getSheetIdFromLocation(location) {
    return location.hash && location.hash.substring(1) || '';
}
var _GC$Spread$Sheets = GC.Spread.Sheets,
    HorizontalPosition = _GC$Spread$Sheets.HorizontalPosition,
    VerticalPosition = _GC$Spread$Sheets.VerticalPosition;

var SHEET_TAB_HEIGHT = 44;
var IPHONEX_SAFE_HEIGHT = 34;
var OFFLINE_TOAST_KEY = '__OFFLINE_TOAST__';
var SHEET_PAGE_HEIGHT = _browserHelper2.default.isIphoneX ? 'calc(100vh - 34px)' : '100vh';

var MobileSheet = function (_PureComponent) {
    (0, _inherits3.default)(MobileSheet, _PureComponent);

    function MobileSheet(props) {
        (0, _classCallCheck3.default)(this, MobileSheet);

        var _this = (0, _possibleConstructorReturn3.default)(this, (MobileSheet.__proto__ || Object.getPrototypeOf(MobileSheet)).call(this, props));

        _this.findMention = function (mentionKeyId, sheetId, row, col) {
            if (_this._collaSpread.spreadLoaded !== true) {
                window.setTimeout(function () {
                    _this.findMention(mentionKeyId, sheetId, row, col);
                }, 500);
                return;
            }
            var targetCol = -1;
            var targetRow = -1;
            var spread = _this._collaSpread.spread;
            var targetSheet = spread.getSheetFromId(sheetId);
            if (!targetSheet) {
                (0, _toastHelper.showToast)({
                    type: 1,
                    message: t('error.sheet_mention_delete'),
                    duration: 3
                });
                return;
            }
            if (targetSheet.getHiddenStatus()) {
                // 被隐藏
                (0, _toastHelper.showToast)({
                    type: 1,
                    message: t('sheet.had.been.hidden'),
                    duration: 3
                });
                return;
            }
            var founded = false;
            var dataTable = targetSheet._dataModel.dataTable;
            if (dataTable && dataTable[row] && dataTable[row][col]) {
                var directSearchArea = dataTable[row][col];
                if (directSearchArea && directSearchArea.segmentArray) {
                    var segArr = directSearchArea.segmentArray;
                    (0, _each3.default)(segArr, function (sItem) {
                        if (sItem.mentionKeyId && sItem.mentionKeyId === mentionKeyId) {
                            targetCol = parseInt(col, 10);
                            targetRow = parseInt(row, 10);
                            founded = true;
                        }
                    });
                }
            }
            if (!founded) {
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
                                if (sItem.mentionKeyId && sItem.mentionKeyId === mentionKeyId) {
                                    targetCol = parseInt(colKey, 10);
                                    targetRow = parseInt(rowKey, 10);
                                    founded = true;
                                }
                            });
                        }
                    });
                });
            }
            if (founded) {
                spread.setActiveSheet(targetSheet.name(), true);
                targetSheet.setActiveCell(targetRow, targetCol);
                // 先激活才行
                _this._collaSpread.context.trigger(_collaborative.CollaborativeEvents.WAKEUP, sheetId);
                _this._showCellTimer && window.clearTimeout(_this._showCellTimer);
                _this._showCellTimer = window.setTimeout(function () {
                    targetSheet._highlightCells = targetSheet._highlightCells || new Map();
                    targetSheet._highlightCells.set(targetRow + '_' + targetCol, 1);
                    var activeSheet = spread.getActiveSheet();
                    var spans = activeSheet._getSpanModel();
                    var span = spans.find(targetRow, targetCol);
                    if (span) {
                        targetRow += span.rowCount - 1;
                        targetCol += span.colCount - 1;
                    }
                    targetSheet.showCell(targetRow, targetCol, VerticalPosition.center, HorizontalPosition.center);
                    targetSheet.notifyShell(_shellNotify.ShellNotifyType.SearchChanged);
                }, 200);
                var deleteHighCell = function deleteHighCell() {
                    targetSheet._highlightCells = null;
                    targetSheet.notifyShell(_shellNotify.ShellNotifyType.SearchChanged);
                };
                setTimeout(function () {
                    deleteHighCell();
                }, 2200);
            } else {
                (0, _toastHelper.showToast)({
                    type: 1,
                    message: t('error.sheet_mention_delete'),
                    duration: 3
                });
            }
        };
        _this.collectMoveToNextRow = function (e) {
            if (e.detail.editState === 1) {
                (0, _tea.collectSuiteEvent)('click_sheet_edit_action', { sheet_edit_action_type: 'click_keyboard_next_row' });
            }
        };
        _this.handleStartEdit = function (e) {
            // 第一次启动交由keyboardchange handler处理, 后面的回车换单元格才这里处理
            if (!_this._resizedWindowHeight) return;
            _this.showActiveCell(_this._resizedWindowHeight);
        };
        _this.handleKeyboardChanged = function (e) {
            if (e.isOpenKeyboard) {
                _this._resizedWindowHeight = e.innerHeight;
                _this.showActiveCell(e.innerHeight);
            } else {
                _this._resizedWindowHeight = 0;
                _this.restoreFaster();
            }
        };
        _this.showActiveCell = function (windowHeight) {
            var activeSheet = _this._collaSpread.getActiveSheet();
            if (!activeSheet) return;
            var col = activeSheet.getActiveColumnIndex();
            var row = activeSheet.getActiveRowIndex();
            _this.showCell(row, col, windowHeight);
        };
        _this.showCell = function (row, col, windowHeight) {
            // 此时表格高度已经resize过了
            if (_this._shell.ui().height === windowHeight) {
                _this.scrollActiveCellIntoView(row, col, 20);
            } else {
                // 滚个键盘高度或者是评论卡片高度，如果滚不动了，那就只能resize了
                if (!_this.scrollActiveCellIntoView(row, col, 0, _this._getFullPageHeight() - windowHeight)) {
                    !_this._listenedFasterResize && _this._shell.ui().addListener(_core.FEventType.AfterFlush, _this.handleFasterResize);
                    _this._listenedFasterResize = true;
                    _this.resizeFaster(windowHeight);
                }
            }
        };
        _this.handleCommentCardWillShow = function () {
            // 因为评论卡片展示会隐藏title bar，高度变化，需要记录正常的window height
            if (!_this._normalWindowHeight) {
                _this._normalWindowHeight = window.innerHeight;
            }
        };
        _this.handleCommentCardWillHide = function () {
            if (!_this._normalWindowHeight) return;
            var restoreHeight = _this._normalWindowHeight - SHEET_TAB_HEIGHT;
            if (_browserHelper2.default.isIphoneX) {
                restoreHeight -= IPHONEX_SAFE_HEIGHT;
            }
            _this.restoreFaster(restoreHeight);
            _this._normalWindowHeight = 0;
        };
        _this.handleFasterResize = function (e) {
            var changes = e.changes;

            if (changes.height && changes.height.before !== changes.height.current) {
                var activeSheet = _this._collaSpread.getActiveSheet();
                if (!activeSheet) return false;
                var col = activeSheet.getActiveColumnIndex();
                var row = activeSheet.getActiveRowIndex();
                _this.scrollActiveCellIntoView(row, col, 20);
            }
            return false;
        };
        _this.onCellPress = function (type, info) {
            var row = info.row,
                col = info.col;
            var spread = _this._collaSpread.spread;

            var activeSheet = spread.getActiveSheet();
            if (!activeSheet) return;
            var selectionModel = activeSheet.getSelections()[0];
            if (!(selectionModel && selectionModel.contains(row, col, 1, 1))) {
                activeSheet.setActiveCell(row, col);
            }
        };
        _this.onActiveSheetChanged = function (e, args) {
            if (args.newSheet) {
                var id = args.newSheet.id();
                if (id !== _this.props.sheetId) {
                    _this._setLocationSheetId(id);
                }
                args.newSheet.setSheetHost(_this._fasterDom);
                args.newSheet.unpreventFocusCanvas();
                _this._shell.updateSheet(args.newSheet);
            }
        };
        _this._setLocationSheetId = function (id) {
            var replace = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : false;

            _this.props.history.replace({
                hash: id,
                search: location.search
            });
        };
        _this.onClientVars = function () {
            _this.setState({
                loading: false
            });
            _this.freezeSheet(false);
            (0, _modal.removeSpreadToast)();
            var spread = _this._collaSpread.spread;

            spread.sheets.forEach(function (sheet) {
                sheet.frozenRowCount(0);
                sheet.frozenColumnCount(0);
            });
            _this.setActiveSheetId(_this.props.sheetId);
            var activeSheet = _this._collaSpread.getActiveSheet();
            activeSheet.setSheetHost(_this._fasterDom);
            activeSheet.unpreventFocusCanvas();
            _tool._FocusHelper._setActiveElement(activeSheet, true);
            _this._shell.updateSheet(activeSheet);
            _this._shell.exec();
            _this.resizeFaster();
        };
        _this.refetchClientVars = function () {
            _this.setState({
                loading: true
            });
            _this.freezeSheet(true);
            (0, _modal.showSpreadErrorToast)(t('sheet.syncing'));
        };
        _this.onChannelStateChange = function (data) {
            if (data.channelState === 'online') {
                _this.freezeSheet(false);
                _this.setState({
                    isOnline: true
                });
                _toast2.default.remove(OFFLINE_TOAST_KEY);
            } else if (data.channelState === 'offline') {
                _this.freezeSheet(true);
                _this.setState({
                    isOnline: false
                });
            }
        };
        _this.onError = function (data) {
            _this.freezeSheet(true);
            _this.setState({
                loading: false
            });
            // 无权限不弹窗，使用docs权限申请页面
            if (data.code + '' === _constants.Errors.ERR_FORBIDDEN) {
                return;
            }
            (0, _modal.showServerErrorModal)(data.code, 'mobile_sheet');
        };
        /**
         * 本地冲突
         */
        _this.onConflict = function () {
            _this.freezeSheet(true);
            (0, _modal.showError)(_modal.ErrorTypes.ERROR_ACTION_CONFLICT, {
                onConfirm: function onConfirm() {
                    _this._context.trigger(_collaborative.CollaborativeEvents.CONFLICT_HANDLE);
                }
            });
        };
        _this.freezeSpread = function () {
            _this.freezeSheet(true);
            (0, _modal.showSpreadErrorToast)(t('sheet.forzen_refresh'));
        };
        _this.setFasterCanvas = function (spreadDom) {
            _this._fasterDom = spreadDom;
        };
        _this.handleDoubleClick = (0, _utils.clickToDbClick)(function (e) {
            var activeSheet = _this._collaSpread.getActiveSheet();
            if (activeSheet && !activeSheet.isEditing()) {
                activeSheet.startEdit();
            }
        }, _sheet.Timeout.dblClickEdit);
        _this.resizeFaster = function (innerHeight) {
            var height = void 0;
            if (innerHeight) {
                height = innerHeight;
            } else {
                height = _this._getFullPageHeight() - SHEET_TAB_HEIGHT;
            }
            var width = _this._fasterDom.clientWidth;
            var ui = _this._shell && _this._shell.ui();
            ui && ui.updateByCfg({ width: width, height: height });
            var sheetView = _this._shell.sheetView();
            sheetView && sheetView.resolveSize();
        };
        var context = _this._context = new _collaborative.CollaborativeContext();
        _this._collaSpread = new _collaborative_spread.CollaborativeSpread(context, {
            showResizeTip: GC.Spread.Sheets.ShowResizeTip.none
        });
        _this.state = {
            isOnline: true,
            loading: true,
            allSheetHidden: false
        };
        _Spread.Spread.sync = _this._sync = new _sync.Sync(context);
        _Spread.Spread.engine = _this._engine = new _engine.Engine(context);
        _Spread.Spread.status = new _status.Status(_this._sync, _this._engine);
        _this._resizedWindowHeight = 0;
        _this._listenedFasterResize = false;
        if (_sdkCompatibleHelper.isSupportSheetContextMenu) {
            window.lark.biz.selection.longPressSelect = function (x, y) {
                _eventEmitter2.default.emit(_$constants.events.MOBILE.CONTEXT_MENU.showSheetContextMenu, x, y);
            };
        }
        return _this;
    }

    (0, _createClass3.default)(MobileSheet, [{
        key: 'componentDidMount',
        value: function componentDidMount() {
            var _this2 = this;

            // 监听键盘弹起和收起
            window.lark.biz.util.onKeyboardChanged(this.handleKeyboardChanged);
            window.addEventListener('sheet:mobile:startEdit', this.handleStartEdit);
            window.addEventListener('docsdk:sheet:updateEdit', this.collectMoveToNextRow);
            var editable = this.props.editable;
            var _props = this.props,
                currentNoteToken = _props.currentNoteToken,
                fetchSuitePublicPermission = _props.fetchSuitePublicPermission,
                fetchUserPermissionOnSuite = _props.fetchUserPermissionOnSuite;

            var suiteType = (0, _suiteHelper.suiteTypeNum)();
            if (currentNoteToken) {
                fetchUserPermissionOnSuite(currentNoteToken, suiteType);
                fetchSuitePublicPermission(currentNoteToken, suiteType);
            }
            this.setEditable(editable);
            var spread = this._collaSpread.spread;

            _Spread.Spread.spread = spread;
            this.switch(this.props.token);
            this._mention = new _Mention2.default({
                spread: spread,
                context: this._context,
                container: this._workbookContainer,
                getCanvasBoundingRect: function getCanvasBoundingRect() {
                    return _this2._fasterDom.getBoundingClientRect();
                }
            });
            this._hyperlink = new _hyperlink2.default({
                spread: spread
            });
            this.createShell(this._fasterDom);
            this._fasterDom.addEventListener('click', this.handleDoubleClick);
            var query = (0, _urlHelper.parseQuery)(window.location.href);
            // 如果URL中有Mention，则代表需要进行AT查找
            if (query && query.type === 'mention') {
                this.findMention(query['key_id'], query['sheet_id'], query.row, query.col);
            }
        }
    }, {
        key: 'createShell',
        value: function createShell(container) {
            this._shell = new _ui_sheet.SheetShell(container, this._collaSpread.spread, this._context);
        }
    }, {
        key: 'componentWillUpdate',
        value: function componentWillUpdate(nextProps) {
            // 切换了文档
            if (nextProps.token !== this.props.token) {
                if (this.props.token) {
                    this.reset();
                }
                this.switch(nextProps.token);
            }
        }
    }, {
        key: 'componentDidUpdate',
        value: function componentDidUpdate(prevProps) {
            var props = this.props;
            // this.freezeSheet(true);
            if (prevProps.sheetId !== this.props.sheetId) {
                this.setActiveSheetId(this.props.sheetId);
            }
            if (prevProps.editable !== props.editable) {
                this.setEditable(props.editable);
            }
        }
    }, {
        key: 'setEditable',
        value: function setEditable(editable) {
            if (!(0, _sdkCompatibleHelper.isSupportSheetEditor)()) {
                this._collaSpread.setEditable(false);
                this._shell && this._shell.setEditable(false);
            } else {
                this._collaSpread.setEditable(editable);
                this._shell && this._shell.setEditable(editable);
            }
        }
    }, {
        key: 'restoreFaster',
        value: function restoreFaster(height) {
            this._listenedFasterResize && this._shell.ui().removeListener(_core.FEventType.AfterFlush, this.handleFasterResize);
            this._listenedFasterResize = false;
            this.resizeFaster(height);
        }
    }, {
        key: 'scrollActiveCellIntoView',
        value: function scrollActiveCellIntoView(row, col) {
            var padding = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : 0;
            var offset = arguments[3];

            var sheetView = this._shell.sheetView();
            return sheetView.scrollCellToPos(row, col, padding, offset);
        }
    }, {
        key: 'componentWillUnmount',
        value: function componentWillUnmount() {
            window.removeEventListener('sheet:mobile:startEdit', this.handleStartEdit);
            window.removeEventListener('docsdk:sheet:updateEdit', this.collectMoveToNextRow);
            this._fasterDom.removeEventListener('click', this.handleDoubleClick);
            // 清理打点上报相关数据
            _eventEmitter2.default.trigger(_$constants.events.MOBILE.DOCS.Statistics.fetchClientVarDelete, [this.props.token]);
            this.reset();
            _toast2.default.remove(OFFLINE_TOAST_KEY);
            this._collaSpread.destroy();
            this._mention.destory();
            this._hyperlink && this._hyperlink.destory();
            _Spread.Spread.spread = _Spread.Spread.engine = _Spread.Spread.sync = null;
            this._shell && this._shell.exit();
        }
    }, {
        key: 'setActiveSheetId',
        value: function setActiveSheetId(sheetId) {
            var spread = this._collaSpread.spread;

            if (!spread || !spread.sheets || spread.sheets.length <= 0) return;
            var sheets = spread.sheets;
            var activeSheet = null;
            var toastText = '';
            var getNextUnhideSheet = function getNextUnhideSheet() {
                var index = spread.pickUnhidSheetIndex(0);
                return index > -1 ? sheets[index] : null;
            };
            if (!sheetId) {
                activeSheet = getNextUnhideSheet();
            } else {
                activeSheet = spread.getSheetFromId(sheetId);
                if (!activeSheet) {
                    activeSheet = getNextUnhideSheet();
                } else if (activeSheet.getHiddenStatus()) {
                    // 提示被隐藏，切换下一张
                    toastText = t('sheet.had.been.hidden');
                    activeSheet = getNextUnhideSheet();
                }
            }
            // 全被隐藏
            if (!activeSheet) {
                this.setState({ allSheetHidden: true });
            } else {
                toastText && (0, _toastHelper.showToast)({
                    type: 1,
                    message: toastText,
                    duration: 3
                });
                spread.setActiveSheet(activeSheet.name(), true);
                this.setState({ allSheetHidden: false });
            }
        }
        /**
         * 切换文档
         */

    }, {
        key: 'switch',
        value: function _switch(token) {
            if (token) {
                var collaSpread = this._collaSpread;
                collaSpread.bindEvents();
                collaSpread.spread.bind(_sheet.Events.ActiveSheetChanged, this.onActiveSheetChanged);
                collaSpread.spread.bind(_sheet.Events.CellPress, this.onCellPress);
                this.bindCollaborativeEvents();
                console.info('[SHEET LOG - SWITCH SHEET] token: ' + token + '; activeSheetId: ' + this.props.sheetId);
                this._sync.connect(token, this.props.sheetId);
            } else {
                console.info('[SHEET LOG - SWITCH SHEET] no token!');
            }
        }
    }, {
        key: 'reset',
        value: function reset() {
            (0, _modal.removeSpreadToast)();
            this.setState({
                loading: true
            });
            this._collaSpread.spread.unbind(_sheet.Events.ActiveSheetChanged, this.onActiveSheetChanged);
            this._collaSpread.spread.unbind(_sheet.Events.CellPress, this.onCellPress);
            this.freezeSheet(false);
            this._sync.disconnect();
            this._engine.reset();
            this.unbindCollaborativeEvents();
            this._collaSpread.reset();
        }
    }, {
        key: 'bindCollaborativeEvents',
        value: function bindCollaborativeEvents() {
            var context = this._context;
            this._sync.bindCollaborativeEvents();
            this._engine.bindCollaborativeEvents();
            this._collaSpread.bindCollaborativeEvents();
            context.bind(_collaborative.CollaborativeEvents.CLIENT_VARS, this.onClientVars);
            context.bind(_collaborative.CollaborativeEvents.ERROR, this.onError);
            context.bind(_collaborative.CollaborativeEvents.LOCAL_CONFLICT, this.onConflict);
            context.bind(_collaborative.CollaborativeEvents.REJECT_COMMIT, this.onConflict);
            context.bind(_collaborative.CollaborativeEvents.FREEZE_SPREAD, this.freezeSpread);
            context.bind(_collaborative.CollaborativeEvents.REFETCH_CLIENT_VARS, this.refetchClientVars);
            context.bind(_collaborative.CollaborativeEvents.CHANNEL_STATE_CHANGE, this.onChannelStateChange);
        }
    }, {
        key: 'unbindCollaborativeEvents',
        value: function unbindCollaborativeEvents() {
            var context = this._context;
            this._engine.unbindCollaborativeEvents();
            this._sync.unbindCollaborativeEvents();
            context.unbind(_collaborative.CollaborativeEvents.CLIENT_VARS, this.onClientVars);
            context.unbind(_collaborative.CollaborativeEvents.ERROR, this.onError);
            context.unbind(_collaborative.CollaborativeEvents.LOCAL_CONFLICT, this.onConflict);
            context.unbind(_collaborative.CollaborativeEvents.REJECT_COMMIT, this.onConflict);
            context.unbind(_collaborative.CollaborativeEvents.FREEZE_SPREAD, this.freezeSpread);
            context.unbind(_collaborative.CollaborativeEvents.REFETCH_CLIENT_VARS, this.refetchClientVars);
            this._collaSpread.unbindCollaborativeEvents();
        }
    }, {
        key: 'shouldSheetEditable',
        value: function shouldSheetEditable() {
            return this.state.isOnline && this.props.editable;
        }
    }, {
        key: 'freezeSheet',
        value: function freezeSheet(freeze) {
            this.props.freezeSheetToggle && this.props.freezeSheetToggle(freeze);
        }
    }, {
        key: '_getFullPageHeight',
        value: function _getFullPageHeight() {
            if (this._workbookContainer) {
                return this._workbookContainer.getBoundingClientRect().height;
            } else {
                return _browserHelper2.default.isIphoneX ? window.innerHeight - IPHONEX_SAFE_HEIGHT : window.innerHeight;
            }
        }
    }, {
        key: 'render',
        value: function render() {
            var _this3 = this;

            var _state = this.state,
                loading = _state.loading,
                allSheetHidden = _state.allSheetHidden;
            var _props2 = this.props,
                copyPermission = _props2.copyPermission,
                commentable = _props2.commentable,
                editable = _props2.editable,
                token = _props2.token;
            var spread = this._collaSpread.spread;

            var activeSheet = spread.getActiveSheet();
            var sheetId = activeSheet ? activeSheet.id() : '';
            var canCopy = copyPermission === _common.USER_TYPE_ON_SUITE.READABLE || editable;
            return _react2.default.createElement("div", null, _react2.default.createElement("div", { className: "spreadsheet-wrap layout-column flex", style: { height: SHEET_PAGE_HEIGHT, visibility: allSheetHidden ? 'hidden' : 'visible' }, ref: function ref(_ref) {
                    return _this3._workbookContainer = _ref;
                } }, this.shouldSheetEditable() && _react2.default.createElement(_headerSelectionBubble2.default, { sheet: spread.getSheetFromId(this.props.sheetId), getSheetView: function getSheetView() {
                    return _this3._shell.sheetView();
                } }), loading && _react2.default.createElement("div", { className: "spreadsheet-wrap__spin layout-column layout-main-cross-center" }, _react2.default.createElement(_spin.Spin, null)), _react2.default.createElement("div", { style: { flex: 1 }, ref: this.setFasterCanvas }), _sdkCompatibleHelper.isSupportSheetComment && _react2.default.createElement(_comment2.default, { onHide: this.handleCommentCardWillHide, onShow: this.handleCommentCardWillShow, showCell: this.showCell, spread: spread, token: token, context: this._context }), _sdkCompatibleHelper.isSupportSheetComment && !_sdkCompatibleHelper.isSupportSheetContextMenu && _react2.default.createElement(_OldContextMenu2.default, { spread: spread, getSheetView: function getSheetView() {
                    return _this3._shell.sheetView();
                }, editable: editable, commentable: commentable }), _sdkCompatibleHelper.isSupportSheetContextMenu && _react2.default.createElement(_ContextMenu2.default, { spread: spread, sheetId: sheetId, editable: editable, commentable: commentable, canCopy: canCopy, getSheetView: function getSheetView() {
                    return _this3._shell.sheetView();
                } }), _react2.default.createElement(_zoom_tips2.default, null), _react2.default.createElement(_tabs.SheetTabs, { editable: false, spread: spread })), allSheetHidden && _react2.default.createElement("div", { className: "all-sheet-hidden", style: { position: 'fixed', top: '200px', left: '0px', width: '100%', textAlign: 'center' } }, _react2.default.createElement("img", { src: _emptySheet2.default }), _react2.default.createElement("p", { style: { marginTop: '24px', color: '#b7bec7', fontSize: '20px' } }, t('all-sheets-have-been-hidden'))));
        }
    }]);
    return MobileSheet;
}(_react.PureComponent);

exports.default = (0, _reactRouterDom.withRouter)((0, _reactRedux.connect)(function (state, props) {
    return {
        token: props.match.params.token,
        sheetId: getSheetIdFromLocation(props.location),
        editable: (0, _sheet2.editableSelector)(state) && state.sheet.status.online,
        commentable: (0, _sheet2.commentableSelector)(state),
        currentNoteToken: (0, _suite.selectCurrentSuiteToken)(state),
        copyPermission: (0, _share2.selectCopyPermission)(state)
    };
}, function (dispatch) {
    return (0, _redux.bindActionCreators)({
        fetchAuthorizedMembers: _share.fetchAuthorizedMembers,
        fetchSuitePublicPermission: _share.fetchSuitePublicPermission,
        fetchUserPermissionOnSuite: _share.fetchUserPermissionOnSuite,
        freezeSheetToggle: _sheet3.freezeSheetToggle
    }, dispatch);
})(MobileSheet));
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 2948:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.Status = undefined;

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _workerStatus = __webpack_require__(2949);

var _syncStatus = __webpack_require__(2950);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var Status = exports.Status = function () {
    function Status(sync, engine) {
        (0, _classCallCheck3.default)(this, Status);

        this._sync = sync;
        // this._engine = engine;
        this._wokerStatus = new _workerStatus.WorkerStatus(this._sync.worker);
        this._syncStatus = new _syncStatus.SyncStatus(this._sync);
    }

    (0, _createClass3.default)(Status, [{
        key: 'collect',
        value: function collect() {
            var promiseList = [this._wokerStatus.collect(), this._syncStatus.collect()];
            Promise.all(promiseList).then(function (statusList) {
                var allStatus = {};
                statusList.forEach(function (item) {
                    allStatus = Object.assign(allStatus, item);
                });
                console.log(allStatus);
            });
        }
    }]);
    return Status;
}();

/***/ }),

/***/ 2949:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.WorkerStatus = undefined;

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var WorkerStatus = exports.WorkerStatus = function () {
    function WorkerStatus(worker) {
        (0, _classCallCheck3.default)(this, WorkerStatus);

        this._worker = worker;
    }

    (0, _createClass3.default)(WorkerStatus, [{
        key: 'collect',
        value: function collect() {
            var _this = this;

            return new Promise(function (resolve, reject) {
                _this._worker.exec('worker.error').then(function (e) {
                    resolve({
                        worker: {
                            errors: e
                        }
                    });
                }).catch(function (ex) {
                    // Raven上报
                    window.Raven && window.Raven.captureException(ex);
                    // ConsoleError
                    console.error(ex);
                    reject(ex);
                });
            });
        }
    }]);
    return WorkerStatus;
}();

/***/ }),

/***/ 2950:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.SyncStatus = undefined;

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var SyncStatus = exports.SyncStatus = function () {
    function SyncStatus(sync) {
        (0, _classCallCheck3.default)(this, SyncStatus);

        this._sync = sync;
    }

    (0, _createClass3.default)(SyncStatus, [{
        key: "collect",
        value: function collect() {
            var _this = this;

            return new Promise(function (resolve, reject) {
                var syncObj = _this._sync;
                resolve({
                    sync: {
                        memberId: syncObj._memberId,
                        network: syncObj._network,
                        token: syncObj._token,
                        sendingChangeset: syncObj.sendingChangeset,
                        spreadLoaded: syncObj.spreadLoaded,
                        io: {
                            channel: syncObj._io.channel,
                            memberId: syncObj._io.memberId,
                            state: syncObj._io.state
                        }
                    }
                });
            });
        }
    }]);
    return SyncStatus;
}();

/***/ }),

/***/ 2991:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _container = __webpack_require__(2992);

var _container2 = _interopRequireDefault(_container);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.default = _container2.default;

/***/ }),

/***/ 2992:
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

var _menu = __webpack_require__(2993);

var _menu2 = _interopRequireDefault(_menu);

var _bind = __webpack_require__(503);

var _sheet = __webpack_require__(713);

var _util = __webpack_require__(1568);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var __decorate = undefined && undefined.__decorate || function (decorators, target, key, desc) {
    var c = arguments.length,
        r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc,
        d;
    if ((typeof Reflect === "undefined" ? "undefined" : (0, _typeof3.default)(Reflect)) === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);else for (var i = decorators.length - 1; i >= 0; i--) {
        if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    }return c > 3 && r && Object.defineProperty(target, key, r), r;
};

var OldContextMenu = function (_Component) {
    (0, _inherits3.default)(OldContextMenu, _Component);

    function OldContextMenu() {
        (0, _classCallCheck3.default)(this, OldContextMenu);

        var _this = (0, _possibleConstructorReturn3.default)(this, (OldContextMenu.__proto__ || Object.getPrototypeOf(OldContextMenu)).apply(this, arguments));

        _this.currentActiveCell = {
            row: 0,
            col: 0
        };
        _this.state = {
            visible: false,
            rect: { x: 0, y: 0, w: 0, h: 0 }
        };
        return _this;
    }

    (0, _createClass3.default)(OldContextMenu, [{
        key: "componentDidMount",
        value: function componentDidMount() {
            this.bindEvents();
        }
    }, {
        key: "componentWillMount",
        value: function componentWillMount() {
            this.unbindEvents();
        }
    }, {
        key: "bindEvents",
        value: function bindEvents() {
            var spread = this.props.spread;
            spread.bind(_sheet.Events.CellPress, this.handleCellPress);
            spread.bind(_sheet.Events.CellClick, this.handleCellClick);
            spread.bind(_sheet.Events.TopPosChanged, this.hideMenu);
            spread.bind(_sheet.Events.LeftPosChagned, this.hideMenu);
        }
    }, {
        key: "unbindEvents",
        value: function unbindEvents() {
            var spread = this.props.spread;
            spread.unbind(_sheet.Events.CellPress, this.handleCellPress);
            spread.unbind(_sheet.Events.CellClick, this.handleCellClick);
            spread.unbind(_sheet.Events.TopPosChanged, this.hideMenu);
            spread.unbind(_sheet.Events.LeftPosChagned, this.hideMenu);
        }
    }, {
        key: "hideMenu",
        value: function hideMenu() {
            if (this.state.visible) {
                this.setState({ visible: false });
            }
        }
    }, {
        key: "handleCellClick",
        value: function handleCellClick(type, info) {
            this.hideMenu();
        }
    }, {
        key: "handleCellPress",
        value: function handleCellPress(type, info) {
            var row = info.row,
                col = info.col;
            var _props = this.props,
                spread = _props.spread,
                getSheetView = _props.getSheetView;

            var activeSheet = spread.getActiveSheet();
            if (!activeSheet) return;
            var selectionRange = activeSheet.getSelections()[0];
            var isInsideSelection = selectionRange && selectionRange.contains(row, col, 1, 1);
            if (!isInsideSelection) {
                return;
            }
            this.currentActiveCell = { row: row, col: col };
            var sheetView = getSheetView();
            var table = sheetView.detectTableByCell(row, col);
            var rect = sheetView.getContentBounds();
            var layout = table.range2ViewRect(new _util.Range(row, col, 1, 1));
            this.setState({
                visible: true,
                rect: {
                    x: (layout.x + rect.x) * sheetView.zoom,
                    y: (layout.y + rect.y) * sheetView.zoom,
                    w: layout.width * sheetView.zoom,
                    h: layout.height * sheetView.zoom
                }
            });
        }
    }, {
        key: "handleSelect",
        value: function handleSelect(action) {
            this.hideMenu();
            // const spread = this.props.spread;
            // const sheet = spread.getActiveSheet();
            this.props.onSelect && this.props.onSelect(action);
            switch (action) {
                case 'comment':
                    this.props.spread.trigger(_sheet.Events.AddComment, this.currentActiveCell);
                    break;
                case 'copy':
                    // spread.commandManager().execute({
                    //   cmd: 'clickCopy',
                    //   sheetName: sheet.name(),
                    //   sheetId: sheet.id(),
                    //   teaSource: 'CONTEXT_MENU',
                    // });
                    break;
                case 'paste':
                    break;
                case 'cut':
                    // spread.commandManager().execute({
                    //   cmd: 'clickCut',
                    //   sheetName: sheet.name(),
                    //   sheetId: sheet.id(),
                    //   teaSource: 'CONTEXT_MENU',
                    // });
                    break;
                case 'clear':
                    break;
            }
        }
    }, {
        key: "render",
        value: function render() {
            var _this2 = this;

            var items = this.props.commentable ? [{
                id: 'comment',
                value: t('mobile.sheet.comment')
            }] : [];
            if (items.length <= 0) return null;
            var _state = this.state,
                visible = _state.visible,
                rect = _state.rect;

            return _react2.default.createElement(_menu2.default, { show: visible, items: items, rect: rect, cls: "ios", onItemClick: function onItemClick(id) {
                    _this2.handleSelect(id);
                } });
        }
    }]);
    return OldContextMenu;
}(_react.Component);

exports.default = OldContextMenu;

__decorate([(0, _bind.Bind)()], OldContextMenu.prototype, "hideMenu", null);
__decorate([(0, _bind.Bind)()], OldContextMenu.prototype, "handleCellClick", null);
__decorate([(0, _bind.Bind)()], OldContextMenu.prototype, "handleCellPress", null);
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 2993:
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

__webpack_require__(2994);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var RATE = window.innerWidth / 375 * 50;
var SPACE = 5;
var isEnUS = document.body.id.indexOf('en-US') > -1 ? true : false;

var Menu = function (_Component) {
    (0, _inherits3.default)(Menu, _Component);

    function Menu() {
        (0, _classCallCheck3.default)(this, Menu);
        return (0, _possibleConstructorReturn3.default)(this, (Menu.__proto__ || Object.getPrototypeOf(Menu)).apply(this, arguments));
    }

    (0, _createClass3.default)(Menu, [{
        key: 'handleItemClick',
        value: function handleItemClick(id) {
            this.props.onItemClick && this.props.onItemClick(id);
        }
    }, {
        key: 'getBubbleWidth',
        value: function getBubbleWidth(cls) {
            // return cls === 'ios' ? 5 * RATE : 4.2 * RATE;
            return (isEnUS ? 2 : 1.24) * RATE;
        }
    }, {
        key: 'getBubbleHeight',
        value: function getBubbleHeight(cls) {
            // return cls === 'ios' ? 0.72 * RATE : 0.86 * RATE;
            return (isEnUS ? 0.68 : 0.72) * RATE;
        }
    }, {
        key: 'getArrowWidth',
        value: function getArrowWidth(cls) {
            // return cls === 'ios' ? 0.36 * RATE : 0;
            return 0.36 * RATE;
        }
    }, {
        key: 'getArrowHeight',
        value: function getArrowHeight(cls) {
            // return cls === 'ios' ? 0.18 * RATE : 0;
            return 0.18 * RATE;
        }
    }, {
        key: 'getTop',
        value: function getTop(cls, rect) {
            var y = rect.y,
                h = rect.h;

            var bh = this.getBubbleHeight(cls);
            var th = this.getArrowHeight(cls);
            var top = y - (bh + th + SPACE);
            return top < 0 ? y + h + th + SPACE : top;
        }
    }, {
        key: 'getLeft',
        value: function getLeft(cls, rect) {
            var x = rect.x,
                w = rect.w;

            var bw = this.getBubbleWidth(cls);
            var result = Math.max(4, x + w / 2 - bw / 2);
            return Math.min(result, window.innerWidth - 4 - bw);
        }
    }, {
        key: 'getArrowLeft',
        value: function getArrowLeft(cls, rect) {
            // const { x, w } = rect;
            var tw = this.getArrowWidth(cls);
            var bw = this.getBubbleWidth(cls);
            return (bw - tw) / 2;
            // const bl = this.getLeft(cls, rect);
            // const tl = Math.min(bw - tw * 2, x + w / 2 - bl);
            // const itemCount = this.props.items.length;
            // const itemWidth = bw / itemCount;
            // let i = 1;
            // let isCollapse = false;
            // while (i <= itemCount) {
            //   if (itemWidth * i > tl && itemWidth * i < tl + tw) {
            //     isCollapse = true;
            //     break;
            //   }
            //   i++;
            // }
            // return isCollapse ? itemWidth * i : tl;
        }
    }, {
        key: 'render',
        value: function render() {
            var _this2 = this;

            var _props = this.props,
                show = _props.show,
                cls = _props.cls,
                items = _props.items,
                rect = _props.rect;

            var clsname = 'sheet-context-menu ' + cls + (show ? ' visible' : ' hide');
            var bl = this.getLeft(cls, rect);
            var bt = this.getTop(cls, rect);
            var tl = this.getArrowLeft(cls, rect);
            var arrowUp = bt > rect.y + rect.h ? true : false;
            var tb = arrowUp ? this.getBubbleHeight(cls) : 0 - this.getArrowHeight(cls);
            return _react2.default.createElement("div", { className: clsname, style: { top: bt + 'px', left: bl + 'px' } }, _react2.default.createElement("div", { className: "menu-item-wrap" }, items.map(function (_ref) {
                var id = _ref.id,
                    value = _ref.value;

                return _react2.default.createElement("div", { className: "menu-item", key: id, onTouchEnd: function onTouchEnd(e) {
                        e.preventDefault();_this2.handleItemClick(id);
                    } }, value);
            })), cls === 'ios' && _react2.default.createElement("div", { className: arrowUp ? 'arrow arrow-up' : 'arrow', style: { left: tl + 'px', bottom: tb + 'px' } }));
        }
    }]);
    return Menu;
}(_react.Component);

exports.default = Menu;

/***/ }),

/***/ 2994:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3000:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _container = __webpack_require__(3001);

var _container2 = _interopRequireDefault(_container);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.default = _container2.default;

/***/ }),

/***/ 3001:
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

var _tips = __webpack_require__(3002);

var _tips2 = _interopRequireDefault(_tips);

var _sheet = __webpack_require__(713);

var _eventEmitter = __webpack_require__(272);

var _eventEmitter2 = _interopRequireDefault(_eventEmitter);

var _events = __webpack_require__(273);

var _events2 = _interopRequireDefault(_events);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var ZoomTips = function (_Component) {
    (0, _inherits3.default)(ZoomTips, _Component);

    function ZoomTips() {
        (0, _classCallCheck3.default)(this, ZoomTips);

        var _this = (0, _possibleConstructorReturn3.default)(this, (ZoomTips.__proto__ || Object.getPrototypeOf(ZoomTips)).apply(this, arguments));

        _this.timer = null;
        _this.handleChange = _this.eventHandler.bind(_this);
        _this.state = {
            show: false,
            value: 1
        };
        return _this;
    }

    (0, _createClass3.default)(ZoomTips, [{
        key: 'componentDidMount',
        value: function componentDidMount() {
            _eventEmitter2.default.on(_events2.default.MOBILE.SHEET.Zoom, this.handleChange);
        }
    }, {
        key: 'componentWillUnmount',
        value: function componentWillUnmount() {
            _eventEmitter2.default.off(_events2.default.MOBILE.SHEET.Zoom, this.handleChange);
        }
    }, {
        key: 'eventHandler',
        value: function eventHandler(value) {
            var _this2 = this;

            if (this.timer) {
                clearTimeout(this.timer);
                this.timer = null;
            }
            this.setState({
                value: value,
                show: true
            });
            this.timer = setTimeout(function () {
                _this2.setState({ show: false, value: 0 });
            }, 500);
        }
    }, {
        key: 'render',
        value: function render() {
            var _state = this.state,
                show = _state.show,
                value = _state.value;

            var content = '';
            if (value === _sheet.MAX_ZOOM) {
                content = t('mobile.sheet.zoom.max') + ': ' + (_sheet.MAX_ZOOM * 100).toFixed(0) + '%';
            } else if (value === _sheet.MIN_ZOOM) {
                content = t('mobile.sheet.zoom.min') + ': ' + (_sheet.MIN_ZOOM * 100).toFixed(0) + '%';
            } else {
                content = t('mobile.sheet.zoom') + ': ' + (value * 100).toFixed(0) + '%';
            }
            return _react2.default.createElement(_tips2.default, { visible: show, content: content });
        }
    }]);
    return ZoomTips;
}(_react.Component);

exports.default = ZoomTips;
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 3002:
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

__webpack_require__(3003);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var Tips = function (_Component) {
    (0, _inherits3.default)(Tips, _Component);

    function Tips(props) {
        (0, _classCallCheck3.default)(this, Tips);
        return (0, _possibleConstructorReturn3.default)(this, (Tips.__proto__ || Object.getPrototypeOf(Tips)).call(this, props));
    }

    (0, _createClass3.default)(Tips, [{
        key: 'render',
        value: function render() {
            var _props = this.props,
                visible = _props.visible,
                content = _props.content;

            if (visible) {
                return _react2.default.createElement("div", { className: "zoom_tips" }, _react2.default.createElement("span", null, content));
            } else {
                return null;
            }
        }
    }]);
    return Tips;
}(_react.Component);

exports.default = Tips;

/***/ }),

/***/ 3003:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3004:
/***/ (function(module, exports) {

module.exports = "data:image/png;base64,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"

/***/ })

}]);
//# sourceMappingURL=https://s3.pstatp.com/eesz/resource/bear/js/sheet.57f23420ba9d571441c7.js.map