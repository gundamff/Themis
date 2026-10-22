### Task 0: 恢复完整上游 Themis 工作树

**Files:**
- Sync: 整个上游 `gundamff/Themis` `main` 到本工作区（保留已有 `docs/superpowers/**` 与 `.gitignore`）
- Do not commit: `_pdf_extract/`

**Interfaces:**
- Consumes: 无
- Produces: 上游全部现有文件可读可改（`SOUL.md`、`skills/**`、`scripts/verify.sh` 等）

- [ ] **Step 1: 拉取上游到临时目录**

```bash
# Windows PowerShell — 优先 git；失败则 gh 或 zip
git clone --depth 1 https://github.com/gundamff/Themis.git "$env:TEMP\Themis-upstream"
```

Expected: 克隆成功，`$env:TEMP\Themis-upstream` 含 `SOUL.md`、`skills/`、`scripts/`。

- [ ] **Step 2: 合并进工作区（不覆盖设计文档）**

```powershell
# 从上游复制除 .git 外的文件；已存在的 docs/superpowers 与本地 .gitignore 保留/合并
robocopy "$env:TEMP\Themis-upstream" "D:\eclipse\git\Themis" /E /XD .git _pdf_extract docs\superpowers
# 确认 docs/superpowers 仍在
Test-Path "D:\eclipse\git\Themis\docs\superpowers\specs\2026-10-22-themis-hermes-security-design.md"
Test-Path "D:\eclipse\git\Themis\SOUL.md"
```

Expected: 两个 `Test-Path` 均为 `True`。

- [ ] **Step 3: 合并 .gitignore（保留 `_pdf_extract/` 忽略）**

确保 `.gitignore` 至少包含上游规则，并保留：

```
_pdf_extract/
config/secrets.env
inventory/hosts.yaml
*.env
!*.env.example
```

- [ ] **Step 4: Commit 工作树基线（若相对 design-only 根提交有新增上游文件）**

```bash
git add -A
git status
git commit -m "chore: sync upstream Themis tree while keeping design docs"
```

---
