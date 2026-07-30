import SwiftUI

struct MilestoneEditView: View {
    @Environment(AppStore.self) private var store
    let pet: Pet
    var onDone: () -> Void

    @State private var title = ""
    @State private var date = Date()
    @State private var showValidation = false

    var body: some View {
        Form {
            TextField("标题（如：第一次打疫苗）", text: $title)
            DatePicker("日期", selection: $date, displayedComponents: .date)
            if showValidation {
                Text("请填写里程碑标题")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
            Button("保存") {
                let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    showValidation = true
                    return
                }
                store.addMilestone(pet: pet, title: trimmed, date: date)
                onDone()
            }
            .frame(maxWidth: .infinity)
            .font(.headline)
        }
    }
}
