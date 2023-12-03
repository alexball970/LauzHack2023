//
//  PollView.swift
//  lauzhackPolls
//
//  Created by Julien Coquet on 02/12/2023.
//


import SwiftUI
import FirebaseFirestore

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
    @State var promttf1 = """
        user: Hi there! How are you today?
        assistant: I'm doing well, thank you! How about you?
        user: Oh, I'm doing fine, just a bit tired. By the way, did you catch the latest movie that was released?
        assistant: No, I haven't had the chance to watch it yet. What's the movie about?
        user: Well, it's a sci-fi thriller with a twist ending. John, my friend, recommended it to me.
        assistant: That sounds interesting! I'll have to check it out. Speaking of John, how is he doing these days?
        user: John is doing great. He recently got a promotion at work. He's excited about the new responsibilities.
        assistant: That's fantastic news! Please pass along my congratulations to him. By the way, have you made any exciting plans for the weekend?
        user: Not yet, but Sarah and I are thinking of going hiking. Sarah loves the outdoors, and it's been a while since we had a nature getaway.
        assistant: Hiking sounds like a wonderful idea. I'm sure you'll have a fantastic time. What's Sarah's favorite hiking spot?
        user: Sarah loves the trails in the national park. The scenery is breathtaking, especially during this time of the year when the leaves are changing colors.
        assistant: The national park is a beautiful choice. Make sure to take some photos to capture the autumn colors. By the way, did you hear about the new cafe that opened downtown?
        user: Yes, I did! Emily, my sister, visited it last week and said their pastries are amazing. We're planning to check it out this weekend after our hike.
        assistant: That sounds like a delightful plan! I hope the pastries live up to the hype. If you discover any hidden gems, let me know!
        user: Absolutely! Will do. So, what have you been up to lately?
        assistant: Well, I've been assisting users with various queries and learning from our conversations. It's always interesting to engage in diverse discussions.
        """
    @State var promttf = ""
    @State var Answer = ""
    @State var degrees = 0.0
    let theopenaiclass = OpenAIConnector()
    
    
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


