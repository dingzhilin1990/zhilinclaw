# ZhiLinClaw - GitHub 上传指南

## 📋 上传步骤

### 方式 1: 使用 GitHub CLI（推荐）

#### 1. 安装 GitHub CLI（如果未安装）
```bash
# Windows (winget)
winget install GitHub.cli

# 或者下载 https://cli.github.com/
```

#### 2. 登录 GitHub
```bash
gh auth login
```

按照提示完成认证。

#### 3. 创建并推送仓库
```bash
cd c:\Users\neal_\zhilinclaw

# 创建公开仓库
gh repo create zhilinclaw --public --source=. --remote=origin --push

# 或者创建私有仓库
# gh repo create zhilinclaw --private --source=. --remote=origin --push
```

完成！🎉

---

### 方式 2: 手动在 GitHub 网站操作

#### 步骤 1: 创建新仓库
1. 访问 https://github.com/new
2. 仓库名称：`zhilinclaw`
3. 描述：`本地优先的开源 AI助手框架 - 融合 OpenClaw + IronClaw + Hanwudi 三大理念`
4. 选择 **Public**（公开）或 **Private**（私有）
5. **不要**勾选 "Add a README file"
6. **不要**勾选 ".gitignore"
7. **不要**选择许可证（已包含 Apache-2.0）
8. 点击 "Create repository"

#### 步骤 2: 关联远程仓库并推送
```bash
cd c:\Users\neal_\zhilinclaw

# 如果之前添加过远程地址，先删除
git remote remove origin

# 添加新的远程地址（替换为你的用户名）
git remote add origin https://github.com/YOUR_USERNAME/zhilinclaw.git

# 推送到 GitHub
git push -u origin main
```

---

### 方式 3: 使用 Git 凭据管理器（Windows）

#### 1. 安装 Git Credential Manager
下载地址：https://github.com/GitCredentialManager/git-credential-manager/releases

#### 2. 创建仓库并推送
```bash
cd c:\Users\neal_\zhilinclaw

# 创建仓库（会提示浏览器登录）
gh repo create zhilinclaw --public --source=. --remote=origin --push
```

---

## 🔐 认证方式

### 使用 Personal Access Token

如果使用 HTTPS 推送时提示认证失败：

1. 访问 https://github.com/settings/tokens
2. 点击 "Generate new token (classic)"
3. 选择权限：`repo` (Full control of private repositories)
4. 生成后复制 Token
5. 推送时使用 Token 作为密码

```bash
# 推送时会提示输入用户名和密码
# 用户名：你的 GitHub 用户名
# 密码：刚才生成的 Token
git push -u origin main
```

---

## ✅ 验证上传成功

推送成功后，访问：
```
https://github.com/YOUR_USERNAME/zhilinclaw
```

应该能看到所有文件。

---

## 📝 后续操作建议

### 1. 完善仓库信息
- [ ] 添加 Topics 标签：`ai`, `agent`, `openharmony`, `harmonyos`, `arkts`, `metagpt`
- [ ] 设置网站：如果有 GitHub Pages
- [ ] 添加项目链接到 README

### 2. 保护主分支
1. 进入 Settings → Branches
2. 添加分支保护规则：`main`
3. 勾选 "Require a pull request before merging"

### 3. 添加 CI/CD（可选）
创建 `.github/workflows/ci.yml`：
```yaml
name: CI

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '16'
      - name: Install dependencies
        run: npm install
      - name: Build
        run: npm run build
```

---

## 🎉 分享你的项目

上传成功后，可以：
1. 在社交媒体分享项目链接
2. 提交到 OpenHarmony 社区
3. 参与开源项目展示
4. 邀请协作者加入

---

## 📞 遇到问题？

### 常见错误及解决方案

**错误 1: Repository not found**
```bash
# 原因：GitHub 上还没有创建这个仓库
# 解决：先在 GitHub 创建空仓库，再推送
```

**错误 2: Authentication failed**
```bash
# 原因：认证失败
# 解决：使用 Personal Access Token 代替密码
```

**错误 3: Permission denied**
```bash
# 原因：没有权限写入仓库
# 解决：检查是否是仓库所有者或有写入权限
```

---

## 🔗 相关链接

- [GitHub 文档](https://docs.github.com/)
- [Git 快速参考](https://education.github.com/git-cheat-sheet-education.pdf)
- [GitHub CLI 文档](https://cli.github.com/manual/)

---

🤖 Generated with ZhiLinClaw Framework
