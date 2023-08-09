part of '../controllers/info_popup_controller.dart';

/// [InfoPopup] is a widget that shows a popup with a text and an arrow indicator.
class OverlayInfoPopup extends StatefulWidget {
  /// Creates a [InfoPopup] widget.
  const OverlayInfoPopup({
    required LayerLink layerLink,
    required RenderBox targetRenderBox,
    required Color areaBackgroundColor,
    required InfoPopupArrowTheme indicatorTheme,
    required InfoPopupContentTheme contentTheme,
    required VoidCallback onAreaPressed,
    required Function(Size size) onLayoutMounted,
    required Offset contentOffset,
    required Offset indicatorOffset,
    required PopupDismissTriggerBehavior dismissTriggerBehavior,
    required bool enableHighlight,
    required HighLightTheme highlightTheme,
    required VoidCallback hideOverlay,
    Widget? customContent,
    String? contentTitle,
    double? contentMaxWidth,
    super.key,
  })  : _layerLink = layerLink,
        _targetRenderBox = targetRenderBox,
        _areaBackgroundColor = areaBackgroundColor,
        _indicatorTheme = indicatorTheme,
        _contentTheme = contentTheme,
        _onAreaPressed = onAreaPressed,
        _onLayoutMounted = onLayoutMounted,
        _contentOffset = contentOffset,
        _indicatorOffset = indicatorOffset,
        _dismissTriggerBehavior = dismissTriggerBehavior,
        _customContent = customContent,
        _contentTitle = contentTitle,
        _contentMaxWidth = contentMaxWidth,
        _enableHighlight = enableHighlight,
        _highLightTheme = highlightTheme,
        _hideOverlay = hideOverlay;

  final LayerLink _layerLink;
  final RenderBox _targetRenderBox;
  final Widget? _customContent;
  final String? _contentTitle;
  final Color _areaBackgroundColor;
  final InfoPopupArrowTheme _indicatorTheme;
  final InfoPopupContentTheme _contentTheme;
  final VoidCallback _onAreaPressed;
  final Function(Size size) _onLayoutMounted;
  final Offset _contentOffset;
  final Offset _indicatorOffset;
  final PopupDismissTriggerBehavior _dismissTriggerBehavior;
  final double? _contentMaxWidth;
  final bool _enableHighlight;
  final HighLightTheme _highLightTheme;
  final VoidCallback _hideOverlay;

  @override
  State<OverlayInfoPopup> createState() => _OverlayInfoPopupState();
}

class _OverlayInfoPopupState extends State<OverlayInfoPopup> {
  final GlobalKey _bodyKey = GlobalKey();

