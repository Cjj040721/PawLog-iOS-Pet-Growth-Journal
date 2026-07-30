import SwiftUI

/// 添加疫苗 / 驱虫提醒。保存时检查通知权限，被拒则回调 onDenied 引导去系统设置。
struct ReminderEditView: View {
    @Environment(AppStore.self) private var store
    let pet: Pet
    var onDenied: () -> Void
    var onDone: () -> Void

    @State private var type: ReminderType = .vaccine
    @State private var dueDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var isSaving = false

    var body: some View {
        Form {
            Picker("类型", selection: $type) {
                ForEach(ReminderType.allCases) { item in
                    Text(item.title).tag(item)
                }
            }
            .pickerStyle(.segmented)

            DatePicker("到期日", selection: $dueDate, in: Date()..., displayedComponents: .date)

            Section {
                Text("到期当天上午 9:00 会收到本地通知")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Button(isSaving ? "保存中…" : "保存提醒") {
                save()
            }
            .frame(maxWidth: .infinity)
            .font(.headline)
            .disabled(isSaving)
        }
    }

    private func save() {
        isSaving = true
        Task { @MainActor in
            let scheduled = await store.addReminder(pet: pet, type: type, dueDate: dueDate)
            isSaving = false
            if scheduled {
                onDone()
            } else {
                onDenied()
            }
        }
    }
}
