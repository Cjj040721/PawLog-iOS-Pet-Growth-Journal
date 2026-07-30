import SwiftUI
import PhotosUI

/// 档案表单：启动引导（创建）与档案页（编辑）共用。
/// 校验：名字必填；生日 / 领养日至少填一个。
struct PetFormView: View {
    @Environment(AppStore.self) private var store

    /// 非 nil 表示编辑模式
    let existingPet: Pet?
    var onSaved: (Pet) -> Void

    @State private var name: String
    @State private var breed: String
    @State private var birthday: Date?
    @State private var adoptionDate: Date?
    @State private var photo: UIImage?
    @State private var pickedItem: PhotosPickerItem?
    @State private var validationMessage: String?

    init(existingPet: Pet?, onSaved: @escaping (Pet) -> Void) {
        self.existingPet = existingPet
        self.onSaved = onSaved
        _name = State(initialValue: existingPet?.name ?? "")
        _breed = State(initialValue: existingPet?.breed ?? "")
        _birthday = State(initialValue: existingPet?.birthday)
        _adoptionDate = State(initialValue: existingPet?.adoptionDate)
        _photo = State(initialValue: PhotoStore.load(existingPet?.photoFilename))
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    let currentPhoto = photo
                    PhotosPicker(selection: $pickedItem, matching: .images) {
                        if let currentPhoto {
                            Image(uiImage: currentPhoto)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 96, height: 96)
                                .clipShape(Circle())
                        } else {
                            ZStack {
                                Circle()
                                    .fill(Color(.systemGray5))
                                    .frame(width: 96, height: 96)
                                Image(systemName: "camera.fill")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            Section("基本信息") {
                TextField("名字（必填）", text: $name)
                TextField("品种（可选）", text: $breed)
            }

            Section("重要日期（至少填一个）") {
                OptionalDatePicker(title: "生日", date: $birthday)
                OptionalDatePicker(title: "领养日", date: $adoptionDate)
            }

            if let validationMessage {
                Section {
                    Text(validationMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }

            Section {
                Button(existingPet == nil ? "创建档案" : "保存") {
                    save()
                }
                .frame(maxWidth: .infinity)
                .font(.headline)
            }
        }
        .onChange(of: pickedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    photo = image
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            validationMessage = "请填写宠物的名字"
            return
        }
        guard birthday != nil || adoptionDate != nil else {
            validationMessage = "生日和领养日至少填写一个"
            return
        }
        validationMessage = nil
        let trimmedBreed = breed.trimmingCharacters(in: .whitespacesAndNewlines)
        let breedValue = trimmedBreed.isEmpty ? nil : trimmedBreed

        if let existingPet {
            store.updatePet(existingPet, name: trimmedName, breed: breedValue, birthday: birthday, adoptionDate: adoptionDate, photo: photo)
            onSaved(existingPet)
        } else {
            let pet = store.createPet(name: trimmedName, breed: breedValue, birthday: birthday, adoptionDate: adoptionDate, photo: photo)
            onSaved(pet)
        }
    }
}

/// 可清空的日期选择：默认「未设置」，开启后出现 DatePicker。
private struct OptionalDatePicker: View {
    let title: String
    @Binding var date: Date?

    var body: some View {
        if date != nil {
            DatePicker(
                title,
                selection: Binding(
                    get: { date ?? Date() },
                    set: { date = $0 }
                ),
                in: ...Date(),
                displayedComponents: .date
            )
            Button("清除\(title)", role: .destructive) {
                date = nil
            }
            .font(.footnote)
        } else {
            Button("设置\(title)") {
                date = Date()
            }
        }
    }
}
