import Foundation
import RealmSwift
import Combine

protocol SettingsStore {
    func save(_ settings: UserSettings) throws
    func fetchSettings() -> UserSettings
    func update(_ settings: UserSettings) throws
    var settingsPublisher: AnyPublisher<UserSettings, Never> { get }
}

class RealmSettingsStore: SettingsStore {
    private let realm: Realm
    private let settingsSubject = CurrentValueSubject<UserSettings, Never>(UserSettings())
    private var observationToken: NotificationToken?
    
    var settingsPublisher: AnyPublisher<UserSettings, Never> {
        settingsSubject.eraseToAnyPublisher()
    }
    
    init() throws {
        realm = try Realm()
        setupNotificationToken()
    }
    
    private func setupNotificationToken() {
        let settings = realm.objects(UserSettings.self)
        
        if let existingSettings = settings.first {
            settingsSubject.send(existingSettings)
        } else {
            // Create default settings if none exist
            let defaultSettings = UserSettings()
            try? save(defaultSettings)
        }
        
        observationToken = settings.observe { [weak self] changes in
            switch changes {
            case .initial(let settings):
                if let first = settings.first {
                    self?.settingsSubject.send(first)
                }
            case .update(let settings, _, _, _):
                if let first = settings.first {
                    self?.settingsSubject.send(first)
                }
            case .error(let error):
                print("Error observing settings: \(error)")
            }
        }
    }
    
    func save(_ settings: UserSettings) throws {
        try realm.write {
            realm.add(settings)
        }
    }
    
    func fetchSettings() -> UserSettings {
        if let settings = realm.objects(UserSettings.self).first {
            return settings
        }
        return UserSettings()
    }
    
    func update(_ settings: UserSettings) throws {
        try realm.write {
            realm.add(settings, update: .modified)
        }
    }
} 