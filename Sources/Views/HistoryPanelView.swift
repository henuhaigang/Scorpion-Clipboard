import SwiftUI

struct HistoryPanelView: View {
    @Bindable var viewModel: HistoryViewModel
    var onDismiss: () -> Void

    @State private var hoveredItem: ClipboardItem?

    var body: some View {
        VStack(spacing: 0) {
            headerView
            searchBar
            Divider().opacity(0.5)
            itemList
            footerView
        }
        .frame(width: 380, height: 500)
        .background(VisualEffectBlur(material: .sheet, blendingMode: .behindWindow))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Image(systemName: "clipboard.fill")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("ScorpionClipboard")
                .font(.headline)
            Spacer()
            Text("\(viewModel.itemCount) 条记录")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.callout)
            TextField("搜索剪贴板历史...", text: Binding(
                get: { viewModel.searchText },
                set: { viewModel.updateSearch($0) }
            ))
            .textFieldStyle(.plain)
            .font(.callout)
 
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.updateSearch("")
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(Color.primary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Item List

    private var itemList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(Array(viewModel.filteredItems.enumerated()), id: \.element.id) { index, item in
                        ClipboardItemRow(
                            item: item,
                            index: index + 1,
                            isSelected: viewModel.selectedRowIndex == index,
                            isHovered: hoveredItem?.id == item.id,
                            onTap: {
                                viewModel.pasteItem(item)
                                onDismiss()
                            },
                            onDelete: { viewModel.deleteItem(item) },
                            onIgnoreApp: { viewModel.ignoreCurrentApp() }
                        )
                        .onHover { hovering in
                            hoveredItem = hovering ? item : nil
                        }
                        .id(item.id)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .onChange(of: viewModel.selectedRowIndex) { _, newValue in
                guard newValue >= 0, newValue < viewModel.filteredItems.count else { return }
                let targetId = viewModel.filteredItems[newValue].id
                withAnimation(.easeInOut(duration: 0.15)) {
                    proxy.scrollTo(targetId, anchor: .center)
                }
            }
        }
    }

    // MARK: - Footer

    @ViewBuilder
    private var footerView: some View {
        if let status = viewModel.statusMessage {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text(status)
                    .font(.caption)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.primary.opacity(0.05))
        } else {
            HStack(spacing: 12) {
                Label("↑↓ 选择", systemImage: "arrow.up.arrow.down")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Label("Enter 粘贴", systemImage: "keyboard")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Label("点击粘贴", systemImage: "hand.tap")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Text("ESC 关闭")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.primary.opacity(0.03))
        }
    }
}

// MARK: - Clipboard Item Row

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let index: Int
    let isSelected: Bool
    let isHovered: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    let onIgnoreApp: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            indexBadge
            contentPreview
            Spacer()
            shortcutHint
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("删除", systemImage: "trash")
            }

            Divider()

            Button {
                onIgnoreApp()
            } label: {
                Label("忽略当前应用", systemImage: "eye.slash")
            }
        }
        .help(item.fullText ?? item.briefText)
    }

    // MARK: - Index Badge

    private var indexBadge: some View {
        ZStack {
            Circle()
                .fill(index <= 9 ? Color.accentColor.opacity(0.15) : Color.clear)
                .frame(width: 24, height: 24)

            Text(index <= 9 ? "\(index % 10)" : "")
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(index <= 9 ? Color.accentColor : .clear)
        }
    }

    // MARK: - Content Preview

    @ViewBuilder
    private var contentPreview: some View {
        switch item.type {
        case .text, .rtf:
            Text(item.briefText)
                .lineLimit(2)
                .font(.system(.body, design: .default))
                .foregroundStyle(.primary)

        case .image:
            HStack(spacing: 8) {
                if let data = item.thumbnailData, let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        )
                }
                Text("图片")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

        case .fileURL:
            HStack(spacing: 8) {
                Image(systemName: "doc.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.briefText)
                        .lineLimit(1)
                        .font(.callout)
                    if let path = item.filePath {
                        Text(path)
                            .lineLimit(1)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }

    // MARK: - Shortcut Hint

    @ViewBuilder
    private var shortcutHint: some View {
        if index <= 9 {
            Text("\(index % 10)")
                .font(.system(.caption2, design: .rounded, weight: .medium))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.primary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }

    // MARK: - Row Background

    @ViewBuilder
    private var rowBackground: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.accentColor.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor.opacity(0.4), lineWidth: 1)
                )
        } else if isHovered {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.accentColor.opacity(0.08))
        } else {
            Color.clear
        }
    }
}

// MARK: - Visual Effect Blur

struct VisualEffectBlur: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
