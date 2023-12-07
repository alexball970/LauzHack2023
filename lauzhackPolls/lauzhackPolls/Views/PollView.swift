//
//  PollView.swift
//  lauzhackPolls
//
//  Created by Julien Coquet on 02/12/2023.
//


import SwiftUI
import FirebaseFirestore
import CoreImage.CIFilterBuiltins


class PollViewModel0: ObservableObject {
    // ... other properrties and methods
    
    @Published var comments: String = "" // Store fetched comments
    
    func fetchComments(for pollId: String) {
        let db = Firestore.firestore()
        let documentRef = db.document("comments/\(pollId)")
        documentRef.getDocument { documentSnapshot, error in
            if let error = error {
                // Handle error
                print("Error fetching comments: \(error.localizedDescription)")
                return
            }
            
            if let data = documentSnapshot?.data(), let content = data["content"] as? String {
                // Update comments when data is fetched
                DispatchQueue.main.async {
                    self.comments = content
                }
            }
        }
    }
}





struct PollView: View {
    
    let db = Firestore.firestore()
    var vm: PollViewModel
    var error: String? = nil
    var comments = [String]()
    @StateObject var vm0 = PollViewModel0()
    @State private var commentInput: String = ""
    @State var promttf = ""
    @State var Answer = ""
    @State var degrees = 0.0
    let theopenaiclass = OpenAIConnector()
    
    @State private var isQRCodeSheetPresented = false
    @State private var generatedQRCode: UIImage? = nil
    
    let filter = CIFilter.qrCodeGenerator()
    let context = CIContext()
    
    func generateQRCode(_ pollId : String) -> UIImage {
        let customScheme = "QRscan" // Replace with your app's custom scheme
        let urlString = "\(customScheme)://poll/\(pollId)"
        let data = Data(urlString.utf8)
        filter.setValue(data , forKey: "inputMessage")
        if let qrCodeImage = filter.outputImage {
            if let qrCodeCGImage = context.createCGImage(qrCodeImage, from: qrCodeImage.extent) {
                return UIImage(cgImage: qrCodeCGImage)
            }
        }
        return UIImage(systemName: "xmark") ?? UIImage()
    }
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading) {
                    Text("Poll ID")
                    Text(vm.pollId)
                        .font(.caption)
                        .textSelection(.enabled)
                }
                
                HStack {
                    Text("Updated at")
                    Spacer()
                    if let updatedAt = vm.poll?.updatedAt {
                        Text(updatedAt, style: .time)
                    }
                }
                
                HStack {
                    Text("Total Vote Count")
                    Spacer()
                    if let totalCount = vm.poll?.totalCount {
                        Text(String(totalCount))
                    }
                }
                
            }
            
            
            if let options = vm.poll?.options {
                Section {
                    PollChartView(options: options)
                        .frame(height: 200)
                        .padding(.vertical)
                }
                
                Section("Vote") {
                    ForEach(options) { option in
                        Button(action: {
                            vm.incrementOption(option)
                        }, label: {
                            HStack {
                                // Text("+1")
                                Text(option.name)
                                Spacer()
                                Text(String(option.count))
                            }
                        })
                    }
                
                Section("Forum") {
                    VStack {
                        if Answer.count != 0{
                            Text(Answer)
                        }
                        // Text(Answer)
                        ZStack{
                            TextEditor(text: $promttf)
                                .font(.body)
                                .cornerRadius(10)
                                .frame(height: 0)
                            //                        if promttf1.count == 0{
                            //                            Text("").foregroundColor(.gray)
                            //                        }
                        }
                        Button(action:{

                                            Answer = theopenaiclass.processPrompt(prompt: "Generate a summary that captures the key points of this conversation and that captures what the majority of people are saying: \(vm0.comments)")!

                                        }){
                                            Label("Generate AI Summary", systemImage: "chart.bar.fill")
                                                .padding()
                                                .foregroundColor(.white)
                                                .background(Color.blue)
                                                .cornerRadius(8)
                                        }
                    }
                }
                    Section {
                                    VStack(alignment: .leading) {
                                        Text("Log")
                                        Text(vm0.comments)
                                            .font(.caption)
                                            .textSelection(.enabled)
                                    }
                                    .onAppear {
                                        vm0.fetchComments(for: vm.pollId) // Fetch comments when the view appears
                                    }
                                }
                Section {
                    TextField("Enter comment", text: $commentInput)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        
                    Button("Submit") {
                        vm.newComment = commentInput
                        commentInput = ""
                        // Assigning the comment to view model property
                        Task { await vm.createNewComment() }
                        }
                        
                    }
                    
                    
                }
                Section {
                    DisclosureGroup("QR Code"){
                        VStack {
                            Spacer()
                            Image(uiImage: generateQRCode(vm.pollId))
                                .interpolation(.none)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .padding()
                            Spacer()
                        }
                    }
                }
                
            }
        }
        .navigationTitle(vm.poll?.name ?? "")
        .onAppear {
            vm.listenToPoll()
        }

    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


