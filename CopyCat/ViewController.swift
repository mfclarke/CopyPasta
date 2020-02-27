//
//  ViewController.swift
//  CopyCat
//
//  Created by Maximilian Clarke on 28/2/20.
//  Copyright © 2020 Maximilian Clarke. All rights reserved.
//

import UIKit

let fileURL = FileManager().urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("CopyPastaData")

struct AppData: Codable {
    var strings: [String]
    
    init() {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            self = try decoder.decode(AppData.self, from: data)
        } catch {
            self = AppData(strings: [])
        }
    }
    
    init(strings: [String]) {
        self.strings = strings
    }
}

class ViewController: UITableViewController {
    
    var data = AppData()
    let pasteboard = UIPasteboard(name: .general, create: false)!
    
    var longPressGesture: UILongPressGestureRecognizer!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.allowsMultipleSelectionDuringEditing = true
        
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressGesture.minimumPressDuration = 0.5
        self.tableView.addGestureRecognizer(longPressGesture)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(handleNewItem))
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int { 1 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { data.strings.count }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        print("Copied to clipboard")
        pasteboard.string = data.strings[indexPath.row]
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.textLabel?.text = data.strings[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool { true }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle { .delete }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            data.strings.remove(at: indexPath.row)
            persistStrings()
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    @objc func handleLongPress() {
        let locationInTableView = longPressGesture.location(in: self.tableView)
        guard let indexPath = tableView.indexPathForRow(at: locationInTableView), longPressGesture.state == .began else {
            return
        }
        
        var editStringTextField: UITextField!
        
        let alert = UIAlertController(title: "Change text for item", message: nil, preferredStyle: .alert)
        
        let ok = UIAlertAction(title: "OK", style: .default) { [unowned self] _ in
            self.data.strings[indexPath.row] = editStringTextField.text ?? ""
            self.persistStrings()
            self.tableView.reloadRows(at: [indexPath], with: .fade)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ in }
        
        alert.addAction(ok)
        alert.addAction(cancel)
        
        alert.addTextField { textField in
            textField.text = self.data.strings[indexPath.row]
            editStringTextField = textField
        }
        
        present(alert, animated: true, completion: nil)
    }
    
    @objc func handleNewItem() {
        var newStringTextField: UITextField!
        
        let alert = UIAlertController(title: "Enter text for new item", message: nil, preferredStyle: .alert)
        
        let ok = UIAlertAction(title: "OK", style: .default) { [unowned self] _ in
            self.data.strings.append(newStringTextField.text ?? "")
            self.persistStrings()
            self.tableView.insertRows(at: [IndexPath(row: self.data.strings.count - 1, section: 0)], with: .top)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ in }
        
        alert.addAction(ok)
        alert.addAction(cancel)
        
        alert.addTextField { textField in
            newStringTextField = textField
        }
        
        present(alert, animated: true, completion: nil)
    }

    func persistStrings() {
        let encoder = JSONEncoder()
        do {
            let dataData = try encoder.encode(data)
            try dataData.write(to: fileURL)
        } catch {
            print("Error writing to file: \(error)")
        }
    }
}