  @override
  void initState() {
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handlePointerEvent);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        _updateContentLayoutSize();
      },
    );
    super.initState();
  }

  bool _isPointListenerDisposed = false;
  void _handlePointerEvent(PointerEvent event) {
    if (!mounted) {
      return;
    }

    final bool mouseIsConnected =
        RendererBinding.instance.mouseTracker.mouseIsConnected;

    if (mouseIsConnected) {
      GestureBinding.instance.pointerRouter.removeGlobalRoute(
        _handlePointerEvent,
      );
      _isPointListenerDisposed = true;
      return;
    }

    final RenderBox? renderBox =
        _bodyKey.currentContext!.findRenderObject() as RenderBox?;

    if (renderBox == null) {
      return;
    }

    final Offset clickPosition = event.position;
    final Offset contentPosition = renderBox.localToGlobal(Offset.zero);

    switch (widget._dismissTriggerBehavior) {
      case PopupDismissTriggerBehavior.onTapContent:
        if (clickPosition.dx >= contentPosition.dx &&
            clickPosition.dx <= contentPosition.dx + contentSize.width &&
            clickPosition.dy >= contentPosition.dy &&
            clickPosition.dy <= contentPosition.dy + contentSize.height) {
          setState(() {
            _isLayoutMounted = false;
          });

          Future.delayed(
            Duration(milliseconds: 150),
            () {
              widget._hideOverlay();
            },
          );
        }
        break;
      case PopupDismissTriggerBehavior.onTapArea:
        if (!(clickPosition.dx >= contentPosition.dx &&
            clickPosition.dx <= contentPosition.dx + contentSize.width &&
            clickPosition.dy >= contentPosition.dy &&
            clickPosition.dy <= contentPosition.dy + contentSize.height)) {
          widget._onAreaPressed();
        }
        break;
      case PopupDismissTriggerBehavior.anyWhere:
        setState(() {
          _isLayoutMounted = false;
        });

        Future.delayed(
          Duration(milliseconds: 150),
          () {
            widget._hideOverlay();
          },
        );
        break;
      case PopupDismissTriggerBehavior.manuel:
        // do nothing
        break;
    }
  }

  @override
  void dispose() {
    if (!_isPointListenerDisposed) {
      GestureBinding.instance.pointerRouter.removeGlobalRoute(
        _handlePointerEvent,
      );
    }

    super.dispose();
  }

  Offset get _indicatorOffset {
    final double indicatorWidth = widget._indicatorTheme.arrowSize.width;
    switch (widget._indicatorTheme.arrowDirection) {
      case ArrowDirection.up:
        return Offset(
              _targetWidgetRect.width / 2 - indicatorWidth / 2,
              _targetWidgetRect.height,
            ) +
            widget._indicatorOffset +
            _highlightOffset;
      case ArrowDirection.down:
        return Offset(
              _targetWidgetRect.width / 2 - indicatorWidth / 2,
              -widget._indicatorTheme.arrowSize.height,
            ) +
            widget._indicatorOffset +
            _highlightOffset;
    }
  }

  Offset get _highlightOffset {
    double highlightVerticalGap = 0;

    if (widget._enableHighlight) {
      highlightVerticalGap = widget._highLightTheme.padding.bottom;
    }

    switch (widget._indicatorTheme.arrowDirection) {
      case ArrowDirection.up:
        return Offset(0, highlightVerticalGap);
      case ArrowDirection.down:
        return Offset(0, -highlightVerticalGap);
    }
  }

  Offset get _bodyOffset {
    Offset targetCenterOffset = Offset.zero;

    final double contentWidth = contentSize.width;
    final double contentHeight = contentSize.height;
    final double targetWidth = _targetWidgetRect.width;
    final double targetHeight = _targetWidgetRect.height;
    final double contentDxCenter = targetWidth / 2 - contentWidth / 2;

    switch (widget._indicatorTheme.arrowDirection) {
      case ArrowDirection.up:
        targetCenterOffset = Offset(
          contentDxCenter,
          targetHeight,
        );
        break;
      case ArrowDirection.down:
        targetCenterOffset = Offset(
          contentDxCenter,
          -(contentHeight),
        );
        break;
    }

    targetCenterOffset += _highlightOffset;

    final double contentLeft = contentDxCenter + _targetOffset.dx;
    final double contentRight = contentLeft + contentWidth;
    final double screenWidth = context.screenWidth;

    if (contentLeft < 0) {
      targetCenterOffset += Offset(-contentLeft, 0);
    } else if (contentRight > screenWidth) {
      targetCenterOffset += Offset(screenWidth - contentRight, 0);
    }

    return targetCenterOffset + widget._contentOffset;
  }

  Size? _contentSize;

  Size get contentSize {
    if (!_isLayoutMounted) {
      return widget._targetRenderBox.size;
    } else {
      return _contentSize!;
    }
  }

  @override
  void didUpdateWidget(covariant OverlayInfoPopup oldWidget) {
    _updateContentLayoutSize();
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    _updateContentLayoutSize();
    super.didChangeDependencies();
  }

  bool _isLayoutMounted = false;

  void _updateContentLayoutSize() {
    Future<dynamic>.microtask(
      () {
        Future<void>.delayed(
          const Duration(milliseconds: 50),
          () {
            if (!mounted) {
              return;
            }

            final RenderBox? renderBox =
                _bodyKey.currentContext!.findRenderObject() as RenderBox?;

            if (renderBox == null) {
              return;
            }

            final Size size = renderBox.size;

            if (size != _contentSize) {
              setState(
                () {
                  _contentSize = size;

                  widget._onLayoutMounted(size);
                  _isLayoutMounted = true;
                },
              );
            }
          },
        );
      },
    );
  }

  Rect get _targetWidgetRect {
    if (!widget._targetRenderBox.attached) {
      return Rect.zero;
    }

    final Offset offset = widget._targetRenderBox.localToGlobal(Offset.zero);

    return Rect.fromLTWH(
      offset.dx,
      offset.dy,
      widget._targetRenderBox.size.width,
      widget._targetRenderBox.size.height,
    );
  }

  double get _contentMaxWidth {
    if (widget._contentMaxWidth == null) {
      return context.screenWidth * .8;
    } else {
      return widget._contentMaxWidth!;
    }
  }

  double get _contentMaxHeight {
    const int padding = 16;
    final double screenHeight = context.screenHeight;
    final double bottomPadding = context.mediaQuery.padding.bottom;
    final double topPadding = context.mediaQuery.padding.top;
    final double targetWidgetTopPosition = _targetWidgetRect.top;

    switch (widget._indicatorTheme.arrowDirection) {
      case ArrowDirection.up:
        final double belowSpace = screenHeight -
            targetWidgetTopPosition -
            _targetWidgetRect.height -
            padding -
            bottomPadding;
        return belowSpace;
      case ArrowDirection.down:
        final double aboveSpace = targetWidgetTopPosition - topPadding;
        return aboveSpace;
    }
  }

  Offset get _areaOffset {
    if (widget._enableHighlight) {
      return Offset(-_targetWidgetRect.left, -_targetWidgetRect.top);
    }

    switch (widget._dismissTriggerBehavior) {
      case PopupDismissTriggerBehavior.onTapContent:
        return _bodyOffset;
      case PopupDismissTriggerBehavior.onTapArea:
      case PopupDismissTriggerBehavior.anyWhere:
      case PopupDismissTriggerBehavior.manuel:
        return Offset(-_targetWidgetRect.left, -_targetWidgetRect.top);
    }
  }

  Offset get _targetOffset {
    return widget._targetRenderBox.localToGlobal(Offset.zero);
  }

  bool get _dismissBehaviorIsOnTapContent =>
      widget._dismissTriggerBehavior ==
      PopupDismissTriggerBehavior.onTapContent;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: widget._enableHighlight
          ? _HighLighter(
              area: Rect.fromLTWH(
                _targetWidgetRect.left,
                _targetWidgetRect.top,
                _targetWidgetRect.width,
                _targetWidgetRect.height,
              ),
              padding: widget._highLightTheme.padding,
              radius: widget._highLightTheme.radius,
            )
          : null,
      child: Align(
        child: CompositedTransformFollower(
          link: widget._layerLink,
          showWhenUnlinked: false,
          offset: _areaOffset,
          child: Material(
            color: widget._enableHighlight
                ? widget._highLightTheme.backgroundColor
                : widget._areaBackgroundColor,
            type: (!widget._enableHighlight &&
                    widget._areaBackgroundColor == Colors.transparent)
                ? MaterialType.transparency
                : MaterialType.canvas,
            child: SizedBox(
              height:
                  _dismissBehaviorIsOnTapContent ? null : context.screenHeight,
              width:
                  _dismissBehaviorIsOnTapContent ? null : context.screenWidth,
              child: Column(
                children: <Widget>[
                  CompositedTransformFollower(
                    link: widget._layerLink,
                    showWhenUnlinked: false,
                    offset: _bodyOffset,
                    child: AnimatedScale(
                      scale: _isLayoutMounted ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 150),
                      alignment: Alignment.bottomCenter,
                      curve: Curves.easeInOutQuart,
                      child: ClipPath(
                        clipper: ShapeBorderClipper(
                          shape: ToolTipCustomShape(),
                          textDirection: Directionality.maybeOf(context),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                          child: DecoratedBox(
                            key: _bodyKey,
                            decoration: ShapeDecoration(
                              color: Colors.black38,
                              shape: ToolTipCustomShape(),
                            ),
                            child: Padding(
                              padding: widget._customContent != null
                                  ? EdgeInsets.zero
                                  : widget._contentTheme.contentPadding
                                      .add(EdgeInsets.only(bottom: 10)),
                              child: Text(
                                widget._contentTitle ?? '',
                                style: widget._contentTheme.infoTextStyle,
                                textAlign: widget._contentTheme.infoTextAlign,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ToolTipCustomShape extends ShapeBorder {
  ToolTipCustomShape({this.usePadding = true});
  final bool usePadding;

  @override
  EdgeInsetsGeometry get dimensions =>
      EdgeInsets.only(bottom: usePadding ? 10 : 0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    rect =
        Rect.fromPoints(rect.topLeft, rect.bottomRight - const Offset(0, 10));
    return Path()
      ..addRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 3)))
      ..moveTo(rect.bottomCenter.dx - 5, rect.bottomCenter.dy)
      ..relativeLineTo(5, 10)
      ..relativeLineTo(5, -10)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}
