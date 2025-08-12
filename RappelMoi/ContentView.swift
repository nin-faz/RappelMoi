import SwiftUI

struct ContentView: View {
    // On crée une instance observée du SpeechManager
    @StateObject private var speechManager = SpeechManager()
    
    // Date sélectionnée dans la modale (par défaut maintenant)
    @State private var selectedDate = Date()
    
    // Booléen pour afficher/masquer la modale de date
    @State private var showDatePicker = false
    
    // Texte reconnu en attente d’être ajouté en rappel
    @State private var pendingReminderText = ""

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 100))
                    .foregroundColor(.blue.opacity(0.5))
                    .offset(x: -15)
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 100))
                    .foregroundColor(.blue)
                    .offset(x: 15)
            }
            .frame(width: 100, height: 150)

            // 🧠 Header stylé
            VStack(spacing: 10) {
                // 🔔 Icône + Titre
                HStack(spacing: 10) {
                    Image(systemName: "bell.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                    Text("RappelMoi")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity)
                
                // 📏 Divider stylé
                Divider()
                    .background(Color.blue.opacity(0.7))
                
                // Liste des rappels enregistrés
                if speechManager.reminders.isEmpty {
                    Text("Aucun rappel enregistré pour l’instant.")
                        .foregroundColor(.gray)
                        .italic()
                        .padding()
                } else {
                    List {
                        ForEach(speechManager.reminders) { reminder in
                            VStack(alignment: .leading) {
                                Text(reminder.text)
                                    .font(.body)
                                Text(reminder.date, style: .date) + Text(" ") + Text(reminder.date, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(5)
                        }
                    }
                    .frame(maxHeight: 250) // Limite la hauteur de la liste
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
            
            
            VStack(spacing: 10) {
                
                Text("Nino appuie sur un bouton pour interagir !")
                    .font(.title)
                    .multilineTextAlignment(.center)
                    .padding()
                
                // Bouton pour déclencher la parole
                Button("Parle-moi") {
                    speechManager.speak(text: "Nino, n'oublie pas de régler Asocial et de renvoyer tes chaussures Zara")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                // Bouton pour lancer ou arrêter l'écoute
                Button(action: {
                    if speechManager.isRecording {
                        speechManager.stopRecording()
                        speechManager.readyToListen = false
                    } else {
                        speechManager.playSoundThenStartRecording()
                    }
                }) {
                    Text(speechManager.isRecording && speechManager.readyToListen ? "🎤 Je t'écoute, parle !" : "🎙️ Appuie pour parler")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background((speechManager.isRecording && speechManager.readyToListen) ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                // Affiche le texte reconnu
                Text("Ce que tu as dit :")
                    .font(.headline)
                
                Text(speechManager.recognizedText)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
            }
        }
        // Modale pour choisir la date et l’heure du rappel
        .sheet(isPresented: $showDatePicker) {
            ReminderDatePickerView(selectedDate: $selectedDate, onValidate: {
                speechManager.addReminder(text: pendingReminderText, date: selectedDate) // Ajout du rappel
                showDatePicker = false
                pendingReminderText = ""
            }, onCancel: {
                showDatePicker = false
                pendingReminderText = ""
            })
        }
        
        .onChange(of: speechManager.recognizedText) { newValue, _ in
            print("Texte reconnu changé : \(newValue)")  // <--- ça doit s'afficher dans ta console
            if !newValue.isEmpty && !speechManager.isRecording {
                pendingReminderText = newValue
                selectedDate = Date()
                showDatePicker = true
            }
        }


        // ⚠️ L'alerte doit être ici : sur la vue entière
        .alert(item: $speechManager.alertMessage) { alert in
            Alert(
                title: Text("Attention !"),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
