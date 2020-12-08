//
//  TaskController.swift
//  Tasks
//
//  Created by Jeff Kang on 12/6/20.
//  Copyright © 2020 Lambda School. All rights reserved.
//

import Foundation
import CoreData

enum NetworkError: Error {
    case noIdentifier
    case noRep
    case otherError
    case noData
    case failedDecode
    case failedEncode
}

class TaskController {
    let baseURL = URL(string: "https://ios-tasks-96397-default-rtdb.firebaseio.com/")!
    
    typealias CompletionHandler = (Result<Bool, NetworkError>) -> Void
    
    init() {
        fetchTasksFromServer()
    }
    
    func fetchTasksFromServer(completion: @escaping CompletionHandler = { _ in }) {
        let requestURL = baseURL.appendingPathExtension("json")
        
        URLSession.shared.dataTask(with: requestURL) { (data, _, error) in
            if let error = error {
                print("Error fetching tasks: \(error)")
                completion(.failure(.otherError))
                return
            }
            guard let data = data else {
                print("No data returned by data task")
                completion(.failure(.noData))
                return
            }
            do {
                let taskRepresentations = Array(try JSONDecoder().decode([String : TaskRepresentation].self, from: data).values)
                try self.updateTasks(with: taskRepresentations)
                completion(.success(true))
            } catch {
                print("Error decoding task representations: \(error)")
                completion(.failure(.failedDecode))
                return
            }
        }.resume()
    }
    
    func sendTaskToServer(task: Task, completion: @escaping CompletionHandler = { _ in }) {
        guard let uuid = task.identifier else {
            completion(.failure(.noIdentifier))
            return
        }
        // baseURL/[uuid].json
        let requestURL = baseURL.appendingPathComponent(uuid.uuidString).appendingPathExtension("json")
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "PUT"
        do {
            guard let representation = task.taskRepresentation else {
                completion(.failure(.noRep))
                return
            }
            request.httpBody = try JSONEncoder().encode(representation)
        } catch {
            NSLog("Error encoding task \(task): \(error)")
            completion(.failure(.failedEncode))
            return
        }
        
        URLSession.shared.dataTask(with: request) { (data, _, error) in
            if let error = error {
                NSLog("Error sending task to server \(task): \(error)")
                completion(.failure(.otherError))
                return
            }
            
            completion(.success(true))
        }.resume()
    }
    
    func deleteTaskFromServer(_ task: Task, completion: @escaping CompletionHandler = { _ in }) {
        guard let uuid = task.identifier else {
            completion(.failure(.noIdentifier))
            return
        }
        
        let requestURL = baseURL.appendingPathComponent(uuid.uuidString).appendingPathExtension("json")
        var request = URLRequest(url: requestURL)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            print(response!)
            completion(.success(true))
        }.resume()
        
    }
    
    private func updateTasks(with representations: [TaskRepresentation]) throws {
        let context = CoreDataStack.shared.container.newBackgroundContext()
        
        let identifiersToFetch = representations.compactMap({UUID(uuidString: $0.identifier)})
        
        let representationsByID = Dictionary(uniqueKeysWithValues: zip(identifiersToFetch, representations))
        var tasksToCreate = representationsByID
        
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiersToFetch)
        
//        let context = CoreDataStack.shared.mainContext
        context.performAndWait {
            do {
                let existingTasks = try context.fetch(fetchRequest)
                // update existing
                for task in existingTasks {
                    guard let id = task.identifier, let representation = representationsByID[id] else { continue }
                    // we already have the task, so we should update
                    task.name = representation.name
                    task.notes = representation.notes
                    task.priority = representation.priority
                    task.complete = representation.complete
                    
                    tasksToCreate.removeValue(forKey: id)
                }
                // create new
                for representation in tasksToCreate.values {
                    Task(taskRepresentation: representation, context: context)
                }
            } catch {
                print("Error fetching tasks for UUIDs: \(error)")
            }
        }
        try CoreDataStack.shared.save(context: context)
        
//        do {
//            let existingTasks = try context.fetch(fetchRequest)
//            // update existing
//            for task in existingTasks {
//                guard let id = task.identifier, let representation = representationsByID[id] else { continue }
//                // we already have the task, so we should update
//                task.name = representation.name
//                task.notes = representation.notes
//                task.priority = representation.priority
//                task.complete = representation.complete
//
//                tasksToCreate.removeValue(forKey: id)
//            }
//            // create new
//            for representation in tasksToCreate.values {
//                Task(taskRepresentation: representation, context: context)
//            }
//        } catch {
//            print("Error fetching tasks for UUIDs: \(error)")
//        }
//        try CoreDataStack.shared.mainContext.save()
    }
    
    private func update(task: Task, with representation: TaskRepresentation) {
        
    }
    
    private func saveToPersistentStore() throws {
        
    }
}
