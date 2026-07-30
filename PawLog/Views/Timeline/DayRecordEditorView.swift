import SwiftUI

/// 拍完照后填写体重 / 备注并保存；同一天重复保存为更新当天记录。
/// 日期可选过去某天，用于补记；选了已有记录的日期会预填并提示将更新。
struct DayRecordEditorView: View {
    @Environment(AppStore.self) private var store
    let pet: Pet
    let image: UIImage
    var onDone: () -> Void

    @State private var date = Date()
    @State private var weightText = ""
    @State private var note = ""

    /// 所选日期已有的记录（有则保存为更新）
    private var existingRecord: DayRecord? {
        pet.records.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            Section("日期") {
                DatePicker("记录日期", selection: $date, in: ...Date(), displayedComponents: .date)
                if existingRecord != nil {
                    Text("当天已有记录，保存将覆盖更新")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            }

            Section("可选信息") {
                HStack {
                    Text("体重")
                    Spacer()
                    TextField("kg", text: $weightText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
                TextField("备注", text: $note, axis: .vertical)
                    .lineLimit(2...4)
            }

            Button("保存记录") {
                let weight = Double(weightText.replacingOccurrences(of: ",", with: "."))
                let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
                store.upsertRecord(
                    for: date,
                    pet: pet,
                    photo: image,
                    weightKg: weight,
                    note: trimmedNote.isEmpty ? nil : trimmedNote
                )
                onDone()
            }
            .frame(maxWidth: .infinity)
            .font(.headline)
        }
        .onChange(of: date, initial: true) { _, newDate in
            // 切到已有记录的日期时预填体重和备注，便于修改而不是从头填
            if let existing = pet.records.first(where: { Calendar.current.isDate($0.date, inSameDayAs: newDate) }) {
                weightText = existing.weightKg.map { String(format: "%.1f", $0) } ?? ""
                note = existing.note ?? ""
            } else {
                weightText = ""
                note = ""
            }
        }
    }
}
