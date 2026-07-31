import SwiftUI
import SwiftData

/// 「我的」：宠物列表与切换、档案展示 + 编辑、小组件计数基准、提醒管理。
struct ProfileView: View {
    @Environment(AppStore.self) private var store
    @Query private var pets: [Pet]
    let pet: Pet

    @State private var showEditor = false
    @State private var showAddPet = false
    @State private var showReminderEditor = false
    @State private var showNotificationDeniedAlert = false

    var body: some View {
        Form {
            Section("我的宠物") {
                ForEach(pets) { item in
                    Button {
                        store.selectedPet = item
                    } label: {
                        HStack(spacing: 12) {
                            if let image = PhotoStore.load(item.photoFilename) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "pawprint.fill")
                                    .foregroundStyle(Color.pawPrimary)
                                    .frame(width: 36, height: 36)
                                    .background(Color.pawFill, in: Circle())
                            }
                            Text(item.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            if item.persistentModelID == pet.persistentModelID {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                }
                Button("添加宠物") { showAddPet = true }
            }

            Section {
                HStack(spacing: 16) {
                    if let image = PhotoStore.load(pet.photoFilename) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 72, height: 72)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "pawprint.fill")
                            .font(.largeTitle)
                            .foregroundStyle(Color.pawPrimary)
                            .frame(width: 72, height: 72)
                            .background(Color.pawFill, in: Circle())
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(pet.name)
                            .font(.title3.bold())
                        if let breed = pet.breed, !breed.isEmpty {
                            Text(breed)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if let days = store.daysTogether(for: pet) {
                            Text("在一起第 \(days) 天")
                                .font(.subheadline)
                                .monospacedDigit()
                                .foregroundStyle(Color.pawPrimaryStrong)
                        }
                    }
                    Spacer()
                }
                Button("编辑档案") { showEditor = true }
            }

            Section("小组件") {
                Picker("计数基准", selection: Binding(
                    get: { store.countBase },
                    set: { store.countBase = $0 }
                )) {
                    ForEach(CountBase.allCases) { base in
                        Text(base.title).tag(base)
                    }
                }
            }

            Section("提醒") {
                ForEach(pet.reminders.sorted { $0.dueDate < $1.dueDate }) { reminder in
                    HStack {
                        Label(reminder.type.title, systemImage: reminder.type == .vaccine ? "syringe" : "pill")
                        Spacer()
                        Text(reminder.dueDate.pawLogShortFormatted)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete { offsets in
                    let sorted = pet.reminders.sorted { $0.dueDate < $1.dueDate }
                    for index in offsets {
                        store.deleteReminder(sorted[index])
                    }
                }
                Button("添加提醒") { showReminderEditor = true }
            }
        }
        .navigationTitle("我的")
        .sheet(isPresented: $showEditor) {
            NavigationStack {
                PetFormView(existingPet: pet) { _ in showEditor = false }
                    .navigationTitle("编辑档案")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .sheet(isPresented: $showAddPet) {
            NavigationStack {
                PetFormView(existingPet: nil) { newPet in
                    store.selectedPet = newPet
                    showAddPet = false
                }
                    .navigationTitle("添加宠物")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .sheet(isPresented: $showReminderEditor) {
            NavigationStack {
                ReminderEditView(pet: pet, onDenied: {
                    showNotificationDeniedAlert = true
                }) {
                    showReminderEditor = false
                }
                .navigationTitle("添加提醒")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .alert("无法设置提醒", isPresented: $showNotificationDeniedAlert) {
            Button("去设置") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("通知权限已被拒绝，请在系统设置中开启通知后再设置提醒。")
        }
    }
}
