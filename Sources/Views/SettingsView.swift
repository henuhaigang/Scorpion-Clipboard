import KeyboardShortcuts
import SwiftUI

struct SettingsView: View {
    @Bindable var settings: SettingsModel
    @Bindable var ignoreListManager: IgnoreListManager

    @State private var showAppPicker = false

    var body: some View {
        TabView {
            generalTab
            ignoreTab
        }
        .frame(width: 450, height: 350)
    }

    private var generalTab: some View {
        Form {
            Section("历史记录") {
                Picker("最大条数", selection: $settings.historyLimit) {
                    ForEach([10, 20, 30, 40, 50, 60, 70, 80, 90, 100], id: \.self) { count in
                        Text("\(count) 条").tag(count)
                    }
                }

                Toggle("重启后保留历史", isOn: $settings.persistAfterRestart)
            }

            Section("快捷键") {
                KeyboardShortcuts.Recorder("显示/隐藏面板", name: .togglePanel)
            }

            Section("面板位置") {
                Picker("显示方式", selection: $settings.panelPosition) {
                    Text("菜单栏下拉").tag(PanelPosition.menuBar)
                    Text("独立浮动窗口").tag(PanelPosition.floatingWindow)
                    Text("跟随鼠标").tag(PanelPosition.followMouse)
                    Text("固定位置").tag(PanelPosition.fixedPosition)
                }
            }
        }
        .formStyle(.grouped)
        .tabItem { Label("通用", systemImage: "gear") }
    }

    private var ignoreTab: some View {
        VStack {
            List {
                ForEach(ignoreListManager.ignoredBundleIDs, id: \.self) { bundleID in
                    HStack {
                        Text(bundleID)
                        Spacer()
                        Button(role: .destructive) {
                            ignoreListManager.removeIgnoredApp(bundleID)
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack {
                Spacer()
                Button {
                    showAppPicker = true
                } label: {
                    Label("添加应用", systemImage: "plus")
                }
            }
            .padding()
        }
        .tabItem { Label("忽略列表", systemImage: "app.badge.checkmark") }
        .sheet(isPresented: $showAppPicker) {
            AppPickerSheet(ignoreListManager: ignoreListManager)
        }
    }
}

struct AppPickerSheet: View {
    let ignoreListManager: IgnoreListManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            Text("选择要忽略的应用")
                .font(.headline)
                .padding()

            List {
                ForEach(ignoreListManager.runningApps(), id: \.bundleID) { app in
                    HStack {
                        Text(app.name)
                        Spacer()
                        Text(app.bundleID)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if ignoreListManager.isAppIgnored(bundleID: app.bundleID) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if ignoreListManager.isAppIgnored(bundleID: app.bundleID) {
                            ignoreListManager.removeIgnoredApp(app.bundleID)
                        } else {
                            ignoreListManager.addIgnoredApp(app.bundleID)
                        }
                    }
                }
            }

            Button("完成") { dismiss() }
                .padding()
        }
        .frame(width: 400, height: 400)
    }
}
