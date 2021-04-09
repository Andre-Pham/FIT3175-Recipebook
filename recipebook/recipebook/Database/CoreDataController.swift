import UIKit
import CoreData

class CoreDataController: NSObject {
    // Required properties
    var listeners = MulticastDelegate<DatabaseListener>()
    var persistentContainer: NSPersistentContainer
    
    // What do these properties do???
    var allMealsFetchedResultsController: NSFetchedResultsController<Meal>?
    var allIngredientsFetchedResultsController: NSFetchedResultsController<Ingredient>?
    
    // Constructor
    override init() {
        persistentContainer = NSPersistentContainer(name: "RecipebookDataModel")
        persistentContainer.loadPersistentStores() {
            (description, error) in if let error = error {
                fatalError("Failed to load Core Data Stack with error: \(error)")
            }
        }
        
        super.init()
    }
    
    // Retrieves all meal entities stored within Core Data persistent memory
    func fetchAllMeals() -> [Meal] {
        if allMealsFetchedResultsController == nil {
            // Instantiate fetch request
            let request: NSFetchRequest<Meal> = Meal.fetchRequest()
            let nameSortDescriptor = NSSortDescriptor(key: "name", ascending: true)
            request.sortDescriptors = [nameSortDescriptor]
            
            // Initialise Fetched Results Controller
            allMealsFetchedResultsController = NSFetchedResultsController<Meal>(fetchRequest: request, managedObjectContext: persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
            
            // Set this class to be the results delegate
            allMealsFetchedResultsController?.delegate = self
            
            // Perform fetch request
            do {
                try allMealsFetchedResultsController?.performFetch()
            }
            catch {
                print("Fetch Request Failed: \(error)")
            }
        }
        
        if let meals = allMealsFetchedResultsController?.fetchedObjects {
            return meals
        }
        
        return [Meal]() // Empty
    }

    // Retrieves all ingredient entities stored within Core Data persistent memory
    func fetchAllIngredients() -> [Ingredient] {
        if allIngredientsFetchedResultsController == nil {
            // Instantiate fetch request
            let request: NSFetchRequest<Ingredient> = Ingredient.fetchRequest()
            let nameSortDescriptor = NSSortDescriptor(key: "name", ascending: true)
            request.sortDescriptors = [nameSortDescriptor]
            
            // Initialise Fetched Results Controller
            allIngredientsFetchedResultsController = NSFetchedResultsController<Ingredient>(fetchRequest: request, managedObjectContext: persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
            
            // Set this class to be the results delegate
            allIngredientsFetchedResultsController?.delegate = self
            
            // Perform fetch request
            do {
                try allIngredientsFetchedResultsController?.performFetch()
            }
            catch {
                print("Fetch Request Failed: \(error)")
            }
        }
        
        if let ingredients = allIngredientsFetchedResultsController?.fetchedObjects {
            return ingredients
        }
        
        return [Ingredient]() // Empty
    }
}

extension CoreDataController: DatabaseProtocol {
    // Checks if there are changes to be saved inside of hte view context and then
    // saves, if necessary
    func saveChanges() {
        if persistentContainer.viewContext.hasChanges {
            do {
                try persistentContainer.viewContext.save()
            }
            catch {
                fatalError("Failed to save changes to Core Data with error: \(error)")
            }
        }
    }
    
    func addListener(listener: DatabaseListener) {
        // Adds the new database listener to the list of listeners
        listeners.addDelegate(listener)
        
        // Provides the listener with the initial immediate results depending on the type
        if listener.listenerType == .meal || listener.listenerType == .all {
            listener.onAnyMealChange(change: .update, meals: fetchAllMeals())
        }
        if listener.listenerType == .ingredient || listener.listenerType == .all {
            listener.onAnyIngredientChange(change: .update, ingredients: fetchAllIngredients())
        }
    }
    
    // Removes a specific listener from the set of saved listeners
    func removeListener(listener: DatabaseListener) {
        listeners.removeDelegate(listener)
    }
    
    func addMeal(name: String, instructions: String) -> Meal {
        // Create Meal entity
        let meal = NSEntityDescription.insertNewObject(forEntityName: "Meal", into: persistentContainer.viewContext) as! Meal
        // Assign attributes to Meal entity
        meal.name = name
        meal.instructions = instructions
        
        return meal
    }
    
    func deleteMeal(meal: Meal) {
        persistentContainer.viewContext.delete(meal)
    }
    
    func addIngredient(name: String, ingredientDescription: String) -> Ingredient {
        // Create Ingredient entity
        let ingredient = NSEntityDescription.insertNewObject(forEntityName: "Ingredient", into: persistentContainer.viewContext) as! Ingredient
        // Assign attributes to Meal entity
        ingredient.name = name
        ingredient.ingredientDescription = ingredientDescription
        
        return ingredient
    }
    
    func deleteIngredient(ingredient: Ingredient) {
        persistentContainer.viewContext.delete(ingredient)
    }
    
    func addIngredientMeasurementToMeal(ingredientMeasurement: IngredientMeasurement, meal: Meal) -> Bool {
        guard let mealIngredients = meal.ingredients, !mealIngredients.contains(ingredientMeasurement) else {
            return false
        }
        
        meal.addToIngredients(ingredientMeasurement)
        return true
    }
    
    func removeIngredientMeasurementFromMeal(ingredientMeasurement: IngredientMeasurement, meal: Meal) {
        meal.removeFromIngredients(ingredientMeasurement)
    }
    
}

extension CoreDataController: NSFetchedResultsControllerDelegate {
    // Called whenever the FetchedResultsController detects a change to the result
    // of its fetch
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if controller == allMealsFetchedResultsController {
            listeners.invoke() {
                listener in if listener.listenerType == .meal || listener.listenerType == .all {
                    listener.onAnyMealChange(change: .update, meals: fetchAllMeals())
                }
            }
        }
        else if controller == allIngredientsFetchedResultsController {
            listeners.invoke {
                (listener) in if listener.listenerType == .ingredient || listener.listenerType == .all {
                    listener.onAnyIngredientChange(change: .update, ingredients: fetchAllIngredients())
                }
            }
        }
    }
}
