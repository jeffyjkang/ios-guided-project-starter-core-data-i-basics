//
//  TaskDetailViewController.swift
//  Tasks
//
//  Created by Jeff Kang on 12/4/20.
//  Copyright © 2020 Lambda School. All rights reserved.
//

import UIKit

class TaskDetailViewController: UIViewController {
    
    // MARK: - Properties
    var taskController: TaskController?
    var task: Task?
    var wasEdited = false
    
    // MARK: - IBOutlets
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var completeButton: UIButton!
    @IBOutlet weak var prioritySegmentedControl: UISegmentedControl!
    @IBOutlet weak var notesTextView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationItem.rightBarButtonItem = editButtonItem
        updateViews()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if wasEdited {
            guard let name = nameTextField.text, !name.isEmpty, let task = task else { return }
            
            let notes = notesTextView.text
            task.name = name
            task.notes = notes
            let priorityIndex = prioritySegmentedControl.selectedSegmentIndex
            task.priority = TaskPriority.allCases[priorityIndex].rawValue
            taskController?.sendTaskToServer(task: task)
            do {
                try CoreDataStack.shared.mainContext.save()
            } catch {
                NSLog("Error saving managed object context")
            }
        }
    }
    
    // MARK: - Actions
    @IBAction func toggleComplete(_ sender: UIButton) {
        wasEdited = true
        task?.complete.toggle()
        sender.setImage((task?.complete ?? false) ? UIImage(systemName: "checkmark.square.fill") : UIImage(systemName: "square"), for: .normal)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if editing { wasEdited = true }
        
        nameTextField.isUserInteractionEnabled = editing
        notesTextView.isUserInteractionEnabled = editing
        prioritySegmentedControl.isUserInteractionEnabled = editing
        navigationItem.hidesBackButton = editing
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    private func updateViews() {
        nameTextField.text = task?.name
        nameTextField.isUserInteractionEnabled = isEditing
        
        notesTextView.text = task?.notes
        notesTextView.isUserInteractionEnabled = isEditing
        
        completeButton.setImage((task?.complete ?? false) ? UIImage(systemName: "checkmark.square.fill") : UIImage(systemName: "square"), for: .normal)
        
        let priority: TaskPriority
        if let taskPriority = task?.priority {
            priority = TaskPriority(rawValue: taskPriority)!
        } else {
            priority = .normal
        }
        prioritySegmentedControl.selectedSegmentIndex = TaskPriority.allCases.firstIndex(of: priority) ?? 1
        prioritySegmentedControl.isUserInteractionEnabled = isEditing
    }
    
}