public class OpenAIConnector {
    let openAIURL = URL(string: "https://api.openai.com/v1/engines/text-davinci-002/completions")
    var openAIKey: String {
        return "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"
    }
    
    private func executeRequest(request: URLRequest, withSessionConfig sessionConfig: URLSessionConfiguration?) -> Data? {
        let semaphore = DispatchSemaphore(value: 0)
        let session: URLSession
        if (sessionConfig != nil) {
            session = URLSession(configuration: sessionConfig!)
        } else {
            session = URLSession.shared
        }
        var requestData: Data?
        let task = session.dataTask(with: request as URLRequest, completionHandler:{ (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if error != nil {
                print("error: \(error!.localizedDescription): \(error!.localizedDescription)")
            } else if data != nil {
                requestData = data
            }
            
            print("Semaphore signalled")
            semaphore.signal()
        })
        task.resume()
        
        // Handle async with semaphores. Max wait of 10 seconds
        let timeout = DispatchTime.now() + .seconds(20)
        print("Waiting for semaphore signal")
        let retVal = semaphore.wait(timeout: timeout)
        print("Done waiting, obtained - \(retVal)")
        return requestData
    }
    
    public func processPrompt(
        prompt: String
    ) -> Optional<String> {
        
        var request = URLRequest(url: self.openAIURL!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(self.openAIKey)", forHTTPHeaderField: "Authorization")
        let httpBody: [String: Any] = [
            "prompt" : prompt,
            "max_tokens" : 100
     //       "temperature": String(temperature)
        ]
        
        var httpBodyJson: Data
        
        do {
            httpBodyJson = try JSONSerialization.data(withJSONObject: httpBody, options: .prettyPrinted)
        } catch {
            print("Unable to convert to JSON \(error)")
            return nil
        }
        request.httpBody = httpBodyJson
        if let requestData = executeRequest(request: request, withSessionConfig: nil) {
            let jsonStr = String(data: requestData, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
            print(jsonStr)
            ///
            //MARK: I know there's an error below, but we'll fix it later on in the article, so make sure not to change anything
            ///
            let responseHandler = OpenAIResponseHandler()

            return responseHandler.decodeJson(jsonString: jsonStr)?.choices[0].text
            
        }
        
        return nil
    }
}
struct OpenAIResponseHandler {
    func decodeJson(jsonString: String) -> OpenAIResponse? {
        let json = jsonString.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        do {
            let product = try decoder.decode(OpenAIResponse.self, from: json)
            
            return product
            
        } catch {
            print("Error decoding OpenAI API Response")
        }
        
        return nil
    }
}

struct OpenAIResponse: Codable{
    var id: String
    var object : String
    var created : Int
    var model : String
    var choices : [Choice]
}
struct Choice : Codable{
    var text : String
    var index : Int
    var logprobs: String?
    var finish_reason: String
}

public extension Binding where Value: Equatable {
    init(_ source: Binding<Value?>, replacingNilWith nilProxy: Value) {
        self.init(
            get: { source.wrappedValue ?? nilProxy },
            set: { newValue in
                if newValue == nilProxy {
                    source.wrappedValue = nil
                }
                else {
                    source.wrappedValue = newValue
                }
        })
    }
}


#Preview {
    NavigationStack {
        PollView(vm: .init(pollId: "22262451-09CC-4E9F-8556-616DA9A5207D"))
    }
}


