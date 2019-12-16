/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter_music_player/components/custom_icon_button.dart';
import 'package:flutter_music_player/logic/player/player_widgets.dart';
import 'package:flutter_music_player/constants/constants.dart';
import 'package:flutter_music_player/logic/player/playlist.dart';

// import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_music_player/logic/player/nativePlayer.dart';

import 'package:flutter/material.dart';
import 'package:flutter_music_player/logic/player/player.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'album_art.dart';
import 'play_pause_button.dart';
import 'dart:async';

const double progressLineHeight = 3.0;

/// FIXME: art rotating on main and search routes are distinct

/// Renders current playing track
class BottomTrackPanel extends StatelessWidget {
  BottomTrackPanel({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (PlaylistControl.songsEmpty(PlaylistType.global))
      return SizedBox.shrink();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: StreamBuilder(
              stream: MusicPlayer.onPlayerStateChanged,
              builder: (context, snapshot) {
                return Material(
                  color: AppTheme.bottomTrackPanel.auto(context),
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.of(context).pushNamed(Routes.player.value);
                    },
                    child: ListTile(
                      dense: true,
                      isThreeLine: false,
                      contentPadding: EdgeInsets.only(
                          top: 5.0, bottom: 5.0, left: 10.0, right: 10.0),
                      title: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            PlaylistControl.currentSong?.title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 16.5),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Artist(
                                artist: PlaylistControl.currentSong?.artist,
                                // textStyle: TextStyle(fontWeight: ThemeControl.isDark ? FontWeight.w400 : FontWeight.w500),
                                ),
                          ),
                        ],
                      ),
                      leading: RotatingAlbumArtWithProgress(),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Transform.translate(
                            offset: Offset(10, 0),
                            child: AnimatedPlayPauseButton(
                              isLarge: true,
                            ),
                          ),
                          CustomIconButton(
                            iconSize: 32,
                            splashColor: AppTheme.splash.auto(context),
                            size: 56,
                            icon: Icon(Icons.skip_next),
                            color: AppTheme.playPauseIcon.auto(context),
                            onPressed: MusicPlayer.playNext,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
        ),
      ),
    );
  }
}

class RotatingAlbumArtWithProgress extends StatefulWidget {
  RotatingAlbumArtWithProgress({Key key}) : super(key: key);

  @override
  _RotatingAlbumArtWithProgressState createState() =>
      _RotatingAlbumArtWithProgressState();
}

class _RotatingAlbumArtWithProgressState
    extends State<RotatingAlbumArtWithProgress> {
  /// Actual track position value
  Duration _value = Duration(seconds: 0);
  // Duration of playing track
  Duration _duration = Duration(seconds: 0);

  StreamSubscription<Duration> _changePositionSubscription;
  StreamSubscription<void> _changeSongSubscription;
  StreamSubscription<AudioPlayerState> _playerStateChangeSubscription;

  GlobalKey<RotatingAlbumArtState> _rotatingArtGlobalKey =
      GlobalKey<RotatingAlbumArtState>();

  @override
  void initState() {
    super.initState();

    _setInitialCurrentPosition();

    _playerStateChangeSubscription =
        MusicPlayer.onPlayerStateChanged.listen((event) {
      switch (event) {
        case AudioPlayerState.PLAYING:
          _rotatingArtGlobalKey.currentState.rotate();
          break;
        case AudioPlayerState.PAUSED:
        case AudioPlayerState.COMPLETED:
        case AudioPlayerState.STOPPED:
        default: // Can be null so don't throw, just stop animation
          _rotatingArtGlobalKey.currentState.stopRotating();
          break;
      }
    });

    // Handle track position movement
    _changePositionSubscription =
        MusicPlayer.onAudioPositionChanged.listen((event) {
      if (event.inSeconds != _value.inSeconds) {
        // Prevent waste updates
        setState(() {
          _value = event;
        });
      }
    });

    // Handle song change
    _changeSongSubscription =
        PlaylistControl.onSongChange.listen((event) async {
      _value = await MusicPlayer.currentPosition;
      setState(() {
        _duration =
            Duration(milliseconds: PlaylistControl.currentSong?.duration);
      });
    });
  }

  @override
  void dispose() {
    _playerStateChangeSubscription.cancel();
    _changePositionSubscription.cancel();
    _changeSongSubscription.cancel();
    super.dispose();
  }

  _setInitialCurrentPosition() async {
    var currentPosition = await MusicPlayer.currentPosition;
    setState(() {
      _value = currentPosition;
      _duration = Duration(milliseconds: PlaylistControl.currentSong?.duration);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: CircularPercentIndicator(
        percent: _value.inMilliseconds / _duration.inMilliseconds,
        radius: 48.0 -
            progressLineHeight, // 48.0 is `constraints.maxHeight` if we see it in `LayoutBuilder`
        lineWidth: progressLineHeight,
        circularStrokeCap: CircularStrokeCap.round,
        progressColor: Colors.deepPurple,
        backgroundColor: Colors.transparent,
        center: RotatingAlbumArt(
          key: _rotatingArtGlobalKey,
          path: PlaylistControl.currentSong?.albumArtUri,
          initIsRotating: MusicPlayer.playState == AudioPlayerState.PLAYING,
        ),
      ),
    );
  }
}
