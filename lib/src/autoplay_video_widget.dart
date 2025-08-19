import 'dart:math';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Partage l'ID du post en lecture pour garantir une seule vidéo jouée.
class _FeedNowPlaying {
  static final ValueNotifier<String?> current = ValueNotifier<String?>(null);
}

/// Vidéo autoplay style feed (play quand visible, pause sinon) + mute/unmute.
class AutoPlayVideo extends StatefulWidget {
  const AutoPlayVideo({
    super.key,
    required this.postId,
    required this.videoUrl,
    this.thumbUrl,
    this.playThreshold = 0.6,
    this.startMuted = true,
    this.loop = true,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
  });

  final String postId, videoUrl;
  final String? thumbUrl;
  final double playThreshold, borderRadius;
  final bool startMuted, loop;
  final BoxFit fit;

  @override
  State<AutoPlayVideo> createState() => _AutoPlayVideoState();
}

class _AutoPlayVideoState extends State<AutoPlayVideo>
    with AutomaticKeepAliveClientMixin {
  VideoPlayerController? _c;
  bool _inited = false, _muted = true, _showHint = false;
  double _visible = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _muted = widget.startMuted;
    _init();
    _FeedNowPlaying.current.addListener(_onGlobal);
  }

  Future<void> _init() async {
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    await c.initialize();
    await c.setLooping(widget.loop);
    await c.setVolume(_muted ? 0 : 1);
    if (!mounted) return;
    setState(() {
      _c = c;
      _inited = true;
    });
    _apply();
  }

  void _onGlobal() {
    if (_c != null &&
        _FeedNowPlaying.current.value != widget.postId &&
        _c!.value.isPlaying) {
      _c!.pause();
    }
  }

  void _apply() {
    if (!_inited || _c == null) return;
    final play = _visible >= widget.playThreshold;
    if (play) {
      if (_FeedNowPlaying.current.value != widget.postId) {
        _FeedNowPlaying.current.value = widget.postId;
      }
      if (!_c!.value.isPlaying) {
        _c!.play();
        if (_muted) _hint();
      }
    } else {
      if (_c!.value.isPlaying) _c!.pause();
    }
    if (mounted) setState(() {});
  }

  void _hint() async {
    setState(() => _showHint = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _showHint = false);
  }

  Future<void> _toggleMute() async {
    if (_c == null) return;
    _muted = !_muted;
    await _c!.setVolume(_muted ? 0 : 1);
    if (!_muted) _showHint = false;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _FeedNowPlaying.current.removeListener(_onGlobal);
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ar = (_c?.value.aspectRatio == null || _c!.value.aspectRatio == 0)
        ? 9 / 16
        : max(0.01, _c!.value.aspectRatio);

    return VisibilityDetector(
      key: Key('vp_${widget.postId}'),
      onVisibilityChanged: (i) {
        _visible = i.visibleFraction.clamp(0.0, 1.0);
        _apply();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: AspectRatio(
          aspectRatio: ar,
          child: Stack(fit: StackFit.expand, children: [
            if (!_inited && widget.thumbUrl != null)
              Image.network(widget.thumbUrl!, fit: widget.fit),
            if (_inited)
              FittedBox(
                fit: widget.fit,
                child: SizedBox(
                  width: _c!.value.size.width,
                  height: _c!.value.size.height,
                  child: VideoPlayer(_c!),
                ),
              ),
            // zone de tap
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    if (_c == null) return;
                    if (_c!.value.isPlaying && _muted) {
                      await _toggleMute();
                    } else {
                      if (_c!.value.isPlaying) {
                        _c!.pause();
                      } else {
                        _FeedNowPlaying.current.value = widget.postId;
                        await _c!.play();
                        if (_muted) _hint();
                      }
                      setState(() {});
                    }
                  },
                ),
              ),
            ),
            // hint
            if (_c?.value.isPlaying == true && _muted)
              IgnorePointer(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: _showHint ? 1 : 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text(
                        'Tap to unmute',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // bouton mute
            Positioned(
              top: 10,
              right: 10,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Material(
                  color: Colors.black54,
                  child: InkWell(
                    onTap: _toggleMute,
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.volume_off, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
