import SwiftUI

struct ReminderDatePickerView: View {
    @Binding var selectedDate: Date    // Date sélectionnée, liée à la vue parente
    var onValidate: () -> Void         // Action à faire quand on valide le choix
    var onCancel: () -> Void           // Action à faire quand on annule

    var body: some View {
        NavigationView {
            VStack {
                // Sélecteur de date et heure avec affichage graphique
                DatePicker("Choisis la date et l’heure", selection: $selectedDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
                    .padding()

                Spacer()

                // Boutons "Annuler" et "Valider" en bas
                HStack {
                    Button("Annuler") {
                        onCancel()    // Appelle la fonction annuler passée en paramètre
                    }
                    .padding()

                    Spacer()

                    Button("Valider") {
                        onValidate()  // Appelle la fonction valider passée en paramètre
                    }
                    .padding()
                }
            }
            .onAppear {
                print("Modale ReminderDatePickerView ouverte")
            }
            .navigationTitle("Quand te le rappeler ?")  // Titre en haut de la vue
        }
    }
}
