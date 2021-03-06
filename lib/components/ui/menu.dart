/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;

/// Widget that builds drawer
class DrawerWidget extends StatefulWidget {
  const DrawerWidget({Key key}) : super(key: key);

  @override
  _DrawerWidgetState createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget>
    with SingleTickerProviderStateMixin {
  bool _tappedList = false;
  bool _devMode = false;

  @override
  void initState() {
    super.initState();
    _fetchDevMode();
    () async {
      // Without a this future this won't work
      await Future.delayed(const Duration(microseconds: 1));

      SystemUiOverlayStyleControl.setSystemUiOverlay(
        Constants.AppSystemUIThemes.drawerScreen.autoWithoutContext,
        saveToHistory: false,
      );
    }();
  }

  @override
  void dispose() {
    () async {
      if (!_tappedList) {
        // Animate only nav panel here
        await SystemUiOverlayStyleControl.animateSystemUiOverlay(
          from: Constants.AppSystemUIThemes.drawerScreen.autoWithoutContext,
          to: Constants.AppSystemUIThemes.allScreens.autoWithoutContext,
          curve: Curves.easeInCirc,
          settings: AnimationControllerSettings(
            duration: const Duration(milliseconds: 300),
          ),
        );
      }
    }();

    super.dispose();
  }

  /// Should be called when menu item is pressed
  void _handleMenuItemClick() {
    _tappedList = true;
    SystemUiOverlayStyleControl.setSystemUiOverlay(
      Constants.AppSystemUIThemes.drawerScreen.autoWithoutContext,
      saveToHistory: false,
    );
  }

  Future<void> _handleClickSettings() {
    _handleMenuItemClick();
    return App.navigatorKey.currentState
        .popAndPushNamed(Constants.Routes.settings.value);
  }

  Future<void> _handleClickDebug() async {
    _handleMenuItemClick();
    return App.navigatorKey.currentState
        .popAndPushNamed(Constants.Routes.dev.value);
  }

  Future<void> _fetchDevMode() async {
    _devMode = await Prefs.developerModeBool.getPref();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: //This will change the drawer background
            Constants.AppTheme.drawer.auto(context),
      ),
      child: Drawer(
        child: ListView(
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: <Widget>[
            Container(
              padding:
                  const EdgeInsets.only(left: 22.0, top: 45.0, bottom: 7.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SweyerLogo(),
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Text(
                      Constants.Config.APPLICATION_TITLE,
                      style:TextStyle(
                        fontSize: 30.0,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).textTheme.headline6.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(),
            SizedBox(
              height: 7.0,
            ),
            MenuItem(
              'Настройки',
              icon: Icons.settings,
              onTap: _handleClickSettings,
            ),
            if (_devMode)
              MenuItem(
                'Дебаг',
                icon: Icons.adb,
                onTap: _handleClickDebug,
              ),
          ],
        ),
      ),
    );
  }
}

class MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Function onTap;
  final Function onLongPress;
  const MenuItem(
    this.title, {
    Key key,
    this.icon,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: SMMListTile(
        dense: true,
        leading: icon != null
            ? Padding(
                padding: const EdgeInsets.only(left: 15.0),
                child: Icon(
                  icon,
                  size: 22.0,
                  color: Theme.of(context).colorScheme.onSurface,
                  // color: Constants.AppTheme,
                ),
              )
            : null,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15.0,
            color: Constants.AppTheme.menuItem.auto(context),
          ),
        ),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}

class AnimatedMenuCloseButton extends StatefulWidget {
  AnimatedMenuCloseButton({
    Key key,
    this.animateDirection,
    this.iconSize,
    this.size,
    this.iconColor,
    this.onMenuClick,
    this.onCloseClick,
  }) : super(key: key);

  /// If true, on mount will animate to close icon
  /// Else will animate backwards
  /// If omitted - menu icon will be shown on mount without any animation
  final bool animateDirection;
  final double iconSize;
  final double size;
  final Color iconColor;

  /// Handle click when menu is shown
  final Function onMenuClick;

  /// Handle click when close icon is shown
  final Function onCloseClick;

  AnimatedMenuCloseButtonState createState() => AnimatedMenuCloseButtonState();
}

class AnimatedMenuCloseButtonState extends State<AnimatedMenuCloseButton>
    with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: kSMMSelectionDuration);
    _animation =
        CurveTween(curve: Curves.easeOut).animate(_animationController);

    if (widget.animateDirection != null) {
      if (widget.animateDirection) {
        _animationController.forward();
      } else {
        _animationController.value = 0.0;
        _animationController.forward();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SMMIconButton(
      size: widget.size ?? kSMMIconButtonSize,
      iconSize: widget.iconSize ?? kSMMIconButtonIconSize,
      color: Theme.of(context).colorScheme.onSurface,
      onPressed: widget.animateDirection == true
          ? widget.onCloseClick
          : widget.onMenuClick,
      icon: AnimatedIcon(
        icon: widget.animateDirection == null || widget.animateDirection == true
            ? AnimatedIcons.menu_close
            : AnimatedIcons.close_menu,
        color:
            widget.iconColor ?? Constants.AppTheme.playPauseIcon.auto(context),
        progress: _animation,
      ),
    );
  }
}
