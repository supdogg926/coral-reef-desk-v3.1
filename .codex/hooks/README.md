# Codex Hooks 模板说明

本目录只放低风险 Hooks 模板。

当前策略：

- 先提交模板，不直接接管 Codex 全局配置。
- 避免因为 hook 配置格式差异导致 Codex 启动失败。
- 后续在副本仓库验证通过后，再决定是否启用。

目标：

- 拦截 `git checkout main`。
- 拦截 `git switch main`。
- 拦截 `git merge main`。
- 拦截 `git rebase main`。
- 拦截 `git tag`。
- 拦截 `project.godot` 修改。
- 提醒每次 commit 前输出 diff 摘要。
