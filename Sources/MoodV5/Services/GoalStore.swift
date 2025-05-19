import Foundation
import RealmSwift
import Combine

protocol GoalStore {
    func save(_ goal: Goal) throws
    func fetchAllGoals() -> [Goal]
    func delete(goal: Goal) throws
    func update(_ goal: Goal) throws
    var goalsPublisher: AnyPublisher<[Goal], Never> { get }
}

class RealmGoalStore: GoalStore {
    private let realm: Realm
    private let goalsSubject = CurrentValueSubject<[Goal], Never>([])
    
    var goalsPublisher: AnyPublisher<[Goal], Never> {
        goalsSubject.eraseToAnyPublisher()
    }
    
    init() throws {
        realm = try Realm()
        setupNotificationToken()
    }
    
    private func setupNotificationToken() {
        let goals = realm.objects(Goal.self)
        goalsSubject.send(Array(goals))
        
        let token = goals.observe { [weak self] changes in
            switch changes {
            case .initial(let goals):
                self?.goalsSubject.send(Array(goals))
            case .update(let goals, _, _, _):
                self?.goalsSubject.send(Array(goals))
            case .error(let error):
                print("Error observing goals: \(error)")
            }
        }
    }
    
    func save(_ goal: Goal) throws {
        try realm.write {
            realm.add(goal)
        }
    }
    
    func fetchAllGoals() -> [Goal] {
        Array(realm.objects(Goal.self).sorted(byKeyPath: "startDate", ascending: false))
    }
    
    func delete(goal: Goal) throws {
        try realm.write {
            realm.delete(goal)
        }
    }
    
    func update(_ goal: Goal) throws {
        try realm.write {
            realm.add(goal, update: .modified)
        }
    }
} 