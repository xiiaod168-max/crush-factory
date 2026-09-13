# Public release checklist

这份清单用于把源码和可运行 Build 放到 GitHub。源码提交不包含导出缓存、历史录屏或本地存档。

## Repository

- Repository visibility: Public
- Repository name: `crush-factory`
- Default branch: `main`
- License: MIT
- About / topics: see [GITHUB_METADATA.md](GITHUB_METADATA.md)
- Social preview: `docs/media/hero.png`

## Release

1. Create tag `v0.6.0-m6-review.1` from the public source commit.
2. Create a GitHub Release titled `M6 Content Expansion Prototype`.
3. Upload `CrushFactory-M6-review-01-Windows-x64.zip` as the release asset.
4. Link `gameplay-full.mp4` from the release or attach it separately if the repository bandwidth is acceptable.
5. Keep the release marked as a review prototype until M6 receives visual acceptance.

## Before publishing

- Run `git diff --check`.
- Run the content, progress, controller, and existing-material regression tests.
- Confirm no `.env`, token, key, personal save, or local machine credential is staged.
- Confirm the ZIP opens and the Windows executable starts on a clean machine.
- Keep the M5 stable commit `834dc10` available as a rollback point.
