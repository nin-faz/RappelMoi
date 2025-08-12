import Foundation
import AVFoundation
import Speech
import Combine

// Wrapper pour gérer les alertes avec Identifiable
struct AlertWrapper: Identifiable {
    let id = UUID()
    let message: String
}

var audioPlayer: AVAudioPlayer?

// Classe qui gère la synthèse vocale et la reconnaissance vocale
class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {

    // Variables observables pour informer la vue (ContentView) des changements
    @Published var recognizedText = ""   // Texte reconnu par la reconnaissance vocale
    @Published var isRecording = false   // Est-ce que l'enregistrement est en cours ?
    @Published var isSpeaking = false    // Est-ce que la synthèse vocale parle ?
    @Published var alertMessage: AlertWrapper? // Message d'alerte à afficher en cas d'erreur ou problème
    @Published var readyToListen = false // Pour enregistrer notre voix juste après le son d'activation vocale
    @Published var reminders: [Reminder] = [] // Liste observable de rappels que l'on va afficher dans l'UI
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "fr-FR")) // Reconnaissance vocale FR
    private let audioEngine = AVAudioEngine() // Gère l'entrée audio du micro
    private var request = SFSpeechAudioBufferRecognitionRequest() // Objet pour envoyer les données audio à Apple
    private var recognitionTask: SFSpeechRecognitionTask? // Tâche de reconnaissance en cours
    private var speechSynthesizer = AVSpeechSynthesizer() // Pour parler avec la voix synthétique
    
    private var silenceTimer: Timer? // Timer pour détecter le silence prolongé
    
    // Initialisation : on met ce SpeechManager en tant que délégué pour la synthèse vocale
    override init() {
        super.init()
        speechSynthesizer.delegate = self
    }
    
    // Fonction pour jouer un son de démarrage (notif-activation-vocale.mp3)
    func playSoundThenStartRecording() {
        readyToListen = false // On est pas encore prêt
        guard let soundURL = Bundle.main.url(forResource: "notif-activation-vocale", withExtension: "mp3") else {
            print("🔇 Son introuvable")
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.delegate = self
            audioPlayer?.play()
        } catch {
            print("Erreur de lecture du son : \(error.localizedDescription)")
        }
    }
    
    // Demande d'autorisation pour accéder au micro et à la reconnaissance vocale
    func requestPermissionAndRecord() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    self.startRecording()  // Autorisé : on commence à écouter
                } else {
                    self.alertMessage = AlertWrapper(message: "Autorisation refusée pour la reconnaissance vocale.")
                }
            }
        }
    }
    
    // Démarre l'enregistrement audio et lance la reconnaissance vocale
    func startRecording() {
        recognizedText = ""  // Réinitialise le texte reconnu
        isRecording = true   // Indique que l'enregistrement est actif
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            alertMessage = AlertWrapper(message: "Erreur de session audio : \(error.localizedDescription)")
            isRecording = false
            return
        }
        
        let inputNode = audioEngine.inputNode
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            alertMessage = AlertWrapper(message: "Erreur lors du démarrage de l'audio.")
            isRecording = false
            return
        }
        
        let inputFormat = inputNode.inputFormat(forBus: 0)
//        print("Input format: \(inputFormat)")

        // Crée une nouvelle requête pour bufferiser l'audio
        request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true // Rapport des résultats partiels (en temps réel)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { buffer, when in
            self.request.append(buffer)
        }
        

        // Lance la reconnaissance vocale avec la requête
        recognitionTask = speechRecognizer?.recognitionTask(with: request) { result, error in
            if let result = result {
                self.recognizedText = result.bestTranscription.formattedString // Mets à jour le texte reconnu
                
                // 🔁 Réinitialise le timer à chaque mot reconnu
                self.startSilenceTimer()
            }
            
            // Si erreur ou fin de reconnaissance, on arrête l'enregistrement
            if error != nil || (result?.isFinal ?? false) {
                self.stopRecording()
            }
        }
        
        // 🕒 Démarre le timer de silence dès le début de l’écoute
        startSilenceTimer()
    }
    
    // Arrête l'enregistrement et la reconnaissance vocale
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        isRecording = false
        
        // 🛑 Arrête le timer de silence
        silenceTimer?.invalidate()
        silenceTimer = nil
    }
    
    // Lance ou relance le timer de silence de 3 secondes
    private func startSilenceTimer() {
        silenceTimer?.invalidate() // On annule l'ancien timer s'il existe
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            print("⏱️ Silence détecté, arrêt de l'écoute.")
            self.stopRecording()
        }
    }
    
    // Fonction pour que la machine parle avec la voix synthétique
    func speak(text: String) {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate) // Stop la parole précédente si besoin
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
            
            // Vérifie si le volume est à zéro (silencieux)
            if audioSession.outputVolume == 0 {
                alertMessage = AlertWrapper(message: "Ton iPhone est en mode silencieux ou le volume est à zéro, augmente le son.")
                return
            }
            
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "fr-FR")
            speechSynthesizer.speak(utterance) // Lance la synthèse vocale
            isSpeaking = true
            
        } catch {
            alertMessage = AlertWrapper(message: "Erreur : \(error.localizedDescription)")
        }
    }
    
    // Fonction pour ajouter un nouveau rappel à la liste
    func addReminder(text: String, date: Date) {
        guard date >= Date() else {
            alertMessage = AlertWrapper(message: "Impossible de mettre un rappel dans le passé.")
            return
        }
        let newReminder = Reminder(text: text, date: date)  // Crée un rappel avec le texte et la date fournis
        reminders.append(newReminder) // Ajoute ce rappel à la liste
    }
}

// AVSpeechSynthesizerDelegate
extension SpeechManager {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
}

// AVAudioPlayerDelegate
extension SpeechManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        readyToListen = true
        isRecording = true
        do {
            try AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Erreur remise session audio : \(error.localizedDescription)")
        }
        startRecording()
    }
}
