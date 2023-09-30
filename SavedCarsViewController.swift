//
//  SavedCarsViewController.swift
//  CarID
//
//  Created by Aryan Sinha on 17/09/23.
//

import Foundation
import Foundation
import UIKit

class SavedCarsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    // Declare the savedCars array to hold the saved car data
    var savedCars: [SavedCar] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        // Configure the table view, set delegates, and data source
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    // Implement UITableViewDataSource and UITableViewDelegate methods to display saved cars in the table view.
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return savedCars.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SavedCarCell", for: indexPath) // Use your own cell identifier
        let savedCar = savedCars[indexPath.row]
        cell.textLabel?.text = savedCar.name
        // Optionally, display the timestamp as well: cell.detailTextLabel?.text = "\(savedCar.timestamp)"
        return cell
    }
}

