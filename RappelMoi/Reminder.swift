import Foundation

// Modèle représentant un rappel avec un identifiant unique, un texte, et une date
struct Reminder: Identifiable, Codable {
    let id: UUID          // Identifiant unique pour chaque rappel
    var text: String          // Le texte du rappel (ex : "acheter parfum Dior")
    var date: Date            // La date et l'heure du rappel
    
    // Initialiseur personnalisé qui génère un id si non fourni
    init(id: UUID = UUID(), text: String, date: Date) {
        self.id = id
        self.text = text
        self.date = date
    }
}
