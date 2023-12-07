//
//  HomeView.swift
//  lauzhackPolls
//
//  Created by Julien Coquet on 02/12/2023.
//


import SwiftUI
import AVFoundation
import UIKit

struct HomeView: View {
    @Bindable var vm = HomeViewModel()
    
    @State private var isScannerActive = false
    @State private var scannedCode: String? = nil
    
    @State private var pollInput: String = ""

    var body: some View {
        List {
            existingPollSection
            livePollsSection
            myPollsSection
            createPollsSection
            addOptionsSection
        }
        .scrollDismissesKeyboard(.interactively)
        .alert("Error", isPresented: .constant(vm.error != nil)) {
            
        } message: {
            Text(vm.error ?? "an error occured")
        }
        .sheet(item: $vm.modalPollId) { id in
            NavigationStack {
                PollView(vm: .init(pollId: id))
            }
        }
        .navigationTitle("EPFL Polls")
        .onAppear {
            
            vm.listenToLivePolls()
        }
        .onOpenURL { url in
                vm.handleURLScheme(url)
        }
    }

    var existingPollSection: some View {
        Section(header: Text("")) {
            DisclosureGroup {
                TextField("Enter poll id", text: $pollInput)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Button("Join") {
                    vm.existingPollId = pollInput
                    pollInput = ""
                    Task { await vm.joinExistingPoll() }
                    
                }
            } label: {
                Label("Join a Poll", systemImage: "link")
            }
        }
    }

    var livePollsSection: some View {
        Section{
            DisclosureGroup("Latest Live Polls"){
                ForEach(vm.polls) { poll in
                    VStack {
                        HStack(alignment: .top) {
                            Text(poll.name)
                            Spacer()
                            Image(systemName: "chart.bar.xaxis")
                            Text(String(poll.totalCount))
                            if let updatedAt = poll.updatedAt {
                                Image(systemName: "clock.fill")
                                Text(updatedAt, style: .time)
                            }
                        }
                        PollChartView(options: poll.options)
                            .frame(height: 160)
                    }
                    .padding(.vertical)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        vm.modalPollId = poll.id
                    }
                }
            
            }
        }
    }

    var myPollsSection: some View {
        Section{
            DisclosureGroup("My Polls"){
                ForEach(vm.polls) { poll in
                    VStack {
                        HStack(alignment: .top) {
                            Text(poll.name)
                            Spacer()
                            let highestCountOption = poll.options.max(by: { $0.count < $1.count })

                            if let highestCountOption = highestCountOption {
                                Text("Winner: \(highestCountOption.name)")
                            } else {
                                Text("No options available")
                            }
                        }
                    }
                    .padding(.vertical)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        vm.modalPollId = poll.id
                    }
                }
            
            }
        }
    }

    var createPollsSection: some View {
        Section(header: Text("Create a Poll"), footer: Text("Enter poll name & add 2-4 options to submit")) {
            TextField("Enter poll name", text: $vm.newPollName, axis: .vertical)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            Button("Submit") {
                Task { await vm.createNewPoll() }
            }
            .disabled(vm.isCreateNewPollButtonDisabled)
            .padding(.vertical)

            if vm.isLoading {
                ProgressView()
            }
        }
    }

    var addOptionsSection: some View {
        Section(header: Text("Options")) {
            TextField("Enter option name", text: $vm.newOptionName)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            Button("+ Add Option") {
                vm.addOption()
            }
            .disabled(vm.isAddOptionsButtonDisabled)
            .padding(.vertical)

            ForEach(vm.newPollOptions, id: \.self) { option in
                Text(option)
            }
            .onDelete { indexSet in
                vm.newPollOptions.remove(atOffsets: indexSet)
            }
        }
    }
}

extension String: Identifiable {
    public var id: Self { self }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}


