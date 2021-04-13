//
//  CreateMealTableViewController.swift
//  recipebook
//
//  Created by Andre Pham on 7/4/21.
//

import UIKit

class CreateMealTableViewController: UITableViewController {

    // MARK: - Properties
    
    // Identifiers
    let CELL_MEAL_NAME: String = "mealNameCell"
    let CELL_MEAL_INSTRUCTIONS: String = "mealInstructionsCell"
    let CELL_MEAL_INGREDIENT: String = "mealIngredientCell"
    let CELL_ADD_INGREDIENT: String = "addIngredientCell"
    
    // Sections
    let SECTION_MEAL_NAME: Int = 0
    let SECTION_MEAL_INSTRUCTIONS: Int = 1
    let SECTION_MEAL_INGREDIENTS: Int = 2
    let SECTION_ADD_INGREDIENT: Int = 3
    
    // Core Data
    weak var databaseController: DatabaseProtocol?
    
    // Other properties
    var mealName: String = ""
    var mealInstructions: String = ""
    var mealIngredients: [IngredientMeasurementData] = []
    
    // MARK: - Methods

    /// Calls on page load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Sets property databaseController to reference to the databaseController from AppDelegate
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        // Sets title to meal name if a meal is selected
        if self.mealName.count != 0 {
            self.title = self.mealName
        }
    }

    /// Returns how many sections the TableView has
    override func numberOfSections(in tableView: UITableView) -> Int {
        // Section 0: meal name
        // Section 1: meal instructions
        // Section 2: meal ingredients
        // Section 3: option to add ingredient
        return 4
    }

    /// Returns the number of rows in any given section
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case SECTION_MEAL_NAME:
            // Section displays the meal's name
            return 1
        case SECTION_MEAL_INSTRUCTIONS:
            // Section displays the meal's instructions
            return 1
        case SECTION_MEAL_INGREDIENTS:
            // If there's no ingredients, there's one cell that indicates that
            if mealIngredients.count == 0 {
                return 1
            }
            // Cell for each ingredient
            return self.mealIngredients.count
        case SECTION_ADD_INGREDIENT:
            // Section displays option to add more ingredients
            return 1
        default:
            return 0
        }
    }
    
    /// Creates the cells and contents of the TableView
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == SECTION_MEAL_NAME {
            let cell = tableView.dequeueReusableCell(withIdentifier: CELL_MEAL_NAME, for: indexPath)
            
            if self.mealName.count == 0 {
                cell.textLabel?.text = "Tap to enter meal name."
                cell.textLabel?.textColor = UIColor(named: "defaultCellContent")
            }
            else {
                cell.textLabel?.text = self.mealName
                cell.textLabel?.textColor = UIColor.label
            }
            
            return cell
        }
        else if indexPath.section == SECTION_MEAL_INSTRUCTIONS {
            let cell = tableView.dequeueReusableCell(withIdentifier: CELL_MEAL_INSTRUCTIONS, for: indexPath)
            
            if self.mealInstructions.count == 0 {
                cell.textLabel?.text = "Tap to enter meal instructions."
                cell.textLabel?.textColor = UIColor(named: "defaultCellContent")
            }
            else {
                cell.textLabel?.text = self.mealInstructions
                cell.textLabel?.textColor = UIColor.label
            }
            
            return cell
        }
        else if indexPath.section == SECTION_MEAL_INGREDIENTS {
            let cell = tableView.dequeueReusableCell(withIdentifier: CELL_MEAL_INGREDIENT, for: indexPath)
            
            cell.selectionStyle = UITableViewCell.SelectionStyle.none
            
            if self.mealIngredients.count == 0 {
                cell.textLabel?.text = "No ingredients!"
                cell.textLabel?.textColor = UIColor(named: "defaultCellContent")
                cell.detailTextLabel?.text = ""
            }
            else {
                let ingredient = mealIngredients[indexPath.row]
                
                cell.textLabel?.text = ingredient.name
                cell.textLabel?.textColor = UIColor.label
                cell.detailTextLabel?.text = ingredient.quantity
            }
            
            return cell
        }
        else {
            // indexPath.section == SECTION_ADD_INGREDIENT
            
            let cell = tableView.dequeueReusableCell(withIdentifier: CELL_ADD_INGREDIENT, for: indexPath)
            
            cell.textLabel?.text = "Add Ingredient"
            cell.textLabel?.textColor = UIColor(named: "defaultCellContent")
            
            return cell
        }
    }
    
    /// Returns whether a given section can be edited
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == SECTION_MEAL_INGREDIENTS && self.mealIngredients.count > 0 {
            return true
        }

        return false
    }
    
    /// Allows the deletion of ingredients via swipe gesture
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete && indexPath.section == SECTION_MEAL_INGREDIENTS {
            tableView.performBatchUpdates({
                    self.mealIngredients.remove(at: indexPath.row)
                    self.tableView.deleteRows(at: [indexPath], with: .fade)
                    self.tableView.reloadSections([SECTION_MEAL_INGREDIENTS], with: .automatic)
                },
                completion: nil
            )
        }
    }
    
    /// Assigns headers to the sections of cells
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case SECTION_MEAL_NAME:
            return "MEAL NAME"
        case SECTION_MEAL_INSTRUCTIONS:
            return "INSTRUCTIONS"
        case SECTION_MEAL_INGREDIENTS:
            return "INGREDIENTS"
        case SECTION_ADD_INGREDIENT:
            return nil
        default:
            return nil
        }
    }
    
    /// Transfers relevant infromation to ViewControllers to edit either the meal name, instructions or ingredients when the user travels there
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editMealName" {
            // Define the destination ViewController to assign its properties
            let destination = segue.destination as! EditMealNameViewController
            
            // Assign properties to the destination ViewController
            destination.previousMealName = self.mealName
            destination.editMealDelegate = self
        }
        else if segue.identifier == "editMealInstructions" {
            // Define the destination ViewController to assign its properties
            let destination = segue.destination as! EditMealInstructionsViewController
            
            // Assign properties to the destination ViewController
            destination.previousMealInstructions = self.mealInstructions
            destination.editMealDelegate = self
        }
        else {
            // segue.identifier == "editMealIngredients"
            
            // Define the destination ViewController to assign its properties
            let destination = segue.destination as! EditMealIngredientsTableViewController
            
            // Assign properties to the destination ViewController
            destination.editMealDelegate = self
        }
    }
    
    // MARK: - Actions
    
    /// Saves the meal to core data and returns the user to the root page when the 'Save' button is clicked
    @IBAction func saveMeal(_ sender: Any) {
        // Validation
        var errorMessages = [String]()
        if self.mealName.count == 0 {
            errorMessages.append("has a name")
        }
        if self.mealInstructions.count == 0 {
            errorMessages.append("has one or more instructions")
        }
        if self.mealIngredients.count == 0 {
            errorMessages.append("has one or more ingredients")
        }
        if errorMessages.count > 0 {
            var errorMessage: String
            if errorMessages.count > 1 {
                let firstErrors = errorMessages[0...(errorMessages.count-2)].joined(separator: ", ")
                errorMessage = "Please ensure the meal \(firstErrors) and \(errorMessages[errorMessages.count-1])."
            }
            else {
                errorMessage = "Please ensure the meal \(errorMessages[0])."
            }
            Popup.displayPopup(title: "Invalid Meal", message: errorMessage, viewController: self)
            return
        }
        
        // Save to core data
        if let newMeal = databaseController?.addMeal(name: self.mealName, instructions: self.mealInstructions) {
            for ingredient in self.mealIngredients {
                let name = ingredient.name!
                let quantity = ingredient.quantity!
                let _ = databaseController?.addIngredientMeasurementToMeal(name: name, quantity: quantity, meal: newMeal)
            }
        }
        
        navigationController?.popToRootViewController(animated: true)
        return
    }
    
}

// MARK: - EditMealDelegate Extension

extension CreateMealTableViewController: EditMealDelegate {
    
    /// Delegate function to update the meal name
    func updateMealName(_ newMealName: String) {
        self.mealName = newMealName
        
        if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: SECTION_MEAL_NAME)) {
            cell.textLabel?.text = newMealName
            self.tableView.reloadSections([SECTION_MEAL_NAME], with: .automatic)
        }
    }
    
    /// Delegate function to update the meal instructions
    func updateMealInstructions(_ newMealInstructions: String) {
        self.mealInstructions = newMealInstructions
        
        if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: SECTION_MEAL_INSTRUCTIONS)) {
            cell.textLabel?.text = newMealInstructions
            self.tableView.reloadSections([SECTION_MEAL_INSTRUCTIONS], with: .automatic)
        }
    }
    
    /// Delegate function to update the meal ingredients
    func updateMealIngredients(_ newIngredient: IngredientMeasurementData) {
        self.mealIngredients.append(newIngredient)
        self.tableView.reloadSections([SECTION_MEAL_INGREDIENTS], with: .automatic)
    }
    
}
