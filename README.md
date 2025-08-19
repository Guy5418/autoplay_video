# autoplay_video

Feed-style auto-play video (IG/FB): single-playing exclusivity, visibility-based play/pause, Tap to unmute, loop, BoxFit & border radius.

## Use
```dart
AutoPlayVideo(
  postId: 'p1',
  videoUrl: 'https://…/video.mp4',
  thumbUrl: 'https://…/thumb.jpg',
  playThreshold: 0.6,
  startMuted: true,
  loop: true,
  borderRadius: 12,
  fit: BoxFit.cover,
)

---

## 3) Git : init → commit → tag → push

Dans **PowerShell** (depuis le dossier du repo) :

```powershell
git init
git add .
git commit -m "v0.1.0: first clean release - single library structure"

# Lier le dépôt GitHub (remplace TON_USER)
git remote add origin https://github.com/Guy5418/autoplay_video.git

# Tag version
git tag v0.1.0

# Push code + tags
git push -u origin main
git push origin --tags
