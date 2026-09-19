# cargo 模块

> 面包屑：[dotfiles](../CLAUDE.md) > cargo

## 职责

Cargo 的 registry 镜像源配置，把 `crates.io` 替换为国内镜像（阿里云/中科大/上交/清华/rustcc），加速依赖拉取。

## 文件清单

| 文件 | symlink 目标 | 用途 |
|------|-------------|------|
| `.cargo/config.toml` | `~/.cargo/config.toml` | Cargo 镜像源配置 |

## 主要配置项

- `[source.crates-io] replace-with = 'aliyun'` —— 默认使用阿里云 sparse 镜像（`sparse+` 协议，需 cargo ≥ 1.68）
- 备选源按需切换：把 `replace-with` 改为 `ustc` / `sjtu` / `tuna` / `rustcc` 即可

## 修改指南

- 更换默认镜像 → 编辑 `.cargo/config.toml` 中 `[source.crates-io] replace-with` 的值
- 新增镜像源 → 追加一个 `[source.<name>]` 段（`registry = "<sparse|git>+<url>"`）

## 注意

- `cargo search` / `cargo publish` 不走 source 替换（直接访问 crates.io API），在镜像配置下不受支持是预期行为；`cargo add / build / fetch` 正常走镜像。