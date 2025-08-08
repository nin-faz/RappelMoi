import SwiftUI

struct ContentView: View {
    // On crée une instance observée du SpeechManager
    @StateObject private var speechManager = SpeechManager()

    var body: some View {
        VStack(spacing: 20) {
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
