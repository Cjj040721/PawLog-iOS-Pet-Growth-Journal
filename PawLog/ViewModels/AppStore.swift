import Foundation
import SwiftData
import UIKit
import WidgetKit

@MainActor
@Observable
final class AppStore {
    private let modelContext: ModelContext

    /// 小组件「在一起第 N 天」的计数基准，写入 App Group 共享存储并刷新 widget。
    var countBase: CountBase {
        didSet {
            WidgetSharedSettings.countBase = countBase
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    /// 当前选中的宠物（多宠物时由「我的」页切换）。为 nil 时调用方回退到第一只。
    var selectedPet: Pet?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.countBase = WidgetSharedSettings.countBase
    }

    // MARK: - 宠物档案

    @discardableResult
    func createPet(name: String, breed: String?, birthday: Date?, adoptionDate: Date?, photo: UIImage?) -> Pet {
        let filename = photo.flatMap { PhotoStore.save($0) }
        let pet = Pet(name: name, breed: breed, birthday: birthday, adoptionDate: adoptionDate, photoFilename: filename)
        modelContext.insert(pet)
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
        return pet
    }

    func updatePet(_ pet: Pet, name: String, breed: String?, birthday: Date?, adoptionDate: Date?, photo: UIImage?) {
        pet.name = name
        pet.breed = breed
        pet.birthday = birthday
        pet.adoptionDate = adoptionDate
        if let photo {
            PhotoStore.delete(pet.photoFilename)
            pet.photoFilename = PhotoStore.save(photo)
        }
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// 计数基准对应的日期；领养日优先，未填则用生日（spec：默认领养日，未填领养日则用生日）。
    func baseDate(for pet: Pet) -> Date? {
        switch countBase {
        case .adoption: pet.adoptionDate ?? pet.birthday
        case .birthday: pet.birthday ?? pet.adoptionDate
        }
    }

    func daysTogether(for pet: Pet) -> Int? {
        baseDate(for: pet).map { Date.daysTogether(from: $0) }
    }

    // MARK: - 照片日记

    /// 一天一条：当天已有记录则更新，否则新建。
    func upsertRecord(for date: Date, pet: Pet, photo: UIImage?, weightKg: Double?, note: String?) {
        let day = date.startOfDay
        let existing = pet.records.first { Calendar.current.isDate($0.date, inSameDayAs: day) }
        if let existing {
            if let photo {
                PhotoStore.delete(existing.photoFilename)
                existing.photoFilename = PhotoStore.save(photo)
            }
            existing.weightKg = weightKg
            existing.note = note
        } else {
            let filename = photo.flatMap { PhotoStore.save($0) }
            let record = DayRecord(date: day, photoFilename: filename, weightKg: weightKg, note: note)
            record.pet = pet
            modelContext.insert(record)
        }
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    func deleteRecord(_ record: DayRecord) {
        PhotoStore.delete(record.photoFilename)
        modelContext.delete(record)
        try? modelContext.save()
    }

    // MARK: - 里程碑

    func addMilestone(pet: Pet, title: String, date: Date) {
        let milestone = Milestone(title: title, date: date)
        milestone.pet = pet
        modelContext.insert(milestone)
        try? modelContext.save()
    }

    func deleteMilestone(_ milestone: Milestone) {
        modelContext.delete(milestone)
        try? modelContext.save()
    }

    // MARK: - 提醒

    /// 安排本地通知并入库。返回 false 表示通知权限被拒，调用方需引导用户去系统设置。
    func addReminder(pet: Pet, type: ReminderType, dueDate: Date) async -> Bool {
        let granted = await NotificationService.shared.ensureAuthorization()
        guard granted else { return false }

        let reminder = Reminder(type: type, dueDate: dueDate)
        reminder.pet = pet
        modelContext.insert(reminder)
        try? modelContext.save()

        let body = "\(pet.name) 的\(type.title)到期了"
        await NotificationService.shared.scheduleReminder(id: reminder.notificationID, body: body, on: dueDate)
        return true
    }

    func deleteReminder(_ reminder: Reminder) {
        NotificationService.shared.cancel(id: reminder.notificationID)
        modelContext.delete(reminder)
        try? modelContext.save()
    }
}
